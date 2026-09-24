import SwiftUI

enum MemoryTheme {
    static let cream = Color(red: 0.961, green: 0.945, blue: 0.910)
    static let ink = Color(red: 0.070, green: 0.070, blue: 0.070)
    static let muted = Color(red: 0.070, green: 0.070, blue: 0.070).opacity(0.40)
    static let gray = Color(red: 0.780, green: 0.780, blue: 0.765)
    static let stone = Color(red: 0.745, green: 0.690, blue: 0.600)
    static let sage = Color(red: 0.180, green: 0.620, blue: 0.278)
    static let orange = Color(red: 0.929, green: 0.380, blue: 0.180)
    static let gold = Color(red: 0.910, green: 0.770, blue: 0.290)
    static let lavender = Color(red: 0.788, green: 0.702, blue: 0.910)
    static let coral = Color(red: 0.890, green: 0.365, blue: 0.290)
    static let paper = Color(red: 0.988, green: 0.980, blue: 0.961)

    static let cardRadius: CGFloat = 22

    static let badgeColors: [Color] = [orange, sage, gold, coral, lavender, stone]

    static func badgeColor(for string: String) -> Color {
        let sum = string.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return badgeColors[abs(sum) % badgeColors.count]
    }

    static func contactCardFill(at index: Int) -> Color {
        let palette = [gray, paper, stone, cream]
        return palette[index % palette.count]
    }
}

enum AppTab: Hashable, CaseIterable {
    case updates
    case contacts

    var title: String {
        switch self {
        case .updates: "Updates"
        case .contacts: "Contacts"
        }
    }

    var badge: String {
        switch self {
        case .updates: "1"
        case .contacts: "2"
        }
    }

    var color: Color {
        switch self {
        case .updates: MemoryTheme.orange
        case .contacts: MemoryTheme.sage
        }
    }
}

extension Font {
    static func memory(_ size: CGFloat, weight: Font.Weight = .black) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
}

struct MemoryDisplay: ViewModifier {
    var size: CGFloat
    var weight: Font.Weight = .black

    func body(content: Content) -> some View {
        content
            .font(.memory(size, weight: weight))
            .fontWidth(.condensed)
            .foregroundStyle(MemoryTheme.ink)
            .tracking(-0.8)
    }
}

extension View {
    func memoryDisplay(_ size: CGFloat, weight: Font.Weight = .black) -> some View {
        modifier(MemoryDisplay(size: size, weight: weight))
    }

    func memoryBackground() -> some View {
        background(MemoryTheme.cream.ignoresSafeArea())
            .toolbarBackground(MemoryTheme.cream, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.light, for: .navigationBar)
    }
}

struct MemoryCard<Content: View>: View {
    var fill: Color
    var minHeight: CGFloat = 108
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(18)
            .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .leading)
            .background(fill, in: RoundedRectangle(cornerRadius: MemoryTheme.cardRadius, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: MemoryTheme.cardRadius, style: .continuous))
    }
}

struct LetterBadge: View {
    var letter: String
    var color: Color
    var size: CGFloat = 36

    var body: some View {
        Text(letter)
            .font(.memory(size * 0.40, weight: .heavy))
            .fontWidth(.condensed)
            .foregroundStyle(MemoryTheme.ink)
            .frame(width: size, height: size)
            .background(color, in: Circle())
            .overlay {
                Circle().stroke(MemoryTheme.paper, lineWidth: 3)
            }
            .accessibilityHidden(true)
    }
}

struct CountBadge: View {
    var count: Int
    var color: Color
    var size: CGFloat = 56

    var body: some View {
        Text("\(count)")
            .font(.memory(size * 0.42))
            .fontWidth(.condensed)
            .foregroundStyle(MemoryTheme.ink)
            .frame(width: size, height: size)
            .background(color, in: Circle())
            .overlay {
                Circle().stroke(MemoryTheme.paper, lineWidth: 3)
            }
            .accessibilityLabel("\(count) items")
    }
}

struct CircleIconButton: View {
    var systemName: String
    var fill: Color
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(MemoryTheme.ink)
                .frame(width: 40, height: 40)
                .background(fill, in: Circle())
        }
        .buttonStyle(.plain)
    }
}

struct EditorialHeader: View {
    var title: String
    var subtitle: String
    var count: Int?
    var countColor: Color = MemoryTheme.orange
    var trailing: AnyView? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: -6) {
                Text(title)
                    .memoryDisplay(48)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(subtitle)
                    .memoryDisplay(48)
                    .foregroundStyle(MemoryTheme.ink.opacity(0.28))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Spacer(minLength: 8)
            if let trailing {
                trailing
            } else if let count {
                CountBadge(count: count, color: countColor)
            }
        }
    }
}

struct SectionWord: View {
    var text: String

    var body: some View {
        Text(text.uppercased())
            .font(.memory(13, weight: .heavy))
            .fontWidth(.condensed)
            .tracking(1.2)
            .foregroundStyle(MemoryTheme.ink)
            .padding(.top, 8)
            .padding(.bottom, 2)
    }
}

struct MemorySearchField: View {
    @Binding var text: String
    var prompt: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(MemoryTheme.ink)
            TextField(prompt, text: $text)
                .font(.memory(16, weight: .semibold))
                .fontWidth(.condensed)
                .foregroundStyle(MemoryTheme.ink)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(MemoryTheme.muted)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(MemoryTheme.gray, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
