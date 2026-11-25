import SwiftUI
import StoreKit

struct SettingsTabView: View {

    @EnvironmentObject var manager: DataManager
    @State private var showPaywall = false
    @State private var showMailError = false
    @State private var showAchievements = false
    @State private var showDeleteCollectionConfirm: ArtCollection?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        if !manager.isPremium {
                            ProBanner
                        } else {
                            ProStatusBanner
                        }

                        // Streak
                        StreakCard

                        // Stats
                        SettingsGroup(title: "Stats") {
                            SettingsRow(icon: "photo.stack", iconColor: .blue, title: "Total Creations") {
                                Text("\(manager.gallery.totalGenerationCount)").foregroundColor(.secondary)
                            }
                            SettingsRow(icon: "heart.fill", iconColor: .pink, title: "Favorites") {
                                Text("\(manager.gallery.favoriteArtworks.count)").foregroundColor(.secondary)
                            }
                            SettingsRow(icon: "flame.fill", iconColor: .orange, title: "Current Streak") {
                                Text("\(manager.streak.currentStreak) days").foregroundColor(.secondary)
                            }
                            SettingsRow(icon: "trophy.fill", iconColor: .yellow, title: "Longest Streak") {
                                Text("\(manager.streak.longestStreak) days").foregroundColor(.secondary)
                            }
                            SettingsRow(icon: "gift.fill", iconColor: .green, title: "Bonus Credits") {
                                Text("\(manager.streak.bonusCredits + manager.referral.bonusCredits)").foregroundColor(.secondary)
                            }
                            if !manager.isPremium {
                                SettingsRow(icon: "sparkle", iconColor: DS.Colors.accent, title: "Free Today") {
                                    Text("\(manager.remainingFreeGenerations) left").foregroundColor(.secondary)
                                }
                            }
                            Button {
                                HapticManager.tap(); showAchievements = true
                            } label: {
                                SettingsRow(icon: "medal.fill", iconColor: .mint, title: "Achievements") {
                                    HStack(spacing: 6) {
                                        Text("\(manager.achievements.unlockedCount)/\(manager.achievements.totalCount)")
                                            .foregroundColor(.secondary)
                                        Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundColor(.secondary)
                                    }
                                }
                            }.buttonStyle(.plain)
                        }

                        // Appearance
                        SettingsGroup(title: "Appearance") {
                            ForEach(AppAppearance.allCases) { mode in
                                SettingsRadio(
                                    icon: mode == .dark ? "moon.fill" : (mode == .light ? "sun.max.fill" : "circle.lefthalf.filled"),
                                    iconColor: mode == .dark ? .indigo : (mode == .light ? .orange : .gray),
                                    title: mode.displayName,
                                    isSelected: manager.appearance == mode
                                ) {
                                    HapticManager.selectionChanged()
                                    withAnimation { manager.appearance = mode }
                                }
                            }
                        }

                        // Notifications
                        SettingsGroup(title: "Notifications") {
                            SettingsToggle(
                                icon: "bell.fill", iconColor: .red,
                                title: "Daily Reminder",
                                subtitle: "Get notified when free generations reset",
                                isOn: Binding(
                                    get: { manager.notificationsEnabled },
                                    set: { newValue in
                                        if newValue {
                                            Task {
                                                let granted = await manager.notifications.requestPermission()
                                                manager.notificationsEnabled = granted
                                                HapticManager.tap()
                                            }
                                        } else {
                                            manager.notifications.cancelDailyReminder()
                                            manager.notificationsEnabled = false
                                            HapticManager.tap()
                                        }
                                    }
                                )
                            )
                        }

