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

enum TiebreakMode: String, CaseIterable, Codable, Identifiable {
    case standard = "Standard (6:6)"
    case off = "Aus"

    var id: String { rawValue }
}

enum PointDisplay: Equatable {
    case regular(teamA: String, teamB: String)
    case deuce
    case advantage(TeamSide)
    case tiebreak(teamA: Int, teamB: Int)
}

enum ServeSide: String, Codable, Equatable {
    case right
    case left

    var toggled: ServeSide {
        self == .right ? .left : .right
    }
}

enum ServePlayer: Int, Codable, Equatable {
    case player1 = 1
    case player2 = 2

    var toggled: ServePlayer {
        self == .player1 ? .player2 : .player1
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

struct PendingMatchSnapshot: Identifiable, Equatable, Codable {
    let id: UUID
    let state: MatchState
    let history: [MatchState]
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
    let resumeState: MatchState?

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
        case resumeState
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
        winner: TeamSide?,
        resumeState: MatchState? = nil
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
        self.resumeState = resumeState
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
        resumeState = try container.decodeIfPresent(MatchState.self, forKey: .resumeState)
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
        try container.encodeIfPresent(resumeState, forKey: .resumeState)
    }
}

struct MatchSetup: Equatable, Codable {
    var teamAName: String
    var teamBName: String
    var format: MatchFormat
    var ruleMode: RuleMode
    var tiebreakMode: TiebreakMode

    private enum CodingKeys: String, CodingKey {
        case teamAName
        case teamBName
        case format
        case ruleMode
        case tiebreakMode
    }

    init(
        teamAName: String,
        teamBName: String,
        format: MatchFormat,
        ruleMode: RuleMode,
        tiebreakMode: TiebreakMode = .standard
    ) {
        self.teamAName = teamAName
        self.teamBName = teamBName
        self.format = format
        self.ruleMode = ruleMode
        self.tiebreakMode = tiebreakMode
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        teamAName = try container.decode(String.self, forKey: .teamAName)
        teamBName = try container.decode(String.self, forKey: .teamBName)
        format = try container.decode(MatchFormat.self, forKey: .format)
        ruleMode = try container.decode(RuleMode.self, forKey: .ruleMode)
        tiebreakMode = try container.decodeIfPresent(TiebreakMode.self, forKey: .tiebreakMode) ?? .standard
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(teamAName, forKey: .teamAName)
        try container.encode(teamBName, forKey: .teamBName)
        try container.encode(format, forKey: .format)
        try container.encode(ruleMode, forKey: .ruleMode)
        try container.encode(tiebreakMode, forKey: .tiebreakMode)
    }

    static let `default` = MatchSetup(
        teamAName: "Team A",
        teamBName: "Team B",
        format: .bestOfThree,
        ruleMode: .advantage,
        tiebreakMode: .standard
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
    var servingPlayer: ServePlayer = .player1
    // Team A starts the match with player 1, so next Team-A service turn starts with player 2.
    var nextServingPlayerTeamA: ServePlayer = .player2
    var nextServingPlayerTeamB: ServePlayer = .player1
    var isTiebreak: Bool = false
    var tiebreakPointsTeamA: Int = 0
    var tiebreakPointsTeamB: Int = 0
    var tiebreakFirstServerTeam: TeamSide? = nil

    var completedSets: [SetScore] = []

    var gamesTeamA: Int = 0
    var gamesTeamB: Int = 0

    var setsTeamA: Int = 0
    var setsTeamB: Int = 0

    var isMatchFinished: Bool = false
    var winner: TeamSide? = nil

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
