//
//  ResultView.swift
//  padtap Watch App
//

import SwiftUI

struct ResultView: View {
    @ObservedObject var viewModel: MatchViewModel

    var body: some View {
        if let state = viewModel.matchState, let winner = state.winner {
            ScrollView {
                VStack(spacing: 8) {
                    Text("Match vorbei")
                        .font(.headline)
                    Text("Sieger")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(viewModel.teamName(for: winner))
                        .font(.title3)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text("Sätze: \(state.setsTeamA) : \(state.setsTeamB)")
                        .font(.body)

                    if viewModel.canUndo {
                        Button("Undo letzter Punkt") {
                            viewModel.undo()
                        }
                        .buttonStyle(.bordered)
                    }

                    Button("Revanche") {
                        viewModel.startRematch()
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Neues Match", role: .destructive) {
                        viewModel.resetToSetup()
                    }
                    .buttonStyle(.bordered)
                }
                .padding(8)
            }
        } else {
            ProgressView()
        }
    }
}

#Preview {
    ResultView(viewModel: MatchViewModel())
}
