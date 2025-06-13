import Foundation
import SwiftUI

struct APIHighlightItem: Codable {
    let text: String
    let title: String?
    let author: String?
    let book_id: Int?
}

struct APIBookDetails: Codable {
    let title: String
    let author: String
}

struct APIHighlightListResponse: Codable {
    let count: Int
    let results: [APIHighlightItem]
}

enum ReadwiseError: Error, LocalizedError {
    case apiKeyMissing
    case apiKeyInvalid
    case networkError(Error)
    case decodingError(Error)
    case unknownError

    var errorDescription: String? {
        switch self {
        case .apiKeyMissing:
            return "Readwise API Key is missing."
        case .apiKeyInvalid:
            return "Readwise API Key is invalid or unauthorized."
        case .networkError(let underlyingError):
            return "Network error: \(underlyingError.localizedDescription)"
        case .decodingError:
            return "Failed to decode server response."
        case .unknownError:
            return "An unknown error occurred."
        }
    }
}

class ReadwiseService: ObservableObject {
    @Published var currentQuote: Quote?
    
    private var apiKey: String
    private let baseURL = "https://readwise.io/api/v2"
    
    private var totalHighlightsCount: Int?
    private let highlightsPerPage: Int = 20

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    private func fetchTotalHighlightsCountIfNeeded() async throws {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ReadwiseError.apiKeyMissing
        }

        if totalHighlightsCount != nil {
            return // Count is already cached
        }
        
        guard var urlComponents = URLComponents(string: "\(baseURL)/highlights/") else {
            throw ReadwiseError.networkError(URLError(.badURL))
        }
        urlComponents.queryItems = [URLQueryItem(name: "page_size", value: "1")]
        
        guard let countURL = urlComponents.url else {
            throw ReadwiseError.networkError(URLError(.badURL))
        }
        
        var request = URLRequest(url: countURL)
        request.setValue("Token \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ReadwiseError.networkError(URLError(.badServerResponse))
        }

        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            throw ReadwiseError.apiKeyInvalid
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let statusCode = httpResponse.statusCode
            throw ReadwiseError.networkError(URLError(URLError.Code(rawValue: statusCode)))
        }
        
        do {
            let listResponse = try JSONDecoder().decode(APIHighlightListResponse.self, from: data)
            self.totalHighlightsCount = listResponse.count
        } catch {
            throw ReadwiseError.decodingError(error)
        }
    }

    private func fetchBookDetails(for bookID: Int) async throws -> APIBookDetails? {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        guard let url = URL(string: "\(baseURL)/books/\(bookID)/") else {
            throw ReadwiseError.networkError(URLError(.badURL))
        }
        
        var request = URLRequest(url: url)
        request.setValue("Token \(apiKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            return nil
        }

        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            return nil
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            return nil
        }
        
        do {
            return try JSONDecoder().decode(APIBookDetails.self, from: data)
        } catch {
            return nil
        }
    }
    
    func fetchRandomQuote() async throws {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ReadwiseError.apiKeyMissing
        }

        try await fetchTotalHighlightsCountIfNeeded()
        
        guard let count = totalHighlightsCount, count > 0 else {
            DispatchQueue.main.async {
                self.currentQuote = Quote(text: "No highlights available in your library.", author: "", source: "")
            }
            return
        }
        
        let totalPages = Int(ceil(Double(count) / Double(highlightsPerPage)))
        let randomPageNumber = Int.random(in: 1...max(1, totalPages))
        
        guard var urlComponents = URLComponents(string: "\(baseURL)/highlights/") else {
            throw ReadwiseError.networkError(URLError(.badURL))
        }
        urlComponents.queryItems = [
            URLQueryItem(name: "page", value: "\(randomPageNumber)"),
            URLQueryItem(name: "page_size", value: "\(highlightsPerPage)")
        ]
        
        guard let pageURL = urlComponents.url else {
            throw ReadwiseError.networkError(URLError(.badURL))
        }
        
        var request = URLRequest(url: pageURL)
        request.setValue("Token \(apiKey)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ReadwiseError.networkError(URLError(.badServerResponse))
            }
            
            if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                throw ReadwiseError.apiKeyInvalid
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                throw ReadwiseError.networkError(URLError(URLError.Code(rawValue: httpResponse.statusCode)))
            }

            let listResponse = try JSONDecoder().decode(APIHighlightListResponse.self, from: data)
            
            if var randomHighlight = listResponse.results.randomElement() {
                var finalAuthor = randomHighlight.author
                var finalTitle = randomHighlight.title

                // If author or title is nil, and we have a book_id, try to fetch book details
                if (finalAuthor == nil || finalTitle == nil), let bookID = randomHighlight.book_id {
                    do {
                        if let bookDetails = try await fetchBookDetails(for: bookID) {
                            finalAuthor = finalAuthor ?? bookDetails.author
                            finalTitle = finalTitle ?? bookDetails.title
                        }
                    } catch {
                        // Continue with potentially unknown author/title
                    }
                }

                DispatchQueue.main.async {
                    self.currentQuote = Quote(
                        text: randomHighlight.text,
                        author: finalAuthor ?? "Unknown Author",
                        source: finalTitle ?? "Unknown Source"
                    )
                }
            } else {
                DispatchQueue.main.async {
                    self.currentQuote = Quote(text: "Could not fetch a random highlight.", author: "", source: "")
                }
            }
        } catch let error as ReadwiseError {
            throw error
        } catch let decodingError as DecodingError {
            throw ReadwiseError.decodingError(decodingError)
        } catch {
            throw ReadwiseError.networkError(error)
        }
    }

    func updateApiKey(_ newKey: String) {
        let trimmedKey = newKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedKey != apiKey else { return }
        apiKey = trimmedKey
        totalHighlightsCount = nil // Reset cache
        Task { @MainActor in
            self.currentQuote = nil
        }
    }
}
