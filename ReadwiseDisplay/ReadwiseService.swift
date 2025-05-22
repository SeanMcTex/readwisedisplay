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
            
            if !(200...299).contains(httpResponse.statusCode) {
                let responseBody = String(data: data, encoding: .utf8) ?? "No parsable body"
                print("ReadwiseService: HTTP Error \(httpResponse.statusCode). Body: \(responseBody)")
                throw URLError(URLError.Code(rawValue: httpResponse.statusCode), userInfo: [NSLocalizedDescriptionKey: "HTTP Error \(httpResponse.statusCode). Body: \(responseBody)"])
            }
            
            let readwiseQuote = try JSONDecoder().decode(ReadwiseQuote.self, from: data)
            
            DispatchQueue.main.async {
                self.currentQuote = Quote(
                    text: readwiseQuote.text,
                    author: readwiseQuote.author,
                    source: readwiseQuote.source_title
                )
                print("ReadwiseService: Quote updated successfully.")
            }
        } catch {
            print("ReadwiseService: Error during URLSession or JSON decoding: \(error)")
            throw error
        }
    }
}
