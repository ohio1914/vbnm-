import SwiftUI

struct QuizView: View {
    @Environment(AppViewModel.self) private var vm
    let quiz: Quiz

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(Color.secondary.opacity(0.2))
                    Rectangle()
                        .fill(Color.accentColor)
                        .frame(width: geo.size.width * progress)
                        .animation(.easeInOut, value: vm.currentQuestionIndex)
                }
            }
            .frame(height: 4)

            // Question counter
            HStack {
                Text("Fråga \(min(vm.currentQuestionIndex + 1, quiz.questions.count)) av \(quiz.questions.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(vm.score) rätt")
                    .font(.caption.bold())
                    .foregroundStyle(.accentColor)
            }
            .padding(.horizontal)
            .padding(.top, 12)

            if let question = vm.currentQuestion {
                ScrollView {
                    VStack(spacing: 16) {
                        // Question text
                        Text(question.text)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.secondary.opacity(0.08),
                                        in: RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal)

                        // Options
                        ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                            OptionButton(
                                letter: ["A", "B", "C", "D"][index],
                                text: option,
                                state: optionState(index: index, question: question)
                            ) {
                                vm.selectOption(index)
                            }
                            .padding(.horizontal)
                        }

                        // Explanation
                        if vm.isShowingExplanation {
                            explanationCard(question: question)
                                .padding(.horizontal)
                                .transition(.move(edge: .bottom).combined(with: .opacity))

                            Button {
                                withAnimation { vm.nextQuestion() }
                            } label: {
                                Text(vm.currentQuestionIndex + 1 < quiz.questions.count
                                     ? "Nästa fråga →"
                                     : "Se resultatet 🎉")
                                    .bold()
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.accentColor)
                                    .foregroundStyle(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .padding(.horizontal)
                            .transition(.opacity)
                        }
                    }
                    .padding(.vertical)
                    .animation(.easeInOut(duration: 0.3), value: vm.isShowingExplanation)
                }
            }
        }
        .navigationTitle(quiz.book.title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
    }

    private var progress: Double {
        guard quiz.questions.count > 0 else { return 0 }
        return Double(vm.currentQuestionIndex) / Double(quiz.questions.count)
    }

    private func optionState(index: Int, question: Question) -> OptionButton.AnswerState {
        guard let selected = vm.selectedOptionIndex else { return .normal }
        if index == question.correctOptionIndex { return .correct }
        if index == selected { return .wrong }
        return .dimmed
    }

    private func explanationCard(question: Question) -> some View {
        let correct = vm.selectedOptionIndex == question.correctOptionIndex
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(correct ? .green : .red)
                Text(correct ? "Rätt!" : "Fel!")
                    .font(.headline)
                    .foregroundStyle(correct ? .green : .red)
            }
            Text(question.explanation)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            (correct ? Color.green : Color.red).opacity(0.08),
            in: RoundedRectangle(cornerRadius: 12)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke((correct ? Color.green : Color.red).opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Option Button

struct OptionButton: View {
    enum AnswerState { case normal, correct, wrong, dimmed }

    let letter: String
    let text: String
    let state: AnswerState
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Letter badge
                Text(letter)
                    .font(.headline)
                    .frame(width: 32, height: 32)
                    .background(badgeColor)
                    .foregroundStyle(state == .normal || state == .dimmed ? .primary : .white)
                    .clipShape(Circle())

                Text(text)
                    .font(.subheadline)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(state == .dimmed ? .secondary : .primary)

                Spacer()

                if state == .correct {
                    Image(systemName: "checkmark").foregroundStyle(.green).bold()
                } else if state == .wrong {
                    Image(systemName: "xmark").foregroundStyle(.red).bold()
                }
            }
            .padding()
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: state == .normal ? 1 : 2)
            )
        }
        .disabled(state != .normal)
        .animation(.easeInOut(duration: 0.25), value: state)
    }

    private var backgroundColor: Color {
        switch state {
        case .normal:  Color(.secondarySystemBackground)
        case .correct: Color.green.opacity(0.12)
        case .wrong:   Color.red.opacity(0.12)
        case .dimmed:  Color(.secondarySystemBackground).opacity(0.5)
        }
    }

    private var badgeColor: Color {
        switch state {
        case .normal:  Color.accentColor.opacity(0.15)
        case .correct: Color.green
        case .wrong:   Color.red
        case .dimmed:  Color.secondary.opacity(0.15)
        }
    }

    private var borderColor: Color {
        switch state {
        case .normal:  Color.secondary.opacity(0.3)
        case .correct: Color.green
        case .wrong:   Color.red
        case .dimmed:  Color.clear
        }
    }
}
