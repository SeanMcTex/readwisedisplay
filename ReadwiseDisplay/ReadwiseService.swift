import Foundation
import SwiftUI

struct ReadwiseQuote: Codable {
    let text: String
    let author: String
    let source_title: String
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
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.setValue("Token \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let readwiseQuote = try JSONDecoder().decode(ReadwiseQuote.self, from: data)
        
        DispatchQueue.main.async {
            self.currentQuote = Quote(
                text: readwiseQuote.text,
                author: readwiseQuote.author,
                source: readwiseQuote.source_title
            )
        }
    }
}
