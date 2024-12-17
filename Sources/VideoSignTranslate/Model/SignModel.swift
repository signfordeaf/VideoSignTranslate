//
//  SignModel.swift
//  VideoSignTranslate
//
//  Created by Selim Yavaşoğlu on 10.12.2024.
//

import Foundation

public struct SignModel: Codable, Sendable {
    let data: [SignData]?
    let status: Bool?
}

public struct SignData: Codable, Sendable {
    let st, et: Double?
    let vu: String?
    let vd: Double?
    let s: String?
    let q: Int?
}

