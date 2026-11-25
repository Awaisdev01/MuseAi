import SwiftUI

struct HomeTabView: View {

    @EnvironmentObject var manager: DataManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var animateHero = false
    @State private var selectedAsset: AssetModel?

    private var categories: [String] {
        Array(Set(AppConfig.inspirationAssets.map(\.category))).sorted().filter { !$0.isEmpty }
    }

    private var bgColor: some View {
        Group {
            if colorScheme == .dark {
                DS.Gradients.background.ignoresSafeArea()
            } else {
                Color(.systemBackground).ignoresSafeArea()
            }
        }
    }

    private var textPrimary: Color { colorScheme == .dark ? DS.Colors.textPrimary : Color(.label) }
    private var textSecondary: Color { colorScheme == .dark ? DS.Colors.textSecondary : Color(.secondaryLabel) }
    private var textTertiary: Color { colorScheme == .dark ? DS.Colors.textTertiary : Color(.tertiaryLabel) }
    private var cardBg: Color { colorScheme == .dark ? DS.Colors.surface : Color(.secondarySystemBackground) }

    var body: some View {
        NavigationStack {
            ZStack {
                bgColor

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: DS.Spacing.xxxl) {
                        HeroBanner
                        QuickStartSection
                        FeaturedCarousel
                        ForEach(categories, id: \.self) { category in
                            CategorySection(category: category)
                        }
                        Spacer(minLength: 120)
                    }
                    .padding(.top, DS.Spacing.sm)
                }
            }
            .navigationTitle("Explore")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                withAnimation(.easeOut(duration: 0.7).delay(0.15)) { animateHero = true }
            }
            .sheet(item: $selectedAsset) { asset in
                InspirationDetailSheet(asset: asset) {
                    manager.useInspirationPrompt(asset.imageText)
                    selectedAsset = nil
                }
            }
        }
    }

    // MARK: - Hero
    private var HeroBanner: some View {
        ZStack {
            RoundedRectangle(cornerRadius: DS.Radius.xxl, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [DS.Colors.accent.opacity(0.18), DS.Colors.accent.opacity(0.1), Color.clear],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .overlay(RoundedRectangle(cornerRadius: DS.Radius.xxl, style: .continuous).strokeBorder(colorScheme == .dark ? DS.Colors.border : Color(.separator), lineWidth: 1))

            HStack(spacing: DS.Spacing.xl) {
                VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                    Text("What will Muse AI\ncreate today?")
                        .font(DS.Typography.title2)
                        .foregroundColor(textPrimary)
                    Text("Tap any image for prompt details")
                        .font(DS.Typography.subheadline)
                        .foregroundColor(textSecondary)
                }
                Spacer()
                Image(systemName: "sparkles")
                    .font(.system(size: 48, weight: .ultraLight))
                    .foregroundStyle(DS.Gradients.accent)
                    .opacity(animateHero ? 1 : 0)
                    .scaleEffect(animateHero ? 1 : 0.6)
            }
            .padding(DS.Spacing.xxl)
        }
        .frame(height: 150)
        .padding(.horizontal, DS.Spacing.xl)
    }

    // MARK: - Quick Start
    private var QuickStartSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            SectionHeader(title: "Quick Start", color: textPrimary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DS.Spacing.sm) {
                    QuickChip(icon: "sparkles", label: "Fantasy", color: .purple, cs: colorScheme) {
                        manager.useInspirationPrompt("Magical fantasy world with floating islands, waterfalls, and aurora borealis, epic landscape, 8k detail")
                    }
                    QuickChip(icon: "camera.fill", label: "Portrait", color: .blue, cs: colorScheme) {
                        manager.useInspirationPrompt("Professional studio portrait with dramatic rim lighting, shallow depth of field, clean dark background")
                    }
                    QuickChip(icon: "leaf.fill", label: "Nature", color: .green, cs: colorScheme) {
                        manager.useInspirationPrompt("Breathtaking mountain landscape at golden hour with wildflowers, crystal lake reflection, dramatic clouds")
                    }
                    QuickChip(icon: "star.fill", label: "Anime", color: .pink, cs: colorScheme) {
                        manager.useInspirationPrompt("Beautiful anime character in cherry blossom garden, Studio Ghibli style, vibrant colors, detailed illustration")
                    }
                    QuickChip(icon: "building.2.fill", label: "Sci-Fi", color: .cyan, cs: colorScheme) {
                        manager.useInspirationPrompt("Futuristic cyberpunk city at night with neon lights, rain-soaked streets, flying vehicles, cinematic")
                    }
                }
                .padding(.horizontal, DS.Spacing.xl)
            }
        }
    }

    // MARK: - Featured
    private var FeaturedCarousel: some View {
        let assets = AppConfig.inspirationAssets.filter(\.isHorizontal)
        return VStack(alignment: .leading, spacing: DS.Spacing.md) {
            SectionHeader(title: "Featured", color: textPrimary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DS.Spacing.lg) {
                    ForEach(assets) { asset in
                        FeaturedCard(asset: asset, cs: colorScheme) {
                            HapticManager.tap()
                            selectedAsset = asset
                        }
                    }
                }
                .padding(.horizontal, DS.Spacing.xl)
            }
        }
    }

    // MARK: - Category
    private func CategorySection(category: String) -> some View {
        let assets = AppConfig.inspirationAssets.filter { $0.category == category }
        return VStack(alignment: .leading, spacing: DS.Spacing.md) {
            SectionHeader(title: category, color: textPrimary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DS.Spacing.md) {
                    ForEach(assets) { asset in
                        InspirationCard(asset: asset, cs: colorScheme) {
                            HapticManager.tap()
                            selectedAsset = asset
                        }
                    }
                }
                .padding(.horizontal, DS.Spacing.xl)
            }
        }
    }
}

