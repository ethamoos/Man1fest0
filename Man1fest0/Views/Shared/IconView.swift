import SwiftUI

#if os(macOS)
import AppKit
typealias PlatformImage = NSImage
#else
import UIKit
typealias PlatformImage = UIImage
#endif

struct IconView: View {
    let urlString: String?
    var size: CGFloat = 30
    var cornerRadius: CGFloat? = nil

    @State private var image: PlatformImage? = nil
    @EnvironmentObject var progress: Progress

    var body: some View {
        Group {
            if let img = image {
                #if os(macOS)
                Image(nsImage: img)
                    .resizable()
                #else
                Image(uiImage: img)
                    .resizable()
                #endif
            } else {
                ZStack {
                    Color.gray.opacity(0.08)
                    ProgressView()
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius ?? size / 2))
        .onAppear {
            load()
        }
        .task(id: urlString) {
            await load()
        }
    }

    @MainActor
    private func load() async {
        guard let urlString = urlString else { return }
        do {
            let ns = try await IconImageLoader.shared.fetchIcon(urlString: urlString, targetSize: CGSize(width: size, height: size))
            self.image = ns as? PlatformImage
        } catch {
            // ignore and leave placeholder
            return
        }
    }
}

struct IconView_Previews: PreviewProvider {
    static var previews: some View {
        IconView(urlString: "https://euw2.myurl.com/icon/hash_accfb8273af78d6e2f456a9e3ea882267f82e99c13f9e515d374ffd749aba082")
            .frame(width: 30, height: 30)
            .environmentObject(Progress())
    }
}
