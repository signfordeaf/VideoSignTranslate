//
//  KingfisherInitializer.swift
//  VideoSignTranslate
//
//  Created by Selim Yavaşoğlu on 16.12.2024.
//

import Foundation

public class VideoSignController { // "public" ekleniyor
    public nonisolated(unsafe) static let shared = VideoSignController()
    private var _apiKey: String?

    public var apiKey: String { // "public" ekleniyor
        guard let key = _apiKey else {
            fatalError("API Key has not been initialized. Call `initialize(apiKey:)` before accessing it.")
        }
        return key
    }

    private init() { }

    public func initialize(apiKey: String) { // "public" ekleniyor
        guard _apiKey == nil else {
            fatalError("API Key has already been initialized and cannot be changed.")
        }
        self._apiKey = apiKey
        print("VideoSignInit initialized with API Key.")
    }
    
    /// Do not Use, automatic video bundle id identifier.
    public func initVideoBundleURL(_ videoURL: URL) -> String {
        let pathComponents = videoURL.pathComponents
        if pathComponents.count >= 2 {
            let lastComponent = pathComponents.last // Son bileşen
            let secondLastComponent = pathComponents[pathComponents.count - 2] // Sondan bir önceki bileşen
            let appBundle = Bundle.main.bundleIdentifier
            return "\(appBundle ?? "").\(secondLastComponent)/\(lastComponent ?? "None")"
        } else {
            return ""
        }
    }
}

