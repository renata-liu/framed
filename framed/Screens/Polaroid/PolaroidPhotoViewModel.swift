//
//  PolaroidPhotoViewModel.swift
//  framed
//
//  Created by Renata Liu on 2025-06-03.
//
import SwiftUI
import PhotosUI

final class PolaroidPhotoViewModel: ObservableObject {
    @Published var selectedPhoto: UIImage?
    @Published var photosPickerItem: PhotosPickerItem?
    @Published var showingSaveAlert = false
    @Published var saveMessage = ""
    
    @MainActor
    func loadAndFilterPhoto() async {
        if let photosPickerItem, let data = try? await photosPickerItem.loadTransferable(type: Data.self) {
            if let originalImage = UIImage(data: data) {
                let filteredImage = applyFilter(to: originalImage)
                selectedPhoto = filteredImage
            }
        }
        photosPickerItem = nil
    }
    
    func applyFilter(to image: UIImage) -> UIImage {
        guard let ciImage = CIImage(image: image) else { return image }
        
        let context = CIContext()
        let outputImage = applyPolaroidFilter(to: ciImage)
        
        guard let outputImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return image
        }
        
        return UIImage(cgImage: outputImage)
    }
    
    func applyPolaroidFilter(to image: CIImage) -> CIImage {
        let sourceExtent = image.extent
        let size = min(sourceExtent.width, sourceExtent.height)
        let cropRect = CGRect(
            x: (sourceExtent.width - size) / 2,
            y: (sourceExtent.height - size) / 2,
            width: size,
            height: size
        )
        let croppedImage = image.cropped(to: cropRect)
        
        let temperatureFilter = CIFilter.temperatureAndTint()
        temperatureFilter.inputImage = croppedImage
        temperatureFilter.neutral = CIVector(x: 6500, y: 0)
        temperatureFilter.targetNeutral = CIVector(x: 7200, y: 100)
        
        let colorControls = CIFilter.colorControls()
        colorControls.inputImage = temperatureFilter.outputImage
        colorControls.contrast = 1.0
        colorControls.brightness = 0.2
        colorControls.saturation = 0.9

        let vignette = CIFilter.vignette()
        vignette.inputImage = colorControls.outputImage
        vignette.intensity = 0.3
        vignette.radius = 1.5

        let noiseReduction = CIFilter.noiseReduction()
        noiseReduction.inputImage = vignette.outputImage
        noiseReduction.noiseLevel = 0.02
        noiseReduction.sharpness = 0.4
        
        let gaussianBlur = CIFilter.gaussianBlur()
        gaussianBlur.inputImage = noiseReduction.outputImage
        gaussianBlur.radius = 0.2
        
        let colorMatrix = CIFilter.colorMatrix()
        colorMatrix.inputImage = gaussianBlur.outputImage
        colorMatrix.rVector = CIVector(x: 1.05, y: 0.02, z: 0.0, w: 0.0)
        colorMatrix.gVector = CIVector(x: 0.0, y: 1.0, z: 0.05, w: 0.0)
        colorMatrix.bVector = CIVector(x: 0.0, y: 0.0, z: 0.95, w: 0.0)
        colorMatrix.aVector = CIVector(x: 0.0, y: 0.0, z: 0.0, w: 1.0)
        colorMatrix.biasVector = CIVector(x: 0.02, y: 0.01, z: -0.01, w: 0.0)
        
        return colorMatrix.outputImage ?? image
    }
    
    func saveImageToPhotos(_ image: UIImage) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized, .limited:
                    self.performSave(image)
                case .denied, .restricted:
                    self.saveMessage = "Photo library access denied. Please enable it in Settings."
                    self.showingSaveAlert = true
                case .notDetermined:
                    self.saveMessage = "Photo library access not determined."
                    self.showingSaveAlert = true
                @unknown default:
                    self.saveMessage = "Photo library access error."
                    self.showingSaveAlert = true
                }
            }
        }
    }
    
    func performSave(_ image: UIImage) {
        PHPhotoLibrary.shared().performChanges {
            PHAssetCreationRequest.creationRequestForAsset(from: image)
        } completionHandler: { success, error in
            DispatchQueue.main.async {
                if success {
                    self.saveMessage = "Photo saved to your photo library!"
                } else {
                    self.saveMessage = "Failed to save photo: \(error?.localizedDescription ?? "Unknown error")"
                }
                self.showingSaveAlert = true
            }
        }
    }
}

