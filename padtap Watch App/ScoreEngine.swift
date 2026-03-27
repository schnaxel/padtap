//
//  ScoreEngine.swift
//  padtap Watch App
//

import Foundation

enum ScoreEvent: Equatable {
    case none
    case pointWon
    case gameWon(TeamSide)
    case setWon(TeamSide)
    case matchWon(TeamSide)
}

struct ScoreTransition {
    let state: MatchState
    let event: ScoreEvent
}

struct ScoreEngine {
    private let tennisPoints = ["0", "15", "30", "40"]

    func initialState(from setup: MatchSetup) -> MatchState {
        var normalizedSetup = setup
        normalizedSetup.teamAName = normalizedName(setup.teamAName, fallback: "Team A")
        normalizedSetup.teamBName = normalizedName(setup.teamBName, fallback: "Team B")
        return MatchState(setup: normalizedSetup)
    }

    func pointDisplay(for state: MatchState) -> PointDisplay {
        if state.setup.ruleMode == .advantage, state.pointsTeamA == 3, state.pointsTeamB == 3 {
            if let advantageTeam = state.advantageTeam {
                return .advantage(advantageTeam)
            }
            return .deuce
        }

        return .regular(
            teamA: tennisPoints[safe: state.pointsTeamA] ?? "40",
            teamB: tennisPoints[safe: state.pointsTeamB] ?? "40"
        )
    }

    func addPoint(to team: TeamSide, in currentState: MatchState) -> ScoreTransition {
        guard !currentState.isMatchFinished, !currentState.tiebreakPending else {
            return ScoreTransition(state: currentState, event: .none)
        }

        var state = currentState
        let bothAtForty = state.pointsTeamA == 3 && state.pointsTeamB == 3

        if bothAtForty {
            switch state.setup.ruleMode {
            case .goldenPoint:
                return finishGame(winner: team, from: state)
            case .advantage:
                if let advantageTeam = state.advantageTeam {
                    if advantageTeam == team {
                        return finishGame(winner: team, from: state)
                    } else {
                        state.advantageTeam = nil
                        return pointWonTransition(from: state)
                    }
                } else {
                    state.advantageTeam = team
                    return pointWonTransition(from: state)
                }
            }
        }

        switch team {
        case .teamA:
            if state.pointsTeamA < 3 {
                state.pointsTeamA += 1
                return pointWonTransition(from: state)
            }
            return finishGame(winner: .teamA, from: state)
        case .teamB:
            if state.pointsTeamB < 3 {
                state.pointsTeamB += 1
                return pointWonTransition(from: state)
            }
            return finishGame(winner: .teamB, from: state)
        }
    }

    private func finishGame(winner: TeamSide, from currentState: MatchState) -> ScoreTransition {
        var state = currentState

        switch winner {
        case .teamA:
            state.gamesTeamA += 1
        case .teamB:
            state.gamesTeamB += 1
        }

        state.pointsTeamA = 0
        state.pointsTeamB = 0
        state.advantageTeam = nil
        let nextServingTeam = state.servingTeam.opponent
        let nextServingPlayer: ServePlayer
        switch nextServingTeam {
        case .teamA:
            nextServingPlayer = state.nextServingPlayerTeamA
            state.nextServingPlayerTeamA = nextServingPlayer.toggled
        case .teamB:
            nextServingPlayer = state.nextServingPlayerTeamB
            state.nextServingPlayerTeamB = nextServingPlayer.toggled
        }
        state.servingTeam = nextServingTeam
        state.servingSide = .right
        state.servingPlayer = nextServingPlayer

        if state.gamesTeamA == 6 && state.gamesTeamB == 6 {
            state.tiebreakPending = true
            return ScoreTransition(state: state, event: .gameWon(winner))
        }

        if hasWonSet(team: winner, in: state) {
            let finishedSet = SetScore(teamAGames: state.gamesTeamA, teamBGames: state.gamesTeamB)
            state.completedSets.append(finishedSet)

            switch winner {
            case .teamA:
                state.setsTeamA += 1
            case .teamB:
                state.setsTeamB += 1
            }

            state.gamesTeamA = 0
            state.gamesTeamB = 0
            state.tiebreakPending = false

            if hasWonMatch(team: winner, in: state) {
                state.isMatchFinished = true
                state.winner = winner
                return ScoreTransition(state: state, event: .matchWon(winner))
            }

            return ScoreTransition(state: state, event: .setWon(winner))
        }

        return ScoreTransition(state: state, event: .gameWon(winner))
    }

    private func pointWonTransition(from currentState: MatchState) -> ScoreTransition {
        var state = currentState
        state.servingSide = state.servingSide.toggled
        return ScoreTransition(state: state, event: .pointWon)
    }

    private func hasWonSet(team: TeamSide, in state: MatchState) -> Bool {
        let ownGames = games(for: team, in: state)
        let opponentGames = games(for: team.opponent, in: state)
        return ownGames >= 6 && ownGames - opponentGames >= 2
    }

    private func hasWonMatch(team: TeamSide, in state: MatchState) -> Bool {
        let ownSets = sets(for: team, in: state)
        return ownSets >= state.setup.format.setsToWin
    }

    private func games(for team: TeamSide, in state: MatchState) -> Int {
        switch team {
        case .teamA:
            return state.gamesTeamA
        case .teamB:
            return state.gamesTeamB
        }
    }

    private func sets(for team: TeamSide, in state: MatchState) -> Int {
        switch team {
        case .teamA:
            return state.setsTeamA
        case .teamB:
            return state.setsTeamB
        }
    }

    private func normalizedName(_ raw: String, fallback: String) -> String {
        let cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? fallback : cleaned
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