                        // Collections
                        if !manager.gallery.collections.isEmpty {
                            SettingsGroup(title: "Collections") {
                                ForEach(manager.gallery.collections) { col in
                                    HStack(spacing: 14) {
                                        Text(col.emoji).font(.title3)
                                        Text(col.name).font(.body).foregroundColor(Color(.label))
                                        Spacer()
                                        Text("\(manager.gallery.artworks(in: col).count)")
                                            .font(.subheadline).foregroundColor(.secondary)
                                        Button {
                                            HapticManager.warning()
                                            showDeleteCollectionConfirm = col
                                        } label: {
                                            Image(systemName: "trash")
                                                .font(.caption)
                                                .foregroundColor(.red.opacity(0.6))
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                }
                            }
                        }

                        // Subscription
                        if !manager.isPremium {
                            SettingsGroup(title: "Subscription") {
                                SettingsButton(icon: "crown", iconColor: .yellow, title: "Upgrade to Pro") {
                                    HapticManager.tap(); showPaywall = true
                                }
                                SettingsButton(icon: "arrow.clockwise", iconColor: .green, title: "Restore Purchases") {
                                    HapticManager.tap()
                                    Task { await manager.storeKit.restorePurchases() }
                                }
                            }
                        }

                        // Social
                        SettingsGroup(title: "Spread the Word") {
                            SettingsButton(icon: "star", iconColor: .yellow, title: "Rate App") {
                                HapticManager.tap(); requestReview()
                            }
                            SettingsButton(
                                icon: "square.and.arrow.up", iconColor: .blue,
                                title: manager.referral.hasEarnedToday ? "Share App" : "Share App · +1 Free Generation"
                            ) {
                                HapticManager.tap(); shareApp()
                            }
                        }

                        // Legal
                        SettingsGroup(title: "Support & Legal") {
                            SettingsButton(icon: "envelope", iconColor: .orange, title: "Contact Support") {
                                HapticManager.tap(); sendEmail()
                            }
                            SettingsLink(icon: "hand.raised", iconColor: DS.Colors.accent, title: "Privacy Policy", url: AppConfig.privacyURL)
                            SettingsLink(icon: "doc.text", iconColor: .indigo, title: "Terms of Use", url: AppConfig.termsAndConditionsURL)
                        }

                        VStack(spacing: 4) {
                            Text(AppConfig.appName).font(.footnote.weight(.medium)).foregroundColor(.secondary)
                            Text("Version \(AppConfig.appVersion)").font(.caption).foregroundColor(.secondary.opacity(0.6))
                        }
                        .padding(.top, 8)
                        .accessibilityElement(children: .combine)

                        Spacer(minLength: 120)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showPaywall) {
                PaywallView().environmentObject(manager)
            }
            .sheet(isPresented: $showAchievements) {
                AchievementsView().environmentObject(manager)
            }
            .alert("Email", isPresented: $showMailError) {
                Button("Copy Email") {
                    UIPasteboard.general.string = AppConfig.emailSupport
                    HapticManager.success()
                }
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please email us at \(AppConfig.emailSupport)")
            }
            .alert("Delete Collection?", isPresented: Binding(
                get: { showDeleteCollectionConfirm != nil },
                set: { if !$0 { showDeleteCollectionConfirm = nil } }
            )) {
                Button("Delete", role: .destructive) {
                    if let col = showDeleteCollectionConfirm {
                        manager.gallery.deleteCollection(col)
                        HapticManager.heavyImpact()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Images in this collection won't be deleted, just uncategorized.")
            }
        }
    }

    // MARK: - Streak Card
    private var StreakCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(manager.streak.currentStreak > 0 ? Color.orange.opacity(0.15) : Color.white.opacity(0.04))
                        .frame(width: 50, height: 50)
                    Image(systemName: manager.streak.currentStreak > 0 ? "flame.fill" : "flame")
                        .font(.title2)
                        .foregroundColor(manager.streak.currentStreak > 0 ? .orange : .secondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(manager.streak.currentStreak > 0 ? "\(manager.streak.currentStreak)-Day Streak" : "Start a Streak!")
                        .font(.headline).foregroundColor(Color(.label))
                    if let next = manager.streak.nextMilestone {
                        Text("\(manager.streak.daysUntilNextReward) more days for +\(next.bonusCredits) bonus generations")
                            .font(.caption).foregroundColor(.secondary)
                    } else {
                        Text("Generate daily to earn bonus credits")
                            .font(.caption).foregroundColor(.secondary)
                    }
                }
                Spacer()
            }

