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
                    for index in decoded.indices { decoded[index].isSelected = false }
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


// MARK: - IconImageLoader (embedded here so it's included in the app target)
import Foundation
import CryptoKit

#if os(macOS)
import AppKit
typealias TargetImage = NSImage
#else
import UIKit
typealias TargetImage = UIImage
#endif

final class IconImageLoader {
    static let shared = IconImageLoader()

    private let memoryCache = NSCache<NSString, AnyObject>()
    private var inFlightTasks: [String: Task<TargetImage, Error>] = [:]
    private let diskCacheURL: URL

    private init() {
        memoryCache.totalCostLimit = 10 * 1024 * 1024
        let fm = FileManager.default
        if let appSupport = try? fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true) {
            let dir = appSupport.appendingPathComponent("Man1fest0").appendingPathComponent("Icons")
            self.diskCacheURL = dir
            if !fm.fileExists(atPath: dir.path) {
                try? fm.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
            }
        } else {
            self.diskCacheURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("Man1fest0Icons")
            try? fm.createDirectory(at: diskCacheURL, withIntermediateDirectories: true, attributes: nil)
        }
    }

    func fetchIcon(urlString: String?, targetSize: CGSize = CGSize(width: 30, height: 30)) async throws -> TargetImage {
        guard let urlString = urlString, let url = URL(string: urlString) else { throw URLError(.badURL) }
        let key = cacheKey(for: urlString, size: targetSize)

        if let cached = memoryCache.object(forKey: key as NSString) as? TargetImage {
            return cached
        }

        let diskFile = diskCacheURL.appendingPathComponent(keyForFilename(urlString: urlString, size: targetSize))
        if FileManager.default.fileExists(atPath: diskFile.path) {
            if let data = try? Data(contentsOf: diskFile) {
                #if os(macOS)
                if let img = NSImage(data: data) as? TargetImage {
                    memoryCache.setObject(img, forKey: key as NSString, cost: data.count)
                    return img
                }
                #else
                if let img = UIImage(data: data) as? TargetImage {
                    memoryCache.setObject(img, forKey: key as NSString, cost: data.count)
                    return img
                }
                #endif
            }
        }

        return try await withCheckedThrowingContinuation { continuation in
            if let existing = self.inFlightTasks[key] {
                Task {
                    do {
                        let img = try await existing.value
                        continuation.resume(returning: img)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
                return
            }

            let task = Task<TargetImage, Error> {
                defer { self.removeInFlight(forKey: key) }
                let (data, _) = try await URLSession.shared.data(from: url)
                #if os(macOS)
                guard let image = NSImage(data: data) else { throw URLError(.cannotDecodeContentData) }
                let thumb = self.makeThumbnail(from: image, maxSize: targetSize)
                if let t = thumb, let tdata = t.pngData() {
                    self.memoryCache.setObject(t, forKey: key as NSString, cost: tdata.count)
                    try? tdata.write(to: diskFile, options: .atomic)
                    return t as! TargetImage
                }
                self.memoryCache.setObject(image, forKey: key as NSString, cost: data.count)
                try? data.write(to: diskFile, options: .atomic)
                return image as! TargetImage
                #else
                guard let image = UIImage(data: data) else { throw URLError(.cannotDecodeContentData) }
                let thumb = self.makeThumbnailIOS(from: image, maxSize: targetSize)
                if let t = thumb, let tdata = t.pngData() {
                    self.memoryCache.setObject(t, forKey: key as NSString, cost: tdata.count)
                    try? tdata.write(to: diskFile, options: .atomic)
                    return t as! TargetImage
                }
                self.memoryCache.setObject(image, forKey: key as NSString, cost: data.count)
                try? data.write(to: diskFile, options: .atomic)
                return image as! TargetImage
                #endif
            }

            self.setInFlight(task: task, forKey: key)

            Task {
                do {
                    let img = try await task.value
                    continuation.resume(returning: img)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func cacheKey(for urlString: String, size: CGSize) -> String {
        return "\(urlString)|\(Int(size.width))x\(Int(size.height))"
    }

    private func keyForFilename(urlString: String, size: CGSize) -> String {
        let hash = SHA256.hash(data: Data(urlString.utf8)).compactMap { String(format: "%02x", $0) }.joined()
        return "\(hash)_\(Int(size.width))x\(Int(size.height)).png"
    }

    private func setInFlight(task: Task<TargetImage, Error>, forKey key: String) {
        DispatchQueue.main.async { self.inFlightTasks[key] = task }
    }
    private func removeInFlight(forKey key: String) {
        DispatchQueue.main.async { self.inFlightTasks.removeValue(forKey: key) }
    }

    #if os(macOS)
    private func makeThumbnail(from image: NSImage, maxSize: CGSize) -> NSImage? {
        let rep = image.bestRepresentation(for: NSRect(origin: .zero, size: image.size), context: nil, hints: nil)
        let origSize = CGSize(width: rep?.pixelsWide ?? Int(image.size.width), height: rep?.pixelsHigh ?? Int(image.size.height))
        let scale = min(1.0, min(maxSize.width / origSize.width, maxSize.height / origSize.height))
        let targetW = max(1, Int(origSize.width * scale))
        let targetH = max(1, Int(origSize.height * scale))
        let targetSize = CGSize(width: targetW, height: targetH)
        let dest = NSImage(size: targetSize)
        dest.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        image.draw(in: NSRect(origin: .zero, size: targetSize), from: NSRect(origin: .zero, size: image.size), operation: .copy, fraction: 1.0)
        dest.unlockFocus()
        return dest
    }
    #else
    private func makeThumbnailIOS(from image: UIImage, maxSize: CGSize) -> UIImage? {
        let origSize = image.size
        let scale = min(1.0, min(maxSize.width / origSize.width, maxSize.height / origSize.height))
        let targetSize = CGSize(width: max(1, Int(origSize.width * scale)), height: max(1, Int(origSize.height * scale)))
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 0)
        image.draw(in: CGRect(origin: .zero, size: targetSize))
        let scaled = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return scaled
    }
    #endif
}

#if os(macOS)
fileprivate extension NSImage {
    func pngData() -> Data? {
        guard let tiff = self.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let data = rep.representation(using: .png, properties: [:])
        else { return nil }
        return data
    }
}
#else
fileprivate extension UIImage {
    func pngData() -> Data? { self.pngData() }
}
#endif
