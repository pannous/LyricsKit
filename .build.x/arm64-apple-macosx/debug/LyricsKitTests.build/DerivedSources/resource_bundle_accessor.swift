import class Foundation.Bundle

extension Foundation.Bundle {
    static let module: Bundle = {
        let mainPath = Bundle.main.bundleURL.appendingPathComponent("LyricsKit_LyricsKitTests.bundle").path
        let buildPath = "/Users/me/dev/apps/Lyrics-Translator/LyricsKit/.build/arm64-apple-macosx/debug/LyricsKit_LyricsKitTests.bundle"

        let preferredBundle = Bundle(path: mainPath)

        guard let bundle = preferredBundle ?? Bundle(path: buildPath) else {
            fatalError("could not load resource bundle: from \(mainPath) or \(buildPath)")
        }

        return bundle
    }()
}