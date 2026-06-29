import Foundation

// MARK: - Book (Google Books API)

struct BookSearchResponse: Codable {
    let items: [BookItem]?
}

struct BookItem: Codable, Identifiable {
    let id: String
    let volumeInfo: VolumeInfo

    var title: String { volumeInfo.title }
    var authors: String { volumeInfo.authors?.joined(separator: ", ") ?? "Okänd författare" }
    var description: String { volumeInfo.description ?? "Ingen beskrivning tillgänglig." }
    var coverURL: URL? {
        guard let raw = volumeInfo.imageLinks?.thumbnail else { return nil }
        // Force HTTPS (Google sometimes returns http)
        return URL(string: raw.replacingOccurrences(of: "http://", with: "https://"))
    }
    var pageCount: Int { volumeInfo.pageCount ?? 0 }
}

struct VolumeInfo: Codable {
    let title: String
    let authors: [String]?
    let description: String?
    let pageCount: Int?
    let imageLinks: ImageLinks?
    let language: String?
}

struct ImageLinks: Codable {
    let thumbnail: String?
}

// MARK: - Quiz

struct Quiz: Identifiable {
    let id = UUID()
    let book: BookItem
    let fromPage: Int
    let toPage: Int
    let questions: [Question]

    var pagesLabel: String { "Sidor \(fromPage)–\(toPage)" }
}

struct Question: Identifiable {
    let id = UUID()
    let text: String
    let options: [String]           // exactly 4
    let correctOptionIndex: Int
    let explanation: String
}

// MARK: - Gemini JSON response shapes

struct GeminiResponse: Codable {
    let candidates: [GeminiCandidate]?
}

struct GeminiCandidate: Codable {
    let content: GeminiContent?
}

struct GeminiContent: Codable {
    let parts: [GeminiPart]?
}

struct GeminiPart: Codable {
    let text: String?
}

// MARK: - Quiz JSON (what Gemini returns inside its text)

struct QuizJSON: Codable {
    let questions: [QuestionJSON]
}

struct QuestionJSON: Codable {
    let text: String
    let options: [String]
    let correctOptionIndex: Int
    let explanation: String
}

// MARK: - Screen Time Reward

struct QuizResult {
    let score: Int
    let total: Int

    var percentage: Double { total > 0 ? Double(score) / Double(total) : 0 }
    var minutesEarned: Int { Int(percentage * 60) }   // 0–60 min scaled

    var grade: String {
        switch percentage {
        case 0.9...:  return "A"
        case 0.8..<0.9: return "B"
        case 0.7..<0.8: return "C"
        case 0.6..<0.7: return "D"
        default:        return "F"
        }
    }

    var emoji: String {
        switch percentage {
        case 0.8...: return "🎉"
        case 0.6..<0.8: return "👍"
        default: return "📚"
        }
    }

    var message: String {
        switch percentage {
        case 0.9...:    return "Fantastiskt! Du kan allt!"
        case 0.8..<0.9: return "Bra jobbat! Du läste ordentligt."
        case 0.6..<0.8: return "Okej! Läs lite mer nästa gång."
        default:        return "Försök igen – läs sidorna en gång till!"
        }
    }
}
