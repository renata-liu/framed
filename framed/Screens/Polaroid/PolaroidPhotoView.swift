//
//  PhotoView.swift
//  framed
//
//  Created by Renata Liu on 2025-06-03.
//
//
import SwiftUI
import PhotosUI
import CoreImage
import CoreImage.CIFilterBuiltins

struct PolaroidPhotoView: View {
    @StateObject private var viewModel: PolaroidPhotoViewModel = PolaroidPhotoViewModel()

    var body: some View {
        VStack {
            PhotosPicker(selection: $viewModel.photosPickerItem, matching: .any(of: [.images, .livePhotos, .screenshots, .bursts])) {
                Text("Pick a photo")
            }

            if viewModel.selectedPhoto != nil {
                Image(uiImage: viewModel.selectedPhoto!)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 300, maxHeight: 400)
            }
        }
        .onChange(of: viewModel.photosPickerItem) {_, _ in
            Task {
                await viewModel.loadAndFilterPhoto()
            }
        }
    }
}

#Preview {
    PolaroidPhotoView()
}

