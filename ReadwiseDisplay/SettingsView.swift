//
//  SettingsView.swift
//  ReadwiseDisplay
//
//  Created by Sean Mc Mains on 5/22/25.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("quoteRefreshInterval") private var quoteRefreshInterval: Double = 10.0
    @AppStorage("readwiseAPIKey") private var apiKey: String = ""
    @Environment(\.dismiss) var dismiss
    
    @State private var isAPIKeyVisible = false
    
    private var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimum = 5
        formatter.maximum = 300
        formatter.allowsFloats = false
        formatter.isLenient = true
        return formatter
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 4) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(.secondary)
                
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            .padding(.top, 24)
            .padding(.bottom, 32)
            
            // Main content
            VStack(spacing: 24) {
                // Display Settings Section
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader(title: "Display", icon: "clock.fill")
                    
                    VStack(spacing: 12) {
                        SettingRow(
                            label: "Refresh Interval",
                            description: "How often quotes update automatically"
                        ) {
                            HStack(spacing: 8) {
                                TextField("", value: $quoteRefreshInterval, formatter: numberFormatter)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 70)
                                    .multilineTextAlignment(.center)
                                
                                Text("sec")
                                    .foregroundStyle(.secondary)
                                    .font(.system(.body, design: .rounded))
                                
                                Stepper("", value: $quoteRefreshInterval, in: 5...300, step: 5)
                                    .labelsHidden()
                            }
                        }
                        
                        // Visual indicator for refresh rate
                        HStack {
                            Text("Updates every")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Text(formatInterval(quoteRefreshInterval))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.primary)
                            
                            Spacer()
                        }
                        .padding(.leading, 4)
                    }
                }
                
                Divider()
                    .padding(.horizontal, -20)
                
                // API Configuration Section
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader(title: "API Configuration", icon: "key.fill")
                    
                    VStack(spacing: 12) {
                        SettingRow(
                            label: "Readwise API Key",
                            description: "Your personal API key from Readwise"
                        ) {
                            HStack(spacing: 8) {
                                Group {
                                    if isAPIKeyVisible {
                                        TextField("Enter your API key", text: $apiKey)
                                    } else {
                                        SecureField("Enter your API key", text: $apiKey)
                                    }
                                }
                                .textFieldStyle(.roundedBorder)
                                
                                Button(action: { isAPIKeyVisible.toggle() }) {
                                    Image(systemName: isAPIKeyVisible ? "eye.slash.fill" : "eye.fill")
                                        .foregroundStyle(.secondary)
                                        .font(.system(size: 14))
                                }
                                .buttonStyle(.plain)
                                .help(isAPIKeyVisible ? "Hide API key" : "Show API key")
                            }
                        }
                        
                        // API key status indicator
                        HStack {
                            Image(systemName: apiKey.isEmpty ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(apiKey.isEmpty ? .orange : .green)
                            
                            Text(apiKey.isEmpty ? "API key required" : "API key configured")
                                .font(.caption)
                                .foregroundStyle(apiKey.isEmpty ? .orange : .green)
                            
                            Spacer()
                            
                            if !apiKey.isEmpty {
                                Button("Get API Key") {
                                    if let url = URL(string: "https://readwise.io/access_token") {
                                        NSWorkspace.shared.open(url)
                                    }
                                }
                                .font(.caption)
                                .foregroundStyle(.blue)
                            }
                        }
                        .padding(.leading, 4)
                    }
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Footer with done button
            HStack {
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .frame(minWidth: 420, idealWidth: 480, maxWidth: 520,
               minHeight: 320, idealHeight: 380, maxHeight: 450)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private func formatInterval(_ seconds: Double) -> String {
        let intSeconds = Int(seconds)
        if intSeconds < 60 {
            return "\(intSeconds) seconds"
        } else if intSeconds == 60 {
            return "1 minute"
        } else if intSeconds % 60 == 0 {
            return "\(intSeconds / 60) minutes"
        } else {
            let minutes = intSeconds / 60
            let remainingSeconds = intSeconds % 60
            return "\(minutes)m \(remainingSeconds)s"
        }
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.blue)
                .frame(width: 20)
            
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
        }
    }
}

struct SettingRow<Content: View>: View {
    let label: String
    let description: String
    let content: Content
    
    init(label: String, description: String, @ViewBuilder content: () -> Content) {
        self.label = label
        self.description = description
        self.content = content()
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: 180, alignment: .leading)
            
            Spacer()
            
            content
                .frame(alignment: .trailing)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    SettingsView()
}
