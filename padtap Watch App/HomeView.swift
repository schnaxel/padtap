//
//  HomeView.swift
//  padtap Watch App
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: MatchViewModel

    var body: some View {
        ThemedScreen {
            VStack(spacing: 10) {
                Spacer(minLength: 2)

                HStack(spacing: 8) {
                    PadTapLogo(size: 30)

                    VStack(alignment: .leading, spacing: 1) {
                        Text("PadTap")
                            .font(.headline)
                            .foregroundStyle(AppTheme.textPrimary)

                        Text("Padel Score")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 10)

                SurfaceCard {
                    VStack(spacing: 8) {
                        Button {
                            viewModel.showSetup()
                        } label: {
                            Label("Neues Match", systemImage: "plus.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PrimaryPillButtonStyle())

                        Button {
                            viewModel.showHistory()
                        } label: {
                            Label("Letzte Matches", systemImage: "clock.arrow.circlepath")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(SecondaryPillButtonStyle())

                        if viewModel.hasPendingMatch {
                            Text("Offenes Match in Historie")
                                .font(.caption2)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                }
                .padding(.horizontal, 8)

                Spacer(minLength: 0)
            }
        }
    }
}

#Preview {
    HomeView(viewModel: MatchViewModel())
}
