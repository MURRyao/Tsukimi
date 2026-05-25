import SwiftUI

struct NotchHandleView: View {
    let revealAction: () -> Void

    @State private var dragOffset: CGFloat = 0
    @State private var isHovering = false

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Capsule(style: .continuous)
                    .fill(BagEndDesign.ColorToken.graphite.opacity(0.98))
                    .shadow(color: BagEndDesign.ColorToken.graphite.opacity(0.2), radius: 12, y: 5)

                HStack(spacing: 8) {
                    Circle()
                        .fill(BagEndDesign.ColorToken.brandAccent)
                        .frame(width: 7, height: 7)

                    Text("Bag End")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.92))

                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white.opacity(0.72))
                }
                .opacity(isHovering ? 1 : 0.82)
            }
            .frame(width: BagEndDesign.Shelf.handleWidth, height: 34)

            Capsule(style: .continuous)
                .fill(BagEndDesign.ColorToken.brandAccent.opacity(0.9))
                .frame(width: 54, height: 5)
                .padding(.top, 4)
                .opacity(isHovering || dragOffset > 0 ? 1 : 0.72)
        }
        .offset(y: dragOffset)
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    dragOffset = min(max(value.translation.height, 0), 32)
                }
                .onEnded { value in
                    let isTap = abs(value.translation.width) < 4 && abs(value.translation.height) < 4
                    let isPullDown = value.translation.height > 14
                    dragOffset = 0

                    if isTap || isPullDown {
                        revealAction()
                    }
                }
        )
    }
}