// MARK: - Inspiration Detail Sheet
struct InspirationDetailSheet: View {
    let asset: AssetModel
    let onUsePrompt: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var cs
    @State private var copied = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: DS.Spacing.xxl) {
                    if let image = UIImage(named: asset.imageName) {
                        Image(uiImage: image)
                            .resizable().aspectRatio(contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.xl, style: .continuous))
                    }

                    VStack(alignment: .leading, spacing: DS.Spacing.lg) {
                        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                            Text("Prompt")
                                .font(DS.Typography.caption1.weight(.semibold))
                                .foregroundColor(cs == .dark ? DS.Colors.textSecondary : Color(.secondaryLabel))
                            Text(asset.imageText)
                                .font(DS.Typography.body)
                                .foregroundColor(cs == .dark ? DS.Colors.textPrimary : Color(.label))
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        HStack(spacing: DS.Spacing.sm) {
                            if !asset.category.isEmpty {
                                Label(asset.category, systemImage: "tag.fill")
                                    .font(DS.Typography.caption1)
                                    .foregroundColor(DS.Colors.accent)
                                    .padding(.horizontal, 10).padding(.vertical, 5)
                                    .background(DS.Colors.accent.opacity(0.1), in: Capsule())
                            }
                        }
                    }
                    .padding(.horizontal, DS.Spacing.xl)

                    VStack(spacing: DS.Spacing.md) {
                        Button {
                            HapticManager.impact()
                            onUsePrompt()
                            dismiss()
                        } label: {
                            HStack(spacing: DS.Spacing.sm) {
                                Image(systemName: "wand.and.stars")
                                Text("Use This Prompt")
                            }
                            .accentButtonStyle()
                        }
                        .buttonStyle(PressableStyle())

                        Button {
                            UIPasteboard.general.string = asset.imageText
                            HapticManager.success()
                            withAnimation { copied = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation { copied = false }
                            }
                        } label: {
                            HStack(spacing: DS.Spacing.sm) {
                                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                                Text(copied ? "Copied!" : "Copy Prompt")
                            }
                            .font(DS.Typography.headline)
                            .foregroundColor(cs == .dark ? DS.Colors.textPrimary : Color(.label))
                            .frame(maxWidth: .infinity).frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: DS.Radius.large, style: .continuous)
                                    .fill(cs == .dark ? DS.Colors.surface : Color(.tertiarySystemBackground))
                            )
                        }
                        .buttonStyle(PressableStyle())
                    }
                    .padding(.horizontal, DS.Spacing.xl)
                }
                .padding(.top, DS.Spacing.lg)
                .padding(.bottom, DS.Spacing.section)
            }
            .background((cs == .dark ? AnyView(DS.Gradients.background) : AnyView(Color(.systemBackground))).ignoresSafeArea())
            .navigationTitle("Inspiration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Subviews
private struct SectionHeader: View {
    let title: String; let color: Color
    var body: some View {
        Text(title).font(DS.Typography.title3).foregroundColor(color).padding(.horizontal, DS.Spacing.xl)
    }
}

private struct QuickChip: View {
    let icon: String; let label: String; let color: Color; let cs: ColorScheme; let action: () -> Void
    var body: some View {
        Button { HapticManager.tap(); action() } label: {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.caption).foregroundColor(color)
                Text(label).font(DS.Typography.caption1.weight(.semibold)).foregroundColor(cs == .dark ? DS.Colors.textPrimary : Color(.label))
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(color.opacity(0.25), lineWidth: 1))
        }.buttonStyle(PressableStyle())
    }
}

