import XCTest
@testable import LyricsService

final class LyricsKitTests: XCTestCase {
    
    func testBasic() {
        let url = Bundle.module.url(forResource: "銀の龍の背に乗って", withExtension: "lrcx", subdirectory: "Resources")!
        let str = try! String(contentsOf: url)
        let lrc = Lyrics(str)!
        XCTAssertEqual(lrc.count, 61)
        XCTAssertEqual(lrc.idTags.count, 4)
        XCTAssertEqual(lrc.metadata.attachmentTags, [.timetag, .furigana, .translation(languageCode: "zh-Hans")])
        XCTAssertEqual(lrc.lineIndex(at: 0), nil)
        XCTAssertEqual(lrc.lineIndex(at: 50), 8)
        XCTAssertEqual(lrc.lineIndex(at: 320), 60)
        lrc.timeDelay = 50
        XCTAssertEqual(lrc.offset, 50000)
        XCTAssertEqual(lrc.lineIndex(at: 0), 8)
    }
    
    func testSearching() {
        let source = LyricsProviders.Group()
        var searchResultEx: XCTestExpectation? = expectation(description: "search succeed")
        let searchReq = LyricsSearchRequest(searchTerm: .info(title: "Uprising", artist: "Muse"), duration: 305)
        let token = source.lyricsPublisher(request: searchReq).sink { _ in
            searchResultEx?.fulfill()
            searchResultEx = nil
        }
        waitForExpectations(timeout: 10)
        token.cancel()
    }
    
    func testNetEase() {
        let searchResultEx = expectation(description: "search succeed")
        let provider = LyricsProviders.NetEase()
        let publisher = provider.lyricsPublisher(request: .init(searchTerm: .info(title: "One Last You", artist: "光田康典"), duration: 0))
        let cancelable = publisher.sink { lyrics in
            searchResultEx.fulfill()
        }
        waitForExpectations(timeout: 10)
        cancelable.cancel()
    }

    /// Verify LRCLib q= fallback finds songs stored under romanised artist names.
    /// 天天年年 by 孙燕姿 is stored in LRCLib as "Stefanie Sun" / "Sun Yanzi".
    func testLRCLibCJKFallback() {
        let ex = expectation(description: "LRCLib CJK fallback finds 天天年年")
        let provider = LyricsProviders.LRCLib()
        let request = LyricsSearchRequest(
            searchTerm: .info(title: "天天年年", artist: "孙燕姿"),
            duration: 0
        )
        let cancellable = provider.lyricsPublisher(request: request).sink { lyrics in
            // Verify lyrics contain the expected first line
            let text = lyrics.description
            XCTAssertTrue(
                text.contains("墨色") || text.contains("天天年年"),
                "Expected 天天年年 lyrics, got: \(text.prefix(200))"
            )
            ex.fulfill()
        }
        waitForExpectations(timeout: 15)
        cancellable.cancel()
    }

    /// Verify NetEase returns correct lyrics for 天天年年 by 孙燕姿.
    func testNetEaseTianTianNianNian() {
        let ex = expectation(description: "NetEase finds 天天年年")
        let provider = LyricsProviders.NetEase()
        let request = LyricsSearchRequest(
            searchTerm: .info(title: "天天年年", artist: "孙燕姿"),
            duration: 0
        )
        let cancellable = provider.lyricsPublisher(request: request).sink { lyrics in
            let text = lyrics.description
            XCTAssertTrue(
                text.contains("墨色") || text.contains("天天年年"),
                "Expected 天天年年 lyrics, got: \(text.prefix(200))"
            )
            ex.fulfill()
        }
        waitForExpectations(timeout: 15)
        cancellable.cancel()
    }
}
