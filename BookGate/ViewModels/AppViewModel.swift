import Foundation
import SwiftUI

@MainActor
@Observable
final class AppViewModel {

    // MARK: - Navigation
    enum Screen {
        case settings
        case search
        case bookDetail(BookItem)
        case quiz(Quiz)
        case result(QuizResult)
    }

    var screen: Screen = .search
    var navigationPath: [Screen] = []

    // MARK: - Search
    var searchQuery    = ""
    var searchResults  : [BookItem] = []
    var isSearching    = false
    var searchError    : String?
    var searchLanguage = "sv"   // default Swedish

    // MARK: - Book detail / page input
    var selectedBook  : BookItem?
    var fromPageText  = ""
    var toPageText    = ""

    // MARK: - Quiz state
    var currentQuiz           : Quiz?
    var currentQuestionIndex  = 0
    var selectedOptionIndex   : Int?
    var isShowingExplanation  = false
    var score                 = 0
    var isGeneratingQuiz      = false
    var quizError             : String?

    // MARK: - Settings
    @AppStorage("geminiAPIKey") var apiKey = ""

    // MARK: - Computed
    var currentQuestion: Question? {
        guard let quiz = currentQuiz,
              currentQuestionIndex < quiz.questions.count else { return nil }
        return quiz.questions[currentQuestionIndex]
    }

    var quizIsFinished: Bool {
        guard let quiz = currentQuiz else { return false }
        return currentQuestionIndex >= quiz.questions.count
    }

    var fromPage: Int { Int(fromPageText) ?? 1 }
    var toPage:   Int { Int(toPageText)   ?? 1 }

    var pageInputValid: Bool {
        fromPage > 0 && toPage >= fromPage
    }

    // MARK: - Search

    func search() async {
        guard !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isSearching  = true
        searchError  = nil
        searchResults = []
        defer { isSearching = false }

        do {
            searchResults = try await BookService.shared.search(
                query: searchQuery, language: searchLanguage)
        } catch {
            searchError = error.localizedDescription
        }
    }

    // MARK: - Generate quiz

    func generateQuiz(for book: BookItem) async {
        guard pageInputValid else { return }
        isGeneratingQuiz = true
        quizError = nil
        defer { isGeneratingQuiz = false }

        do {
            let quiz = try await QuizService.shared.generateQuiz(
                for: book,
                fromPage: fromPage,
                toPage: toPage,
                apiKey: apiKey
            )
            currentQuiz          = quiz
            currentQuestionIndex = 0
            selectedOptionIndex  = nil
            isShowingExplanation = false
            score                = 0
            screen               = .quiz(quiz)
        } catch {
            quizError = error.localizedDescription
        }
    }

    // MARK: - Quiz interaction

    func selectOption(_ index: Int) {
        guard selectedOptionIndex == nil else { return }
        selectedOptionIndex  = index
        isShowingExplanation = true
        if let q = currentQuestion, index == q.correctOptionIndex {
            score += 1
        }
    }

    func nextQuestion() {
        currentQuestionIndex += 1
        selectedOptionIndex  = nil
        isShowingExplanation = false

        if quizIsFinished, let quiz = currentQuiz {
            let result = QuizResult(score: score, total: quiz.questions.count)
            screen = .result(result)
        }
    }

    // MARK: - Reset

    func resetQuiz() {
        currentQuiz          = nil
        currentQuestionIndex = 0
        selectedOptionIndex  = nil
        isShowingExplanation = false
        score                = 0
        fromPageText         = ""
        toPageText           = ""
        screen               = .search
    }
}
