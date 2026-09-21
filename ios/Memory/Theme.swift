import SwiftUI

enum MemoryTheme {
    static let ink = Color(red: 26 / 255, green: 46 / 255, blue: 40 / 255)
    static let inkSoft = Color(red: 61 / 255, green: 90 / 255, blue: 82 / 255)
    static let mist = Color(red: 232 / 255, green: 242 / 255, blue: 239 / 255)
    static let foam = Color(red: 244 / 255, green: 250 / 255, blue: 248 / 255)
    static let sea = Color(red: 13 / 255, green: 115 / 255, blue: 119 / 255)
    static let seaDeep = Color(red: 9 / 255, green: 84 / 255, blue: 86 / 255)
    static let coral = Color(red: 196 / 255, green: 92 / 255, blue: 38 / 255)
    static let sand = Color(red: 212 / 255, green: 196 / 255, blue: 168 / 255)

    static var atmosphere: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: Color(red: 244 / 255, green: 250 / 255, blue: 248 / 255), location: 0),
                .init(color: Color(red: 232 / 255, green: 242 / 255, blue: 239 / 255), location: 0.45),
                .init(color: Color(red: 247 / 255, green: 243 / 255, blue: 235 / 255), location: 1),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

extension Font {
    static func memoryDisplay(_ style: Font.TextStyle) -> Font {
        .system(style, design: .serif)
    }
}
