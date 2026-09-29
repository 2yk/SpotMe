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
            WorkoutScreen(onList: onList, onFinish: { confirmingEnd = true })
                .tag(Page.workout)
            // The system's own player: whatever plays on the watch or the iPhone, the Crown sets the volume.
            NowPlayingView()
                .toolbar(.hidden, for: .navigationBar)
                .tag(Page.nowPlaying)
        }
        .tabViewStyle(.page)
        .finishDialog(isPresented: $confirmingEnd, workout: workout)
        // Finished or discarded, from whichever page: back to Today, where the summary shows.
        .onChange(of: workout.step == nil) { _, ended in
            if ended { onList() }
        }
        #if DEBUG
        .task {
            switch LaunchOptions.screen {
            case "controls", "paused": page = .controls
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

extension View {
    /// Finish workout? Save to Health or not, or keep going.
    func finishDialog(isPresented: Binding<Bool>, workout: WorkoutModel) -> some View {
        confirmationDialog("Finish workout?", isPresented: isPresented) {
            if workout.savesToHealth {
                Button("Save to Health") { Task { await workout.finishWorkout() } }
                Button("Don't save to Health", role: .destructive) {
                    Task { await workout.finishWorkout(saveToHealth: false) }
                }
            } else {
                Button("Finish") { Task { await workout.finishWorkout() } }
            }
            Button("Keep going", role: .cancel) {}
        } message: {
            Text(workout.savesToHealth ? "Your sets stay in SpotMe either way." : "Marks today's session done.")
        }
    }
}
