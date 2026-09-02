import SwiftUI

enum STOTheme {
    static let rose = Color(hex: 0xCE5C82)
    static let roseDark = Color(hex: 0xB9436D)
    static let roseSoft = Color(hex: 0xF8DCE5)
    static let blush = Color(hex: 0xFFF4F6)
    static let blue = Color(hex: 0x3F6D89)
    static let blueDark = Color(hex: 0x2E536A)
    static let blueSoft = Color(hex: 0xDCEAF1)
    static let cream = Color(hex: 0xFBF8F4)
    static let sand = Color(hex: 0xEEE5DB)
    static let ink = Color(hex: 0x20313C)
    static let muted = Color(hex: 0x667883)
    static let white = Color.white
    static let divider = Color(hex: 0xE7DFD8)

    static let cardRadius: CGFloat = 24
    static let controlRadius: CGFloat = 16
    static let pagePadding: CGFloat = 20
}
enum STOFont {
    static func display(_ size: CGFloat, relativeTo style: Font.TextStyle = .title) -> Font {
        .custom("AvenirNextCondensed-DemiBold", size: size, relativeTo: style)
    }

    static func body(_ style: Font.TextStyle = .body, weight: Font.Weight = .regular) -> Font {
        .system(style, design: .rounded, weight: weight)
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255,
            opacity: alpha
        )
    }
}

struct STOPageBackground: View {
    var body: some View {
        LinearGradient(
            colors: [STOTheme.cream, STOTheme.blush.opacity(0.72), STOTheme.white],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

struct STOCard<Content: View>: View {
    private let content: Content
    private let padding: CGFloat
    private let background: Color

    init(
        padding: CGFloat = 18,
        background: Color = STOTheme.white,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.background = background
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: STOTheme.cardRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: STOTheme.cardRadius, style: .continuous)
                    .stroke(STOTheme.rose.opacity(0.08), lineWidth: 1)
            }
            .shadow(color: STOTheme.blue.opacity(0.06), radius: 18, y: 8)
    }
}

struct STOPrimaryButtonStyle: ButtonStyle {
    var color: Color = STOTheme.blue

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(STOFont.display(18, relativeTo: .headline))
            .textCase(.uppercase)
            .tracking(0.4)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 54)
            .background(color.opacity(configuration.isPressed ? 0.82 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}

struct STOSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(STOFont.body(.headline, weight: .semibold))
            .foregroundStyle(STOTheme.blue)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 50)
            .background(STOTheme.white.opacity(configuration.isPressed ? 0.7 : 1))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(STOTheme.blue.opacity(0.35), lineWidth: 1.5)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct STOSectionHeader: View {
    let eyebrow: String?
    let title: String
    let detail: String?

    init(_ title: String, eyebrow: String? = nil, detail: String? = nil) {
        self.title = title
        self.eyebrow = eyebrow
        self.detail = detail
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            if let eyebrow {
                Text(eyebrow.uppercased())
                    .font(STOFont.display(13, relativeTo: .caption))
                    .tracking(1.2)
                    .foregroundStyle(STOTheme.rose)
            }
            Text(title)
                .font(STOFont.display(27, relativeTo: .title2))
                .foregroundStyle(STOTheme.blue)
            if let detail {
                Text(detail)
                    .font(STOFont.body(.subheadline))
                    .foregroundStyle(STOTheme.muted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct STOBrandMark: View {
    var compact = false

    var body: some View {
        HStack(spacing: compact ? 7 : 10) {
            ZStack {
                Circle()
                    .fill(STOTheme.roseSoft)
                Image(systemName: "drop.fill")
                    .font(.system(size: compact ? 14 : 21, weight: .bold))
                    .foregroundStyle(STOTheme.rose)
                    .rotationEffect(.degrees(10))
            }
            .frame(width: compact ? 30 : 44, height: compact ? 30 : 44)

            Text("STÖ")
                .font(STOFont.display(compact ? 24 : 34, relativeTo: compact ? .title3 : .title))
                .tracking(2.5)
                .foregroundStyle(STOTheme.blue)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("STÖ Cycle")
    }
}
