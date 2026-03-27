//
//  ScoreView.swift
//  padtap Watch App
//

import SwiftUI

struct ScoreView: View {
    @ObservedObject var viewModel: MatchViewModel

    var body: some View {
        if let state = viewModel.matchState {
            GeometryReader { proxy in
                let columns = viewModel.scoreColumns()

                ZStack {
                    board(state: state, columns: columns)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
            }
        } else {
            ProgressView()
        }
    }

    @ViewBuilder
    private func board(state: MatchState, columns: [ScoreColumnDisplay]) -> some View {
        GeometryReader { geo in
            let leftWidth = geo.size.width * 0.53
            let chipSpacing: CGFloat = 4
            let leftPadding: CGFloat = 8
            let chipWidth = max(20, min(34, (leftWidth - (leftPadding * 2) - (chipSpacing * 2)) / 3))
            let chipHeight = max(22, chipWidth * 0.86)
            let chipFont = max(12, chipWidth * 0.46)

            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white.opacity(0.08))

                HStack(spacing: 0) {
                    leftColumn(
                        state: state,
                        columns: columns,
                        chipWidth: chipWidth,
                        chipHeight: chipHeight,
                        chipFont: chipFont
                    )
                        .frame(width: leftWidth)

                    Rectangle()
                        .fill(Color.primary.opacity(0.85))
                        .frame(width: 2)

                    rightColumn(state: state)
                }
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                Rectangle()
                    .fill(Color.primary.opacity(0.85))
                    .frame(height: 2)

                leftEdgeUndoButton(boardSize: geo.size)
                serveIndicator(state: state, boardSize: geo.size)
            }
        }
    }

    @ViewBuilder
    private func leftColumn(
        state: MatchState,
        columns: [ScoreColumnDisplay],
        chipWidth: CGFloat,
        chipHeight: CGFloat,
        chipFont: CGFloat
    ) -> some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                Spacer(minLength: 0)

                TimelineView(.periodic(from: .now, by: 1)) { timeline in
                    Text(elapsedText(from: state.startedAt, now: timeline.date))
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                }

                Spacer(minLength: 0)

                HStack(spacing: 4) {
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
                .frame(maxWidth: .infinity, alignment: .center)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 8)

            Rectangle()
                .fill(Color.primary.opacity(0.85))
                .frame(height: 2)

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                HStack(spacing: 4) {
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
                .frame(maxWidth: .infinity, alignment: .center)

                Spacer(minLength: 0)

                Text("81 bpm")
                    .font(.system(size: 15, weight: .regular, design: .rounded))

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 8)
        }
    }

    @ViewBuilder
    private func rightColumn(state: MatchState) -> some View {
        VStack(spacing: 0) {
            pointZone(for: .teamA, state: state)
            Rectangle()
                .fill(Color.primary.opacity(0.85))
                .frame(height: 2)
            pointZone(for: .teamB, state: state)
        }
    }

    @ViewBuilder
    private func pointZone(for team: TeamSide, state: MatchState) -> some View {
        Button {
            viewModel.addPoint(to: team)
        } label: {
            GeometryReader { geo in
                let fontSize = min(geo.size.height * 0.7, geo.size.width * 0.72)

                Text(viewModel.pointText(for: team))
                    .font(.system(size: fontSize, weight: .semibold, design: .rounded))
                    .minimumScaleFactor(0.55)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(state.tiebreakPending)
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

    @ViewBuilder
    private func leftEdgeUndoButton(boardSize: CGSize) -> some View {
        Button {
            viewModel.undo()
        } label: {
            ZStack {
                Color.clear

                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 15, weight: .bold))
                    .frame(width: 26, height: 26)
                    .background(.regularMaterial, in: Circle())
            }
            .frame(width: 18, height: boardSize.height)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canUndo)
        .offset(x: -boardSize.width * 0.5 + 9, y: 0)
    }

    @ViewBuilder
    private func serveIndicator(state: MatchState, boardSize: CGSize) -> some View {
        let indicatorWidth = boardSize.width * 0.26
        let indicatorHeight: CGFloat = 12
        let edgeInset: CGFloat = 6
        let xMagnitude = (boardSize.width * 0.5) - (indicatorWidth * 0.5) - edgeInset
        let yMagnitude = (boardSize.height * 0.5) - (indicatorHeight * 0.5) - edgeInset
        // Top team is shown from the opposite court perspective, so left/right is mirrored.
        let displayedSide: ServeSide = state.servingTeam == .teamA ? state.servingSide.toggled : state.servingSide
        let x = displayedSide == .right ? xMagnitude : -xMagnitude
        let y = state.servingTeam == .teamA ? -yMagnitude : yMagnitude

        Capsule()
            .fill(Color.blue.opacity(0.9))
            .frame(width: indicatorWidth, height: indicatorHeight)
            .offset(x: x, y: y)
            .animation(.easeInOut(duration: 0.14), value: state.servingTeam)
            .animation(.easeInOut(duration: 0.14), value: state.servingSide)
    }

    private func elapsedText(from start: Date, now: Date) -> String {
        let total = max(0, Int(now.timeIntervalSince(start)))
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    ScoreView(viewModel: MatchViewModel())
}
