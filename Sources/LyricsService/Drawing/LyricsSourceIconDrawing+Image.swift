//
//  LyricsSourceIconDrawing+Image.swift
//
//  This file is part of LyricsX - https://github.com/pannous/LyricsX
//  Copyright (C) 2017  Xander Deng. Licensed under GPLv3.
//

#if canImport(CoreGraphics)

    import CoreGraphics

    @available(OSX 10.10, iOS 8, tvOS 2, *)
    private extension LyricsProviders.Service {
        
        var drawingMethod: ((CGRect) -> Void)? {
            switch self {
            case .netease:
                return LyricsSourceIconDrawing.drawNetEaseMusic
            case .gecimi:
                return LyricsSourceIconDrawing.drawGecimi
            case .kugou:
                return LyricsSourceIconDrawing.drawKugou
            case .qq:
                return LyricsSourceIconDrawing.drawQQMusic
            case .xiami:
                return LyricsSourceIconDrawing.drawXiami
            default:
                return nil
            }
        }
        
    }
    
#endif

#if canImport(Cocoa)
    
    import Cocoa
    
    extension LyricsSourceIconDrawing {
        
        public static let defaultSize = CGSize(width: 48, height: 48)
        
        public static func icon(of service: LyricsProviders.Service, size: CGSize = defaultSize) -> NSImage? {
            #if !targetEnvironment(macCatalyst)
            return NSImage(size: size, flipped: false) { (NSRect) -> Bool in
                service.drawingMethod?(CGRect(origin: .zero, size: size))
                return true
            }
            #else
            return nil// NSImage(name: NSImage.addTemplateName)!
            #endif
        }
    }
    
#elseif canImport(UIKit)
    
    import UIKit
    
    extension LyricsSourceIconDrawing {
        
        public static let defaultSize = CGSize(width: 48, height: 48)
        
        public static func icon(of source: LyricsProviders.Service, size: CGSize = defaultSize) -> UIImage {
            UIGraphicsBeginImageContextWithOptions(size, false, 0)
            source.drawingMethod?(CGRect(origin: .zero, size: size))
            let image = UIGraphicsGetImageFromCurrentImageContext()?.withRenderingMode(.alwaysOriginal)
            UIGraphicsEndImageContext()
            return image ?? UIImage()
        }
    }

#endif
