import SwiftUI

struct STOSelectionChip: View {
    let title: String
    let symbol: String?
    let isSelected: Bool
    let action: () -> Void

    init(_ title: String, symbol: String? = nil, isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.symbol = symbol
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                if let symbol {
                    Image(systemName: symbol)
                        .font(.system(size: 14, weight: .semibold))
                }
                Text(title)
                    .font(STOFont.body(.subheadline, weight: .semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? Color.white : STOTheme.blue)
            .padding(.horizontal, 14)
            .frame(minHeight: 42)
            .background(isSelected ? STOTheme.rose : STOTheme.white)
            .overlay {
                Capsule()
                    .stroke(isSelected ? STOTheme.rose : STOTheme.blue.opacity(0.18), lineWidth: 1)
            }
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
struct STOIconTile: View {
    let title: String
    let symbol: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    init(
        title: String,
        symbol: String,
        isSelected: Bool,
        color: Color = STOTheme.rose,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.symbol = symbol
        self.isSelected = isSelected
        self.color = color
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 9) {
                ZStack {
                    Circle()
                        .fill(isSelected ? color : color.opacity(0.12))
                    Image(systemName: symbol)
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(isSelected ? Color.white : color)
                }
                .frame(width: 44, height: 44)

                Text(title)
                    .font(STOFont.body(.caption, weight: .semibold))
                    .foregroundStyle(STOTheme.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(height: 32, alignment: .top)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 6)
            .frame(maxWidth: .infinity)
            .background(isSelected ? color.opacity(0.09) : STOTheme.white)
            .overlay {
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .stroke(isSelected ? color : STOTheme.divider, lineWidth: isSelected ? 1.8 : 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct PhaseBadge: View {
    let phase: CyclePhase

    var body: some View {
        Label(phase.shortTitle, systemImage: phase.icon)
            .font(STOFont.body(.caption, weight: .semibold))
            .foregroundStyle(phase.color)
            .padding(.horizontal, 11)
            .padding(.vertical, 7)
            .background(phase.color.opacity(0.11))
            .clipShape(Capsule())
    }
}

struct STOMetricCard: View {
    let value: String
    let label: String
    let symbol: String
    var tint: Color = STOTheme.rose

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 38, height: 38)
                .background(tint.opacity(0.11))
                .clipShape(Circle())

            Text(value)
                .font(STOFont.display(31, relativeTo: .title2))
                .foregroundStyle(STOTheme.blue)
            Text(label)
                .font(STOFont.body(.caption))
                .foregroundStyle(STOTheme.muted)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 142, alignment: .leading)
        .background(STOTheme.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(STOTheme.divider.opacity(0.8), lineWidth: 1)
        }
    }
}

struct STOSafetyNote: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(STOTheme.blue)
                .padding(.top, 1)
            Text(text)
                .font(STOFont.body(.caption))
                .foregroundStyle(STOTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(STOTheme.blueSoft.opacity(0.56))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct EmptyStateCard: View {
    let symbol: String
    let title: String
    let message: String

    var body: some View {
        STOCard {
            VStack(spacing: 12) {
                Image(systemName: symbol)
                    .font(.system(size: 25, weight: .semibold))
                    .foregroundStyle(STOTheme.rose)
                    .frame(width: 52, height: 52)
                    .background(STOTheme.roseSoft)
                    .clipShape(Circle())
                Text(title)
                    .font(STOFont.display(23, relativeTo: .title3))
                    .foregroundStyle(STOTheme.blue)
                Text(message)
                    .font(STOFont.body(.subheadline))
                    .foregroundStyle(STOTheme.muted)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }
}
