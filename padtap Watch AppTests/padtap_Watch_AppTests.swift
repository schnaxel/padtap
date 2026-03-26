//
//  padtap_Watch_AppTests.swift
//  padtap Watch AppTests
//
//  Created by Marcel Kraas on 26.03.26.
//

import Testing
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

    private func initialState(
        format: MatchFormat = .oneSet,
        ruleMode: RuleMode = .advantage
    ) -> MatchState {
        let setup = MatchSetup(
            teamAName: "Team A",
            teamBName: "Team B",
            format: format,
            ruleMode: ruleMode
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
}

private struct NoopHaptics: HapticProviding {
    func play(_ event: HapticEvent) {}
}
