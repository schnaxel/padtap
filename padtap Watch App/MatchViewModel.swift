//
//  MatchViewModel.swift
//  padtap Watch App
//

import SwiftUI
import Combine

@MainActor
final class MatchViewModel: ObservableObject {
    enum Screen {
        case setup
        case score
        case result
    }

    @Published var setupDraft: MatchSetup = .default
    @Published private(set) var matchState: MatchState?
    @Published private(set) var history: [MatchState] = []

    private let engine: ScoreEngine
    private let haptics: HapticProviding

    init(engine: ScoreEngine, haptics: HapticProviding) {
        self.engine = engine
        self.haptics = haptics
    }

    convenience init() {
        self.init(engine: ScoreEngine(), haptics: WatchHapticProvider())
    }

    convenience init(haptics: HapticProviding) {
        self.init(engine: ScoreEngine(), haptics: haptics)
    }

    var screen: Screen {
        guard let matchState else {
            return .setup
        }
        return matchState.isMatchFinished ? .result : .score
    }

    var canUndo: Bool {
        !history.isEmpty
    }

    func startMatch() {
        history.removeAll()
        matchState = engine.initialState(from: setupDraft)
    }

    func addPoint(to team: TeamSide) {
        guard let currentState = matchState else { return }

        history.append(currentState)
        let transition = engine.addPoint(to: team, in: currentState)

        if transition.state == currentState {
            _ = history.popLast()
            return
        }

        matchState = transition.state
        playHaptic(for: transition.event)
    }

    func undo() {
        guard let previousState = history.popLast() else { return }
        matchState = previousState
        haptics.play(.undo)
    }

    func resetToSetup() {
        matchState = nil
        history.removeAll()
    }

    func startRematch() {
        guard let existingState = matchState else {
            startMatch()
            return
        }

        setupDraft = existingState.setup
        startMatch()
    }

    func pointDisplay() -> PointDisplay {
        guard let matchState else {
            return .regular(teamA: "0", teamB: "0")
        }
        return engine.pointDisplay(for: matchState)
    }

    func teamName(for team: TeamSide) -> String {
        let fallback = team == .teamA ? "Team A" : "Team B"
        let setup = matchState?.setup ?? setupDraft
        let raw = team == .teamA ? setup.teamAName : setup.teamBName
        let cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? fallback : cleaned
    }

    func pointText(for team: TeamSide) -> String {
        switch pointDisplay() {
        case let .regular(teamA, teamB):
            return team == .teamA ? teamA : teamB
        case .deuce:
            return "40"
        case let .advantage(advantageTeam):
            return team == advantageTeam ? "Ad" : "40"
        }
    }

    func pointCenterLabel() -> String? {
        switch pointDisplay() {
        case .deuce:
            return "Deuce"
        case let .advantage(team):
            return "Ad \(teamName(for: team))"
        case .regular:
            return nil
        }
    }

    func scoreColumns(maxColumns: Int = 3) -> [ScoreColumnDisplay] {
        guard let state = matchState else {
            return Array(repeating: ScoreColumnDisplay(teamAText: "-", teamBText: "-", isCurrentSet: false), count: maxColumns)
        }

        var columns = state.completedSets.map {
            ScoreColumnDisplay(
                teamAText: "\($0.teamAGames)",
                teamBText: "\($0.teamBGames)",
                isCurrentSet: false
            )
        }

        columns.append(
            ScoreColumnDisplay(
                teamAText: "\(state.gamesTeamA)",
                teamBText: "\(state.gamesTeamB)",
                isCurrentSet: true
            )
        )

        if columns.count < maxColumns {
            let placeholders = Array(
                repeating: ScoreColumnDisplay(teamAText: "-", teamBText: "-", isCurrentSet: false),
                count: maxColumns - columns.count
            )
            columns = placeholders + columns
        } else if columns.count > maxColumns {
            columns = Array(columns.suffix(maxColumns))
        }

        return columns
    }

    private func playHaptic(for event: ScoreEvent) {
        switch event {
        case .none:
            break
        case .pointWon:
            haptics.play(.point)
        case .gameWon:
            haptics.play(.game)
        case .setWon:
            haptics.play(.set)
        case .matchWon:
            haptics.play(.match)
        }
    }
}
