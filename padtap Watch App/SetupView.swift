//
//  SetupView.swift
//  padtap Watch App
//

import SwiftUI

struct SetupView: View {
    @ObservedObject var viewModel: MatchViewModel

    var body: some View {
        ThemedScreen {
            ScrollView {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        PadTapLogo(size: 24)
                        Text("Match Setup")
                            .font(.headline)
                            .foregroundStyle(AppTheme.textPrimary)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 10)
                    .padding(.top, 4)

                    SurfaceCard {
                        VStack(spacing: 8) {
                            sectionTitle("Teams")

                            teamField(title: "Team B (oben)", text: $viewModel.setupDraft.teamBName)
                            teamField(title: "Team A (unten)", text: $viewModel.setupDraft.teamAName)
                        }
                    }

                    SurfaceCard {
                        VStack(spacing: 8) {
                            sectionTitle("Format")

                            Button {
                                cycleMatchFormat()
                            } label: {
                                selectionRow(title: "Sätze", value: viewModel.setupDraft.format.rawValue)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    SurfaceCard {
                        VStack(spacing: 8) {
                            sectionTitle("Regeln")

                            Button {
                                cycleRuleMode()
                            } label: {
                                selectionRow(title: "Mode", value: viewModel.setupDraft.ruleMode.rawValue)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    SurfaceCard {
                        VStack(spacing: 8) {
                            sectionTitle("Tiebreak")

                            Button {
                                cycleTiebreakMode()
                            } label: {
                                selectionRow(title: "Mode", value: viewModel.setupDraft.tiebreakMode.rawValue)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Button("Match starten") {
                        viewModel.startMatch()
                    }
                    .buttonStyle(PrimaryPillButtonStyle())
                    .padding(.top, 2)

                    Button("Zurück") {
                        viewModel.showHome()
                    }
                    .buttonStyle(SecondaryPillButtonStyle())
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
        }
    }

    @ViewBuilder
    private func sectionTitle(_ text: String) -> some View {
        HStack {
            Text(text)
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private func teamField(title: String, text: Binding<String>) -> some View {
        TextField(title, text: text)
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundStyle(AppTheme.textPrimary)
            .padding(.horizontal, 10)
            .frame(height: 34)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(AppTheme.surfaceMuted)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(AppTheme.border, lineWidth: 1)
            )
    }

    @ViewBuilder
    private func selectionRow(
        title: String,
        value: String
    ) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(AppTheme.textSecondary)

            Spacer(minLength: 0)

            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1)

            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(.horizontal, 10)
        .frame(height: 34)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(AppTheme.surfaceMuted)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        )
    }

    private func cycleMatchFormat() {
        let all = MatchFormat.allCases
        guard let currentIndex = all.firstIndex(of: viewModel.setupDraft.format) else { return }
        let nextIndex = (currentIndex + 1) % all.count
        viewModel.setupDraft.format = all[nextIndex]
    }

    private func cycleRuleMode() {
        let all = RuleMode.allCases
        guard let currentIndex = all.firstIndex(of: viewModel.setupDraft.ruleMode) else { return }
        let nextIndex = (currentIndex + 1) % all.count
        viewModel.setupDraft.ruleMode = all[nextIndex]
    }

    private func cycleTiebreakMode() {
        let all = TiebreakMode.allCases
        guard let currentIndex = all.firstIndex(of: viewModel.setupDraft.tiebreakMode) else { return }
        let nextIndex = (currentIndex + 1) % all.count
        viewModel.setupDraft.tiebreakMode = all[nextIndex]
    }
}

#Preview {
    SetupView(viewModel: MatchViewModel())
}
