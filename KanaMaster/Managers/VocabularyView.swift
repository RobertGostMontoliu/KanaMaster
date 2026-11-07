import SwiftUI

struct VocabularyView: View {
    private let repository = VocabularyRepository.shared
    @StateObject private var customGroupStore = VocabularyCustomGroupStore.shared
    @State private var showCreateGroupPrompt = false
    @State private var newGroupName = ""

    var body: some View {
        List {
            Section {
                ForEach(repository.levels(), id: \.self) { level in
                    NavigationLink {
                        VocabularyStudyGroupView(source: .level(level))
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(level)
                                    .font(.headline)
                                Text("Vocabulary level")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(repository.vocabulary(for: level).count)")
                                .font(.subheadline.bold())
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.15), in: Capsule())
                        }
                    }
                }
            } header: {
                Text("Vocabulary Levels")
            }

            Section {
                if customGroupStore.groups.isEmpty {
                    Text("No custom groups yet. Tap + to create one.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(customGroupStore.groups) { group in
                        NavigationLink {
                            VocabularyStudyGroupView(source: .custom(groupID: group.id))
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(group.name)
                                        .font(.headline)
                                    Text("Custom group")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("\(group.vocabularyWords.count)")
                                    .font(.subheadline.bold())
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.15), in: Capsule())
                            }
                        }
                    }
                    .onDelete(perform: deleteCustomGroups)
                }
            } header: {
                HStack {
                    Text("Custom Groups")
                    Spacer()
                    Button {
                        showCreateGroupPrompt = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle("Vocabulary")
        .navigationBarTitleDisplayMode(.inline)
        .alert("New Custom Group", isPresented: $showCreateGroupPrompt) {
            TextField("Group name", text: $newGroupName)
            Button("Create") {
                customGroupStore.createGroup(name: newGroupName)
                newGroupName = ""
            }
            Button("Cancel", role: .cancel) {
                newGroupName = ""
            }
        }
    }

    private func deleteCustomGroups(at offsets: IndexSet) {
        let ids = offsets.compactMap { customGroupStore.groups[safe: $0]?.id }
        for id in ids {
            customGroupStore.deleteGroup(id: id)
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    NavigationStack {
        VocabularyView()
    }
}
