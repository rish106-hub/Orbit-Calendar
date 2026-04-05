import Foundation

@Observable
final class AppState {
    let apiBaseURL: URL

    init(apiBaseURL: URL = URL(string: "http://localhost:8000")!) {
        self.apiBaseURL = apiBaseURL
    }
}

