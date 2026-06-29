import Foundation

enum QuizServiceError: LocalizedError {
    case missingAPIKey
    case networkError(Error)
    case httpError(Int)
    case noContent
    case decodingError(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:       return "Lägg till din Gemini API-nyckel i appen."
        case .networkError(let e): return "Nätverksfel: \(e.localizedDescription)"
        case .httpError(let code): return "API-fel (HTTP \(code)). Kontrollera din nyckel."
        case .noContent:           return "AI returnerade inget svar."
        case .decodingError(let d): return "Kunde inte läsa quiz-svaret: \(d)"
        }
    }
}

final class QuizService {
    static let shared = QuizService()
    private init() {}

    // MARK: - Generate quiz

    func generateQuiz(for book: BookItem, fromPage: Int, toPage: Int,
                      apiKey: String) async throws -> Quiz {
        guard !apiKey.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw QuizServiceError.missingAPIKey
        }

        let prompt = buildPrompt(book: book, from: fromPage, to: toPage)
        let rawJSON = try await callGemini(prompt: prompt, apiKey: apiKey)
        let questions = try parseQuestions(from: rawJSON)

        return Quiz(book: book, fromPage: fromPage, toPage: toPage, questions: questions)
    }

    // MARK: - Prompt

    private func buildPrompt(book: BookItem, from: Int, to: Int) -> String {
        """
        Du är en quiz-generator för skolbarn i Sverige.
        Boken heter "\(book.title)" av \(book.authors).
        Eleven har läst sidorna \(from) till \(to).

        Bokbeskrivning:
        \(book.description.prefix(800))

        Generera 5 flervalsfrågor på SVENSKA om boken och sidorna eleven läste.
        Basera frågorna på bokens handling, karaktärer, teman och viktiga händelser.

        Svara ENDAST med ett JSON-objekt, inget annat. Inga markdown-kodblock.
        Exakt detta format:
        {
          "questions": [
            {
              "text": "Frågetext här?",
              "options": ["Alternativ A", "Alternativ B", "Alternativ C", "Alternativ D"],
              "correctOptionIndex": 0,
              "explanation": "Förklaring på svenska varför detta är rätt."
            }
          ]
        }

        Regler:
        - Exakt 5 frågor
        - Exakt 4 alternativ per fråga
        - correctOptionIndex är 0-baserat (0=A, 1=B, 2=C, 3=D)
        - Alla fel svar ska vara rimliga men felaktiga
        - Skriv allt på svenska
        - BARA JSON, inget annat
        """
    }

    // MARK: - Gemini REST call

    private func callGemini(prompt: String, apiKey: String) async throws -> String {
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else { throw QuizServiceError.noContent }

        let body: [String: Any] = [
            "system_instruction": [
                "parts": [["text": "Du svarar BARA med giltig JSON. Aldrig markdown, aldrig förklaringstext."]]
            ],
            "contents": [
                ["parts": [["text": prompt]]]
            ],
            "generationConfig": [
                "temperature": 0.4,
                "maxOutputTokens": 2048
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 30

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw QuizServiceError.networkError(error)
        }

        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw QuizServiceError.httpError(http.statusCode)
        }

        guard let gemini = try? JSONDecoder().decode(GeminiResponse.self, from: data),
              let text = gemini.candidates?.first?.content?.parts?.first?.text,
              !text.isEmpty else {
            throw QuizServiceError.noContent
        }

        return text
    }

    // MARK: - Parse JSON from Gemini text

    private func parseQuestions(from raw: String) throws -> [Question] {
        // Strip any accidental markdown fences
        let cleaned = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```",     with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleaned.data(using: .utf8) else {
            throw QuizServiceError.decodingError("Kunde inte konvertera text")
        }

        let quizJSON: QuizJSON
        do {
            quizJSON = try JSONDecoder().decode(QuizJSON.self, from: data)
        } catch {
            throw QuizServiceError.decodingError(error.localizedDescription)
        }

        return quizJSON.questions.map { q in
            Question(
                text: q.text,
                options: q.options,
                correctOptionIndex: max(0, min(3, q.correctOptionIndex)),
                explanation: q.explanation
            )
        }
    }
}
