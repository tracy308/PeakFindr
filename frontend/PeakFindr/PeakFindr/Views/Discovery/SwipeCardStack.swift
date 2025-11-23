import SwiftUI

struct SwipeCardStack: View {
    let locations: [LocationResponse]
    var onSkip: (LocationResponse) -> Void
    var onSave: (LocationResponse) -> Void
    var onTapTop: (LocationResponse) -> Void

    @State private var dragOffsets: [String: CGSize] = [:]

    var body: some View {
        ZStack(alignment: .top) {
            // Render bottom -> top so the top card is last in the ZStack
            ForEach(Array(locations.enumerated()), id: \.element.id) { index, loc in
                let isTop = index == 0
                LocationCardView(location: loc)
                    .offset(offset(for: loc, index: index))
                    .scaleEffect(scale(for: index))
                    .zIndex(Double(locations.count - index))
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                guard isTop else { return }
                                dragOffsets[loc.id] = value.translation
                            }
                            .onEnded { value in
                                guard isTop else { return }
                                handleEnd(value, loc: loc)
                            }
                    )
                    .onTapGesture {
                        if isTop { onTapTop(loc) }
                    }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func scale(for index: Int) -> CGFloat {
        // Slightly smaller for deeper cards
        let delta = min(CGFloat(index) * 0.02, 0.08)
        return 1.0 - delta
    }

    private func offset(for loc: LocationResponse, index: Int) -> CGSize {
        // Index 0 is top card, bigger index sits behind slightly lower
        let base = CGSize(width: 0, height: CGFloat(index) * 10)
        let drag = dragOffsets[loc.id] ?? .zero
        return CGSize(width: base.width + drag.width, height: base.height + drag.height)
    }

    private func handleEnd(_ value: DragGesture.Value, loc: LocationResponse) {
        let t = value.translation.width
        let threshold: CGFloat = 120

        if t < -threshold {
            onSkip(loc)
        } else if t > threshold {
            onSave(loc)
        }

        dragOffsets[loc.id] = .zero
    }
}