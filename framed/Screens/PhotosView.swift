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
        outputImage = applyPhotoStripFilter(to: ciImage)
        
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return image
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    private func applyPhotoStripFilter(to image: CIImage) -> CIImage {
        // Step 1: Crop to square center
        let sourceExtent = image.extent
        let size = min(sourceExtent.width, sourceExtent.height)
        let cropRect = CGRect(
            x: (sourceExtent.width - size) / 2,
            y: (sourceExtent.height - size) / 2,
            width: size,
            height: size
        )
        let croppedImage = image.cropped(to: cropRect)

        let noir = CIFilter.photoEffectNoir()
        noir.inputImage = croppedImage

        let colorControls = CIFilter.colorControls()
        colorControls.inputImage = noir.outputImage
        colorControls.contrast = 0.9
        colorControls.brightness = 0.0
        colorControls.saturation = 0.5

        let vignette = CIFilter.vignette()
        vignette.inputImage = colorControls.outputImage
        vignette.intensity = 0.7
        vignette.radius = Float(size / 1.5)

        let blur = CIFilter.gaussianBlur()
        blur.inputImage = vignette.outputImage
        blur.radius = 0.3

        return blur.outputImage ?? image
    }

}

#Preview {
    PhotosView()
}
