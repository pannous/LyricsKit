import XCTest
import Regex
@testable import LyricsService

/*
 results in queries:
 http://music.163.com/api/search/pc?type=1&limit=10&s=Uprising%20Muse&offset=0
 http://music.163.com/api/search/pc?type=1&limit=10&s=李荣浩+在一起嘛好不好&offset=0
 => ART! http://p2.music.126.net/NIu0BZ-nVwnpz1IWMmMAiQ==/109951165034018960.jpg
 => ID:
 http://s.gecimi.com/lrc/408/40851/4085119.lrc
 http://s.gecimi.com/lrc/420/42004/4200493.lrc
 http://img.xiami.net/lyric/1/1769482101_1546468917_8470.trc
 http://img.xiami.net/lyric/0/1769482100_1493278739_7176.xtrc
 */
//https://www.youtube.com/watch?v=w8KQmps-Sog
let lyrics="""
[offset:0]
[al:Uprising]
[ar:Muse]
[ti:Uprising (Does It Offend You Yeah Mix)]
[length:240]
[00:00.000]Uprising (Does It Offend You Yeah Mix) - Muse
[00:09.760]The paranoia is in bloom  the PR
[00:09.760][tr]妄想症正在发芽
[00:33.840]The transmissions will resume
[00:33.840][tr]重新启动变速器
[00:36.660]They'll try to push drugs
[00:36.660][tr]他们想尝试贩毒
[00:38.710]Keep us all dumbed down and hope that
[00:38.710][tr]让我们保持愚昧和希望
[00:41.660]We will never see the truth around
[00:41.660][tr]我们永远不会发现真相
[00:44.320]Another promise  another scene  another
[00:44.320][tr]另一个承诺，另一个场景，另一个
[00:48.740]A package not to keep us trapped in greed
[00:48.740][tr]潘多拉魔盒让我们陷入贪婪的欲望
[00:52.490]With all the green belts wrapped around our minds
[00:52.490][tr]我们的脑海被绿化隔离带所围绕
[00:55.690]And endless red tape to keep the truth confined
[00:55.690][tr]无休止的繁文缛节将真相禁锢了
[00:59.000]They will not force us
[00:59.000][tr]他们不会强迫我们
[01:13.500]They will stop degrading us
[01:13.500][tr]他们会停止对我们的羞辱
[01:21.440]They will not control us
[01:21.440][tr]他们不会控制我们
[01:28.620]We will be victorious
[01:28.620][tr]我们将胜利凯旋
[01:37.870]Interchanging mind control
[01:37.870][tr]赢得精神的自由
[02:10.360]Come let the revolution take it's toll if you could
[02:10.360][tr]如果你可以，来敲响革命的钟声吧
[02:15.280]Flick the switch and open your third eye  you'd see that
[02:15.280][tr]按下开关，睁开你的第三只眼，就能看到
[02:19.270]We should never be afraid to die
[02:19.270][tr]我们应该不惧死亡
[02:21.640]Rise up and take the power back  it's time that
[02:21.640][tr]起来反抗，夺回权力，正是时候
[02:26.440]The fat cats had a heart attack  you know that
[02:26.440][tr]让有钱有势的人心脏病发
[02:30.190]Their time is coming to an end
[02:30.190][tr]他们的时代就要终结
[02:32.820]We have to unify and watch our flag ascend
[02:32.820][tr]我们要团结一致，看着我们的旗帜升起
[02:36.690]They will not force us
[02:36.690][tr]他们不会强迫我们
[02:50.990]They will stop degrading us
[02:50.990][tr]他们会停止对我们的羞辱
[02:58.610]They will not control us
[02:58.610][tr]他们不会控制我们
[03:06.090]
[03:07.020]We will be victorious
[03:07.020][tr]我们将胜利凯旋
[03:13.740]Victorious victorious victorious
[03:13.740][tr]胜利凯旋
"""
let testSong = "Uprising"
let testArtist = "Muse"
let duration = 305.0
let searchReq = LyricsSearchRequest(searchTerm: .info(title: testSong, artist: testArtist), title: testSong, artist: testArtist, duration: duration)

