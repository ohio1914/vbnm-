import SwiftUI

struct SettingsView: View {
    @Environment(AppViewModel.self) private var vm
    @State private var keyInput = ""
    @State private var isSecure = true

    var body: some View {
        @Bindable var vm = vm
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Gratis Gemini API-nyckel")
                        .font(.headline)
                    Text("1. Gå till aistudio.google.com\n2. Logga in med Google\n3. Klicka \"Get API key\"\n4. Kopiera nyckeln och klistra in den här")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("Din API-nyckel") {
                HStack {
                    if isSecure {
                        SecureField("AIza...", text: $vm.apiKey)
                    } else {
                        TextField("AIza...", text: $vm.apiKey)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                    Button {
                        isSecure.toggle()
                    } label: {
                        Image(systemName: isSecure ? "eye" : "eye.slash")
                            .foregroundStyle(.secondary)
                    }
                }

                if !vm.apiKey.isEmpty {
                    Label("Nyckel sparad", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                }
            }

            Section {
                Button("Spara och börja") {
                    vm.screen = .search
                }
                .disabled(vm.apiKey.trimmingCharacters(in: .whitespaces).isEmpty)
                .frame(maxWidth: .infinity)
                .font(.headline)
            }
        }
        .navigationTitle("Inställningar")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !vm.apiKey.isEmpty {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Klar") { vm.screen = .search }
                }
            }
        }
    }
}
