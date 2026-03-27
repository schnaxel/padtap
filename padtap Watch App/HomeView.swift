//
//  HomeView.swift
//  padtap Watch App
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: MatchViewModel

    var body: some View {
        VStack(spacing: 10) {
            Spacer(minLength: 0)

            Text("PadTap")
                .font(.headline)

            Button("Neues Match") {
                viewModel.showSetup()
            }
            .buttonStyle(.borderedProminent)

            Button("Letzte Matches anzeigen") {
                viewModel.showHistory()
            }
            .buttonStyle(.bordered)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
    }
}

#Preview {
    HomeView(viewModel: MatchViewModel())
}
