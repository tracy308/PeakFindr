import SwiftUI

struct SwipeCardStack: View {
    let locations: [LocationResponse]
    var onSkip: (LocationResponse) -> Void
    var onSave: (LocationResponse) -> Void
    var onTapTop: (LocationResponse) -> Void

    @State private var dragOffset: CGSize = .zero

    // How many cards you want visible at once
    private let maxVisibleCards = 3

    var body: some View {
        ZStack {
            let visible = Array(locations.prefix(maxVisibleCards))

            ForEach(Array(visible.enumerated()), id: \.element.id) { index, loc in
                let isTop = index == 0

                LocationCardView(location: loc)
                    // Tiny vertical offset so you can see there's a stack,
                    // but the card itself stays same size.
                    .offset(y: CGFloat(index) * 8)
                    // Apply drag only to the top card
                    .offset(isTop ? dragOffset : .zero)
                    .rotationEffect(
                        isTop
                        ? Angle(degrees: Double(dragOffset.width / 10))
                        : .zero
                    )
                    .shadow(radius: isTop ? 10 : 4)
                    .zIndex(Double(maxVisibleCards - index))
                    .allowsHitTesting(isTop)
                    .onTapGesture {
                        if isTop { onTapTop(loc) }
                    }
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                guard isTop else { return }
                                withAnimation(.interactiveSpring()) {
                                    dragOffset = value.translation
                                }
                            }
                            .onEnded { value in
                                guard isTop else { return }
                                handleEnd(value: value, loc: loc)
                            }
                    )
                    // This controls how cards animate in/out of the stack
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        )
                    )
            }
        }
        // Animate when the underlying locations array changes
        .animation(
            .spring(response: 0.35, dampingFraction: 0.85),
            value: locations
        )
    }

    private func handleEnd(value: DragGesture.Value, loc: LocationResponse) {
        let translation = value.translation.width
        let threshold: CGFloat = 120

        if translation < -threshold {
            // Swipe left = skip
            withAnimation(.spring()) {
                // fling off to the left
                dragOffset = CGSize(width: -600, height: 0)
            }
            // Remove after the fling starts
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                dragOffset = .zero
                onSkip(loc)
            }

        } else if translation > threshold {
            // Swipe right = save
            withAnimation(.spring()) {
                // fling off to the right
                dragOffset = CGSize(width: 600, height: 0)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                dragOffset = .zero
                onSave(loc)
            }

        } else {
            // Not far enough -> snap back
            withAnimation(.spring()) {
                dragOffset = .zero
            }
        }
    }
}
