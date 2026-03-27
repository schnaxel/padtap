//
//  MatchViewModel.swift
//  padtap Watch App
//

import SwiftUI
import Combine

@MainActor
final class MatchViewModel: ObservableObject {
    private enum StorageKey {
        static let completedMatches = "completedMatches.v1"
    }

    enum Screen {
        case home
        case setup
        case score
        case result
        case history
    }

    @Published private(set) var screen: Screen = .home
    @Published var setupDraft: MatchSetup = .default
    @Published private(set) var matchState: MatchState?
    @Published private(set) var history: [MatchState] = []
    @Published private(set) var completedMatches: [CompletedMatchSummary] = []

    private let engine: ScoreEngine
    private let haptics: HapticProviding
    private let userDefaults: UserDefaults

    init(engine: ScoreEngine, haptics: HapticProviding, userDefaults: UserDefaults = .standard) {
        self.engine = engine
        self.haptics = haptics
        self.userDefaults = userDefaults
        loadPersistedCompletedMatches()
    }

    convenience init() {
        self.init(engine: ScoreEngine(), haptics: WatchHapticProvider())
    }

    convenience init(haptics: HapticProviding) {
        self.init(engine: ScoreEngine(), haptics: haptics)
    }

    var canUndo: Bool {
        !history.isEmpty
    }

    func showHome() {
        screen = .home
    }

    func showSetup() {
        matchState = nil
        history.removeAll()
        screen = .setup
    }

    func showHistory() {
        screen = .history
    }

    func startMatch() {
        history.removeAll()
        matchState = engine.initialState(from: setupDraft)
        screen = .score
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

        if transition.state.isMatchFinished {
            appendCompletedMatch(from: transition.state)
            screen = .result
        } else {
            screen = .score
        }
    }

    func undo() {
        let currentState = matchState
        guard let previousState = history.popLast() else { return }

        if currentState?.isMatchFinished == true, previousState.isMatchFinished == false {
            removeCompletedMatch(forStartedAt: previousState.startedAt)
        }

        matchState = previousState
        screen = previousState.isMatchFinished ? .result : .score
        haptics.play(.undo)
    }

    func resetToSetup() {
        showSetup()
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

    func scoreColumns(maxColumns: Int? = 3) -> [ScoreColumnDisplay] {
        guard let state = matchState else {
            let fallbackCount = maxColumns ?? 3
            return Array(repeating: ScoreColumnDisplay(teamAText: "-", teamBText: "-", isCurrentSet: false), count: fallbackCount)
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

        guard let maxColumns else {
            return columns
        }

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

    func setServingTeam(_ team: TeamSide) {
        guard var state = matchState else { return }
        guard state.servingTeam != team else { return }

        history.append(state)
        state.servingTeam = team
        matchState = state
    }

    func endMatch() {
        guard var state = matchState, !state.isMatchFinished else { return }

        history.append(state)
        state.isMatchFinished = true
        state.winner = manualWinner(from: state)
        matchState = state
        appendCompletedMatch(from: state)
        screen = .result
        haptics.play(.match)
    }

    func deleteCompletedMatch(id: UUID) {
        guard let idx = completedMatches.firstIndex(where: { $0.id == id }) else { return }
        completedMatches.remove(at: idx)
        persistCompletedMatches()
    }

    private func manualWinner(from state: MatchState) -> TeamSide? {
        if state.setsTeamA != state.setsTeamB {
            return state.setsTeamA > state.setsTeamB ? .teamA : .teamB
        }
        if state.gamesTeamA != state.gamesTeamB {
            return state.gamesTeamA > state.gamesTeamB ? .teamA : .teamB
        }
        if state.pointsTeamA != state.pointsTeamB {
            return state.pointsTeamA > state.pointsTeamB ? .teamA : .teamB
        }
        if let advantageTeam = state.advantageTeam {
            return advantageTeam
        }
        return nil
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

    private func appendCompletedMatch(from state: MatchState) {
        let unfinishedSet = unfinishedSetIfNeeded(from: state)

        if completedMatches.contains(where: {
            $0.playedAt == state.startedAt
                && $0.teamAName == state.teamAName
                && $0.teamBName == state.teamBName
                && $0.matchFormat == state.setup.format
                && $0.setsTeamA == state.setsTeamA
                && $0.setsTeamB == state.setsTeamB
                && $0.setScores == state.completedSets
                && $0.unfinishedSet == unfinishedSet
                && $0.winner == state.winner
        }) {
            return
        }

        let summary = CompletedMatchSummary(
            playedAt: state.startedAt,
            teamAName: state.teamAName,
            teamBName: state.teamBName,
            matchFormat: state.setup.format,
            setsTeamA: state.setsTeamA,
            setsTeamB: state.setsTeamB,
            setScores: state.completedSets,
            unfinishedSet: unfinishedSet,
            winner: state.winner
        )
        completedMatches.insert(summary, at: 0)
        persistCompletedMatches()
    }

    private func unfinishedSetIfNeeded(from state: MatchState) -> SetScore? {
        if state.gamesTeamA == 0, state.gamesTeamB == 0 {
            return nil
        }
        return SetScore(teamAGames: state.gamesTeamA, teamBGames: state.gamesTeamB)
    }

    private func removeCompletedMatch(forStartedAt startedAt: Date) {
        if let idx = completedMatches.firstIndex(where: { $0.playedAt == startedAt }) {
            completedMatches.remove(at: idx)
            persistCompletedMatches()
        }
    }

    private func loadPersistedCompletedMatches() {
        guard let data = userDefaults.data(forKey: StorageKey.completedMatches) else {
            return
        }
        guard let decoded = try? JSONDecoder().decode([CompletedMatchSummary].self, from: data) else {
            userDefaults.removeObject(forKey: StorageKey.completedMatches)
            return
        }
        completedMatches = decoded
    }

    private func persistCompletedMatches() {
        guard let data = try? JSONEncoder().encode(completedMatches) else {
            return
        }
        userDefaults.set(data, forKey: StorageKey.completedMatches)
    }
}
