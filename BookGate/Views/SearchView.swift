import SwiftUI

// MARK: - Search View

struct SearchView: View {
    @Environment(AppViewModel.self) private var vm

    var body: some View {
        @Bindable var vm = vm
        Group {
            if let book = vm.selectedBook {
                BookDetailView(book: book)
            } else {
                bookSearchContent
            }
        }
        .navigationTitle("📚 BookGate")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    vm.screen = .settings
                } label: {
                    Image(systemName: "gearshape")
                }
            }
        }
    }

    @ViewBuilder
    private var bookSearchContent: some View {
        @Bindable var vm = vm
        VStack(spacing: 0) {
            // Language picker
            Picker("Språk", selection: $vm.searchLanguage) {
                Text("Svenska 🇸🇪").tag("sv")
                Text("Engelska 🇬🇧").tag("en")
                Text("Alla").tag("")
            }
            .pickerStyle(.segmented)
            .padding()

            if vm.searchResults.isEmpty && !vm.isSearching {
                emptyState
            } else {
                bookList
            }
        }
        .searchable(text: $vm.searchQuery, prompt: "Sök efter en bok...")
        .onSubmit(of: .search) {
            Task { await vm.search() }
        }
        .overlay {
            if vm.isSearching {
                ProgressView("Söker böcker...")
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .alert("Fel", isPresented: .constant(vm.searchError != nil)) {
            Button("OK") { vm.searchError = nil }
        } message: {
            Text(vm.searchError ?? "")
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Sök en bok", systemImage: "magnifyingglass")
        } description: {
            Text("Skriv titeln eller författarens namn\noch tryck på Sök.")
        }
    }

    private var bookList: some View {
        @Bindable var vm = vm
        return List(vm.searchResults) { book in
            BookRow(book: book)
                .contentShape(Rectangle())
                .onTapGesture {
                    vm.selectedBook = book
                }
        }
        .listStyle(.plain)
    }
}

// MARK: - Book Row

struct BookRow: View {
    let book: BookItem

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: book.coverURL) { image in
                image.resizable().scaledToFit()
            } placeholder: {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.secondary.opacity(0.2))
                    .overlay(Image(systemName: "book.closed").foregroundStyle(.secondary))
            }
            .frame(width: 50, height: 70)
            .clipShape(RoundedRectangle(cornerRadius: 4))

            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.headline)
                    .lineLimit(2)
                Text(book.authors)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                if book.pageCount > 0 {
                    Text("\(book.pageCount) sidor")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
                .font(.caption)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Book Detail View

struct BookDetailView: View {
    @Environment(AppViewModel.self) private var vm
    let book: BookItem

    var body: some View {
        @Bindable var vm = vm
        ScrollView {
            VStack(spacing: 20) {
                // Cover
                AsyncImage(url: book.coverURL) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.2))
                        .overlay(Image(systemName: "book.closed.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary))
                }
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(radius: 4)

                VStack(spacing: 4) {
                    Text(book.title)
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                    Text(book.authors)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Page range input
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Vilka sidor har du läst?", systemImage: "book.pages")
                            .font(.headline)

                        HStack(spacing: 12) {
                            VStack(alignment: .leading) {
                                Text("Från sida").font(.caption).foregroundStyle(.secondary)
                                TextField("t.ex. 1", text: $vm.fromPageText)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(.roundedBorder)
                            }
                            Text("–").font(.title2)
                            VStack(alignment: .leading) {
                                Text("Till sida").font(.caption).foregroundStyle(.secondary)
                                TextField("t.ex. 50", text: $vm.toPageText)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }

                        if !vm.fromPageText.isEmpty && !vm.toPageText.isEmpty && !vm.pageInputValid {
                            Label("Sidorna ser konstiga ut. Kontrollera dem.", systemImage: "exclamationmark.triangle")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                }
                .padding(.horizontal)

                // Generate button
                Button {
                    Task { await vm.generateQuiz(for: book) }
                } label: {
                    Group {
                        if vm.isGeneratingQuiz {
                            HStack {
                                ProgressView().tint(.white)
                                Text("Skapar quiz...").bold()
                            }
                        } else {
                            Label("Starta quiz", systemImage: "brain.head.profile")
                                .bold()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(vm.pageInputValid ? Color.accentColor : Color.gray)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!vm.pageInputValid || vm.isGeneratingQuiz)
                .padding(.horizontal)

                if let error = vm.quizError {
                    Label(error, systemImage: "exclamationmark.circle")
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Description
                if !book.description.isEmpty {
                    GroupBox("Om boken") {
                        Text(book.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Välj sidor")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Tillbaka") {
                    vm.selectedBook = nil
                    vm.fromPageText = ""
                    vm.toPageText   = ""
                    vm.quizError    = nil
                }
            }
        }
    }
}