final class LyricsKitTests: XCTestCase {
    
    var trialNumber=0

    func getTranslations(lyrics:String) -> String {

        let lyricsPattern = "^(\\[[+-]?\\d+:\\d+(?:\\.\\d+)?\\])+\\[(.+?)\\](.*)"
        let lyricsLineAttachmentRegex = try! Regex(lyricsPattern, options: .anchorsMatchLines)
        let l=lyricsLineAttachmentRegex as Regex
        if lyrics.contains("[tr]"){return lyrics}
        var toTranslate=""
        for line in lyrics.split(separator: "\n") {
            if line~=lyricsPattern { toTranslate.append(contentsOf: line)}//.substring(from: 10)) }
        }
        var enhanced=""
//        for line in lyrics.split(separator: "\n") {
//                    enhanced.append(line)
//                    if line) {
//                        line
//                        enhanced.append(
//                    }
//        //            if line.contains("0]")
//                }
//        SwiftGoogleTranslate.shared.translate(text, "en", "", "text", "base", {translation ,error in
//
//        })
        return "NO"
    }
    
    func testTranslate()  {

//        lyricsLineAttachmentRegex
        var searchResultEx: XCTestExpectation? = expectation(description: "Translate")
        SwiftGoogleTranslate.shared.start(with: "AIzaSyAHIAkpSvR075MDwzxR_E1nJkQLXT1XSbM")
        let text="""
        [00:00.000]Uprising (Does It Offend You Yeah Mix) - Muse
        [00:09.760]The paranoia is in bloom  the PR
        [00:09.760][tr]妄想症正在发芽
"""
        /* [00: 00.000] Uprising (Does It Offend You Ja Mix) - Muse
           [00: 09,760] Die Paranoia ist die PR in voller Blüte
           [00: 09,760] [tr] Paranoia keimen*/
        SwiftGoogleTranslate.shared.translate(text, "en", "", "text", "base", {translation ,error in
            if (error != nil){
                print("ERROR: ",error!)
                XCTAssertNil(error, "No translation found.")
            }else{
                print("Translation:\n",translation!)
            }
            searchResultEx?.fulfill()
        })
        waitForExpectations(timeout: 2)
    }
    
    
    func _test(provider: LyricsProvider) {
        var searchResultEx: XCTestExpectation? = expectation(description: "Search result: \(provider)")
        let token = provider.lyricsPublisher(request: searchReq).sink { lrc in
            print(lrc)
            searchResultEx?.fulfill()
            searchResultEx = nil
        }
        waitForExpectations(timeout: 10)
        token.cancel()
    }
    
    
    func _testManager() {
        _test(provider: LyricsProviders.Group())
    }
    
    
    func _testQQMusic() {// [04:26.610]We will be victorious
//[03:56.920]And we will be victorious HUH?
//[03:56.920][tr]而我们会获胜
        _test(provider: LyricsProviders.QQMusic())
    }
    
    func _testGecimi() {// [04:28.390]We will be victorious
        _test(provider: LyricsProviders.Gecimi())
    }
    
    func _testNetEase() {// best:
//        [04:28.048]We will be victorious
//        [04:28.048][tr]而我们会获胜
//        [04:28.048][tt]<0,0><1101,3><2101,8><3102,11><7244,21><7245>
        _test(provider: LyricsProviders.NetEase())
    }
    
    
    func _testViewLyrics() {// Exceeded timeout of 10 seconds
        _test(provider: LyricsProviders.ViewLyrics())
    }
    
//  removed
//    func _testKugou() {// Exceeded timeout of 10 seconds
//        _test(provider: LyricsProviders.Kugou())
//    }
    
    func _testSyair() {// Exceeded timeout of 10 seconds
        _test(provider: LyricsProviders.Syair())
    }
    
    
    static var allTests = [
    ("testTranslate", testTranslate),
//    ("testProviders", testProviders),
//    ("testCurrent", testCurrent),
    ]
}
