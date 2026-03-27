//
//  MatchModels.swift
//  padtap Watch App
//

import Foundation

enum TeamSide: String, CaseIterable, Codable, Equatable {
    case teamA
    case teamB

    var opponent: TeamSide {
        self == .teamA ? .teamB : .teamA
    }
}

enum MatchFormat: String, CaseIterable, Codable, Identifiable {
    case oneSet = "1 Satz"
    case bestOfThree = "Best of 3"

    var id: String { rawValue }

    var setsToWin: Int {
        switch self {
        case .oneSet:
            return 1
        case .bestOfThree:
            return 2
        }
    }
}

enum RuleMode: String, CaseIterable, Codable, Identifiable {
    case advantage = "Deuce/Advantage"
    case goldenPoint = "Golden Point"

    var id: String { rawValue }
}

enum PointDisplay: Equatable {
    case regular(teamA: String, teamB: String)
    case deuce
    case advantage(TeamSide)
}

enum ServeSide: String, Codable, Equatable {
    case right
    case left

    var toggled: ServeSide {
        self == .right ? .left : .right
    }
}

struct SetScore: Equatable, Codable {
    let teamAGames: Int
    let teamBGames: Int
}

struct ScoreColumnDisplay: Equatable {
    let teamAText: String
    let teamBText: String
    let isCurrentSet: Bool
}

struct MatchSetup: Equatable, Codable {
    var teamAName: String
    var teamBName: String
    var format: MatchFormat
    var ruleMode: RuleMode

    static let `default` = MatchSetup(
        teamAName: "Team A",
        teamBName: "Team B",
        format: .oneSet,
        ruleMode: .advantage
    )
}

struct MatchState: Equatable, Codable {
    var setup: MatchSetup
    var startedAt: Date = Date()

    var pointsTeamA: Int = 0
    var pointsTeamB: Int = 0
    var advantageTeam: TeamSide? = nil
    var servingTeam: TeamSide = .teamA
    var servingSide: ServeSide = .right

    var completedSets: [SetScore] = []

    var gamesTeamA: Int = 0
    var gamesTeamB: Int = 0

    var setsTeamA: Int = 0
    var setsTeamB: Int = 0

    var isMatchFinished: Bool = false
    var winner: TeamSide? = nil

    // MVP marker: at 6:6 we stop play and show "tiebreak not supported yet".
    var tiebreakPending: Bool = false

    init(setup: MatchSetup) {
        self.setup = setup
    }

    var teamAName: String {
        setup.teamAName
    }

    var teamBName: String {
        setup.teamBName
    }
}
