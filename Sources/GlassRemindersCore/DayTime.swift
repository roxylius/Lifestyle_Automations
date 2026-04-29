import Foundation

public struct DayTime: Codable, Hashable, Comparable, CustomStringConvertible {
    public var hour: Int
    public var minute: Int

    public init(hour: Int, minute: Int) {
        self.hour = min(max(hour, 0), 23)
        self.minute = min(max(minute, 0), 59)
    }

    public init?(_ text: String) {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")

        for format in ["H:mm", "HH:mm", "h:mm a", "h a"] {
            formatter.dateFormat = format
            if let date = formatter.date(from: cleaned.uppercased()) {
                let calendar = Calendar.current
                self.hour = calendar.component(.hour, from: date)
                self.minute = calendar.component(.minute, from: date)
                return
            }
        }

        let parts = cleaned.split(separator: ":")
        guard parts.count == 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]),
              (0...23).contains(hour),
              (0...59).contains(minute)
        else {
            return nil
        }

        self.hour = hour
        self.minute = minute
    }

    public var minutesFromMidnight: Int {
        hour * 60 + minute
    }

    public var description: String {
        String(format: "%02d:%02d", hour, minute)
    }

    public static func < (lhs: DayTime, rhs: DayTime) -> Bool {
        lhs.minutesFromMidnight < rhs.minutesFromMidnight
    }

    public static func parseList(_ text: String) -> [DayTime] {
        text
            .split(separator: ",")
            .compactMap { DayTime(String($0)) }
            .removingDuplicates()
            .sorted()
    }
}

private extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
