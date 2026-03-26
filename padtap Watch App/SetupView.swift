//
//  SetupView.swift
//  padtap Watch App
//

import SwiftUI

struct SetupView: View {
    @ObservedObject var viewModel: MatchViewModel

    var body: some View {
        Form {
            Section("Teams") {
                TextField("Team A", text: $viewModel.setupDraft.teamAName)
                TextField("Team B", text: $viewModel.setupDraft.teamBName)
            }

            Section("Matchformat") {
                Picker("Sätze", selection: $viewModel.setupDraft.format) {
                    ForEach(MatchFormat.allCases) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
            }

            Section("Regeln") {
                Picker("Modus", selection: $viewModel.setupDraft.ruleMode) {
                    ForEach(RuleMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
            }

            Section {
                Button("Match starten") {
                    viewModel.startMatch()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .navigationTitle("Padel Score")
    }
}

#Preview {
    SetupView(viewModel: MatchViewModel())
}
