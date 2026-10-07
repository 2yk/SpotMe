import SwiftUI
import WatchKit
import RepCoachCore

/// The workout between its controls (swipe right) and Now Playing (swipe left), as in Apple's Workout app.
struct WorkoutPager: View {
    enum Page: Hashable {
        case controls, workout, nowPlaying
    }

    @Environment(WorkoutModel.self) private var workout
    /// Back to Today's list.
    let onList: () -> Void
    @State private var page = Page.workout
    @State private var confirmingEnd = false

    var body: some View {
        TabView(selection: $page) {
            WorkoutControls(onPauseOrResume: pauseOrResume, onEnd: { confirmingEnd = true },
                            onSkip: skip, onList: onList)
                .tag(Page.controls)
            // Everything's done: Finish just finishes.
            WorkoutScreen(onList: onList, onFinish: { Task { await workout.finishWorkout() } })
                .tag(Page.workout)
            // The system's own player: whatever plays on the watch or the iPhone, the Crown sets the volume.
            NowPlayingView()
                .toolbar(.hidden, for: .navigationBar)
                .tag(Page.nowPlaying)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .overlay(alignment: .bottom) {
            PageDots(index: [Page.controls, .workout, .nowPlaying].firstIndex(of: page) ?? 1,
                     raised: workout.showsEdgeTimer)
                .opacity(page == .workout && workout.stepScrolls ? 0 : 1)
        }
        .ignoresSafeArea(edges: .bottom)
        .sheet(isPresented: $confirmingEnd) { EndWorkoutSheet() }
        // Finished or discarded, from whichever page: back to Today, where the summary shows.
        .onChange(of: workout.step == nil) { _, ended in
            if ended { onList() }
        }
        #if DEBUG
        .task {
            switch LaunchOptions.screen {
            case "controls", "paused", "controls-break": page = .controls
            case "media": page = .nowPlaying
            default: break
            }
        }
        #endif
    }

    /// Pausing stays here, where Resume is; resuming goes back to the workout, as the Workout app does.
    private func pauseOrResume() {
        if workout.isPaused {
            workout.resume()
            show(.workout)
        } else {
            workout.pause()
        }
    }

    private func skip() {
        withAnimation(.snappy) { workout.skip() }
        show(.workout)
    }

    private func show(_ page: Page) {
        withAnimation(.snappy) { self.page = page }
    }
}

/// The three pages as dots: controls, workout, Now Playing. Higher on screens with the edge timer, which runs
/// along the bottom edge.
private struct PageDots: View {
    let index: Int
    let raised: Bool
    @Environment(\.dimmed) private var dimmed

    var body: some View {
        HStack(spacing: pt(4)) {
            ForEach(0..<3) { dot in
                Circle()
                    .fill(.white.opacity(dot == index ? 1 : 0.3))
                    .frame(width: pt(5), height: pt(5))
            }
        }
        .padding(.bottom, pt(raised ? 10 : 5))
        .opacity(dimmed ? 0.35 : 1)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
