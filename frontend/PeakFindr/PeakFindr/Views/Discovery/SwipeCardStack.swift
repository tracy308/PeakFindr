
import SwiftUI

struct SwipeCardStack: View {
    let locations: [Location]
    var onSkip: (Location) -> Void
    var onShowDetail: (Location) -> Void

    @State private var dragOffsets: [UUID: CGSize] = [:]

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(Array(locations.enumerated()), id: \.element.id) { index, loc in
                    let isTop = index == locations.count - 1

                    LocationCardView(location: loc)
                        .frame(maxWidth: .infinity)
                        .offset(offset(for: loc, index: index))
                        .rotationEffect(.degrees(isTop ? Double((dragOffsets[loc.id]?.width ?? 0) / 15) : 0))
                        .scaleEffect(isTop ? 1.0 : scale(for: index))
                        .zIndex(Double(index))
                        .gesture(
                            isTop ?
                            DragGesture()
                                .onChanged { value in
                                    dragOffsets[loc.id] = value.translation
                                }
                                .onEnded { value in
                                    handleDragEnd(value: value, loc: loc, width: proxy.size.width)
                                } : nil
                        )
                        .animation(.interactiveSpring(), value: dragOffsets[loc.id] ?? .zero)
                }
            }
        }
        .frame(minHeight: 380)
    }

    private func offset(for loc: Location, index: Int) -> CGSize {
        let base = CGSize(width: 0, height: CGFloat(index) * 8)
        let drag = dragOffsets[loc.id] ?? .zero
        return CGSize(width: base.width + drag.width, height: base.height + drag.height)
    }

    private func scale(for index: Int) -> CGFloat {
        max(0.92, 1.0 - CGFloat(index) * 0.04)
    }

    private func handleDragEnd(value: DragGesture.Value, loc: Location, width: CGFloat) {
        let translation = value.translation
        let threshold: CGFloat = 120

        if translation.width < -threshold {
            onSkip(loc)
            dragOffsets[loc.id] = .zero
        } else if translation.width > threshold {
            onShowDetail(loc)
            dragOffsets[loc.id] = .zero
        } else {
            dragOffsets[loc.id] = .zero
        }
    }
}
