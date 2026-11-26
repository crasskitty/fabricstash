import SwiftUI
import UIKit

enum StudioChrome {
    static func install() {
        let ink = UIColor(named: "Ink") ?? .label
        let paper = UIColor(named: "Paper") ?? .systemBackground
        let accent = UIColor(named: "Accent")
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = paper
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [.foregroundColor: ink]
        appearance.largeTitleTextAttributes = [.foregroundColor: ink]
        let bar = UINavigationBar.appearance()
        bar.standardAppearance = appearance
        bar.scrollEdgeAppearance = appearance
        bar.compactAppearance = appearance
        bar.tintColor = accent
    }
}

enum Studio {
    static let paper = Color("Paper")
    static let card = Color("Card")
    static let ink = Color("Ink")
    static let inkSecondary = Color("InkSecondary")
    static let accent = Color("Accent")
    static let accentFill = Color("AccentFill")
    static let onAccent = Color("OnAccent")
    static let caution = Color("Caution")
}

extension Color {
    init?(hex: String) {
        guard let rgb = RGB(hex: hex) else { return nil }
        self.init(red: rgb.r, green: rgb.g, blue: rgb.b)
    }
}

struct StudioCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Studio.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Studio.ink.opacity(0.08), lineWidth: 1)
            )
    }
}

extension View {
    func studioCard() -> some View {
        modifier(StudioCard())
    }

    func studioScreen() -> some View {
        background(Studio.paper.ignoresSafeArea())
    }
}

struct AccentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(Studio.onAccent)
            .padding(.vertical, 14)
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity)
            .background(
                Studio.accentFill.opacity(configuration.isPressed ? 0.86 : 1),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
    }
}

struct QuietButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(Studio.ink.opacity(configuration.isPressed ? 0.7 : 1))
            .padding(.vertical, 14)
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity)
            .background(Studio.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Studio.ink.opacity(0.12), lineWidth: 1)
            )
    }
}

struct FactRow: View {
    var label: String
    var value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(Studio.inkSecondary)
            Text(value)
                .font(.body)
                .foregroundStyle(Studio.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

func priceLabel(amount: Decimal?, code: String) -> String? {
    guard let amount else { return nil }
    let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    if trimmed.count == 3, Locale.commonISOCurrencyCodes.contains(trimmed) {
        return amount.formatted(.currency(code: trimmed))
    }
    if trimmed.isEmpty {
        return amount.posixStorageString
    }
    return "\(amount.posixStorageString) \(trimmed)"
}
