import SwiftUI
import UIKit

enum StudioChrome {
    static func install() {
        let ink = UIColor(named: "Ink") ?? .label
        let linen = UIColor(named: "Linen") ?? .systemBackground
        let largeBase = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .largeTitle)
        let inlineBase = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .headline)
        let large = UIFont(descriptor: largeBase.withDesign(.serif) ?? largeBase, size: 0)
        let inline = UIFont(descriptor: inlineBase.withDesign(.serif) ?? inlineBase, size: 0)
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = linen
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [.foregroundColor: ink, .font: inline]
        appearance.largeTitleTextAttributes = [.foregroundColor: ink, .font: large]
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }
}

enum Studio {
    static let linen = Color("Linen")
    static let card = Color("Card")
    static let ink = Color("Ink")
    static let inkSecondary = Color("InkSecondary")
    static let madder = Color("Madder")
    static let madderFill = Color("MadderFill")
    static let onMadder = Color("OnMadder")
    static let sewingGreen = Color("SewingGreen")
    static let sewingGreenFill = Color("SewingGreenFill")

    static func serif(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        .system(style, design: .serif).weight(weight)
    }
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
            .background(Studio.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Studio.ink.opacity(0.08), lineWidth: 1)
            )
    }
}

extension View {
    func studioCard() -> some View {
        modifier(StudioCard())
    }

    func studioScreen() -> some View {
        background(Studio.linen.ignoresSafeArea())
    }
}

struct MadderButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(Studio.onMadder)
            .padding(.vertical, 14)
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity)
            .background(
                Studio.madderFill.opacity(configuration.isPressed ? 0.86 : 1),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
    }
}

struct GreenButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(Studio.onMadder)
            .padding(.vertical, 14)
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity)
            .background(
                Studio.sewingGreenFill.opacity(configuration.isPressed ? 0.86 : 1),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
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
