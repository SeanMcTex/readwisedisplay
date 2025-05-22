//
//  ContentView.swift
//  ReadwiseDisplay
//
//  Created by Sean Mc Mains on 5/21/25.
//

import SwiftUI

struct Quote {
    let text: String
    let author: String
    let source: String
}

struct ContentView: View {
    @StateObject private var readwise = ReadwiseService(apiKey: "BOWw9f4lRQX01JMWttONcbAaSWnhpc5p5RyjAo550ns7LOJIb9")
    private let backgroundColors: [Color] = [
        Color(red: 0.1, green: 0.1, blue: 0.2),
        Color(red: 0.15, green: 0.1, blue: 0.15),
        Color(red: 0.1, green: 0.15, blue: 0.2),
        Color(red: 0.12, green: 0.12, blue: 0.18)
    ]
    @State private var currentColorIndex = 0
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 40) {
                Spacer()
                
                if let quote = readwise.currentQuote {
                    Text(quote.text)
                        .font(.system(size: 32, weight: .light))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .foregroundColor(.white)
                    
                    VStack(spacing: 8) {
                        Text("— \(quote.author)")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                        
                        Text(quote.source)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.white.opacity(0.8))
                            .italic()
                    }
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(backgroundColors[currentColorIndex])
            .task {
                try? await readwise.fetchRandomQuote()
            }
            .onTapGesture {
                currentColorIndex = (currentColorIndex + 1) % backgroundColors.count
                Task {
                    try? await readwise.fetchRandomQuote()
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
