import SwiftUI

struct RootView: View {
    @Environment(AppViewModel.self) private var vm

    var body: some View {
        @Bindable var vm = vm
        NavigationStack {
            switch vm.screen {
            case .settings:
                SettingsView()
            case .search, .bookDetail:
                SearchView()
            case .quiz(let quiz):
                QuizView(quiz: quiz)
            case .result(let result):
                ResultView(result: result)
            }
        }
        .onAppear {
            // Prompt settings if no API key
            if vm.apiKey.isEmpty {
                vm.screen = .settings
            }
        }
    }
}
