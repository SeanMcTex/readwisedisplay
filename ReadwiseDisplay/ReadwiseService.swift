import Foundation
import SwiftUI

// New struct to match the items within the "results" array
struct APIHighlightItem: Codable {
    let text: String
    let title: String? // Title of the source (book, article, etc.)
    let author: String? // Author can sometimes be null
    // We could add 'id' (highlight_id) or other fields if needed later
    let book_id: Int?
}

struct APIBookDetails: Codable {
    let title: String
    let author: String
    // We could add other fields like category if desired later
}

// New struct to match the overall API response structure
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
        case .decodingError(let underlyingError):
            return "Failed to decode server response: \(underlyingError.localizedDescription)"
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
            print("ReadwiseService: API Key is missing.")
            throw ReadwiseError.apiKeyMissing
        }

        if totalHighlightsCount != nil {
            return // Count is already cached
        }
        
        // Fetch page_size=1 just to get the total count
        guard var urlComponents = URLComponents(string: "\(baseURL)/highlights/") else {
            print("ReadwiseService: Invalid URL components for count.")
            throw ReadwiseError.networkError(URLError(.badURL))
        }
        urlComponents.queryItems = [URLQueryItem(name: "page_size", value: "1")]
        
        guard let countURL = urlComponents.url else {
            print("ReadwiseService: Invalid URL for count.")
            throw ReadwiseError.networkError(URLError(.badURL))
        }
        
        var request = URLRequest(url: countURL)
        request.setValue("Token \(apiKey)", forHTTPHeaderField: "Authorization")
        
        print("ReadwiseService: Fetching total highlights count from \(countURL.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("ReadwiseService: Response is not HTTPURLResponse for count.")
            throw ReadwiseError.networkError(URLError(.badServerResponse))
        }

        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            print("ReadwiseService: API Key invalid (HTTP \(httpResponse.statusCode)) when fetching count.")
            throw ReadwiseError.apiKeyInvalid
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let statusCode = httpResponse.statusCode
            let responseBody = String(data: data, encoding: .utf8) ?? "No parsable body"
            print("ReadwiseService: HTTP Error \(statusCode) fetching count. Body: \(responseBody)")
            throw ReadwiseError.networkError(URLError(URLError.Code(rawValue: statusCode), userInfo: [NSLocalizedDescriptionKey: "HTTP Error \(statusCode) fetching count. Body: \(responseBody)"]))
        }
        
        do {
            let listResponse = try JSONDecoder().decode(APIHighlightListResponse.self, from: data)
            self.totalHighlightsCount = listResponse.count
            print("ReadwiseService: Total highlights count fetched and cached: \(self.totalHighlightsCount ?? -1)")
        } catch {
            print("ReadwiseService: DecodingError while fetching count: \(error)")
            throw ReadwiseError.decodingError(error)
        }
    }

    private func fetchBookDetails(for bookID: Int) async throws -> APIBookDetails? {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            // This might not directly lead to a user-facing error if it's a sub-fetch,
            // but the primary fetch would have already failed.
            print("ReadwiseService: API Key is missing when attempting to fetch book details.")
            return nil // Or throw ReadwiseError.apiKeyMissing if this should halt everything
        }

        guard let url = URL(string: "\(baseURL)/books/\(bookID)/") else {
            print("ReadwiseService: Invalid URL for book details (ID: \(bookID)).")
            throw ReadwiseError.networkError(URLError(.badURL))
        }
        var request = URLRequest(url: url)
        request.setValue("Token \(apiKey)", forHTTPHeaderField: "Authorization")

        print("ReadwiseService: Fetching book details for ID \(bookID) from \(url.absoluteString)")
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("ReadwiseService: Response is not HTTPURLResponse for book details (ID: \(bookID)).")
            return nil // Don't throw, just return nil so the main flow can use fallbacks.
        }

        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            print("ReadwiseService: API Key invalid (HTTP \(httpResponse.statusCode)) when fetching book details for ID \(bookID).")
            // Depending on strictness, you might throw ReadwiseError.apiKeyInvalid here too.
            // For now, returning nil lets the main flow use fallbacks.
            return nil
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            print("ReadwiseService: HTTP Error \(statusCode) fetching book details for ID \(bookID).")
            // Optionally, you could inspect the body here for more detailed error messages from Readwise.
            return nil // Don't throw, just return nil so the main flow can use fallbacks.
        }
        do {
            return try JSONDecoder().decode(APIBookDetails.self, from: data)
        } catch {
            print("ReadwiseService: DecodingError for book details (ID: \(bookID)): \(error)")
            return nil // Propagate as nil, don't throw a fatal ReadwiseError here
        }
    }
    
    func fetchRandomQuote() async throws {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("ReadwiseService: fetchRandomQuote called with empty API Key.")
            throw ReadwiseError.apiKeyMissing
        }

        try await fetchTotalHighlightsCountIfNeeded()
        
        guard let count = totalHighlightsCount, count > 0 else {
            print("ReadwiseService: No highlights available or count not fetched.")
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
        
        print("ReadwiseService: Fetching page \(randomPageNumber)/\(totalPages) from \(pageURL.absoluteString)")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            // ... (HTTP response and status code checking remains the same) ...
            guard let httpResponse = response as? HTTPURLResponse else {
                print("ReadwiseService: Response is not HTTPURLResponse for page fetch.")
                throw ReadwiseError.networkError(URLError(.badServerResponse))
            }
            
            print("ReadwiseService: HTTP Status Code for page fetch: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                print("ReadwiseService: API Key invalid (HTTP \(httpResponse.statusCode)) when fetching page.")
                throw ReadwiseError.apiKeyInvalid
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                let responseBody = String(data: data, encoding: .utf8) ?? "No parsable body"
                print("ReadwiseService: HTTP Error \(httpResponse.statusCode) fetching page. Body: \(responseBody)")
                throw ReadwiseError.networkError(URLError(URLError.Code(rawValue: httpResponse.statusCode), userInfo: [NSLocalizedDescriptionKey: "HTTP Error \(httpResponse.statusCode) fetching page. Body: \(responseBody)"]))
            }

            let listResponse = try JSONDecoder().decode(APIHighlightListResponse.self, from: data)
            
            if var randomHighlight = listResponse.results.randomElement() {
                var finalAuthor = randomHighlight.author
                var finalTitle = randomHighlight.title

                // If author or title is nil, and we have a book_id, try to fetch book details
                if (finalAuthor == nil || finalTitle == nil), let bookID = randomHighlight.book_id {
                    print("ReadwiseService: Highlight missing author/title. Attempting to fetch details for book_id: \(bookID)")
                    do {
                        if let bookDetails = try await fetchBookDetails(for: bookID) {
                            finalAuthor = finalAuthor ?? bookDetails.author // Only update if it was originally nil
                            finalTitle = finalTitle ?? bookDetails.title   // Only update if it was originally nil
                            print("ReadwiseService: Successfully fetched book details. Author: '\(bookDetails.author)', Title: '\(bookDetails.title)'")
                        } else {
                             print("ReadwiseService: fetchBookDetails returned nil for book_id: \(bookID).")
                        }
                    } catch {
                        print("ReadwiseService: Error fetching book details for book_id \(bookID): \(error). Proceeding with potentially unknown author/title.")
                        // Log error but continue, fallbacks will be used.
                    }
                }

                DispatchQueue.main.async {
                    self.currentQuote = Quote(
                        text: randomHighlight.text,
                        author: finalAuthor ?? "Unknown Author",
                        source: finalTitle ?? "Unknown Source"
                    )
                    print("ReadwiseService: Quote updated.")
                }
            } else {
                print("ReadwiseService: No highlights found in the results of fetched page \(randomPageNumber).")
                DispatchQueue.main.async {
                    self.currentQuote = Quote(text: "Could not fetch a random highlight.", author: "", source: "")
                }
            }
        } catch let error as ReadwiseError {
            // Re-throw ReadwiseErrors directly
            throw error
        } catch let decodingError as DecodingError {
            print("ReadwiseService: Top-level DecodingError in fetchRandomQuote: \(decodingError)")
            switch decodingError {
            case .typeMismatch(let type, let context):
                print("  Type mismatch: \(type), Path: \(context.codingPath), Description: \(context.debugDescription)")
            case .valueNotFound(let value, let context):
                print("  Value not found: \(value), Path: \(context.codingPath), Description: \(context.debugDescription)")
            case .keyNotFound(let key, let context):
                print("  Key not found: \(key), Path: \(context.codingPath), Description: \(context.debugDescription)")
            case .dataCorrupted(let context):
                print("  Data corrupted: Path: \(context.codingPath), Description: \(context.debugDescription)")
            @unknown default:
                print("  Unknown decoding error.")
            }
            throw ReadwiseError.decodingError(decodingError)
        } catch {
            print("ReadwiseService: Generic error in fetchRandomQuote: \(error)")
            throw ReadwiseError.networkError(error) // Wrap other errors
        }
    }

    func updateApiKey(_ newKey: String) {
        let trimmedKey = newKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedKey != apiKey else { return }
        apiKey = trimmedKey
        totalHighlightsCount = nil // Reset cache
        Task { @MainActor in
            self.currentQuote = nil
            // If the new key is empty, we don't need to trigger a fetch.
            // ContentView will handle displaying the "enter API key" message.
        }
    }
}
