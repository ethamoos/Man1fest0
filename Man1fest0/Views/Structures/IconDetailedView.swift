//
//  IconDetailedView.swift
//  Man1fest0
//
//  Created by Amos Deane on 06/09/2024.
//


import SwiftUI
import ImageIO

struct IconDetailedView: View {
    
    @State var server: String
    @State var selectedIcon: Icon?
    @State private var exporting = false

    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var progress: Progress
    @EnvironmentObject var layout: LayoutManager
    @StateObject private var viewModel = PhotoViewModel()

    var body: some View {
        
        VStack(alignment: .leading) {
            
            LazyVGrid(columns: layout.columnsWide, spacing: 10) {
                
                VStack(alignment: .leading) {
                    
                    if let currentIconUrl = selectedIcon?.url {
                        // Use CachedAsyncImage with thumbnail generation
                        CachedAsyncImage(urlString: currentIconUrl, thumbnailMaxPixelSize: 200) { image in
                            image
                                .resizable()
                                .scaledToFit()
                        } placeholder: {
                            Color.red
                        }
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                        .shadow(color: Color.gray, radius: 2, x: 0, y: 2)
                        
                        Text("Filename:\t\t\(String(describing: selectedIcon?.name ?? ""))")
                        Text("ID:\t\t\t\t\(String(describing: selectedIcon?.id ?? 0))")
                        Text("Url:\t\t\t\t\(String(describing: selectedIcon?.url ?? ""))")
                        
                        Button(action: { print("Pressing button")
                            handleConnect(server: server)
                        }) {
                            HStack(spacing:20) {
                                Text("Refresh")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        
                        //  ################################################################################
                        //              DOWNLOAD OPTION
                        //  ################################################################################
                        
#if os(macOS)
                        
                        Button("Export") {
                            progress.showProgress()
                            progress.waitForABit()
                            exporting = true
                            networkController.separationLine()
                            viewModel.downloadIcon(url: selectedIcon?.url ?? "", filename: selectedIcon?.name ?? "" )
                            //                        print("Printing text to export:\(text)")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.yellow)
                        .shadow(color: Color.gray, radius: 2, x: 0, y: 2)
#endif
                    }
                }
            }
        }
    
        .padding()

        .onAppear {
            print("Icon detailed view appeared. Running onAppear")
            print("selectedIcon is set as:\(String(describing: selectedIcon?.name ?? ""))")
            handleConnect(server: server)
        }
    }
    
    func handleConnect(server: String) {
        print("Handling connection")
        Task {
            try await networkController.getDetailedIcon(server: server, authToken: networkController.authToken, iconID: String(describing: selectedIcon?.id ?? 0))
        }
    }
}

fileprivate final class DemoImageCache {
    static let shared = DemoImageCache()
    private let cache = NSCache<NSString, NSData>()
    func data(forKey key: String) -> Data? { cache.object(forKey: key as NSString) as Data? }
    func set(data: Data, forKey key: String) { cache.setObject(data as NSData, forKey: key as NSString) }
}

// Renamed from DemoCachedAsyncImage to CachedAsyncImage so the view can use CachedAsyncImage directly
fileprivate struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let urlString: String?
    let thumbnailMaxPixelSize: Int?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder

    @State private var loadedImage: Image? = nil

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

    private func load() async {
        guard let urlString = urlString, !urlString.isEmpty else { return }
        if let cached = DemoImageCache.shared.data(forKey: urlString) {
            #if os(iOS)
            if let ui = UIImage(data: cached) {
                await MainActor.run { loadedImage = Image(uiImage: ui) }
            }
            #else
            if let ns = NSImage(data: cached) { await MainActor.run { loadedImage = Image(nsImage: ns) } }
            #endif
            return
        }
        guard let url = URL(string: urlString) else { return }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return }
            var useData = data
            if let max = thumbnailMaxPixelSize, let thumb = makeThumbnail(from: data, maxPixelSize: max) {
                useData = thumb
            }
            DemoImageCache.shared.set(data: useData, forKey: urlString)
            #if os(iOS)
            if let ui = UIImage(data: useData) { await MainActor.run { loadedImage = Image(uiImage: ui) } }
            #else
            if let ns = NSImage(data: useData) { await MainActor.run { loadedImage = Image(nsImage: ns) } }
            #endif
        } catch {
            return
        }
    }
}

//struct  IconsView_Previews: PreviewProvider {
//    static var previews: some View {
//        IconDetailedView()
//    }
//}
