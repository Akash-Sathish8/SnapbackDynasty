import SwiftUI

/// Disk + memory-cached image loader for team logos.
/// Replaces AsyncImage to avoid re-fetching the same URL across views.
@MainActor
final class LogoCache {
    static let shared = LogoCache()

    private let cache = NSCache<NSString, UIImage>()
    private var inFlight: [URL: Task<UIImage?, Never>] = [:]

    private init() {
        cache.countLimit = 200
        cache.totalCostLimit = 20 * 1024 * 1024  // 20 MB
    }

    func image(for url: URL?) -> UIImage? {
        guard let url else { return nil }
        return cache.object(forKey: url.absoluteString as NSString)
    }

    func load(url: URL) async -> UIImage? {
        if let cached = cache.object(forKey: url.absoluteString as NSString) {
            return cached
        }
        if let existing = inFlight[url] { return await existing.value }
        let task = Task<UIImage?, Never> {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard let image = UIImage(data: data) else { return nil }
                cache.setObject(image, forKey: url.absoluteString as NSString,
                                cost: data.count)
                return image
            } catch { return nil }
        }
        inFlight[url] = task
        let result = await task.value
        inFlight[url] = nil
        return result
    }
}

/// Drop-in replacement for AsyncImage that uses LogoCache.
struct CachedLogoImage: View {
    let urlString: String
    var fallbackColor: Color = .gray

    @State private var image: UIImage?

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                RoundedRectangle(cornerRadius: 6).fill(fallbackColor)
            }
        }
        .task(id: urlString) {
            guard let url = URL(string: urlString) else { return }
            if let cached = LogoCache.shared.image(for: url) {
                image = cached
                return
            }
            image = await LogoCache.shared.load(url: url)
        }
    }
}
