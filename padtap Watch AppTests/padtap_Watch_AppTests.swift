//
//  padtap_Watch_AppTests.swift
//  padtap Watch AppTests
//
//  Created by Marcel Kraas on 26.03.26.
//

import Testing
import Foundation
@testable import padtap_Watch_App

struct padtap_Watch_AppTests {
    private let engine = ScoreEngine()

    @Test("Normales Hochzählen der Punkte")
    func normalPointProgression() {
        var state = initialState(ruleMode: .advantage)

        state = engine.addPoint(to: .teamA, in: state).state
        state = engine.addPoint(to: .teamA, in: state).state
        state = engine.addPoint(to: .teamA, in: state).state

        #expect(state.pointsTeamA == 3)
        #expect(state.pointsTeamB == 0)
        #expect(engine.pointDisplay(for: state) == .regular(teamA: "40", teamB: "0"))
    }

    @Test("Aufschlag startet bei Team A auf rechts")
    func serveStartsRight() {
        let state = initialState(ruleMode: .advantage)
        #expect(state.servingTeam == .teamA)
        #expect(state.servingSide == .right)
        #expect(state.servingPlayer == .player1)
    }

    @Test("Aufschlagseite wechselt nach jedem Punkt")
    func serveSideAlternatesEveryPoint() {
        var state = initialState(ruleMode: .advantage)

        state = engine.addPoint(to: .teamA, in: state).state
        #expect(state.servingTeam == .teamA)
        #expect(state.servingSide == .left)
        #expect(state.servingPlayer == .player1)

        state = engine.addPoint(to: .teamB, in: state).state
        #expect(state.servingTeam == .teamA)
        #expect(state.servingSide == .right)
        #expect(state.servingPlayer == .player1)
    }

    @Test("Deuce wird korrekt angezeigt")
    func deuceDisplay() {
        var state = initialState(ruleMode: .advantage)

        state = reachDeuce(from: state)

        #expect(engine.pointDisplay(for: state) == .deuce)
        #expect(state.advantageTeam == nil)
    }

    @Test("Advantage und Rückkehr zu Deuce")
    func advantageFlow() {
        var state = initialState(ruleMode: .advantage)
        state = reachDeuce(from: state)

        state = engine.addPoint(to: .teamA, in: state).state
        #expect(engine.pointDisplay(for: state) == .advantage(.teamA))

        state = engine.addPoint(to: .teamB, in: state).state
        #expect(engine.pointDisplay(for: state) == .deuce)
        #expect(state.advantageTeam == nil)
    }

    @Test("Golden Point bei 40:40 gewinnt direkt das Game")
    func goldenPointWinsGameImmediately() {
        var state = initialState(ruleMode: .goldenPoint)
        state = reachDeuce(from: state)

        state = engine.addPoint(to: .teamB, in: state).state

        #expect(state.gamesTeamA == 0)
        #expect(state.gamesTeamB == 1)
        #expect(state.pointsTeamA == 0)
        #expect(state.pointsTeamB == 0)
        #expect(state.advantageTeam == nil)
        #expect(state.servingTeam == .teamB)
        #expect(state.servingSide == .right)
        #expect(state.servingPlayer == .player1)
    }

    @Test("Game-Gewinn setzt Punkte zurück")
    func gameWinResetsPoints() {
        var state = initialState(ruleMode: .advantage)

        state = engine.addPoint(to: .teamA, in: state).state
        state = engine.addPoint(to: .teamA, in: state).state
        state = engine.addPoint(to: .teamA, in: state).state
        state = engine.addPoint(to: .teamA, in: state).state

        #expect(state.gamesTeamA == 1)
        #expect(state.gamesTeamB == 0)
        #expect(state.pointsTeamA == 0)
        #expect(state.pointsTeamB == 0)
        #expect(state.servingTeam == .teamB)
        #expect(state.servingSide == .right)
        #expect(state.servingPlayer == .player1)
    }

    @Test("Aufschlagspieler rotiert je Team nach jedem Service-Game")
    func servingPlayerRotatesPerTeam() {
        var state = initialState(ruleMode: .advantage)

        state = winSimpleGame(for: .teamA, from: state)
        #expect(state.servingTeam == .teamB)
        #expect(state.servingPlayer == .player1)

        state = winSimpleGame(for: .teamB, from: state)
        #expect(state.servingTeam == .teamA)
        #expect(state.servingPlayer == .player2)

        state = winSimpleGame(for: .teamA, from: state)
        #expect(state.servingTeam == .teamB)
        #expect(state.servingPlayer == .player2)
    }

