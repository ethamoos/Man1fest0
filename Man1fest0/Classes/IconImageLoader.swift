import Foundation
import SwiftUI
import CryptoKit

#if os(macOS)
import AppKit
#endif

final class IconImageLoader {
    static let shared = IconImageLoader()

    private let memoryCache = NSCache<NSString, AnyObject>()
    private let ioQueue = DispatchQueue(label: "IconImageLoader.io")
    private let downloadsQueue = DispatchQueue(label: "IconImageLoader.downloads", attributes: .concurrent)
    private var inFlightTasks: [String: Task<NSImage, Error>] = [:]

    private let diskCacheURL: URL

    private init() {
        memoryCache.totalCostLimit = 10 * 1024 * 1024 // ~10MB default

        // Application Support/Man1fest0/Icons
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

    // Public API: fetch NSImage thumbnail for given URL string
    func fetchIcon(urlString: String?, targetSize: CGSize = CGSize(width: 30, height: 30)) async throws -> NSImage {
        guard let urlString = urlString, let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        let key = cacheKey(for: urlString, size: targetSize)

        // 1) memory cache
        if let cached = memoryCache.object(forKey: key as NSString) as? NSImage {
            return cached
        }

        // 2) disk cache
        let diskFile = diskCacheURL.appendingPathComponent(keyForFilename(urlString: urlString, size: targetSize))
        if FileManager.default.fileExists(atPath: diskFile.path) {
            if let data = try? Data(contentsOf: diskFile), let ns = NSImage(data: data) {
                memoryCache.setObject(ns, forKey: key as NSString, cost: data.count)
                return ns
            }
        }

        // 3) in-flight dedupe using Task
        return try await withCheckedThrowingContinuation { continuation in
            // If an in-flight Task exists, await it
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

            // Create a new Task to perform fetch + resize
            let task = Task<NSImage, Error> {
                defer { self.removeInFlight(forKey: key) }
                let (data, _) = try await URLSession.shared.data(from: url)
                // Resize image
                guard let image = NSImage(data: data) else { throw URLError(.cannotDecodeContentData) }
                let thumb = self.makeThumbnail(from: image, maxSize: targetSize)
                // Save to memory and disk
                if let t = thumb, let tdata = t.pngData() {
                    self.memoryCache.setObject(t, forKey: key as NSString, cost: tdata.count)
                    try? tdata.write(to: diskFile, options: .atomic)
                    return t
                }
                // Fallback: return original
                self.memoryCache.setObject(image, forKey: key as NSString, cost: data.count)
                try? data.write(to: diskFile, options: .atomic)
                return image
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

    // MARK: - Helpers
    private func cacheKey(for urlString: String, size: CGSize) -> String {
        return "\(urlString)|\(Int(size.width))x\(Int(size.height))"
    }

    private func keyForFilename(urlString: String, size: CGSize) -> String {
        let hash = SHA256.hash(data: Data(urlString.utf8)).compactMap { String(format: "%02x", $0) }.joined()
        return "\(hash)_\(Int(size.width))x\(Int(size.height)).png"
    }

    private func setInFlight(task: Task<NSImage, Error>, forKey key: String) {
        DispatchQueue.main.async {
            self.inFlightTasks[key] = task
        }
    }
    private func removeInFlight(forKey key: String) {
        DispatchQueue.main.async {
            self.inFlightTasks.removeValue(forKey: key)
        }
    }

    private func makeThumbnail(from image: NSImage, maxSize: CGSize) -> NSImage? {
        let rep = image.bestRepresentation(for: NSRect(x: 0, y: 0, width: image.size.width, height: image.size.height), context: nil, hints: nil)
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
}

// MARK: - NSImage PNG helper
fileprivate extension NSImage {
    func pngData() -> Data? {
        guard let tiff = self.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let data = rep.representation(using: .png, properties: [:])
        else { return nil }
        return data
    }
}
