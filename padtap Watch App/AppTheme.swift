//
//  AppTheme.swift
//  padtap Watch App
//

import SwiftUI

enum AppTheme {
    static let backgroundTop = Color(red: 0.06, green: 0.07, blue: 0.10)
    static let backgroundBottom = Color(red: 0.03, green: 0.04, blue: 0.06)

    static let surface = Color(red: 0.10, green: 0.11, blue: 0.15)
    static let surfaceMuted = Color(red: 0.15, green: 0.17, blue: 0.21)
    static let border = Color.white.opacity(0.14)

    static let accent = Color(red: 0.12, green: 0.64, blue: 0.99)
    static let accentSoft = accent.opacity(0.2)
    static let destructive = Color(red: 0.92, green: 0.34, blue: 0.30)

    static let textPrimary = Color.white
    static let textSecondary = Color(red: 0.67, green: 0.70, blue: 0.75)
}

struct ThemedScreen<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppTheme.backgroundTop, AppTheme.backgroundBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            content
        }
    }
}

struct SurfaceCard<Content: View>: View {
    let cornerRadius: CGFloat
    @ViewBuilder var content: Content

    init(
        cornerRadius: CGFloat = 16,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        content
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(AppTheme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(AppTheme.border, lineWidth: 1)
            )
    }
}

struct PrimaryPillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 38)
            .background(
                Capsule(style: .continuous)
                    .fill(AppTheme.accent.opacity(configuration.isPressed ? 0.76 : 1.0))
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct SecondaryPillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundStyle(AppTheme.textPrimary)
            .frame(maxWidth: .infinity, minHeight: 36)
            .background(
                Capsule(style: .continuous)
                    .fill(AppTheme.surfaceMuted.opacity(configuration.isPressed ? 0.76 : 1.0))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(AppTheme.border, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct DestructivePillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 36)
            .background(
                Capsule(style: .continuous)
                    .fill(AppTheme.destructive.opacity(configuration.isPressed ? 0.76 : 1.0))
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct PadTapLogo: View {
    var size: CGFloat = 36

    var body: some View {
        ZStack {
            Circle()
                .fill(AppTheme.surfaceMuted)

            Circle()
                .stroke(AppTheme.accentSoft, lineWidth: size * 0.08)

            RoundedRectangle(cornerRadius: size * 0.18, style: .continuous)
                .stroke(AppTheme.textPrimary.opacity(0.9), lineWidth: size * 0.06)
                .padding(size * 0.22)

            Rectangle()
                .fill(AppTheme.textPrimary.opacity(0.9))
                .frame(width: size * 0.05, height: size * 0.40)

            Circle()
                .fill(AppTheme.accent)
                .frame(width: size * 0.2, height: size * 0.2)
                .offset(x: size * 0.18, y: -size * 0.12)
        }
        .frame(width: size, height: size)
    }
}
