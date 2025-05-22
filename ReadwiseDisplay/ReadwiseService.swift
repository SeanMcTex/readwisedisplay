import Foundation
import SwiftUI

// New struct to match the items within the "results" array
struct APIHighlightItem: Codable {
    let text: String
    let title: String? // Title of the source (book, article, etc.)
    let author: String? // Author can sometimes be null
    // We could add 'id' (highlight_id) or other fields if needed later
}

// New struct to match the overall API response structure
struct APIHighlightListResponse: Codable {
    // let count: Int // We don't strictly need count for this feature
    let results: [APIHighlightItem]
}

class ReadwiseService: ObservableObject {
    @Published var currentQuote: Quote?
    
    private let apiKey: String
    private let baseURL = "https://readwise.io/api/v2"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func fetchRandomQuote() async throws {
        guard let url = URL(string: "\(baseURL)/highlights/random") else {
            print("ReadwiseService: Invalid URL")
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.setValue("Token \(apiKey)", forHTTPHeaderField: "Authorization")
        
        print("ReadwiseService: Fetching quote from \(url.absoluteString)")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("ReadwiseService: Response is not HTTPURLResponse")
                throw URLError(.badServerResponse)
            }
            
            print("ReadwiseService: HTTP Status Code: \(httpResponse.statusCode)")
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("ReadwiseService: Received JSON string: \(jsonString)")
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                let responseBody = String(data: data, encoding: .utf8) ?? "No parsable body"
                print("ReadwiseService: HTTP Error \(httpResponse.statusCode). Body: \(responseBody)")
                throw URLError(URLError.Code(rawValue: httpResponse.statusCode), userInfo: [NSLocalizedDescriptionKey: "HTTP Error \(httpResponse.statusCode). Body: \(responseBody)"])
            }
            
            // Decode into APIHighlightListResponse
            let listResponse = try JSONDecoder().decode(APIHighlightListResponse.self, from: data)
            
            // Get the first highlight from the results array
            if let firstHighlight = listResponse.results.first {
                DispatchQueue.main.async {
                    self.currentQuote = Quote(
                        text: firstHighlight.text,
                        // Use the author and title directly from the highlight item
                        author: firstHighlight.author ?? "Unknown Author",
                        source: firstHighlight.title ?? "Unknown Source"
                    )
                    print("ReadwiseService: Highlight text updated successfully using first item from results.")
                }
            } else {
                print("ReadwiseService: No highlights found in the results array.")
                // Optionally, you could set currentQuote to nil or an error state here
                DispatchQueue.main.async {
                    self.currentQuote = Quote(text: "No highlights found in API response.", author: "", source: "")
                }
            }
            
        } catch {
            if let decodingError = error as? DecodingError {
                print("ReadwiseService: DecodingError: \(decodingError)")
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
            } else {
                print("ReadwiseService: Error during URLSession or other processing: \(error)")
            }
            throw error
        }
    }
}
