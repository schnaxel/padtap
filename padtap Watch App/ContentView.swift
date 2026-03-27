//
//  ContentView.swift
//  padtap Watch App
//
//  Created by Marcel Kraas on 26.03.26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = MatchViewModel()

    var body: some View {
        Group {
            switch viewModel.screen {
            case .setup:
                SetupView(viewModel: viewModel)
            case .score:
                ScoreView(viewModel: viewModel)
            case .result:
                ResultView(viewModel: viewModel)
            }
        }
        .persistentSystemOverlays(.hidden)
        .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
