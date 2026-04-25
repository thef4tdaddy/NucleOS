//
//  ButtonStyles.swift
//  NucleOS
//
//  NucleOS custom button styles using the dark purple design token palette.
//

import SwiftUI

// MARK: - Primary

struct NucleOSPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(Color.accentPrimary.opacity(configuration.isPressed ? 0.8 : 1.0))
            .foregroundColor(.white)
            .cornerRadius(8)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Secondary

struct NucleOSSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(Color.clear)
            .foregroundColor(.accentLight)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.accentLight.opacity(0.5), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Destructive

struct NucleOSDestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(Color(hex: "ef4444").opacity(configuration.isPressed ? 0.8 : 1.0))
            .foregroundColor(.white)
            .cornerRadius(8)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - View convenience extensions

extension View {
    func nucleosPrimaryButton() -> some View {
        self.buttonStyle(NucleOSPrimaryButtonStyle())
    }

    func nucleosSecondaryButton() -> some View {
        self.buttonStyle(NucleOSSecondaryButtonStyle())
    }

    func nucleosDestructiveButton() -> some View {
        self.buttonStyle(NucleOSDestructiveButtonStyle())
    }
}
