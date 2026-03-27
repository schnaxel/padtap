//
//  LastMatchesView.swift
//  padtap Watch App
//

import SwiftUI

struct LastMatchesView: View {
    private struct ResumeTarget: Identifiable {
        enum Kind {
            case pending
            case historical
        }

        let kind: Kind
        let match: CompletedMatchSummary

        var id: UUID { match.id }
    }

    @ObservedObject var viewModel: MatchViewModel
    @State private var pendingDeleteMatch: CompletedMatchSummary?
    @State private var pendingResumeTarget: ResumeTarget?
    private static let matchDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        let pendingSummary = viewModel.pendingMatchSummary()

        ThemedScreen {
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    PadTapLogo(size: 22)

                    Text("Letzte Matches")
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 10)
                .padding(.top, 4)

                Button("Zurück") {
                    viewModel.showHome()
                }
                .buttonStyle(SecondaryPillButtonStyle())
                .padding(.horizontal, 8)

                if viewModel.completedMatches.isEmpty, pendingSummary == nil {
                    Spacer(minLength: 0)

                    Text("Noch keine Matches")
                        .font(.footnote)
                        .foregroundStyle(AppTheme.textSecondary)

                    Spacer(minLength: 0)
                } else {
                    List {
                        if let pendingSummary {
                            matchRow(pendingSummary)
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 3, leading: 8, bottom: 3, trailing: 8))
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    pendingResumeTarget = ResumeTarget(kind: .pending, match: pendingSummary)
                                }
                        }

                        ForEach(viewModel.completedMatches) { match in
                            matchRow(match)
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 3, leading: 8, bottom: 3, trailing: 8))
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    guard viewModel.canResume(match: match) else { return }
                                    pendingResumeTarget = ResumeTarget(kind: .historical, match: match)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        pendingDeleteMatch = match
                                    } label: {
                                        Label("Löschen", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
        }
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
        .alert(
            "Offenes Spiel weiter spielen?",
            isPresented: Binding(
                get: { pendingResumeTarget != nil },
                set: { isPresented in
                    if !isPresented { pendingResumeTarget = nil }
                }
            ),
            presenting: pendingResumeTarget
        ) { target in
            Button("Ja") {
                switch target.kind {
                case .pending:
                    viewModel.resumePendingMatch()
                case .historical:
                    viewModel.resumeCompletedMatch(target.match)
                }
                pendingResumeTarget = nil
            }
            Button("Nein", role: .cancel) {
                pendingResumeTarget = nil
            }
        } message: { target in
            Text("\(target.match.teamAName) vs \(target.match.teamBName)")
        }
    }

    @ViewBuilder
    private func matchRow(_ match: CompletedMatchSummary) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(match.teamAName) vs \(match.teamBName)")
                .font(.caption2)
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1)

            Text(Self.matchDateFormatter.string(from: match.playedAt))
                .font(.caption2)
                .foregroundStyle(AppTheme.textSecondary)

            Text("Sätze \(match.setsTeamA):\(match.setsTeamB)")
                .font(.caption2)
                .foregroundStyle(AppTheme.textSecondary)

            setScoreBoard(for: match)
                .padding(.top, 4)

            if match.winner == nil || viewModel.canResume(match: match) {
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
    private func setScoreBoard(for match: CompletedMatchSummary) -> some View {
        GeometryReader { geo in
            let maxColumns = maxColumns(for: match.matchFormat)
            let columns = scoreColumns(for: match, maxColumns: maxColumns)
            let chipSpacing: CGFloat = 4
            let availableWidth = max(0, geo.size.width - (chipSpacing * CGFloat(max(0, columns.count - 1))))
            let maxHeight = geo.size.height
            let maxChipHeightByLayout = max(18, (maxHeight - chipSpacing) / 2)
            let maxChipWidthByLayout = maxChipHeightByLayout / 0.86
            let chipWidth = max(20, min(34, min(maxChipWidthByLayout, availableWidth / CGFloat(max(1, columns.count)))))
            let chipHeight = max(18, chipWidth * 0.86)
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
                    .fill(highlighted ? AppTheme.accentSoft : Color.clear.opacity(0.01))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .stroke(AppTheme.border, lineWidth: 1)
            )
    }
}

#Preview {
    LastMatchesView(viewModel: MatchViewModel())
}
