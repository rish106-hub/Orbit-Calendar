import Foundation
import Observation

enum AppSection: String, CaseIterable, Identifiable {
    case calendar = "Calendar"
    case booking = "Booking"
    case settings = "Settings"

    var id: String { rawValue }
}

enum AuthMode: String {
    case login
    case signup
}

enum AuthServiceState {
    case checking
    case ready
    case degraded(String)
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

struct AuthResponse: Codable {
    let token: String
    let user: UserProfile
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
    var authMode: AuthMode = .login
    var authEmail = ""
    var authPassword = ""
    var authDisplayName = ""
    var authTimezone = TimeZone.current.identifier
    var authToken: String?
    var authServiceState: AuthServiceState = .checking

    private let apiClient: APIClient
    private let authStorageKey = "orbit_auth_token"

    init(apiBaseURL: URL = URL(string: "http://localhost:8000")!) {
        self.apiBaseURL = apiBaseURL
        self.apiClient = APIClient(baseURL: apiBaseURL)
        self.authToken = UserDefaults.standard.string(forKey: authStorageKey)
    }

    func bootstrap() async {
        await refreshAuthServiceStatus()
        guard profile == nil, let token = authToken else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            async let me = apiClient.fetchMe(token: token)
            async let sync = apiClient.syncSampleCalendar(token: token)
            _ = try await sync
            profile = try await me
            try await refreshEvents(token: token)
            bookingPage = try await apiClient.fetchBookingPage(token: token)
        } catch {
            clearSession()
            errorMessage = error.localizedDescription
        }
    }

    func refreshAuthServiceStatus() async {
        authServiceState = .checking
        do {
            let status = try await apiClient.fetchAuthStatus()
            if status.databaseReady {
                authServiceState = .ready
            } else {
                authServiceState = .degraded("Orbit can reach the API, but the database is degraded.")
            }
        } catch {
            authServiceState = .degraded(error.localizedDescription)
        }
    }

    func refreshEvents(token: String? = nil) async throws {
        let resolvedToken = try requireToken(token)
        let calendar = Calendar.current
        let now = Date()
        let start = calendar.startOfDay(for: now)
        let end = calendar.date(byAdding: .day, value: 7, to: start) ?? now
        let response = try await apiClient.fetchEvents(start: start, end: end, token: resolvedToken)
        events = response.events.sorted(by: { $0.startsAt < $1.startsAt })
    }

    func runAgent() async {
        let text = agentInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await apiClient.queryAgent(text: text, token: try requireToken())
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
            try await apiClient.executeAction(
                toolName: pendingAction.toolName,
                arguments: pendingAction.arguments,
                token: try requireToken()
            )
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
            self.bookingPage = try await apiClient.updateBookingPage(bookingPage, token: try requireToken())
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func submitAuth() async {
        errorMessage = nil
        let trimmedEmail = authEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDisplayName = authDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTimezone = authTimezone.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedEmail.contains("@") else {
            errorMessage = "Enter a valid email address."
            return
        }

        guard authPassword.count >= 8 else {
            errorMessage = "Password must be at least 8 characters."
            return
        }

        if authMode == .signup {
            guard !trimmedDisplayName.isEmpty else {
                errorMessage = "Display name is required."
                return
            }

            guard !trimmedTimezone.isEmpty else {
                errorMessage = "Timezone is required."
                return
            }
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let response: AuthResponse
            switch authMode {
            case .login:
                response = try await apiClient.login(email: trimmedEmail, password: authPassword)
            case .signup:
                response = try await apiClient.signup(
                    email: trimmedEmail,
                    password: authPassword,
                    displayName: trimmedDisplayName,
                    defaultTimezone: trimmedTimezone
                )
            }

            authToken = response.token
            UserDefaults.standard.set(response.token, forKey: authStorageKey)
            profile = response.user
            authServiceState = .ready
            _ = try await apiClient.syncSampleCalendar(token: response.token)
            try await refreshEvents(token: response.token)
            bookingPage = try await apiClient.fetchBookingPage(token: response.token)
            authEmail = trimmedEmail
            authPassword = ""
        } catch {
            errorMessage = error.localizedDescription
            await refreshAuthServiceStatus()
        }
    }

    func logout() async {
        guard let token = authToken else { return }
        do {
            try await apiClient.logout(token: token)
        } catch {
            errorMessage = error.localizedDescription
        }
        clearSession()
    }

    private func clearSession() {
        authToken = nil
        profile = nil
        events = []
        bookingPage = nil
        latestAgentResponse = nil
        pendingAction = nil
        UserDefaults.standard.removeObject(forKey: authStorageKey)
    }

    private func requireToken(_ token: String? = nil) throws -> String {
        if let token {
            return token
        }
        if let authToken {
            return authToken
        }
        throw APIError.serverError("Please log in first.")
    }
}
