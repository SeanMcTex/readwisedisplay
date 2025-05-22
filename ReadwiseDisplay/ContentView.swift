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
    // Ensure this apiKey is your valid Readwise API key
    @StateObject private var readwise = ReadwiseService(apiKey: "BOWw9f4lRQX01JMWttONcbAaSWnhpc5p5RyjAo550ns7LOJIb9")
    private let backgroundColors: [Color] = [
        Color(red: 0.1, green: 0.1, blue: 0.2),
        Color(red: 0.15, green: 0.1, blue: 0.15),
        Color(red: 0.1, green: 0.15, blue: 0.2),
        Color(red: 0.12, green: 0.12, blue: 0.18)
    ]
    @State private var currentColorIndex = 0
    
    private let timer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()
    
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
                } else {
                    Text("Loading quote...")
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(backgroundColors[currentColorIndex])
            .task {
                do {
                    try await readwise.fetchRandomQuote()
                    // No background change on initial load, only quote
                } catch {
                    print("Error fetching quote on task: \(error)")
                }
            }
            .onTapGesture {
                Task {
                    do {
                        try await readwise.fetchRandomQuote()
                        currentColorIndex = (currentColorIndex + 1) % backgroundColors.count
                    } catch {
                        print("Error fetching quote on tap: \(error)")
                    }
                }
            }
            .onReceive(timer) { _ in
                Task {
                    do {
                        try await readwise.fetchRandomQuote()
                        currentColorIndex = (currentColorIndex + 1) % backgroundColors.count
                    } catch {
                        print("Error fetching quote on timer: \(error)")
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
