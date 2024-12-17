//
//  SignCacheModel.swift
//  VideoSignTranslate
//
//  Created by Selim Yavaşoğlu on 11.12.2024.
//

import Foundation

public struct SignCacheModel: Codable, Sendable {
    let videoType: String?
    let videoPath: String?
    let videoURL: String?
    let videoBundleId: String?
    let signModel: SignModel?
    
    public func copyWith(
        videoType: String? = nil,
        videoPath: String? = nil,
        videoURL: String? = nil,
        videoBundleId: String? = nil,
        signModel: SignModel? = nil
    ) -> SignCacheModel {
        return SignCacheModel(
            videoType: videoType ?? self.videoType,
            videoPath: videoPath ?? self.videoPath,
            videoURL: videoURL ?? self.videoURL,
            videoBundleId: videoBundleId ?? self.videoBundleId,
            signModel: signModel ?? self.signModel
        )
    }
}

