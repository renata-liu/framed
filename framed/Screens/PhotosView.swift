//
//  PhotosView.swift
//  framed
//
//  Created by Renata Liu on 2025-06-03.
//
import SwiftUI
import PhotosUI
import CoreImage
import CoreImage.CIFilterBuiltins

struct PhotosView: View {
    @State private var selectedPhotos: [UIImage] = []
    @State private var photosPickerItems: [PhotosPickerItem] = []
    
    var body: some View {
        VStack {
            PhotosPicker("Pick photos", selection: $photosPickerItems, maxSelectionCount: 4, selectionBehavior: .ordered, matching: .any(of: [.images, .livePhotos, .screenshots, .bursts]))
                .padding()
            
            if !selectedPhotos.isEmpty {
                ScrollView(.horizontal) {
                    HStack(spacing: 20) {
                        ForEach(0..<selectedPhotos.count, id: \.self) { index in
                            VStack {
                                Image(uiImage: selectedPhotos[index])
                                    .resizable()
                                    .frame(width: 150, height: 150)
                                    .aspectRatio(contentMode: .fill)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            Spacer()
        }
        .onChange(of: photosPickerItems) { _, _ in
            Task {
                await loadAndFilterPhotos()
            }
        }
    }
    
    // Load photos and apply filters
    @MainActor
    private func loadAndFilterPhotos() async {
        for item in photosPickerItems {
            if let data = try? await item.loadTransferable(type: Data.self) {
                if let originalImage = UIImage(data: data) {
                    let filteredImage = applyFilter(to: originalImage)
                    selectedPhotos.append(filteredImage)
                }
            }
        }
        photosPickerItems.removeAll()
    }
    
    // Apply Core Image filters
    private func applyFilter(to image: UIImage) -> UIImage {
        guard let ciImage = CIImage(image: image) else { return image }
        
        let context = CIContext()
        var outputImage = ciImage
        outputImage = applyPolaroidFilter(to: ciImage)
        
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return image
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    // Individual filter implementations
    private func applyPolaroidFilter(to image: CIImage) -> CIImage {
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
        temperatureFilter.targetNeutral = CIVector(x: 7200, y: 100) // Warmer with yellow tint
        
        // Step 3: Reduce contrast and increase brightness (Instax has a softer, overexposed look)
        let colorControls = CIFilter.colorControls()
        colorControls.inputImage = temperatureFilter.outputImage
        colorControls.contrast = 0.85  // Lower contrast
        colorControls.brightness = 0.15 // Slightly overexposed
        colorControls.saturation = 0.9  // Slightly desaturated
        
        // Step 4: Add subtle vignette (Instax has slight edge darkening)
        let vignette = CIFilter.vignette()
        vignette.inputImage = colorControls.outputImage
        vignette.intensity = 0.3 // Subtle vignette
        vignette.radius = 1.5
        
        // Step 5: Add film grain/noise for authentic look
        let noiseReduction = CIFilter.noiseReduction()
        noiseReduction.inputImage = vignette.outputImage
        noiseReduction.noiseLevel = 0.02
        noiseReduction.sharpness = 0.4
        
        // Step 6: Slightly blur for that soft Instax look
        let gaussianBlur = CIFilter.gaussianBlur()
        gaussianBlur.inputImage = noiseReduction.outputImage
        gaussianBlur.radius = 0.4
        
        // Step 7: Add a subtle color overlay to mimic the Instax color science
        let colorMatrix = CIFilter.colorMatrix()
        colorMatrix.inputImage = gaussianBlur.outputImage
        colorMatrix.rVector = CIVector(x: 1.05, y: 0.02, z: 0.0, w: 0.0)   // Boost reds slightly
        colorMatrix.gVector = CIVector(x: 0.0, y: 1.0, z: 0.05, w: 0.0)    // Slight green-yellow shift
        colorMatrix.bVector = CIVector(x: 0.0, y: 0.0, z: 0.95, w: 0.0)    // Reduce blues slightly
        colorMatrix.aVector = CIVector(x: 0.0, y: 0.0, z: 0.0, w: 1.0)     // Keep alpha
        colorMatrix.biasVector = CIVector(x: 0.02, y: 0.01, z: -0.01, w: 0.0) // Warm bias
        
        return colorMatrix.outputImage ?? image
    }
}

#Preview {
    PhotosView()
}
