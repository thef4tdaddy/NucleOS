//
//  QuickAddEventView.swift
//  NucleOS
//
//  Natural language quick event creation
//

import SwiftUI

/// Quick add sheet for creating events via natural language input.
struct QuickAddEventView: View {
    @Binding var text: String
    @Binding var isPresented: Bool
    @EnvironmentObject var appSettings: AppSettings

    @State private var parsedEvent: NucleEvent?
    @State private var isParsing = false
    @State private var error: String?

    private let calendarService = CalendarService()

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Quick Add Event")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.textPrimary)

                TextField("e.g. Lunch with Sarah tomorrow at 12pm", text: $text)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 16))
                    .disableAutocorrection(true)

                if let parsed = parsedEvent {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Preview")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.textSecondary)

                        VStack(alignment: .leading, spacing: 8) {
                            Text(parsed.title)
                                .font(.system(size: 16, weight: .semibold))

                            HStack {
                                Image(systemName: "clock")
                                Text(formatDate(parsed.startDate))
                            }
                            .font(.system(size: 13))
                            .foregroundColor(.textMuted)

                            if let location = parsed.location {
                                HStack {
                                    Image(systemName: "location")
                                    Text(location)
                                }
                                .font(.system(size: 13))
                                .foregroundColor(.textMuted)
                            }
                        }
                        .padding()
                        .background(Color.backgroundCard)
                        .cornerRadius(12)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let error = error {
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundColor(.red)
                }

                Spacer()
            }
            .padding()
            .background(Color.backgroundPrimary)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: saveEvent) {
                        Text("Add")
                    }
                    .disabled(parsedEvent == nil || isParsing)
                }
            }
        }
        .onChange(of: text) { _ in
            parseInput()
        }
        .onAppear {
            parseInput()
        }
    }

    private func parseInput() {
        guard !text.isEmpty else {
            parsedEvent = nil
            return
        }

        parsedEvent = NaturalLanguageParser.parse(text)
    }

    private func saveEvent() {
        guard let event = parsedEvent else { return }

        Task {
            do {
                try await calendarService.createEvent(event)
                isPresented = false
            } catch {
                self.error = "Failed to create event: \(error.localizedDescription)"
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

/// Simple natural language parser for event creation.
enum NaturalLanguageParser {
    static func parse(_ input: String) -> NucleEvent? {
        let lowercased = input.lowercased()

        // Extract title (everything before time keywords)
        let timeKeywords = ["today", "tomorrow", "at ", "from ", "next ", "on "]
        var title = input

        for keyword in timeKeywords {
            if let range = lowercased.range(of: keyword) {
                let endIndex = input.index(input.startIndex, offsetBy: range.lowerBound.utf16Offset(in: input))
                title = String(input[..<endIndex]).trimmingCharacters(in: .whitespaces)
                break
            }
        }

        guard !title.isEmpty else { return nil }

        // Parse date/time
        var startDate = Date()
        var endDate = Date().addingTimeInterval(3600)
        let calendar = Calendar.current

        if lowercased.contains("tomorrow") {
            startDate = calendar.date(byAdding: .day, value: 1, to: startDate) ?? startDate
        } else if lowercased.contains("next week") {
            startDate = calendar.date(byAdding: .weekOfYear, value: 1, to: startDate) ?? startDate
        }

        // Simple time parsing
        if let time = extractTime(from: lowercased) {
            var components = calendar.dateComponents([.year, .month, .day], from: startDate)
            components.hour = time.hour
            components.minute = time.minute

            if let date = calendar.date(from: components) {
                startDate = date
                endDate = calendar.date(byAdding: .hour, value: 1, to: startDate) ?? endDate
            }
        }

        // Extract location
        var location: String?
        if let locationRange = lowercased.range(of: "at ") {
            let start = input.index(input.startIndex, offsetBy: locationRange.upperBound.utf16Offset(in: input))
            let remaining = String(input[start...])
            // Stop at time indicators
            let stopWords = [" today", " tomorrow", " at ", " from"]
            let locationString: String
            if let stopRange = stopWords.compactMap({ remaining.lowercased().range(of: $0) }).min(by: { $0.lowerBound < $1.lowerBound }) {
                locationString = String(remaining[..<stopRange.lowerBound])
            } else {
                locationString = remaining
            }
            location = locationString.trimmingCharacters(in: .whitespaces)
        }

        return NucleEvent(
            title: title.prefix(1).uppercased() + title.dropFirst(),
            startDate: startDate,
            endDate: endDate,
            location: location
        )
    }

    private static func extractTime(from text: String) -> (hour: Int, minute: Int)? {
        // Match patterns like "12pm", "12:30pm", "14:00", "2 pm"
        let patterns = [
            "([0-9]{1,2}):([0-9]{2})\\s*(am|pm)",
            "([0-9]{1,2})\\s*(am|pm)",
            "([0-9]{1,2}):([0-9]{2})"
        ]

        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { continue }

            let range = NSRange(text.startIndex..., in: text)
            if let match = regex.firstMatch(in: text, options: [], range: range) {
                let hourStr = String(text[Range(match.range(at: 1), in: text)!])
                guard let hour = Int(hourStr) else { continue }

                var finalHour = hour
                var minute = 0

                if match.numberOfRanges > 2 {
                    let secondRange = match.range(at: 2)
                    if secondRange.location != NSNotFound {
                        let secondStr = String(text[Range(secondRange, in: text)!])
                        if let m = Int(secondStr) {
                            minute = m
                        } else if secondStr.lowercased() == "pm" && hour != 12 {
                            finalHour += 12
                        } else if secondStr.lowercased() == "am" && hour == 12 {
                            finalHour = 0
                        }
                    }

                    if match.numberOfRanges > 3 {
                        let ampmRange = match.range(at: 3)
                        if ampmRange.location != NSNotFound {
                            let ampm = String(text[Range(ampmRange, in: text)!]).lowercased()
                            if ampm == "pm" && finalHour != 12 {
                                finalHour += 12
                            } else if ampm == "am" && finalHour == 12 {
                                finalHour = 0
                            }
                        }
                    }
                }

                return (hour: finalHour, minute: minute)
            }
        }

        return nil
    }
}

#Preview {
    QuickAddEventView(text: .constant("Lunch with Sarah tomorrow at 12pm"), isPresented: .constant(true))
        .environmentObject(AppSettings())
}