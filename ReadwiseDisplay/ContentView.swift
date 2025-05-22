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
    private let backgroundColors: [Color] = [
        Color(red: 0.1, green: 0.1, blue: 0.2),
        Color(red: 0.15, green: 0.1, blue: 0.15),
        Color(red: 0.1, green: 0.15, blue: 0.2),
        Color(red: 0.12, green: 0.12, blue: 0.18)
    ]
    @State private var currentColorIndex = 0
    
    let quote: Quote = Quote(
        text: "The best way to predict the future is to invent it.",
        author: "Alan Kay",
        source: "The Early History of Smalltalk"
    )
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 40) {
                Spacer()
                
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
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(backgroundColors[currentColorIndex])
        }
    }
}

#Preview {
    ContentView()
}
