import Foundation

/// Irish public holidays, computed algorithmically so past and future years
/// stay correct with zero network dependency (no API, no hardcoded list to
/// go stale). Movable feasts (Easter Monday) use the Anonymous Gregorian /
/// Meeus–Jones–Butcher algorithm; "first/last Monday of month" holidays are
/// computed directly; fixed-date holidays follow the official shift-to-
/// Monday rule, with the Dec 25/26 collision case (when Christmas Day and
/// St. Stephen's Day would otherwise land on the same observed day) handled
/// explicitly.
enum IrishHolidays {
    private struct MonthDay: Hashable { let month: Int; let day: Int }

    private static var cache: [Int: Set<MonthDay>] = [:]

    private static let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Europe/Dublin") ?? .current
        return cal
    }()

    static func isHoliday(_ date: Date) -> Bool {
        let year = calendar.component(.year, from: date)
        let comps = calendar.dateComponents([.month, .day], from: date)
        guard let month = comps.month, let day = comps.day else { return false }
        return holidays(for: year).contains(MonthDay(month: month, day: day))
    }

    private static func holidays(for year: Int) -> Set<MonthDay> {
        if let cached = cache[year] { return cached }
        var result: [MonthDay] = []

        func weekday(_ month: Int, _ day: Int) -> Int {
            calendar.component(.weekday, from: calendar.date(from: DateComponents(year: year, month: month, day: day))!)
        }

        // Shifts a fixed date to the next Monday when it falls on Sat/Sun.
        func shiftedToMonday(_ month: Int, _ day: Int) -> MonthDay {
            let wd = weekday(month, day)
            let offset = wd == 7 ? 2 : (wd == 1 ? 1 : 0) // Sat -> +2, Sun -> +1
            guard offset > 0,
                  let base = calendar.date(from: DateComponents(year: year, month: month, day: day)),
                  let shifted = calendar.date(byAdding: .day, value: offset, to: base) else {
                return MonthDay(month: month, day: day)
            }
            let c = calendar.dateComponents([.month, .day], from: shifted)
            return MonthDay(month: c.month!, day: c.day!)
        }

        func nthMonday(_ month: Int, n: Int) -> MonthDay {
            let firstOfMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1))!
            let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
            let day = 1 + ((2 - firstWeekday + 7) % 7) + (n - 1) * 7
            return MonthDay(month: month, day: day)
        }

        func lastMonday(_ month: Int) -> MonthDay {
            let firstOfMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1))!
            let lastDay = calendar.range(of: .day, in: .month, for: firstOfMonth)!.count
            let lastDate = calendar.date(from: DateComponents(year: year, month: month, day: lastDay))!
            let lastWeekday = calendar.component(.weekday, from: lastDate)
            let diff = (lastWeekday - 2 + 7) % 7
            return MonthDay(month: month, day: lastDay - diff)
        }

        // New Year's Day
        result.append(shiftedToMonday(1, 1))

        // St. Brigid's Day (introduced 2023): first Monday in Feb, unless Feb 1 is a Friday.
        if year >= 2023 {
            if weekday(2, 1) == 6 { // Friday
                result.append(MonthDay(month: 2, day: 1))
            } else {
                result.append(nthMonday(2, n: 1))
            }
        }

        // St. Patrick's Day
        result.append(shiftedToMonday(3, 17))

        // Easter Monday (Meeus/Jones/Butcher Gregorian algorithm for Easter Sunday, +1 day)
        let a = year % 19, b = year / 100, c = year % 100
        let d = b / 4, e = b % 4
        let f = (b + 8) / 25
        let g = (b - f + 1) / 3
        let h = (19 * a + b - d - g + 15) % 30
        let i = c / 4, k = c % 4
        let l = (32 + 2 * e + 2 * i - h - k) % 7
        let m = (a + 11 * h + 22 * l) / 451
        let easterMonth = (h + l - 7 * m + 114) / 31
        let easterDay = ((h + l - 7 * m + 114) % 31) + 1
        if let easterSunday = calendar.date(from: DateComponents(year: year, month: easterMonth, day: easterDay)),
           let easterMondayDate = calendar.date(byAdding: .day, value: 1, to: easterSunday) {
            let c2 = calendar.dateComponents([.month, .day], from: easterMondayDate)
            result.append(MonthDay(month: c2.month!, day: c2.day!))
        }

        // May, June, August bank holidays: first Monday of the month
        result.append(nthMonday(5, n: 1))
        result.append(nthMonday(6, n: 1))
        result.append(nthMonday(8, n: 1))

        // October bank holiday: last Monday of the month
        result.append(lastMonday(10))

        // Christmas Day & St. Stephen's Day — official scheme moves each to
        // the next available weekday, resolving the case where both would
        // otherwise fall on the same day.
        switch weekday(12, 25) {
        case 7: // Dec 25 is Saturday
            result.append(MonthDay(month: 12, day: 27)) // Christmas -> Monday
            result.append(MonthDay(month: 12, day: 28)) // Stephen's -> Tuesday
        case 1: // Dec 25 is Sunday (so Dec 26 is Monday)
            result.append(MonthDay(month: 12, day: 27)) // Christmas -> Tuesday (Monday taken)
            result.append(MonthDay(month: 12, day: 26)) // Stephen's stays Monday
        case 6: // Dec 25 is Friday (so Dec 26 is Saturday)
            result.append(MonthDay(month: 12, day: 25))
            result.append(MonthDay(month: 12, day: 28)) // Stephen's -> Monday
        default:
            result.append(MonthDay(month: 12, day: 25))
            result.append(MonthDay(month: 12, day: 26))
        }

        let set = Set(result)
        cache[year] = set
        return set
    }
}
