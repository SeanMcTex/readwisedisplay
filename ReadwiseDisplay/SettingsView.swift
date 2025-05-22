//
//  SettingsView.swift
//  ReadwiseDisplay
//
//  Created by Sean Mc Mains on 5/22/25.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("quoteRefreshInterval") private var quoteRefreshInterval: Double = 10.0
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("Settings")
                .font(.largeTitle)
                .padding(.top)

            HStack {
                Text("Refresh Interval (seconds):")
                TextField("Seconds", value: $quoteRefreshInterval, formatter: NumberFormatter())
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 80)
                Stepper("Seconds", value: $quoteRefreshInterval, in: 5...300, step: 1)
            }
            .padding(.horizontal)

            Button("Done") {
                dismiss()
            }
            .padding(.bottom)
            
            Spacer()
        }
        .padding()
        .frame(minWidth: 300, idealWidth: 400, minHeight: 200, idealHeight: 250)
    }
}

#Preview {
    SettingsView()
}