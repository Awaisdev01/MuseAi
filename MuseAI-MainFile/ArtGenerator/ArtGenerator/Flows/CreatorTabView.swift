import SwiftUI
import PhotosUI

struct CreatorTabView: View {

    @EnvironmentObject var manager: DataManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var cs
    @State private var showPaywall = false
    @State private var showPromptLibrary = false
    @State private var showDiscover = false
    @State private var showConfetti = false
    @State private var showStylePicker = false
    @State private var showAdvanced = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @AppStorage("totalGenerationsForReview") private var totalGens: Int = 0
    @FocusState private var isPromptFocused: Bool

    private var bg: Color { cs == .dark ? DS.Colors.bgBase : Color(.systemBackground) }
    private var card: Color { cs == .dark ? DS.Colors.surface : Color(.secondarySystemBackground) }
    private var txt1: Color { cs == .dark ? DS.Colors.textPrimary : Color(.label) }
    private var txt2: Color { cs == .dark ? DS.Colors.textSecondary : Color(.secondaryLabel) }
    private var txt3: Color { cs == .dark ? DS.Colors.textTertiary : Color(.tertiaryLabel) }
    private var brd: Color { cs == .dark ? DS.Colors.border : Color(.separator) }

    var body: some View {
        NavigationStack {
            ZStack {
                bg.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Scrollable content
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: DS.Spacing.xl) {
                            if !manager.network.isConnected { OfflineBanner }

                            if let image = manager.generatedImage {
                                ResultSection(image: image)
                            } else {
                                PromptArea
                            }
                        }
                        .padding(.horizontal, DS.Spacing.xl)
                        .padding(.top, DS.Spacing.md)
                        .padding(.bottom, 140)
                    }
                    .scrollDismissesKeyboard(.interactively)
                }

                // STICKY BOTTOM BAR — always visible
                VStack {
                    Spacer()
                    BottomBar
                }

