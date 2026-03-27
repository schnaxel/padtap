//
//  LastMatchesView.swift
//  padtap Watch App
//

import SwiftUI

struct LastMatchesView: View {
    @ObservedObject var viewModel: MatchViewModel
    @State private var pendingDeleteMatch: CompletedMatchSummary?
    private static let matchDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Button("Zurück") {
                    viewModel.showHome()
                }
                .buttonStyle(.bordered)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8)

            if viewModel.completedMatches.isEmpty {
                Spacer(minLength: 0)

                Text("Noch keine Matches")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)
            } else {
                List {
                    ForEach(viewModel.completedMatches) { match in
                        matchRow(match)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 3, leading: 8, bottom: 3, trailing: 8))
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    pendingDeleteMatch = match
                                } label: {
                                    Image(systemName: "xmark")
                                }
                            }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .padding(.top, 4)
        .alert(
            "Match löschen?",
            isPresented: Binding(
                get: { pendingDeleteMatch != nil },
                set: { isPresented in
                    if !isPresented { pendingDeleteMatch = nil }
                }
            ),
            presenting: pendingDeleteMatch
        ) { match in
            Button("Löschen", role: .destructive) {
                viewModel.deleteCompletedMatch(id: match.id)
                pendingDeleteMatch = nil
            }
            Button("Abbrechen", role: .cancel) {
                pendingDeleteMatch = nil
            }
        } message: { match in
            Text("\(match.teamAName) vs \(match.teamBName)")
        }
    }

    @ViewBuilder
    private func matchRow(_ match: CompletedMatchSummary) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(match.teamAName) vs \(match.teamBName)")
                .font(.caption2)
                .lineLimit(1)

            Text(Self.matchDateFormatter.string(from: match.playedAt))
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text("Sätze \(match.setsTeamA):\(match.setsTeamB)")
                .font(.caption2)
                .foregroundStyle(.secondary)

            setScoreBoard(for: match)
                .padding(.top, 4)

            if match.winner == nil {
                Text("Manuell beendet")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
    }

    @ViewBuilder
    private func setScoreBoard(for match: CompletedMatchSummary) -> some View {
        GeometryReader { geo in
            let maxColumns = maxColumns(for: match.matchFormat)
            let columns = scoreColumns(for: match, maxColumns: maxColumns)
            let chipSpacing: CGFloat = 4
            let available = max(0, geo.size.width - (chipSpacing * CGFloat(max(0, columns.count - 1))))
            let chipWidth = max(20, min(34, available / CGFloat(max(1, columns.count))))
            let chipHeight = max(22, chipWidth * 0.86)
            let chipFont = max(12, chipWidth * 0.46)

            VStack(spacing: 4) {
                HStack(spacing: chipSpacing) {
                    ForEach(Array(columns.enumerated()), id: \.offset) { _, column in
                        scoreChip(
                            text: column.teamAText,
                            highlighted: column.isCurrentSet,
                            width: chipWidth,
                            height: chipHeight,
                            fontSize: chipFont
                        )
                    }
                }

                HStack(spacing: chipSpacing) {
                    ForEach(Array(columns.enumerated()), id: \.offset) { _, column in
                        scoreChip(
                            text: column.teamBText,
                            highlighted: column.isCurrentSet,
                            width: chipWidth,
                            height: chipHeight,
                            fontSize: chipFont
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .frame(height: 52)
    }

    private func maxColumns(for format: MatchFormat) -> Int {
        switch format {
        case .oneSet:
            return 1
        case .bestOfThree:
            return 3
        case .bestOfFive:
            return 5
        }
    }

    private func scoreColumns(for match: CompletedMatchSummary, maxColumns: Int) -> [ScoreColumnDisplay] {
        var columns = match.setScores.map {
            ScoreColumnDisplay(
                teamAText: "\($0.teamAGames)",
                teamBText: "\($0.teamBGames)",
                isCurrentSet: false
            )
        }

        if let unfinishedSet = match.unfinishedSet {
            columns.append(
                ScoreColumnDisplay(
                    teamAText: "\(unfinishedSet.teamAGames)",
                    teamBText: "\(unfinishedSet.teamBGames)",
                    isCurrentSet: true
                )
            )
        } else if columns.isEmpty {
            columns.append(
                ScoreColumnDisplay(
                    teamAText: "0",
                    teamBText: "0",
                    isCurrentSet: true
                )
            )
        }

        if columns.count < maxColumns {
            let placeholders = Array(
                repeating: ScoreColumnDisplay(teamAText: "-", teamBText: "-", isCurrentSet: false),
                count: maxColumns - columns.count
            )
            columns += placeholders
        } else if columns.count > maxColumns {
            columns = Array(columns.suffix(maxColumns))
        }

        return columns
    }

    @ViewBuilder
    private func scoreChip(
        text: String,
        highlighted: Bool,
        width: CGFloat,
        height: CGFloat,
        fontSize: CGFloat
    ) -> some View {
        Text(text)
            .font(.system(size: fontSize, weight: .medium, design: .rounded))
            .frame(width: width, height: height)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(highlighted ? Color.gray.opacity(0.5) : Color.clear.opacity(0.01))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .stroke(Color.primary.opacity(0.6), lineWidth: 1)
            )
    }
}

#Preview {
    LastMatchesView(viewModel: MatchViewModel())
}
