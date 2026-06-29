import Foundation

enum BookServiceError: LocalizedError {
    case networkError(Error)
    case noResults
    case decodingError

    var errorDescription: String? {
        switch self {
        case .networkError(let e): return "Nätverksfel: \(e.localizedDescription)"
        case .noResults:           return "Inga böcker hittades. Prova ett annat sökord."
        case .decodingError:       return "Kunde inte läsa svaret från Google Books."
        }
    }
}

final class BookService {
    static let shared = BookService()
    private init() {}

    /// Searches Google Books — works for Swedish titles, no API key needed.
    func search(query: String, language: String = "sv") async throws -> [BookItem] {
        var components = URLComponents(string: "https://www.googleapis.com/books/v1/volumes")!
        components.queryItems = [
            URLQueryItem(name: "q",          value: query),
            URLQueryItem(name: "langRestrict", value: language),
            URLQueryItem(name: "maxResults", value: "20"),
            URLQueryItem(name: "printType",  value: "books")
        ]
        guard let url = components.url else { throw BookServiceError.noResults }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response  = try JSONDecoder().decode(BookSearchResponse.self, from: data)
            guard let items = response.items, !items.isEmpty else {
                throw BookServiceError.noResults
            }
            return items
        } catch let error as BookServiceError {
            throw error
        } catch is DecodingError {
            throw BookServiceError.decodingError
        } catch {
            throw BookServiceError.networkError(error)
        }
    }
}
