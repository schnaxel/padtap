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
        static let pendingMatchSnapshot = "pendingMatchSnapshot.v1"
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
    @Published private(set) var pendingMatch: PendingMatchSnapshot?

    private let engine: ScoreEngine
    private let haptics: HapticProviding
    private let userDefaults: UserDefaults

    init(engine: ScoreEngine, haptics: HapticProviding, userDefaults: UserDefaults = .standard) {
        self.engine = engine
        self.haptics = haptics
        self.userDefaults = userDefaults
        loadPersistedCompletedMatches()
        loadPendingMatchSnapshot()
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

    var hasPendingMatch: Bool {
        pendingMatch != nil
    }

    func showHome() {
        persistOrClearCurrentSnapshot()
        screen = .home
    }

    func showSetup() {
        persistOrClearCurrentSnapshot()
        matchState = nil
        history.removeAll()
        screen = .setup
    }

    func showHistory() {
        screen = .history
    }

    func startMatch() {
        history.removeAll()
        let newState = engine.initialState(from: setupDraft)
        matchState = newState
        savePendingMatchSnapshot(state: newState, history: history)
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
            clearPendingMatchSnapshot()
            appendCompletedMatch(from: transition.state)
            screen = .result
        } else {
            savePendingMatchSnapshot(state: transition.state, history: history)
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
        if previousState.isMatchFinished {
            clearPendingMatchSnapshot()
        } else {
            savePendingMatchSnapshot(state: previousState, history: history)
        }
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
        case let .tiebreak(teamA, teamB):
            return team == .teamA ? "\(teamA)" : "\(teamB)"
        }
    }

    func pointCenterLabel() -> String? {
        switch pointDisplay() {
        case .deuce:
            return "Deuce"
        case let .advantage(team):
            return "Ad \(teamName(for: team))"
        case .tiebreak:
            return "Tiebreak"
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

        // Reassign the current service turn to another team without breaking
        // each team's player rotation order.
        let previousServingTeam = state.servingTeam
        let previousServingPlayer = state.servingPlayer

        switch previousServingTeam {
        case .teamA:
            state.nextServingPlayerTeamA = previousServingPlayer
        case .teamB:
            state.nextServingPlayerTeamB = previousServingPlayer
        }

        state.servingTeam = team
        switch team {
        case .teamA:
            let newServingPlayer = state.nextServingPlayerTeamA
            state.servingPlayer = newServingPlayer
            state.nextServingPlayerTeamA = newServingPlayer.toggled
        case .teamB:
            let newServingPlayer = state.nextServingPlayerTeamB
            state.servingPlayer = newServingPlayer
            state.nextServingPlayerTeamB = newServingPlayer.toggled
        }

        if state.isTiebreak, state.tiebreakPointsTeamA == 0, state.tiebreakPointsTeamB == 0 {
            state.tiebreakFirstServerTeam = team
        }

        state.servingSide = servingSideForCurrentScore(in: state)

        matchState = state
        savePendingMatchSnapshot(state: state, history: history)
    }

    func advanceServingOrder() {
        guard var state = matchState, !state.isMatchFinished else { return }
        history.append(state)

        let nextTeam = state.servingTeam.opponent
        state.servingTeam = nextTeam

        switch nextTeam {
        case .teamA:
            let nextPlayer = state.nextServingPlayerTeamA
            state.servingPlayer = nextPlayer
            state.nextServingPlayerTeamA = nextPlayer.toggled
        case .teamB:
            let nextPlayer = state.nextServingPlayerTeamB
            state.servingPlayer = nextPlayer
            state.nextServingPlayerTeamB = nextPlayer.toggled
        }

        if state.isTiebreak, state.tiebreakPointsTeamA == 0, state.tiebreakPointsTeamB == 0 {
            state.tiebreakFirstServerTeam = nextTeam
        }

        state.servingSide = servingSideForCurrentScore(in: state)

        matchState = state
        savePendingMatchSnapshot(state: state, history: history)
    }

    func endMatch() {
        guard var state = matchState, !state.isMatchFinished else { return }
        let resumableState = state

        history.append(state)
        state.isMatchFinished = true
        state.winner = manualWinner(from: state)
        matchState = state
        appendCompletedMatch(from: state, resumeState: resumableState)
        clearPendingMatchSnapshot()
        screen = .result
        haptics.play(.match)
    }

    func pendingMatchSummary() -> CompletedMatchSummary? {
        guard let snapshot = pendingMatch else { return nil }
        let state = snapshot.state
        return CompletedMatchSummary(
            id: snapshot.id,
            playedAt: state.startedAt,
            teamAName: state.teamAName,
            teamBName: state.teamBName,
            matchFormat: state.setup.format,
            setsTeamA: state.setsTeamA,
            setsTeamB: state.setsTeamB,
            setScores: state.completedSets,
            unfinishedSet: unfinishedSetIfNeeded(from: state),
            winner: nil,
            resumeState: state
        )
    }

    func resumePendingMatch() {
        guard let snapshot = pendingMatch else { return }
        setupDraft = snapshot.state.setup
        history = snapshot.history
        matchState = snapshot.state
        savePendingMatchSnapshot(state: snapshot.state, history: snapshot.history)
        screen = .score
    }

    func canResume(match: CompletedMatchSummary) -> Bool {
        match.resumeState != nil
    }

    func resumeCompletedMatch(_ match: CompletedMatchSummary) {
        guard let resumeState = match.resumeState else { return }
        setupDraft = resumeState.setup
        history.removeAll()
        matchState = resumeState
        completedMatches.removeAll(where: { $0.id == match.id })
        persistCompletedMatches()
        savePendingMatchSnapshot(state: resumeState, history: history)
        screen = .score
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
        if state.isTiebreak, state.tiebreakPointsTeamA != state.tiebreakPointsTeamB {
            return state.tiebreakPointsTeamA > state.tiebreakPointsTeamB ? .teamA : .teamB
        }
        if state.pointsTeamA != state.pointsTeamB {
            return state.pointsTeamA > state.pointsTeamB ? .teamA : .teamB
        }
        if let advantageTeam = state.advantageTeam {
            return advantageTeam
        }
        return nil
    }

    private func servingSideForCurrentScore(in state: MatchState) -> ServeSide {
        let isOddPointCount: Bool

        if state.isTiebreak {
            let pointsPlayed = state.tiebreakPointsTeamA + state.tiebreakPointsTeamB
            isOddPointCount = !pointsPlayed.isMultiple(of: 2)
        } else if state.setup.ruleMode == .advantage, state.pointsTeamA == 3, state.pointsTeamB == 3 {
            // In Deuce/Adv mode we only need parity:
            // Deuce => even, Advantage => odd.
            isOddPointCount = state.advantageTeam != nil
        } else {
            let pointsPlayed = state.pointsTeamA + state.pointsTeamB
            isOddPointCount = !pointsPlayed.isMultiple(of: 2)
        }

        return isOddPointCount ? .left : .right
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

    private func appendCompletedMatch(from state: MatchState, resumeState: MatchState? = nil) {
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
                && $0.resumeState == resumeState
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
            winner: state.winner,
            resumeState: resumeState
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

    private func loadPendingMatchSnapshot() {
        guard let data = userDefaults.data(forKey: StorageKey.pendingMatchSnapshot) else {
            return
        }
        guard let decoded = try? JSONDecoder().decode(PendingMatchSnapshot.self, from: data) else {
            userDefaults.removeObject(forKey: StorageKey.pendingMatchSnapshot)
            return
        }

        if decoded.state.isMatchFinished {
            userDefaults.removeObject(forKey: StorageKey.pendingMatchSnapshot)
            return
        }
        pendingMatch = decoded
    }

    private func persistCompletedMatches() {
        guard let data = try? JSONEncoder().encode(completedMatches) else {
            return
        }
        userDefaults.set(data, forKey: StorageKey.completedMatches)
    }

    private func persistOrClearCurrentSnapshot() {
        guard let state = matchState else {
            clearPendingMatchSnapshot()
            return
        }
        if state.isMatchFinished {
            clearPendingMatchSnapshot()
            return
        }
        savePendingMatchSnapshot(state: state, history: history)
    }

    private func savePendingMatchSnapshot(state: MatchState, history: [MatchState]) {
        let snapshotID: UUID
        if let currentSnapshot = pendingMatch, currentSnapshot.state.startedAt == state.startedAt {
            snapshotID = currentSnapshot.id
        } else {
            snapshotID = UUID()
        }

        let snapshot = PendingMatchSnapshot(
            id: snapshotID,
            state: state,
            history: history
        )
        pendingMatch = snapshot

        guard let data = try? JSONEncoder().encode(snapshot) else {
            return
        }
        userDefaults.set(data, forKey: StorageKey.pendingMatchSnapshot)
    }

    private func clearPendingMatchSnapshot() {
        pendingMatch = nil
        userDefaults.removeObject(forKey: StorageKey.pendingMatchSnapshot)
    }
}