                if manager.isGenerating { GeneratingOverlay }
                ConfettiView(isActive: $showConfetti)
            }
            .navigationTitle("Create")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button { HapticManager.tap(); showDiscover = true } label: {
                        Image(systemName: "globe.americas.fill").font(.system(size: 17))
                    }
                    Button { HapticManager.tap(); showPromptLibrary = true } label: {
                        Image(systemName: "book.pages.fill").font(.system(size: 17))
                    }
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView().environmentObject(manager) }
            .sheet(isPresented: $showPromptLibrary) {
                PromptLibraryView { t in manager.promptText = t.prompt }
            }
            .sheet(isPresented: $showDiscover) { DiscoverView().environmentObject(manager) }
            .onChange(of: selectedPhotoItem) { _ in
                Task {
                    if let data = try? await selectedPhotoItem?.loadTransferable(type: Data.self),
                       let img = UIImage(data: data) { manager.sourceImage = img }
                }
            }
        }
    }

    // MARK: - Prompt Area (Before Generation)
    private var PromptArea: some View {
        VStack(spacing: DS.Spacing.lg) {
            // Reference image (compact)
            if let src = manager.sourceImage {
                HStack {
                    Image(uiImage: src).resizable().aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60).clipped()
                        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.small, style: .continuous))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Reference Image").font(DS.Typography.caption1.weight(.semibold)).foregroundColor(txt2)
                        Text("AI will transform this").font(DS.Typography.caption2).foregroundColor(txt3)
                    }
                    Spacer()
                    Button { manager.sourceImage = nil } label: {
                        Image(systemName: "xmark.circle.fill").foregroundColor(txt3)
                    }
                }
                .padding(DS.Spacing.md)
                .background(RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous).fill(card))
            }

            // Main prompt input
            VStack(spacing: DS.Spacing.sm) {
                TextField("Describe your image...", text: $manager.promptText, axis: .vertical)
                    .font(DS.Typography.body).foregroundColor(txt1)
                    .lineLimit(3...8).focused($isPromptFocused)
                    .padding(DS.Spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: DS.Radius.large, style: .continuous).fill(card)
                            .overlay(RoundedRectangle(cornerRadius: DS.Radius.large, style: .continuous)
                                .strokeBorder(isPromptFocused ? DS.Colors.accent.opacity(0.5) : brd, lineWidth: 1))
                    )
                    .tint(DS.Colors.accent)

                // Style chip (inline, compact)
                HStack(spacing: DS.Spacing.sm) {
                    Button { withAnimation { showStylePicker.toggle() } } label: {
                        HStack(spacing: 5) {
                            Image(systemName: manager.selectedStyle.icon).font(.system(size: 12))
                            Text(manager.selectedStyle.name).font(DS.Typography.caption1.weight(.medium))
                            Image(systemName: "chevron.down").font(.system(size: 9))
                        }
                        .foregroundColor(manager.selectedStyle.id != "none" ? DS.Colors.accent : txt2)
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .background(Capsule().fill(manager.selectedStyle.id != "none" ? DS.Colors.accent.opacity(0.12) : card))
                    }
                    .buttonStyle(PressableStyle())

                    Button {
                        HapticManager.selectionChanged()
                        let sizes = manager.generationSettings.model.supportedSizes
                        if let i = sizes.firstIndex(of: manager.generationSettings.size) {
                            manager.generationSettings.size = sizes[(i + 1) % sizes.count]
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: manager.generationSettings.size.icon).font(.system(size: 12))
                            Text(manager.generationSettings.size.displayName).font(DS.Typography.caption1.weight(.medium))
                        }
                        .foregroundColor(txt2)
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .background(Capsule().fill(card))
                    }
                    .buttonStyle(PressableStyle())

                    Button {
                        HapticManager.selectionChanged()
                        let q = ImageQuality.allCases
                        if let i = q.firstIndex(of: manager.generationSettings.quality) {
                            manager.generationSettings.quality = q[(i + 1) % q.count]
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "sparkle").font(.system(size: 12))
                            Text(manager.generationSettings.quality.displayName).font(DS.Typography.caption1.weight(.medium))
                        }
                        .foregroundColor(txt2)
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .background(Capsule().fill(card))
                    }
                    .buttonStyle(PressableStyle())

                    Spacer()

                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Image(systemName: "photo.badge.plus").font(.system(size: 16)).foregroundColor(txt2)
                    }
                }
            }

            // Style picker (expandable)
            if showStylePicker {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DS.Spacing.sm) {
                        StylePill(style: .none, isSelected: manager.selectedStyle == .none, cs: cs) {
                            HapticManager.selectionChanged()
                            withAnimation(DS.Motion.quick) { manager.selectedStyle = .none }
                        }
                        ForEach(ArtStylePreset.allStyles) { style in
                            let locked = !manager.isPremium && !isFreeTierStyle(style)
                            StylePill(style: style, isSelected: manager.selectedStyle == style, isLocked: locked, cs: cs) {
                                if locked { HapticManager.warning(); showPaywall = true }
                                else { HapticManager.selectionChanged(); withAnimation(DS.Motion.quick) { manager.selectedStyle = style } }
                            }
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Suggestions (compact)
            if manager.promptText.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DS.Spacing.sm) {
                        ForEach(quickIdeas, id: \.self) { idea in
                            Button { HapticManager.tap(); manager.promptText = idea } label: {
                                Text(idea).font(DS.Typography.caption2).foregroundColor(txt2).lineLimit(1)
                                    .padding(.horizontal, 12).padding(.vertical, 7)
                                    .background(Capsule().fill(DS.Colors.accent.opacity(0.06)))
                            }
                            .buttonStyle(PressableStyle())
                        }
                    }
                }
            }

            // Recent prompts
            if !manager.recentPrompts.isEmpty && manager.promptText.isEmpty {
                VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                    Text("Recent").font(DS.Typography.caption1.weight(.semibold)).foregroundColor(txt3)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DS.Spacing.sm) {
                            ForEach(manager.recentPrompts.prefix(5), id: \.self) { p in
                                Button { HapticManager.tap(); manager.promptText = p } label: {
                                    Text(p).font(DS.Typography.caption2).foregroundColor(txt2).lineLimit(1)
                                        .padding(.horizontal, 12).padding(.vertical, 7)
                                        .background(Capsule().fill(card))
                                }
                                .buttonStyle(PressableStyle())
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Result (After Generation)
    private func ResultSection(image: UIImage) -> some View {
        VStack(spacing: DS.Spacing.lg) {
            Image(uiImage: image)
                .resizable().aspectRatio(contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.xxl, style: .continuous))
                .shadow(color: DS.Colors.accent.opacity(0.2), radius: 20, y: 10)
                .transition(reduceMotion ? .opacity : .scale(scale: 0.95).combined(with: .opacity))

            // Quick actions
            HStack(spacing: DS.Spacing.md) {
                ActionPill(icon: "square.and.arrow.down", label: "Save") { manager.saveToPhotos() }
                ActionPill(icon: "square.and.arrow.up", label: "Share") {
                    guard let s = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                          let r = s.windows.first?.rootViewController else { return }
                    r.present(UIActivityViewController(activityItems: [image], applicationActivities: nil), animated: true)
                }
                ActionPill(icon: "arrow.triangle.2.circlepath", label: "Redo") {
                    Task { await manager.generateArt() }
                }
                ActionPill(icon: "plus.circle", label: "New") {
                    withAnimation(DS.Motion.standard) { manager.clearGeneration() }
                }
            }

            if let enhanced = manager.enhancedPrompt {
                Text(enhanced).font(DS.Typography.caption1).foregroundColor(txt3).lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(DS.Spacing.md)
                    .background(RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous).fill(card))
            }
        }
    }

    // MARK: - Sticky Bottom Bar
    private var BottomBar: some View {
        VStack(spacing: DS.Spacing.sm) {
            if !manager.isPremium && manager.generatedImage == nil {
                Text("\(manager.remainingFreeGenerations) free today")
                    .font(DS.Typography.caption2).foregroundColor(txt3)
            }

            Button {
                isPromptFocused = false
                if !manager.canGenerate && !manager.isPremium { HapticManager.warning(); showPaywall = true; return }
                Task {
                    await manager.generateArt()
                    if manager.generatedImage != nil { showConfetti = true; SoundManager.play(.success) }
                    if !manager.isPremium && totalGens >= AppConfig.paywallAfterGenerations {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { showPaywall = true }
                    }
                }
            } label: {
                HStack(spacing: DS.Spacing.sm) {
                    if manager.isGenerating {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "sparkles")
                        Text("Generate")
                    }
                }
                .font(DS.Typography.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity).frame(height: 54)
                .background(DS.Gradients.accent.opacity(canGenerate ? 1.0 : 0.4))
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.large, style: .continuous))
                .shadow(color: DS.Colors.accent.opacity(canGenerate ? 0.3 : 0), radius: 12, y: 6)
            }
            .buttonStyle(PressableStyle())
            .disabled(!canGenerate || manager.isGenerating)
        }
        .padding(.horizontal, DS.Spacing.xl)
        .padding(.top, DS.Spacing.md)
        .padding(.bottom, 100)
        .background(
            LinearGradient(colors: [bg.opacity(0), bg, bg], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private var canGenerate: Bool {
        !manager.promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || manager.sourceImage != nil
    }

    // MARK: - Offline
    private var OfflineBanner: some View {
        HStack(spacing: DS.Spacing.sm) {
            Image(systemName: "wifi.slash").font(.caption.weight(.semibold))
            Text("No Internet").font(DS.Typography.caption1.weight(.medium))
        }
        .foregroundColor(.white).frame(maxWidth: .infinity)
        .padding(.vertical, 8).background(DS.Colors.error.opacity(0.9), in: RoundedRectangle(cornerRadius: DS.Radius.small))
    }

    // MARK: - Generating Overlay
    private var GeneratingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea().transition(.opacity)
            VStack(spacing: DS.Spacing.xxl) {
                GenerationTimerView(settings: manager.generationSettings)
                VStack(spacing: DS.Spacing.xs) {
                    Text(manager.generationProgress).font(DS.Typography.headline).foregroundColor(DS.Colors.textPrimary)
                    Text("AI is painting your vision").font(DS.Typography.caption1).foregroundColor(DS.Colors.textTertiary)
                }
            }
            .padding(DS.Spacing.xxxl)
            .glassCard(cornerRadius: DS.Radius.xxl)
            .transition(.scale(scale: 0.92).combined(with: .opacity))
        }
        .animation(DS.Motion.standard, value: manager.isGenerating)
    }

    private func isFreeTierStyle(_ style: ArtStylePreset) -> Bool {
        guard let idx = ArtStylePreset.allStyles.firstIndex(where: { $0.id == style.id }) else { return false }
        return idx < AppConfig.freeStyleCount
    }

    private let quickIdeas = [
        "Japanese garden at sunset with cherry blossoms",
        "Astronaut riding a horse on Mars",
        "Cozy coffee shop on a rainy night",
        "Underwater city with glowing buildings",
        "Fox wearing a crown on a throne",
        "Northern lights over a snowy cabin"
    ]
}

