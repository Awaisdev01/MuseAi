import SwiftUI

struct PromptLibraryView: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var library = PromptLibraryManager.shared
    @State private var searchText = ""
    @State private var selectedTag: String?
    @State private var showNewPrompt = false
    @State private var editingPrompt: PromptTemplate?

    var onSelect: (PromptTemplate) -> Void

    private var filteredPrompts: [PromptTemplate] {
        var results = library.prompts
        if let tag = selectedTag {
            results = results.filter { $0.tags.contains(tag) }
        }
        if !searchText.isEmpty {
            results = library.search(query: searchText)
        }
        return results
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                VStack(spacing: 0) {
                    TagBar
                    if filteredPrompts.isEmpty {
                        Spacer()
                        EmptyState
                        Spacer()
                    } else {
                        PromptList
                    }
                }
            }
            .navigationTitle("Prompt Library")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search prompts...")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showNewPrompt = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(DS.Gradients.accent)
                    }
                    .accessibilityLabel("Create new prompt template")
                }
            }
            .sheet(isPresented: $showNewPrompt) {
                PromptEditorSheet(template: nil) { template in
                    library.save(template)
                    HapticManager.success()
                }
            }
            .sheet(item: $editingPrompt) { template in
                PromptEditorSheet(template: template) { updated in
                    library.save(updated)
                    HapticManager.success()
                }
            }
        }
    }

    private var TagBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                TagChip(label: "All", isActive: selectedTag == nil) {
                    HapticManager.selectionChanged()
                    withAnimation { selectedTag = nil }
                }
                TagChip(label: "⭐ Most Used", isActive: selectedTag == "__mostused") {
                    HapticManager.selectionChanged()
                    withAnimation { selectedTag = "__mostused" }
                }
                ForEach(library.allTags, id: \.self) { tag in
                    TagChip(label: tag, isActive: selectedTag == tag) {
                        HapticManager.selectionChanged()
                        withAnimation { selectedTag = tag }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    private var PromptList: some View {
        let items = selectedTag == "__mostused" ? library.mostUsed : filteredPrompts
        return ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 12) {
                ForEach(items) { template in
                    PromptCard(template: template) {
                        HapticManager.impact()
                        library.incrementUsage(template)
                        onSelect(template)
                        dismiss()
                    } onEdit: {
                        editingPrompt = template
                    } onDelete: {
                        HapticManager.heavyImpact()
                        library.delete(template)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
        }
    }

    private var EmptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "bookmark.slash")
                .font(.system(size: 40, weight: .light))
                .foregroundColor(.secondary)
            Text("No Prompts Found")
                .font(.headline).foregroundColor(Color(.label))
            Text("Create templates to reuse your best prompts.")
                .font(.subheadline).foregroundColor(.secondary)
        }
    }
}

// MARK: - Prompt Card
private struct PromptCard: View {
    let template: PromptTemplate
    let onSelect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(template.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color(.label))
                    Spacer()
                    if template.usageCount > 0 {
                        Text("Used \(template.usageCount)x")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Text(template.prompt)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(3)

                if !template.tags.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(template.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .foregroundColor(.purple)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(DS.Colors.accent.opacity(0.15)))
                        }
                    }
                }

                HStack(spacing: 16) {
                    Spacer()
                    Button { onEdit() } label: {
                        Image(systemName: "pencil")
                            .font(.caption).foregroundColor(.secondary)
                    }
                    Button { onDelete() } label: {
                        Image(systemName: "trash")
                            .font(.caption).foregroundColor(.red.opacity(0.6))
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.tertiarySystemBackground))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(template.title): \(template.prompt)")
        .accessibilityHint("Double tap to use this prompt")
    }
}

// MARK: - Tag Chip
private struct TagChip: View {
    let label: String; let isActive: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundColor(isActive ? .white : .secondary)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(
                    Capsule().fill(isActive ? DS.Colors.accent.opacity(0.3) : Color(.tertiarySystemBackground))
                        .overlay(Capsule().strokeBorder(isActive ? DS.Colors.accent.opacity(0.5) : Color.clear, lineWidth: 1))
                )
        }.buttonStyle(.plain)
    }
}

// MARK: - Prompt Editor Sheet
struct PromptEditorSheet: View {
    let template: PromptTemplate?
    let onSave: (PromptTemplate) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var prompt = ""
    @State private var negativePrompt = ""
    @State private var tagsText = ""
    @State private var styleName = "None"

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        FieldGroup(label: "Title") {
                            TextField("My awesome prompt", text: $title)
                        }
                        FieldGroup(label: "Prompt") {
                            TextField("Describe the image...", text: $prompt, axis: .vertical)
                                .lineLimit(3...8)
                        }
                        FieldGroup(label: "Negative Prompt (optional)") {
                            TextField("Things to avoid...", text: $negativePrompt, axis: .vertical)
                                .lineLimit(2...4)
                        }
                        FieldGroup(label: "Tags (comma separated)") {
                            TextField("landscape, fantasy, detailed", text: $tagsText)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle(template == nil ? "New Prompt" : "Edit Prompt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .disabled(title.isEmpty || prompt.isEmpty)
                        .fontWeight(.semibold)
                }
            }
            .onAppear {
                if let t = template {
                    title = t.title
                    prompt = t.prompt
                    negativePrompt = t.negativePrompt
                    tagsText = t.tags.joined(separator: ", ")
                    styleName = t.styleName
                }
            }
        }
    }

    private func save() {
        let tags = tagsText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        var updated = template ?? PromptTemplate(title: title, prompt: prompt)
        updated.title = title
        updated.prompt = prompt
        updated.negativePrompt = negativePrompt
        updated.tags = tags
        updated.styleName = styleName
        onSave(updated)
        dismiss()
    }
}

private struct FieldGroup<Content: View>: View {
    let label: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label).font(.caption.weight(.semibold)).foregroundColor(.secondary)
            content
                .font(.body).foregroundColor(Color(.label))
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.tertiarySystemBackground))
                )
                .tint(DS.Colors.accent)
        }
    }
}
