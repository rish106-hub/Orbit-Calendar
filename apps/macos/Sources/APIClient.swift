import Foundation

enum APIError: Error, LocalizedError {
    case invalidResponse
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "The server response was invalid."
        case .serverError(let message):
            return message
        }
    }
}

struct APIClient {
    let baseURL: URL
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(baseURL: URL) {
        self.baseURL = baseURL
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
    }

    func fetchMe() async throws -> UserProfile {
        try await request(path: "/api/me", method: "GET")
    }

    func syncSampleCalendar() async throws -> SyncResponse {
        let calendar = Calendar.current
        let now = Date()
        let start = calendar.startOfDay(for: now)
        let end = calendar.date(byAdding: .day, value: 7, to: start) ?? now
        let body = [
            "start": isoString(start),
            "end": isoString(end),
        ]
        return try await request(path: "/api/calendar/sync", method: "POST", body: SyncRequestBody(start: body["start"]!, end: body["end"]!))
    }

    func fetchEvents(start: Date, end: Date) async throws -> CalendarEventsResponse {
        var components = URLComponents(url: baseURL.appending(path: "/api/calendar/events"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "start", value: isoString(start)),
            URLQueryItem(name: "end", value: isoString(end)),
        ]
        guard let url = components?.url else {
            throw APIError.invalidResponse
        }
        return try await request(url: url, method: "GET")
    }

    func queryAgent(text: String) async throws -> AgentResponse {
        try await request(path: "/api/agent/query", method: "POST", body: AgentQueryBody(text: text))
    }

    func executeAction(toolName: String, arguments: [String: String]) async throws {
        let _: EmptyResponse = try await request(
            path: "/api/agent/execute",
            method: "POST",
            body: ExecuteActionBody(toolName: toolName, arguments: arguments)
        )
    }

    func fetchBookingPage() async throws -> BookingPage {
        try await request(path: "/api/booking-page", method: "GET")
    }

    func updateBookingPage(_ bookingPage: BookingPage) async throws -> BookingPage {
        try await request(
            path: "/api/booking-page",
            method: "PUT",
            body: BookingPageUpdateBody(
                slug: bookingPage.slug,
                title: bookingPage.title,
                active: bookingPage.active,
                defaultDurationMinutes: bookingPage.defaultDurationMinutes,
                workingDays: bookingPage.workingDays,
                dayStartLocal: bookingPage.dayStartLocal,
                dayEndLocal: bookingPage.dayEndLocal,
                bufferBeforeMinutes: bookingPage.bufferBeforeMinutes,
                bufferAfterMinutes: bookingPage.bufferAfterMinutes,
                minimumNoticeMinutes: bookingPage.minimumNoticeMinutes
            )
        )
    }

    private func request<T: Decodable>(path: String, method: String) async throws -> T {
        try await request(url: baseURL.appending(path: path), method: method)
    }

    private func request<T: Decodable, Body: Encodable>(path: String, method: String, body: Body? = nil) async throws -> T {
        try await request(url: baseURL.appending(path: path), method: method, body: body)
    }

    private func request<T: Decodable>(url: URL, method: String) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Request failed."
            throw APIError.serverError(message)
        }

        return try decoder.decode(T.self, from: data)
    }

    private func request<T: Decodable, Body: Encodable>(url: URL, method: String, body: Body? = nil) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body {
            request.httpBody = try encoder.encode(body)
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Request failed."
            throw APIError.serverError(message)
        }

        if T.self == EmptyResponse.self {
            return EmptyResponse() as! T
        }

        return try decoder.decode(T.self, from: data)
    }

    private func isoString(_ date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }
}

struct EmptyResponse: Decodable {}

private struct SyncRequestBody: Encodable {
    let start: String
    let end: String
}

private struct AgentQueryBody: Encodable {
    let text: String
}

private struct ExecuteActionBody: Encodable {
    let toolName: String
    let arguments: [String: String]

    private enum CodingKeys: String, CodingKey {
        case toolName = "tool_name"
        case arguments
    }
}

private struct BookingPageUpdateBody: Encodable {
    let slug: String
    let title: String
    let active: Bool
    let defaultDurationMinutes: Int
    let workingDays: [Int]
    let dayStartLocal: String
    let dayEndLocal: String
    let bufferBeforeMinutes: Int
    let bufferAfterMinutes: Int
    let minimumNoticeMinutes: Int

    private enum CodingKeys: String, CodingKey {
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
