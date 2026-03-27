//
//  ScoreView.swift
//  padtap Watch App
//

import SwiftUI

struct ScoreView: View {
    @ObservedObject var viewModel: MatchViewModel
    @State private var pageIndex: Int = 0
    @GestureState private var verticalDragTranslation: CGFloat = 0
    @State private var suppressPointTap = false

    var body: some View {
        if let state = viewModel.matchState {
            GeometryReader { proxy in
                let columns = viewModel.scoreColumns(maxColumns: nil)
                let width = proxy.size.width
                let height = proxy.size.height
                let pageTopInset = max(34, proxy.safeAreaInsets.top + 22)

                VStack(spacing: 0) {
                    board(state: state, columns: columns)
                        .frame(width: width, height: height)

                    subPage(state: state, topInset: pageTopInset)
                        .frame(width: width, height: height)
                }
                .frame(width: width, height: height * 2, alignment: .top)
                .offset(y: (-CGFloat(pageIndex) * height) + verticalDragTranslation)
                .animation(.easeOut(duration: 0.18), value: pageIndex)
                .clipped()
                .contentShape(Rectangle())
                .simultaneousGesture(verticalSwipeGesture(pageHeight: height), including: .gesture)
            }
            .ignoresSafeArea()
        } else {
            ProgressView()
        }
    }

    @ViewBuilder
    private func subPage(state: MatchState, topInset: CGFloat) -> some View {
        let isTeamABinding = Binding<Bool>(
            get: { (viewModel.matchState?.servingTeam ?? .teamA) == .teamA },
            set: { viewModel.setServingTeam($0 ? .teamA : .teamB) }
        )

        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Text("Aufschlagteam")
                    .font(.caption)
                Spacer(minLength: 4)
                Toggle("", isOn: isTeamABinding)
                    .labelsHidden()
            }
            .padding(.horizontal, 10)
            .padding(.top, topInset)

            Spacer(minLength: 0)

            Button("Spiel beenden", role: .destructive) {
                viewModel.endMatch()
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 10)
            .padding(.bottom, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
        .padding(6)
        .ignoresSafeArea()
    }

    private func verticalSwipeGesture(pageHeight: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 18, coordinateSpace: .local)
            .updating($verticalDragTranslation) { value, state, _ in
                guard abs(value.translation.height) > abs(value.translation.width) else { return }

                let dy = value.translation.height
                let movingBeyondTopEdge = pageIndex == 0 && dy > 0
                let movingBeyondBottomEdge = pageIndex == 1 && dy < 0
                state = (movingBeyondTopEdge || movingBeyondBottomEdge) ? dy * 0.2 : dy
            }
            .onEnded { value in
                guard abs(value.translation.height) > abs(value.translation.width) else { return }

                // Prevent accidental point taps when user finishes a vertical page swipe.
                if abs(value.translation.height) > 12 {
                    suppressPointTap = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        suppressPointTap = false
                    }
                }