    @Test("Bei 6:6 startet ein Tiebreak")
    func tiebreakStartsAtSixAll() {
        var state = initialState(format: .bestOfThree, ruleMode: .advantage)
        state = reachSixAll(from: state)

        #expect(state.isTiebreak == true)
        #expect(state.tiebreakPointsTeamA == 0)
        #expect(state.tiebreakPointsTeamB == 0)
        #expect(engine.pointDisplay(for: state) == .tiebreak(teamA: 0, teamB: 0))

        state = engine.addPoint(to: .teamA, in: state).state
        #expect(state.tiebreakPointsTeamA == 1)
        #expect(state.isTiebreak == true)
    }

    @Test("Tiebreak braucht zwei Punkte Vorsprung")
    func tiebreakNeedsTwoPointLead() {
        var state = initialState(format: .bestOfThree, ruleMode: .advantage)
        state = reachSixAll(from: state)

        for _ in 0..<6 {
            state = engine.addPoint(to: .teamA, in: state).state
            state = engine.addPoint(to: .teamB, in: state).state
        }

        state = engine.addPoint(to: .teamA, in: state).state
        #expect(state.isTiebreak == true)
        #expect(state.setsTeamA == 0)
        #expect(state.setsTeamB == 0)

        state = engine.addPoint(to: .teamA, in: state).state
        #expect(state.isTiebreak == false)
        #expect(state.setsTeamA == 1)
        #expect(state.setsTeamB == 0)
        #expect(state.completedSets.last == SetScore(teamAGames: 7, teamBGames: 6))
    }

    @Test("Tiebreak-Aufschlag wechselt 1 Punkt, dann je 2 Punkte")
    func tiebreakServePattern() {
        var state = initialState(format: .bestOfThree, ruleMode: .advantage)
        state = reachSixAll(from: state)

        let firstServer = state.servingTeam
        let secondServer = firstServer.opponent

        state = engine.addPoint(to: .teamA, in: state).state
        #expect(state.servingTeam == secondServer)

        state = engine.addPoint(to: .teamB, in: state).state
        #expect(state.servingTeam == secondServer)

        state = engine.addPoint(to: .teamA, in: state).state
        #expect(state.servingTeam == firstServer)
    }

    @Test("Ohne Tiebreak geht der Satz bei 6:6 weiter")
    func noTiebreakModePlaysOn() {
        var state = initialState(format: .bestOfThree, ruleMode: .advantage, tiebreakMode: .off)
        state = reachSixAll(from: state)

        #expect(state.isTiebreak == false)
        #expect(state.gamesTeamA == 6)
        #expect(state.gamesTeamB == 6)

        state = winSimpleGame(for: .teamA, from: state)
        #expect(state.gamesTeamA == 7)
        #expect(state.gamesTeamB == 6)
        #expect(state.setsTeamA == 0)

        state = winSimpleGame(for: .teamA, from: state)
        #expect(state.setsTeamA == 1)
        #expect(state.gamesTeamA == 0)
        #expect(state.gamesTeamB == 0)
        #expect(state.completedSets.last == SetScore(teamAGames: 8, teamBGames: 6))
    }

    @Test("Satz-Gewinn bei 6 Games mit 2 Vorsprung")
    func setWin() {
        var state = initialState(format: .bestOfThree, ruleMode: .advantage)

        for _ in 0..<6 {
            state = winSimpleGame(for: .teamA, from: state)
        }

        #expect(state.setsTeamA == 1)
        #expect(state.setsTeamB == 0)
        #expect(state.gamesTeamA == 0)
        #expect(state.gamesTeamB == 0)
        #expect(state.isMatchFinished == false)
    }

    @Test("Match-Gewinn entsprechend Matchformat")
    func matchWin() {
        var state = initialState(format: .oneSet, ruleMode: .advantage)

        for _ in 0..<6 {
            state = winSimpleGame(for: .teamA, from: state)
        }

        #expect(state.isMatchFinished == true)
        #expect(state.winner == .teamA)
    }

    @Test("Best of 5 benötigt drei gewonnene Sätze")
    func matchWinBestOfFive() {
        var state = initialState(format: .bestOfFive, ruleMode: .advantage)

        for _ in 0..<6 { state = winSimpleGame(for: .teamA, from: state) }
        #expect(state.setsTeamA == 1)
        #expect(state.isMatchFinished == false)

        for _ in 0..<6 { state = winSimpleGame(for: .teamA, from: state) }
        #expect(state.setsTeamA == 2)
        #expect(state.isMatchFinished == false)

        for _ in 0..<6 { state = winSimpleGame(for: .teamA, from: state) }
        #expect(state.setsTeamA == 3)
        #expect(state.isMatchFinished == true)
        #expect(state.winner == .teamA)
    }

