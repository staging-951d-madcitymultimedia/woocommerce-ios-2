import Foundation
import Yosemite

struct AnalyticsHubTimeRange {
    let start: Date
    let end: Date
}

public class AnalyticsHubTimeRangeGenerator {

    private let currentTimezone = TimeZone.autoupdatingCurrent
    private let currentDate: Date
    private let currentCalendar: Calendar
    private let selectionType: SelectionType

    lazy private(set) var currentTimeRange: AnalyticsHubTimeRange = {
        generateCurrentTimeRangeFrom(selectionType: selectionType)
    }()

    lazy private(set) var previousTimeRange: AnalyticsHubTimeRange = {
        generatePreviousTimeRangeFrom(selectionType: selectionType)
    }()

    lazy private(set) var currentRangeDescription: String = {
        generateDescriptionOf(timeRange: currentTimeRange)
    }()

    lazy private(set) var previousRangeDescription: String = {
        generateDescriptionOf(timeRange: previousTimeRange)
    }()

    var selectionDescription: String {
        selectionType.description
    }

    init(selectedTimeRange: StatsTimeRangeV4,
         currentDate: Date = Date(),
         currentCalendar: Calendar = Calendar(identifier: .iso8601)
    ) {
        self.selectionType = SelectionType.from(selectedTimeRange)
        self.currentDate = currentDate
        self.currentCalendar = currentCalendar
    }

    private func generateCurrentTimeRangeFrom(selectionType: SelectionType) -> AnalyticsHubTimeRange {
        switch selectionType {
        case .today:
            return AnalyticsHubTimeRange(start: currentDate.startOfDay(timezone: currentTimezone), end: currentDate)
        case .weekToDate:
            let weekStart = currentDate.startOfWeek(timezone: currentTimezone, calendar: currentCalendar)
            return AnalyticsHubTimeRange(start: weekStart, end: currentDate)
        case .monthToDate:
            return AnalyticsHubTimeRange(start: currentDate.startOfMonth(timezone: currentTimezone), end: currentDate)
        case .yearToDate:
            return AnalyticsHubTimeRange(start: currentDate.startOfYear(timezone: currentTimezone), end: currentDate)
        }
    }

    private func generatePreviousTimeRangeFrom(selectionType: SelectionType) -> AnalyticsHubTimeRange {
        switch selectionType {
        case .today:
            let oneDayAgo = currentCalendar.date(byAdding: .day, value: -1, to: currentDate)!
            return AnalyticsHubTimeRange(start: oneDayAgo.startOfDay(timezone: currentTimezone), end: oneDayAgo)
        case .weekToDate:
            let oneWeekAgo = currentCalendar.date(byAdding: .day, value: -7, to: currentDate)!
            let lastWeekStart = oneWeekAgo.startOfWeek(timezone: currentTimezone, calendar: currentCalendar)
            return AnalyticsHubTimeRange(start: lastWeekStart, end: oneWeekAgo)
        case .monthToDate:
            let oneMonthAgo = currentCalendar.date(byAdding: .month, value: -1, to: currentDate)!
            return AnalyticsHubTimeRange(start: oneMonthAgo.startOfMonth(timezone: currentTimezone), end: oneMonthAgo)
        case .yearToDate:
            let oneYearAgo = currentCalendar.date(byAdding: .year, value: -1, to: currentDate)!
            return AnalyticsHubTimeRange(start: oneYearAgo.startOfYear(timezone: currentTimezone), end: oneYearAgo)
        }
    }

    private func generateDescriptionOf(timeRange: AnalyticsHubTimeRange) -> String {
        let dateFormatter = DateFormatter()

        if selectionType == .today {
            dateFormatter.dateFormat = "MMM d, yyyy"
            return dateFormatter.string(from: timeRange.start)
        }

        dateFormatter.dateFormat = "MMM d"
        let startDateDescription = dateFormatter.string(from: timeRange.start)
        let endDateDescription = generateEndDateDescription(timeRange: timeRange, dateFormatter: dateFormatter)

        return "\(startDateDescription) - \(endDateDescription)"
    }

    private func generateEndDateDescription(timeRange: AnalyticsHubTimeRange, dateFormatter: DateFormatter) -> String {
        if timeRange.start.isSameMonth(as: timeRange.end, using: currentCalendar) {
            dateFormatter.dateFormat = "d, yyyy"
            return dateFormatter.string(from: timeRange.end)
        } else {
            dateFormatter.dateFormat = "MMM d, yyyy"
            return dateFormatter.string(from: timeRange.end)
        }
    }
}

private extension AnalyticsHubTimeRangeGenerator {

    enum SelectionType {
        case today
        case weekToDate
        case monthToDate
        case yearToDate

        var description: String {
            get {
                switch self {
                case .today:
                    return Localization.today
                case .weekToDate:
                    return Localization.weekToDate
                case .monthToDate:
                    return Localization.monthToDate
                case .yearToDate:
                    return Localization.yearToDate
                }
            }
        }

        static func from(_ statsTimeRange: StatsTimeRangeV4) -> SelectionType {
            switch statsTimeRange {
            case .today:
                return .today
            case .thisWeek:
                return .weekToDate
            case .thisMonth:
                return .monthToDate
            case .thisYear:
                return .yearToDate
            }
        }
    }

    enum Localization {
        static let today = NSLocalizedString("Today", comment: "Today")
        static let weekToDate = NSLocalizedString("Week to Date", comment: "Week to Date")
        static let monthToDate = NSLocalizedString("Month to Date", comment: "Month to Date")
        static let yearToDate = NSLocalizedString("Year to Date", comment: "Year to Date")
    }
}
