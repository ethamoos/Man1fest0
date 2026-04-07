// CachedAsyncImage.swift
// Lightweight cached async image loader with thumbnail generation

import SwiftUI
import ImageIO

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

final class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSString, NSData>()

    func data(forKey key: String) -> Data? {
        return cache.object(forKey: key as NSString) as Data?
    }

    func set(data: Data, forKey key: String) {
        cache.setObject(data as NSData, forKey: key as NSString)
    }
}

actor ImageLoader {
    func loadData(from urlString: String) async throws -> Data {
        if let cached = ImageCache.shared.data(forKey: urlString) { return cached }
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
        ImageCache.shared.set(data: data, forKey: urlString)
        return data
    }

    func loadThumbnail(from urlString: String, maxPixelSize: Int) async throws -> Data {
        let thumbKey = "thumb:\(maxPixelSize):\(urlString)"
        if let cached = ImageCache.shared.data(forKey: thumbKey) { return cached }
        let data = try await loadData(from: urlString)
        guard let thumb = makeThumbnail(from: data, maxPixelSize: maxPixelSize) else { return data }
        ImageCache.shared.set(data: thumb, forKey: thumbKey)
        return thumb
    }

    private func makeThumbnail(from data: Data, maxPixelSize: Int) -> Data? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
            kCGImageSourceCreateThumbnailWithTransform: true
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }

        #if os(iOS)
        let ui = UIImage(cgImage: cgImage)
        return ui.pngData()
        #else
        let ns = NSImage(cgImage: cgImage, size: NSZeroSize)
        guard let tdata = ns.tiffRepresentation else { return nil }
        guard let rep = NSBitmapImageRep(data: tdata) else { return nil }
        return rep.representation(using: .png, properties: [:])
        #endif
    }
}

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let urlString: String?
    let thumbnailMaxPixelSize: Int?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder

    @State private var loadedImage: Image? = nil
    @State private var loaderTask: Task<Void, Never>? = nil

    init(urlString: String?, thumbnailMaxPixelSize: Int? = nil,
         @ViewBuilder content: @escaping (Image) -> Content,
         @ViewBuilder placeholder: @escaping () -> Placeholder) {
        self.urlString = urlString
        self.thumbnailMaxPixelSize = thumbnailMaxPixelSize
        self.content = content
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let image = loadedImage {
                content(image)
            } else {
                placeholder()
                    .task(id: urlString) {
                        await load()
                    }
            }
        }
    }

    private func load() async {
        guard let urlString = urlString, !urlString.isEmpty else { return }
        let loader = ImageLoader()
        do {
            let data: Data
            if let max = thumbnailMaxPixelSize {
                data = try await loader.loadThumbnail(from: urlString, maxPixelSize: max)
            } else {
                data = try await loader.loadData(from: urlString)
            }

            #if os(iOS)
            if let ui = UIImage(data: data) {
                await MainActor.run {
                    loadedImage = Image(uiImage: ui)
                }
            }
            #else
            if let ns = NSImage(data: data) {
                await MainActor.run {
                    loadedImage = Image(nsImage: ns)
                }
            }
            #endif
        } catch {
            // ignore — keep placeholder
            return
        }
    }
}
