import Foundation
import Observation

enum AppSection: String, CaseIterable, Identifiable {
    case calendar = "Calendar"
    case booking = "Booking"
    case settings = "Settings"

    var id: String { rawValue }
}

struct UserProfile: Codable {
    let id: UUID
    let email: String
    let displayName: String?
    let defaultTimezone: String
    let mode: String
    let calendarProvider: String

    private enum CodingKeys: String, CodingKey {
        case id
        case email
        case displayName = "display_name"
        case defaultTimezone = "default_timezone"
        case mode
        case calendarProvider = "calendar_provider"
    }
}

struct CalendarEvent: Codable, Identifiable {
    let id: UUID
    let googleEventID: String
    let title: String?
    let description: String?
    let status: String
    let startsAt: Date
    let endsAt: Date
    let allDay: Bool
    let location: String?
    let meetingURL: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case googleEventID = "google_event_id"
        case title
        case description
        case status
        case startsAt = "starts_at"
        case endsAt = "ends_at"
        case allDay = "all_day"
        case location
        case meetingURL = "meeting_url"
    }
}

struct CalendarEventsResponse: Codable {
    let events: [CalendarEvent]
}

struct BookingPage: Codable {
    let id: UUID
    let userID: UUID
    var slug: String
    var title: String
    var active: Bool
    var defaultDurationMinutes: Int
    var workingDays: [Int]
    var dayStartLocal: String
    var dayEndLocal: String
    var bufferBeforeMinutes: Int
    var bufferAfterMinutes: Int
    var minimumNoticeMinutes: Int

    private enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case slug
        case title
        case active
        case defaultDurationMinutes = "default_duration_minutes"
        case workingDays = "working_days"
        case dayStartLocal = "day_start_local"
        case dayEndLocal = "day_end_local"
        case bufferBeforeMinutes = "buffer_before_minutes"
        case bufferAfterMinutes = "buffer_after_minutes"
        case minimumNoticeMinutes = "minimum_notice_minutes"
    }
}

struct CandidateSlot: Codable, Identifiable {
    let start: String
    let end: String
    let score: Double?

    var id: String { "\(start)-\(end)" }
}

struct ProposedAction: Codable {
    let toolName: String
    let arguments: [String: String]

    private enum CodingKeys: String, CodingKey {
        case toolName = "tool_name"
        case arguments
    }
}

struct AgentResponse: Codable {
    let runID: String
    let intent: String
    let message: String
    let requiresConfirmation: Bool
    let proposedAction: ProposedAction?
    let data: AgentData

    private enum CodingKeys: String, CodingKey {
        case runID = "run_id"
        case intent
        case message
        case requiresConfirmation = "requires_confirmation"
        case proposedAction = "proposed_action"
        case data
    }
}

struct AgentData: Codable {
    let candidateSlots: [CandidateSlot]?

    private enum CodingKeys: String, CodingKey {
        case candidateSlots = "candidate_slots"
    }
}

struct SyncResponse: Codable {
    let syncedCount: Int
    let source: String

    private enum CodingKeys: String, CodingKey {
        case syncedCount = "synced_count"
        case source
    }
}

@MainActor
@Observable
final class AppState {
    let apiBaseURL: URL
    var selectedSection: AppSection = .calendar
    var profile: UserProfile?
    var events: [CalendarEvent] = []
    var bookingPage: BookingPage?
    var agentInput: String = ""
    var latestAgentResponse: AgentResponse?
    var pendingAction: ProposedAction?
    var isLoading = false
    var errorMessage: String?

    private let apiClient: APIClient

    init(apiBaseURL: URL = URL(string: "http://localhost:8000")!) {
        self.apiBaseURL = apiBaseURL
        self.apiClient = APIClient(baseURL: apiBaseURL)
    }

    func bootstrap() async {
        guard profile == nil else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            async let me = apiClient.fetchMe()
            async let sync = apiClient.syncSampleCalendar()
            _ = try await sync
            profile = try await me
            try await refreshEvents()
            bookingPage = try await apiClient.fetchBookingPage()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refreshEvents() async throws {
        let calendar = Calendar.current
        let now = Date()
        let start = calendar.startOfDay(for: now)
        let end = calendar.date(byAdding: .day, value: 7, to: start) ?? now
        let response = try await apiClient.fetchEvents(start: start, end: end)
        events = response.events.sorted(by: { $0.startsAt < $1.startsAt })
    }

    func runAgent() async {
        let text = agentInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await apiClient.queryAgent(text: text)
            latestAgentResponse = response
            pendingAction = response.requiresConfirmation ? response.proposedAction : nil
            if response.intent == "open_booking_settings" {
                selectedSection = .booking
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func confirmPendingAction() async {
        guard let pendingAction else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            try await apiClient.executeAction(toolName: pendingAction.toolName, arguments: pendingAction.arguments)
            self.pendingAction = nil
            latestAgentResponse = nil
            try await refreshEvents()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveBookingPage() async {
        guard let bookingPage else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            self.bookingPage = try await apiClient.updateBookingPage(bookingPage)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
