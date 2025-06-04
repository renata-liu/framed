//
//  HomeView.swift
//  framed
//
//  Created by Renata Liu on 2025-06-03.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            NavigationLink("Polaroid") {
                PolaroidPhotoView()
            }
            
            NavigationLink("Film Strip") {
                PhotosView()
            }
        }
    }
}

#Preview {
    HomeView()
}
