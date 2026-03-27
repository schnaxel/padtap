//
//  ResultView.swift
//  padtap Watch App
//

import SwiftUI

struct ResultView: View {
    @ObservedObject var viewModel: MatchViewModel
    private static let matchDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        if let state = viewModel.matchState {
            ThemedScreen {
                ScrollView {
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            PadTapLogo(size: 22)

                            Text("Ergebnis")
                                .font(.headline)
                                .foregroundStyle(AppTheme.textPrimary)

                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 10)
                        .padding(.top, 4)

                        summaryCard(for: state)

                        Button("Zurück") {
                            viewModel.undo()
                        }
                        .buttonStyle(SecondaryPillButtonStyle())
                        .disabled(!viewModel.canUndo)

                        Button("Neues Spiel") {
                            viewModel.resetToSetup()
                        }
                        .buttonStyle(PrimaryPillButtonStyle())

                        Button("Ende") {
                            viewModel.showHome()
                        }
                        .buttonStyle(SecondaryPillButtonStyle())
                    }
                    .padding(8)
                }
            }
        } else {
            ProgressView()
        }
    }

    @ViewBuilder
    private func summaryCard(for state: MatchState) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(state.teamAName) vs \(state.teamBName)")
                .font(.caption2)
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1)

            Text(Self.matchDateFormatter.string(from: state.startedAt))
                .font(.caption2)
                .foregroundStyle(AppTheme.textSecondary)

            Text("Sätze \(state.setsTeamA):\(state.setsTeamB)")
                .font(.caption2)
                .foregroundStyle(AppTheme.textSecondary)

            setScoreBoard(for: state)
                .padding(.top, 4)

            if state.winner == nil {
                Text("Nicht abgeschlossen")
                    .font(.system(size: 10, weight: .regular, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.top, 5)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(AppTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        )
    }

    @ViewBuilder
    private func setScoreBoard(for state: MatchState) -> some View {
        GeometryReader { geo in
            let maxColumns = maxColumns(for: state.setup.format)
            let columns = scoreColumns(for: state, maxColumns: maxColumns)
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

    private func scoreColumns(for state: MatchState, maxColumns: Int) -> [ScoreColumnDisplay] {
        var columns = state.completedSets.map {
            ScoreColumnDisplay(
                teamAText: "\($0.teamAGames)",
                teamBText: "\($0.teamBGames)",
                isCurrentSet: false
            )
        }

        if let unfinishedSet = unfinishedSetIfNeeded(from: state) {
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

    private func unfinishedSetIfNeeded(from state: MatchState) -> SetScore? {
        if state.gamesTeamA == 0, state.gamesTeamB == 0 {
            return nil
        }
        return SetScore(teamAGames: state.gamesTeamA, teamBGames: state.gamesTeamB)
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
                    .fill(highlighted ? AppTheme.accentSoft : Color.clear.opacity(0.01))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .stroke(AppTheme.border, lineWidth: 1)
            )
    }
}

#Preview {
    ResultView(viewModel: MatchViewModel())
}
