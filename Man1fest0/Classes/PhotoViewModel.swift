//
//  PhotoViewModel.swift
//  Man1fest0
//
//  Created by Amos Deane on 03/09/2025.
//
import SwiftUI

class PhotoViewModel: ObservableObject {
    
    @Published var photos: [Photo] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    let apiURL = "" // Replace with your actual API

// ##################################
// UNUSED
// ##################################
    func fetchPhotos(apiURL: String) {
        isLoading = true
        errorMessage = nil
        guard let url = URL(string: apiURL) else {
            errorMessage = "Invalid API URL"
            isLoading = false
            return
        }
        print("API URL is:\(apiURL)")
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                guard let data = data else {
                    self.errorMessage = "No data received"
                    return
                }
                do {
                    var decoded = try JSONDecoder().decode([Photo].self, from: data)
                    // Initial selection state
                    for i in decoded.indices { decoded[i].isSelected = false }
                    self.photos = decoded
                } catch {
                    self.errorMessage = "Failed to decode photos: \(error)"
                }
            }
        }.resume()
    }

//    func downloadSelectedPhotos() {
//        let selected = photos.filter { $0.isSelected }
//        for photo in selected {
//            downloadIcon(photo)
//        }
//    }

    func downloadAllIcons(allIcons: [Icon]) {
        for eachIcon in allIcons {
            print("Downloading icon:\(eachIcon.name)")
            self.downloadIcon(url: eachIcon.url, filename: eachIcon.name)
        }
    }
    
     func downloadIcon(url: String, filename: String) {
        guard let url = URL(string: url) else { return }
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else { return }
            let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
            let fileURL = downloads.appendingPathComponent("photo_\(filename).jpg")
            do {
                try data.write(to: fileURL)
            } catch {
                print("Failed to save \(filename): \(error)")
            }
        }
        task.resume()
    }
}
