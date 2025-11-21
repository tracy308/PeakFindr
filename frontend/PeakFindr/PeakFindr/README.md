
# Peakfindr (MVVM SwiftUI Demo)

This folder contains a minimal SwiftUI app following MVVM (SVVM) with three tabs:

- Discover: Tinder-style swipe cards for locations
- Social: Social Hub with chat rooms and a simple chat interface
- Profile: User profile with levels, points, streaks, and recent visits

## Folder structure (Option A)

- `Models/` — app data models (Location, Review, Chat, UserProfile)
- `ViewModels/` — `DiscoveryViewModel`, `ChatViewModel`, `ProfileViewModel`
- `Views/`
  - `Discovery/` — discovery stack, detail page, review form
  - `Social/` — social hub + chat room
  - `Profile/` — profile view & stat cards
- `Services/` — `Navigator` for opening Maps
- `Resources/` — screenshot images; import them into your Xcode asset catalog if desired.

## Usage

1. Create a new Xcode SwiftUI iOS project named `Peakfindr`.
2. Drag the contents of this folder into the Xcode project (keeping groups for Models, ViewModels, Views, Services).
3. Add the PNGs from `Resources/` into the asset catalog if you want to use them as images and rename entries to match:
   - `peak_sample`
   - `social_header`
   - `profile_header`
4. Build and run on iOS 17+.

Swipe left in Discover to skip, swipe right to open details. Save locations and write reviews; profile stats will update using notifications.