// MARK: - Style Pill
private struct StylePill: View {
    let style: ArtStylePreset; let isSelected: Bool; var isLocked: Bool = false; let cs: ColorScheme; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: style.icon).font(.caption)
                Text(style.name).font(DS.Typography.caption1.weight(.medium))
                if isLocked { Image(systemName: "lock.fill").font(.system(size: 8)) }
            }
            .foregroundColor(isSelected ? .white : (cs == .dark ? DS.Colors.textSecondary : Color(.secondaryLabel)))
            .padding(.horizontal, 14).padding(.vertical, 9)
            .background(Capsule().fill(isSelected ? style.color.opacity(0.35) : (cs == .dark ? DS.Colors.surface : Color(.tertiarySystemBackground))))
            .overlay(Capsule().strokeBorder(isSelected ? style.color.opacity(0.6) : Color.clear, lineWidth: 1))
        }.buttonStyle(PressableStyle())
    }
}

// MARK: - Action Pill
private struct ActionPill: View {
    let icon: String; let label: String; let action: () -> Void
    @Environment(\.colorScheme) private var cs
    var body: some View {
        Button(action: { HapticManager.tap(); action() }) {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 16))
                Text(label).font(DS.Typography.caption2.weight(.medium))
            }
            .foregroundColor(cs == .dark ? DS.Colors.textPrimary.opacity(0.8) : Color(.label))
            .frame(maxWidth: .infinity).frame(height: 54)
            .background(RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous)
                .fill(cs == .dark ? DS.Colors.surface : Color(.secondarySystemBackground)))
        }.buttonStyle(PressableStyle())
    }
}

#Preview { CreatorTabView().environmentObject(DataManager()) }
