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
    case bestOfFive = "Best of 5"

    var id: String { rawValue }

    var setsToWin: Int {
        switch self {
        case .oneSet:
            return 1
        case .bestOfThree:
            return 2
        case .bestOfFive:
            return 3
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

struct CompletedMatchSummary: Identifiable, Equatable, Codable {
    let id: UUID
    let playedAt: Date
    let teamAName: String
    let teamBName: String
    let matchFormat: MatchFormat
    let setsTeamA: Int
    let setsTeamB: Int
    let setScores: [SetScore]
    let unfinishedSet: SetScore?
    let winner: TeamSide?

    private enum CodingKeys: String, CodingKey {
        case id
        case playedAt
        case teamAName
        case teamBName
        case matchFormat
        case setsTeamA
        case setsTeamB
        case setScores
        case unfinishedSet
        case winner
    }

    init(
        id: UUID = UUID(),
        playedAt: Date,
        teamAName: String,
        teamBName: String,
        matchFormat: MatchFormat = .bestOfThree,
        setsTeamA: Int,
        setsTeamB: Int,
        setScores: [SetScore],
        unfinishedSet: SetScore?,
        winner: TeamSide?
    ) {
        self.id = id
        self.playedAt = playedAt
        self.teamAName = teamAName
        self.teamBName = teamBName
        self.matchFormat = matchFormat
        self.setsTeamA = setsTeamA
        self.setsTeamB = setsTeamB
        self.setScores = setScores
        self.unfinishedSet = unfinishedSet
        self.winner = winner
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        playedAt = try container.decode(Date.self, forKey: .playedAt)
        teamAName = try container.decode(String.self, forKey: .teamAName)
        teamBName = try container.decode(String.self, forKey: .teamBName)
        matchFormat = try container.decodeIfPresent(MatchFormat.self, forKey: .matchFormat) ?? .bestOfThree
        setsTeamA = try container.decode(Int.self, forKey: .setsTeamA)
        setsTeamB = try container.decode(Int.self, forKey: .setsTeamB)
        setScores = try container.decode([SetScore].self, forKey: .setScores)
        unfinishedSet = try container.decodeIfPresent(SetScore.self, forKey: .unfinishedSet)
        winner = try container.decodeIfPresent(TeamSide.self, forKey: .winner)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(playedAt, forKey: .playedAt)
        try container.encode(teamAName, forKey: .teamAName)
        try container.encode(teamBName, forKey: .teamBName)
        try container.encode(matchFormat, forKey: .matchFormat)
        try container.encode(setsTeamA, forKey: .setsTeamA)
        try container.encode(setsTeamB, forKey: .setsTeamB)
        try container.encode(setScores, forKey: .setScores)
        try container.encodeIfPresent(unfinishedSet, forKey: .unfinishedSet)
        try container.encodeIfPresent(winner, forKey: .winner)
    }
}

struct MatchSetup: Equatable, Codable {
    var teamAName: String
    var teamBName: String
    var format: MatchFormat
    var ruleMode: RuleMode

    static let `default` = MatchSetup(
        teamAName: "Team A",
        teamBName: "Team B",
        format: .bestOfThree,
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
