import SwiftUI
import UIKit

struct AtmosphereBackground: View {
    var body: some View {
        ZStack {
            MemoryTheme.atmosphere
            Circle()
                .fill(MemoryTheme.sea.opacity(0.16))
                .frame(width: 280, height: 280)
                .blur(radius: 70)
                .offset(x: -140, y: -180)
            Circle()
                .fill(MemoryTheme.coral.opacity(0.10))
                .frame(width: 260, height: 260)
                .blur(radius: 70)
                .offset(x: 150, y: 220)
        }
        .ignoresSafeArea()
    }
}

struct SeaButtonStyle: ButtonStyle {
    var disabled = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(disabled ? MemoryTheme.sea.opacity(0.45) : MemoryTheme.sea)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

struct EmptyCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.white.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(MemoryTheme.ink.opacity(0.12), lineWidth: 1)
        )
    }
}

struct PersonAvatar: View {
    let person: Person
    var size: CGFloat = 40

    var body: some View {
        Group {
            if let data = person.thumbnail, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Text(person.initials)
                    .font(.system(size: size * 0.36, weight: .medium))
                    .foregroundStyle(MemoryTheme.seaDeep)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(MemoryTheme.mist)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}