private struct FeaturedCard: View {
    let asset: AssetModel; let cs: ColorScheme; let onTap: () -> Void
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Image area — fixed size, clipped
                ZStack(alignment: .bottomLeading) {
                    Group {
                        if let image = UIImage(named: asset.imageName) {
                            Image(uiImage: image).resizable().aspectRatio(contentMode: .fill)
                        } else {
                            Color(cs == .dark ? .secondarySystemBackground : .tertiarySystemBackground)
                        }
                    }
                    .frame(width: 280, height: 160).clipped()

                    LinearGradient(colors: [.clear, .black.opacity(0.6)], startPoint: .center, endPoint: .bottom)

                    HStack(spacing: 5) {
                        Image(systemName: "sparkles").font(.system(size: 10))
                        Text("Tap for details").font(DS.Typography.caption1.weight(.medium))
                    }
                    .foregroundColor(.white.opacity(0.85))
                    .padding(DS.Spacing.md)
                }

                // Text area — separate, constrained
                Text(asset.imageText)
                    .font(DS.Typography.caption2)
                    .foregroundColor(cs == .dark ? DS.Colors.textTertiary : Color(.secondaryLabel))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(width: 280, alignment: .leading)
                    .padding(.horizontal, DS.Spacing.md)
                    .padding(.vertical, DS.Spacing.sm)
                    .background(cs == .dark ? DS.Colors.bgCard : Color(.secondarySystemBackground))
            }
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.xl, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.xl, style: .continuous)
                    .strokeBorder(cs == .dark ? DS.Colors.border : Color(.separator).opacity(0.5), lineWidth: 1)
            )
        }.buttonStyle(PressableStyle())
    }
}

private struct InspirationCard: View {
    let asset: AssetModel; let cs: ColorScheme; let onTap: () -> Void
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: DS.Spacing.sm) {
                Group {
                    if let image = UIImage(named: asset.imageName) {
                        Image(uiImage: image).resizable().aspectRatio(contentMode: .fill)
                    } else {
                        Color(cs == .dark ? .secondarySystemBackground : .tertiarySystemBackground)
                    }
                }
                .frame(width: 140, height: 140).clipped()
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.large, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: DS.Radius.large, style: .continuous)
                    .strokeBorder(cs == .dark ? DS.Colors.border : Color(.separator).opacity(0.3), lineWidth: 1))

                Text(asset.imageText)
                    .font(DS.Typography.caption2)
                    .foregroundColor(cs == .dark ? DS.Colors.textTertiary : Color(.tertiaryLabel))
                    .lineLimit(2).frame(width: 140, alignment: .leading)
            }
        }.buttonStyle(PressableStyle())
    }
}

#Preview {
    HomeTabView().environmentObject(DataManager())
}
