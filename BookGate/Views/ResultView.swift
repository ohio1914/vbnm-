import SwiftUI

struct ResultView: View {
    @Environment(AppViewModel.self) private var vm
    let result: QuizResult

    @State private var secondsRemaining: Int = 0
    @State private var timerRunning = false
    @State private var timer: Timer?

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {

                // Big emoji + grade
                VStack(spacing: 8) {
                    Text(result.emoji)
                        .font(.system(size: 72))
                    Text("Betyg: \(result.grade)")
                        .font(.largeTitle.bold())
                    Text(result.message)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)

                // Score card
                GroupBox {
                    HStack(spacing: 0) {
                        scoreColumn(value: "\(result.score)/\(result.total)", label: "Rätt svar")
                        Divider().padding(.vertical, 8)
                        scoreColumn(value: "\(result.percentage * 100, format: .number.precision(.fractionLength(0)))%",
                                    label: "Procent")
                        Divider().padding(.vertical, 8)
                        scoreColumn(value: "\(result.minutesEarned) min", label: "Skärmtid")
                    }
                }
                .padding(.horizontal)

                // Timer section
                GroupBox {
                    VStack(spacing: 16) {
                        Label("Din skärmtid", systemImage: "hourglass")
                            .font(.headline)

                        if result.minutesEarned == 0 {
                            Text("Du fick inga minuter den här gången.\nLäs sidorna igen och försök!")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        } else if timerRunning {
                            // Countdown
                            VStack(spacing: 8) {
                                Text(timeString(secondsRemaining))
                                    .font(.system(size: 54, weight: .bold, design: .monospaced))
                                    .foregroundStyle(secondsRemaining < 60 ? .red : .accentColor)
                                Text("kvar av dina \(result.minutesEarned) minuter")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                ProgressView(value: Double(secondsRemaining),
                                             total: Double(result.minutesEarned * 60))
                                    .tint(secondsRemaining < 60 ? .red : .accentColor)

                                Button("Avbryt timer") {
                                    stopTimer()
                                }
                                .foregroundStyle(.red)
                                .font(.caption)
                            }
                        } else if secondsRemaining == 0 && !timerRunning {
                            // Not started yet
                            VStack(spacing: 12) {
                                Text("Du har tjänat \(result.minutesEarned) minuters skärmtid! 🎉")
                                    .font(.subheadline)
                                    .multilineTextAlignment(.center)
                                Text("Starta timern och visa den för dina föräldrar.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)

                                Button {
                                    startTimer()
                                } label: {
                                    Label("Starta \(result.minutesEarned) min timer", systemImage: "play.fill")
                                        .bold()
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.green)
                                        .foregroundStyle(.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        } else {
                            // Timer finished
                            VStack(spacing: 8) {
                                Text("⏰ Tiden är ute!")
                                    .font(.title2.bold())
                                Text("Bra jobbat! Dina \(result.minutesEarned) minuter är slut.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                    }
                    .padding(4)
                }
                .padding(.horizontal)

                // Action buttons
                VStack(spacing: 12) {
                    Button {
                        vm.resetQuiz()
                    } label: {
                        Label("Läs en ny bok", systemImage: "books.vertical")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    if let quiz = vm.currentQuiz {
                        Button {
                            // Retry same book/pages
                            vm.screen = .quiz(quiz)
                            vm.currentQuestionIndex = 0
                            vm.score = 0
                            vm.selectedOptionIndex = nil
                            vm.isShowingExplanation = false
                        } label: {
                            Label("Försök igen med samma bok", systemImage: "arrow.clockwise")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .foregroundStyle(.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .navigationTitle("Resultat")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .onDisappear { stopTimer() }
    }

    // MARK: - Timer logic

    private func startTimer() {
        secondsRemaining = result.minutesEarned * 60
        timerRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if secondsRemaining > 0 {
                secondsRemaining -= 1
            } else {
                stopTimer()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        timerRunning = false
    }

    private func timeString(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    // MARK: - Helper

    private func scoreColumn(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.title2.bold())
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}