    @Test("Undo stellt den letzten Zustand wieder her")
    @MainActor
    func undoRestoresPreviousState() {
        let viewModel = MatchViewModel(haptics: NoopHaptics())
        viewModel.setupDraft = MatchSetup.default
        viewModel.startMatch()

        viewModel.addPoint(to: .teamA)
        #expect(viewModel.matchState?.pointsTeamA == 1)

        viewModel.undo()
        #expect(viewModel.matchState?.pointsTeamA == 0)
        #expect(viewModel.matchState?.pointsTeamB == 0)
    }

    @Test("Undo kann auch Matchende rückgängig machen")
    @MainActor
    func undoAfterMatchEnd() {
        let viewModel = MatchViewModel(haptics: NoopHaptics())
        viewModel.setupDraft = MatchSetup(teamAName: "Team A", teamBName: "Team B", format: .oneSet, ruleMode: .advantage)
        viewModel.startMatch()

        for _ in 0..<24 {
            viewModel.addPoint(to: .teamA)
        }

        #expect(viewModel.matchState?.isMatchFinished == true)
        #expect(viewModel.matchState?.winner == .teamA)

        viewModel.undo()

        #expect(viewModel.matchState?.isMatchFinished == false)
        #expect(viewModel.matchState?.winner == nil)
    }

    @Test("Laufendes Match wird persistiert und wieder geladen")
    @MainActor
    func pendingMatchPersistence() {
        let suite = "padtap.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)

        var viewModel = MatchViewModel(engine: ScoreEngine(), haptics: NoopHaptics(), userDefaults: defaults)
        viewModel.setupDraft = MatchSetup.default
        viewModel.startMatch()
        viewModel.addPoint(to: TeamSide.teamA)

        #expect(viewModel.pendingMatchSummary() != nil)

        viewModel = MatchViewModel(engine: ScoreEngine(), haptics: NoopHaptics(), userDefaults: defaults)
        #expect(viewModel.pendingMatchSummary() != nil)
        #expect(viewModel.pendingMatch?.state.pointsTeamA == 1)
        #expect(viewModel.pendingMatch?.state.isMatchFinished == false)
    }

    @Test("Manuell beendetes Match kann aus Historie fortgesetzt werden")
    @MainActor
    func resumeHistoricalOpenMatch() {
        let suite = "padtap.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)

        let viewModel = MatchViewModel(engine: ScoreEngine(), haptics: NoopHaptics(), userDefaults: defaults)
        viewModel.setupDraft = MatchSetup.default
        viewModel.startMatch()
        viewModel.addPoint(to: TeamSide.teamA)
        viewModel.endMatch()

        guard let resumable = viewModel.completedMatches.first else {
            Issue.record("Expected a resumable historical match")
            return
        }
        #expect(viewModel.canResume(match: resumable))

        viewModel.resumeCompletedMatch(resumable)

        #expect(viewModel.matchState?.isMatchFinished == false)
        #expect(viewModel.matchState?.pointsTeamA == 1)
        #expect(viewModel.screen == MatchViewModel.Screen.score)
    }

    private func initialState(
        format: MatchFormat = .oneSet,
        ruleMode: RuleMode = .advantage,
        tiebreakMode: TiebreakMode = .standard
    ) -> MatchState {
        let setup = MatchSetup(
            teamAName: "Team A",
            teamBName: "Team B",
            format: format,
            ruleMode: ruleMode,
            tiebreakMode: tiebreakMode
        )
        return engine.initialState(from: setup)
    }

    private func reachDeuce(from state: MatchState) -> MatchState {
        var current = state
        for _ in 0..<3 {
            current = engine.addPoint(to: .teamA, in: current).state
            current = engine.addPoint(to: .teamB, in: current).state
        }
        return current
    }

    private func winSimpleGame(for team: TeamSide, from state: MatchState) -> MatchState {
        var current = state
        for _ in 0..<4 {
            current = engine.addPoint(to: team, in: current).state
        }
        return current
    }

    private func reachSixAll(from state: MatchState) -> MatchState {
        var current = state
        for _ in 0..<6 {
            current = winSimpleGame(for: .teamA, from: current)
            current = winSimpleGame(for: .teamB, from: current)
        }
        return current
    }
}

private struct NoopHaptics: HapticProviding {
    func play(_ event: HapticEvent) {}
}
