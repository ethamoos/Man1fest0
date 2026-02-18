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

    // Simple in-memory cache for downloaded image data to avoid repeated network requests
    private static let imageDataCache = NSCache<NSString, NSData>()

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
            // Handle network errors and nil data on the main thread
            if let error = error {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "No data received"
                }
                return
            }
            // Decode JSON off the main thread to avoid blocking UI
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    var decoded = try JSONDecoder().decode([Photo].self, from: data)
                    // Initial selection state
                    for i in decoded.indices { decoded[i].isSelected = false }
                    // Publish once on the main actor
                    DispatchQueue.main.async {
                        self.photos = decoded
                        self.isLoading = false
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.errorMessage = "Failed to decode photos: \(error)"
                    }
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

    /// Fetch raw image Data for a given image URL string. Uses an in-memory cache to avoid repeated downloads.
    /// Calls the completion on the main thread.
    func fetchImageData(for urlString: String, completion: @escaping (Data?) -> Void) {
        if let cached = Self.imageDataCache.object(forKey: urlString as NSString) {
            completion(cached as Data)
            return
        }
        guard let url = URL(string: urlString) else { completion(nil); return }
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            // Optionally we could validate/transform the data off-main-thread here (create NSImage/UIImage) if needed
            Self.imageDataCache.setObject(data as NSData, forKey: urlString as NSString)
            DispatchQueue.main.async { completion(data) }
        }.resume()
    }
}
