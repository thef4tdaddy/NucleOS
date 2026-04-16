//
//  Color+Theme.swift
//  NucleOS
//
//  Design tokens for the NucleOS dark purple aesthetic
//

import SwiftUI

extension Color {
    // Backgrounds
    static let backgroundPrimary = Color(hex: "08060f")
    static let backgroundSecondary = Color(hex: "0b0915")
    static let backgroundCard = Color(hex: "0d0b1a")

    // Borders
    static let border = Color(hex: "17122a")

    // Accents
    static let accentPrimary = Color(hex: "5b3fd4")
    static let accentLight = Color(hex: "7c5cf0")
    static let accentLavender = Color(hex: "c4b5fd")

    // Text
    static let textPrimary = Color(hex: "ede9ff")
    static let textSecondary = Color(hex: "b8aedd")
    static let textMuted = Color(hex: "6a5a8a")
    static let textDim = Color(hex: "3a2f52")

    // Hex initializer
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        r = (int >> 16) & 0xFF
        g = (int >> 8) & 0xFF
        b = int & 0xFF

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
}