            if manager.streak.currentStreak > 0 {
                GeometryReader { geo in
                    let next = manager.streak.nextMilestone?.day ?? (manager.streak.currentStreak + 1)
                    let prev = StreakManager.milestones.last(where: { $0.day < next })?.day ?? 0
                    let progress = min(1.0, Double(manager.streak.currentStreak - prev) / Double(next - prev))
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.08)).frame(height: 6)
                        Capsule().fill(LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * progress, height: 6)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(manager.streak.currentStreak > 0 ? Color.orange.opacity(0.2) : Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    // MARK: - Pro Banners
    private var ProBanner: some View {
        Button { HapticManager.tap(); showPaywall = true } label: {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "crown.fill").foregroundStyle(DS.Gradients.gold)
                        Text("Upgrade to Pro").font(.headline).foregroundColor(Color(.label))
                    }
                    Text("Unlimited · All styles · HD · Batch · Upscale")
                        .font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.subheadline.weight(.semibold)).foregroundColor(.secondary)
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(LinearGradient(colors: [DS.Colors.accent.opacity(0.15), DS.Colors.accentLight.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(DS.Colors.accent.opacity(0.3), lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Upgrade to Pro")
    }

    private var ProStatusBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill").font(.title2).foregroundStyle(DS.Gradients.gold)
            VStack(alignment: .leading, spacing: 2) {
                Text("Pro Member").font(.headline).foregroundColor(Color(.label))
                Text("All features unlocked").font(.caption).foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.white.opacity(0.06)))
        .accessibilityElement(children: .combine)
    }

    // MARK: - Helpers
    private func requestReview() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        SKStoreReviewController.requestReview(in: scene)
    }

    private func shareApp() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else { return }
        let vc = UIActivityViewController(activityItems: [AppConfig.appStoreURL], applicationActivities: nil)
        vc.completionWithItemsHandler = { _, completed, _, _ in
            guard completed else { return }
            manager.objectWillChange.send()
            if manager.referral.recordShare() {
                HapticManager.success()
            }
        }
        root.present(vc, animated: true)
    }

    private func sendEmail() {
        let subject = "\(AppConfig.appName) Support".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Support"
        let mailto = "mailto:\(AppConfig.emailSupport)?subject=\(subject)"
        if let url = URL(string: mailto), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            showMailError = true
        }
    }
}

// MARK: - Settings Components
private struct SettingsGroup<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.subheadline.weight(.semibold)).foregroundColor(.secondary).padding(.leading, 4)
            VStack(spacing: 0) { content }
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white.opacity(0.06)))
        }
    }
}

private struct SettingsRow<Trailing: View>: View {
    let icon: String; let iconColor: Color; let title: String
    @ViewBuilder let trailing: Trailing
    var body: some View {
        HStack(spacing: 14) {
            SettingsIcon(systemName: icon, color: iconColor)
            Text(title).font(.body).foregroundColor(Color(.label))
            Spacer()
            trailing
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }
}

private struct SettingsButton: View {
    let icon: String; let iconColor: Color; let title: String; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                SettingsIcon(systemName: icon, color: iconColor)
                Text(title).font(.body).foregroundColor(Color(.label))
                Spacer()
                Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundColor(.secondary)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
        }.buttonStyle(.plain).accessibilityLabel(title)
    }
}

private struct SettingsLink: View {
    let icon: String; let iconColor: Color; let title: String; let url: URL
    var body: some View {
        Link(destination: url) {
            HStack(spacing: 14) {
                SettingsIcon(systemName: icon, color: iconColor)
                Text(title).font(.body).foregroundColor(Color(.label))
                Spacer()
                Image(systemName: "arrow.up.right").font(.caption.weight(.semibold)).foregroundColor(.secondary)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
        }.accessibilityLabel(title)
    }
}

private struct SettingsRadio: View {
    let icon: String; let iconColor: Color; let title: String; let isSelected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                SettingsIcon(systemName: icon, color: iconColor)
                Text(title).font(.body).foregroundColor(Color(.label))
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .purple : .secondary)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct SettingsToggle: View {
    let icon: String; let iconColor: Color; let title: String; let subtitle: String
    @Binding var isOn: Bool
    var body: some View {
        HStack(spacing: 14) {
            SettingsIcon(systemName: icon, color: iconColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body).foregroundColor(Color(.label))
                Text(subtitle).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            Toggle("", isOn: $isOn).labelsHidden().tint(DS.Colors.accent)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }
}

private struct SettingsIcon: View {
    let systemName: String; let color: Color
    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 14, weight: .semibold)).foregroundColor(Color(.label))
            .frame(width: 30, height: 30)
            .background(RoundedRectangle(cornerRadius: 7, style: .continuous).fill(color))
            .accessibilityHidden(true)
    }
}

#Preview {
    SettingsTabView().environmentObject(DataManager())
}
