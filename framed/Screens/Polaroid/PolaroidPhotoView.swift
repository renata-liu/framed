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
import Photos

struct PolaroidPhotoView: View {
    @StateObject private var viewModel: PolaroidPhotoViewModel = PolaroidPhotoViewModel()

    var body: some View {
        VStack {
            PhotosPicker(selection: $viewModel.photosPickerItem, matching: .any(of: [.images, .livePhotos, .screenshots, .bursts])) {
                Text("Pick a photo")
            }

            if let selectedPhoto = viewModel.selectedPhoto {
                Image(uiImage: selectedPhoto)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 300, maxHeight: 400)
                
                Button(action: {
                    viewModel.saveImageToPhotos(selectedPhoto)
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("Save to Photos")
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                .padding(.top, 20)
            }
        }
        .onChange(of: viewModel.photosPickerItem) { _, _ in
            Task {
                await viewModel.loadAndFilterPhoto()
            }
        }
        .alert("Save Photo", isPresented: $viewModel.showingSaveAlert) {
            Button("OK") { }
        } message: {
            Text(viewModel.saveMessage)
        }
    }
}

#Preview {
    PolaroidPhotoView()
}
