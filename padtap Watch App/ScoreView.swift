//
//  ScoreView.swift
//  padtap Watch App
//

import SwiftUI

struct ScoreView: View {
    @ObservedObject var viewModel: MatchViewModel

    var body: some View {
        if let state = viewModel.matchState {
            ScrollView {
                VStack(spacing: 8) {
                    header(state: state)
                    stats(state: state)
                    points(state: state)

                    if state.tiebreakPending {
                        Text("6:6 - Tiebreak noch nicht unterstützt")
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.yellow)
                            .padding(.horizontal, 6)
                    }

                    pointButton(for: .teamA, title: "Punkt \(state.teamAName)", disabled: state.tiebreakPending)
                    pointButton(for: .teamB, title: "Punkt \(state.teamBName)", disabled: state.tiebreakPending)

                    HStack(spacing: 8) {
                        Button("Undo") {
                            viewModel.undo()
                        }
                        .buttonStyle(.bordered)
                        .disabled(!viewModel.canUndo)

                        Button("Neues Match", role: .destructive) {
                            viewModel.resetToSetup()
                        }
                        .buttonStyle(.bordered)
                    }
                    .font(.footnote)
                }
                .padding(8)
            }
        } else {
            ProgressView()
        }
    }

    @ViewBuilder
    private func header(state: MatchState) -> some View {
        Text("\(state.teamAName) vs \(state.teamBName)")
            .font(.caption2)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.8)
    }

    @ViewBuilder
    private func stats(state: MatchState) -> some View {
        HStack(spacing: 8) {
            teamStatCard(
                name: state.teamAName,
                sets: state.setsTeamA,
                games: state.gamesTeamA
            )
            teamStatCard(
                name: state.teamBName,
                sets: state.setsTeamB,
                games: state.gamesTeamB
            )
        }
    }

    @ViewBuilder
    private func teamStatCard(name: String, sets: Int, games: Int) -> some View {
        VStack(spacing: 2) {
            Text(name)
                .font(.caption2)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text("S \(sets)")
                .font(.caption)
            Text("G \(games)")
                .font(.caption)
                .bold()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private func points(state: MatchState) -> some View {
        switch viewModel.pointDisplay() {
        case let .regular(teamA, teamB):
            Text("\(teamA) : \(teamB)")
                .font(.title3)
                .fontWeight(.semibold)
        case .deuce:
            Text("Deuce")
                .font(.title3)
                .fontWeight(.semibold)
        case let .advantage(team):
            Text("Ad \(viewModel.teamName(for: team))")
                .font(.title3)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.75)
        }
    }

    @ViewBuilder
    private func pointButton(for team: TeamSide, title: String, disabled: Bool) -> some View {
        Button {
            viewModel.addPoint(to: team)
        } label: {
            Text(title)
                .frame(maxWidth: .infinity, minHeight: 40)
        }
        .buttonStyle(.borderedProminent)
        .disabled(disabled)
    }
}

#Preview {
    ScoreView(viewModel: MatchViewModel())
}