                let threshold = pageHeight * 0.22
                if value.translation.height < -threshold {
                    pageIndex = min(pageIndex + 1, 1)
                } else if value.translation.height > threshold {
                    pageIndex = max(pageIndex - 1, 0)
                }
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
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 8)

            Rectangle()
                .fill(Color.primary.opacity(0.85))
                .frame(height: 2)

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                Text("81 bpm")
                    .font(.system(size: 15, weight: .regular, design: .rounded))

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 8)
        }
        .overlay {
            synchronizedSetMatrix(
                columns: columns,
                chipWidth: chipWidth,
                chipHeight: chipHeight,
                chipFont: chipFont,
                interactionToken: interactionToken(for: state)
            )
            .frame(height: (chipHeight * 2) + 4)
            .padding(.horizontal, 8)
        }
    }

    @ViewBuilder
    private func rightColumn(state: MatchState) -> some View {
        VStack(spacing: 0) {
            pointZone(for: .teamB, state: state)
            Rectangle()
                .fill(Color.primary.opacity(0.85))
                .frame(height: 2)
            pointZone(for: .teamA, state: state)
        }
    }

    @ViewBuilder
    private func pointZone(for team: TeamSide, state: MatchState) -> some View {
        Button {
            guard !suppressPointTap else { return }
            viewModel.addPoint(to: team)
        } label: {
            GeometryReader { geo in
                let fontSize = min(geo.size.height * 0.7, geo.size.width * 0.72)
                let chipAlignment: Alignment = team == .teamA ? .top : .bottom

                Text(viewModel.pointText(for: team))
                    .font(.system(size: fontSize, weight: .semibold, design: .rounded))
                    .minimumScaleFactor(0.55)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .overlay(alignment: chipAlignment) {
                        teamNameChip(for: team, maxWidth: geo.size.width * 0.8)
                            .padding(.vertical, 3)
                    }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(state.tiebreakPending || suppressPointTap)
    }

    @ViewBuilder
    private func teamNameChip(for team: TeamSide, maxWidth: CGFloat) -> some View {
        Text(viewModel.teamName(for: team))
            .font(.system(size: 11, weight: .medium, design: .rounded))
            .minimumScaleFactor(0.7)
            .lineLimit(1)
            .padding(.horizontal, 7)
            .frame(height: 18)
            .frame(maxWidth: maxWidth)
            .background(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(Color.gray.opacity(0.38))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .stroke(Color.primary.opacity(0.6), lineWidth: 1)
            )
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
    private func synchronizedSetMatrix(
        columns: [ScoreColumnDisplay],
        chipWidth: CGFloat,
        chipHeight: CGFloat,
        chipFont: CGFloat,
        interactionToken: Int
    ) -> some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(Array(columns.enumerated()), id: \.offset) { idx, column in
                        VStack(spacing: 4) {
                            scoreChip(
                                text: column.teamBText,
                                highlighted: column.isCurrentSet,
                                width: chipWidth,
                                height: chipHeight,
                                fontSize: chipFont
                            )
                            scoreChip(
                                text: column.teamAText,
                                highlighted: column.isCurrentSet,
                                width: chipWidth,
                                height: chipHeight,
                                fontSize: chipFont
                            )
                        }
                        .id(idx)
                    }
                }
                .padding(.horizontal, 2)
            }
            .onAppear {
                scrollToLastChip(using: proxy, count: columns.count, animated: false)
            }
            .onChange(of: interactionToken) { _ in
                scrollToLastChip(using: proxy, count: columns.count, animated: true)
            }
        }
    }

    private func interactionToken(for state: MatchState) -> Int {
        var value = state.completedSets.count
        value = (value * 16) + state.gamesTeamA
        value = (value * 16) + state.gamesTeamB
        value = (value * 8) + state.pointsTeamA
        value = (value * 8) + state.pointsTeamB
        value = (value * 3) + (state.advantageTeam == .teamA ? 1 : state.advantageTeam == .teamB ? 2 : 0)
        return value
    }

    private func scrollToLastChip(
        using proxy: ScrollViewProxy,
        count: Int,
        animated: Bool
    ) {
        guard count > 0 else { return }
        let lastID = count - 1
        if animated {
            withAnimation(.easeOut(duration: 0.18)) {
                proxy.scrollTo(lastID, anchor: .trailing)
            }
        } else {
            proxy.scrollTo(lastID, anchor: .trailing)
        }
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
        let displayedSide: ServeSide = state.servingTeam == .teamB ? state.servingSide.toggled : state.servingSide
        let x = displayedSide == .right ? xMagnitude : -xMagnitude
        let y = state.servingTeam == .teamB ? -yMagnitude : yMagnitude

        ZStack {
            Capsule()
                .fill(Color.blue.opacity(0.9))

            Text("\(state.servingPlayer.rawValue)")
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(width: indicatorWidth, height: indicatorHeight)
        .offset(x: x, y: y)
        .animation(.easeInOut(duration: 0.14), value: state.servingTeam)
        .animation(.easeInOut(duration: 0.14), value: state.servingSide)
        .animation(.easeInOut(duration: 0.14), value: state.servingPlayer)
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
