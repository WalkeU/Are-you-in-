#if DEBUG
import Foundation
import SwiftUI

/// Debug-only automation driven entirely by launch environment variables, so the app can
/// be scripted end-to-end (register -> pair -> play -> results) for screenshot/QA passes
/// without any OS-level input injection. Inert unless UITEST_MODE=1 is set, and compiled
/// out of Release builds entirely.
@MainActor
enum UITestHarness {
    static let isEnabled = ProcessInfo.processInfo.environment["UITEST_MODE"] == "1"
    static var name: String? { ProcessInfo.processInfo.environment["UITEST_NAME"] }
    static var pairCode: String? { ProcessInfo.processInfo.environment["UITEST_PAIR_CODE"] }
    static var autoStartCount: Int? { ProcessInfo.processInfo.environment["UITEST_START_COUNT"].flatMap(Int.init) }
    static var autoAccept: Bool { ProcessInfo.processInfo.environment["UITEST_AUTO_ACCEPT"] == "1" }
    static var autoAnswer: Bool { ProcessInfo.processInfo.environment["UITEST_AUTO_ANSWER"] == "1" }
    static var gotoHistory: Bool { ProcessInfo.processInfo.environment["UITEST_GOTO_HISTORY"] == "1" }
    /// Extra pause after each step - 0 for fast scripted runs, bumped up when a human
    /// (or a screenshot pass) needs a window to observe an intermediate state.
    static var stepDelayMs: Int { ProcessInfo.processInfo.environment["UITEST_STEP_MS"].flatMap(Int.init) ?? 0 }

    static func log(_ message: String) {
        NSLog("UITEST_STAGE %@", message)
    }

    static func pauseForStep() async {
        guard stepDelayMs > 0 else { return }
        try? await Task.sleep(for: .milliseconds(stepDelayMs))
    }

    static func runOnboarding(appState: AppState) async {
        guard isEnabled else { return }

        if case .loggedOut = appState.phase, let name {
            await appState.register(name: name)
        }

        if case .awaitingPartner(let user) = appState.phase {
            log("registered name=\(user.name) inviteCode=\(user.inviteCode)")
            if let pairCode {
                let success = await appState.pair(inviteCode: pairCode)
                log(success ? "paired" : "pairFailed")
            }
        } else if case .ready = appState.phase {
            log("alreadyPaired")
        }
    }

    static func runHome(viewModel: HomeViewModel, path: Binding<[AppRoute]>) async {
        guard isEnabled else { return }

        if gotoHistory {
            log("goingToHistory")
            path.wrappedValue.append(.history)
            return
        }

        var didStart = false
        for _ in 0..<90 {
            if autoAccept, viewModel.incomingInvite != nil {
                log("incomingInviteVisible")
                await pauseForStep()
                if let sessionId = await viewModel.acceptInvite() {
                    log("acceptedInvite sessionId=\(sessionId)")
                    path.wrappedValue.append(.game(sessionId: sessionId))
                }
                return
            }
            if let summary = viewModel.mySessionSummary, summary.status == .active {
                log("continuingSession id=\(summary.id)")
                path.wrappedValue.append(.game(sessionId: summary.id))
                return
            }
            if !didStart, let count = autoStartCount, viewModel.incomingInvite == nil, viewModel.mySessionSummary == nil {
                if let session = await viewModel.startSession(itemCount: count) {
                    log("sessionCreated id=\(session.id) status=\(session.status.rawValue)")
                    didStart = true
                    await pauseForStep()
                }
            }
            try? await Task.sleep(for: .seconds(1))
            await viewModel.load()
        }
    }

    static func runGame(viewModel: GameViewModel, path: Binding<[AppRoute]>) async {
        guard isEnabled, autoAnswer else { return }
        for _ in 0..<200 {
            switch viewModel.stage {
            case .answering:
                if let item = viewModel.currentItem {
                    // Pause on the plain yes/no card first - this is the real "are you
                    // in?" decision moment - before deciding and (if relevant) showing
                    // the give/receive/both follow-up, exactly like a real tap would.
                    log("showingQuestion kink=\"\(item.name)\" hasRoleVariant=\(item.hasRoleVariant)")
                    await pauseForStep()
                    if item.hasRoleVariant {
                        viewModel.awaitingRoleFor = item
                        await pauseForStep()
                        await viewModel.answer(true, role: .both)
                    } else {
                        await viewModel.answer(true, role: nil)
                    }
                    log("answered kink=\"\(item.name)\"")
                }
            case .completed:
                log("gameCompleted")
                await pauseForStep()
                path.wrappedValue.append(.results(sessionId: viewModel.sessionId))
                return
            case .waitingForPartner:
                log("waitingForPartner")
                return
            case .failed(let message):
                log("gameFailed message=\"\(message)\"")
                return
            case .loading:
                break
            }
            try? await Task.sleep(for: .milliseconds(300))
        }
    }
}
#endif
