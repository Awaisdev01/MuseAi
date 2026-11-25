import SwiftUI

struct DashboardContentView: View {

    @EnvironmentObject var manager: DataManager
    @State private var selectedTab: AppTab = .home
    @State private var showPaywall = false
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.colorScheme) private var cs

    var body: some View {
        Group {
            if sizeClass == .regular {
                iPadLayout
            } else {
                iPhoneLayout
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView().environmentObject(manager)
        }
        .alert("Error", isPresented: $manager.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(manager.errorMessage ?? "Something went wrong.")
        }
        .alert("Streak Reward!", isPresented: $manager.showStreakReward) {
            Button("Awesome!", role: .cancel) {}
        } message: {
            if let reward = manager.streak.lastReward {
                Text("\(reward.title)\n+\(reward.bonusCredits) bonus generations earned!")
            }
        }
    }

    // MARK: - iPad
    private var iPadLayout: some View {
        NavigationSplitView {
            List {
                Section("Create") {
                    sidebarButton(.home)
                    sidebarButton(.create)
                }
                Section("Library") {
                    sidebarButton(.gallery)
                }
                Section("App") {
                    sidebarButton(.settings)
                }
                if !manager.isPremium {
                    Section {
                        Button { HapticManager.tap(); showPaywall = true } label: {
                            Label {
                                Text("Upgrade to Pro").font(.subheadline.weight(.semibold))
                            } icon: {
                                Image(systemName: "crown.fill").foregroundStyle(DS.Gradients.gold)
                            }
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationTitle(AppConfig.appName)
        } detail: {
            TabContent
        }
    }

    private func sidebarButton(_ tab: AppTab) -> some View {
        Button {
            HapticManager.selectionChanged()
            selectedTab = tab
        } label: {
            Label(tab.title, systemImage: tab.rawValue)
        }
        .listRowBackground(selectedTab == tab ? DS.Colors.accent.opacity(0.12) : Color.clear)
    }

    // MARK: - iPhone
    private var iPhoneLayout: some View {
        ZStack(alignment: .bottom) {
            (cs == .dark ? AnyView(DS.Gradients.background.ignoresSafeArea()) : AnyView(Color(.systemBackground).ignoresSafeArea()))

            TabContent
                .padding(.bottom, 82)

            GlassTabBar

            if !manager.isPremium {
                VStack {
                    HStack {
                        Spacer()
                        Button { HapticManager.tap(); showPaywall = true } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "crown.fill").font(.system(size: 10))
                                Text("PRO").font(.system(size: 11, weight: .bold))
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 11).padding(.vertical, 6)
                            .background(DS.Gradients.gold, in: Capsule())
                            .shadow(color: DS.Colors.goldStart.opacity(0.35), radius: 8, y: 4)
                        }
                        .padding(.trailing, DS.Spacing.lg).padding(.top, DS.Spacing.sm)
                    }
                    Spacer()
                }
            }
        }
    }

    @ViewBuilder
    private var TabContent: some View {
        switch selectedTab {
        case .home: HomeTabView()
        case .create: CreatorTabView()
        case .gallery: GalleryView()
        case .settings: SettingsTabView()
        }
    }

    // MARK: - Glass Tab Bar
    private var GlassTabBar: some View {
        VStack(spacing: 0) {
            Spacer()
            Group {
                if #available(iOS 26.0, *) {
                    GlassEffectContainer(spacing: 12) {
                        tabBarContent
                            .padding(.horizontal, DS.Spacing.sm)
                            .padding(.vertical, DS.Spacing.sm)
                            .glassEffect(.regular, in: Capsule())
                    }
                    .padding(.horizontal, DS.Spacing.lg)
                    .padding(.bottom, DS.Spacing.sm)
                } else {
                    tabBarContent
                        .padding(.horizontal, DS.Spacing.sm)
                        .padding(.top, DS.Spacing.md)
                        .padding(.bottom, 30)
                        .background(
                            Rectangle().fill(.ultraThinMaterial)
                                .ignoresSafeArea(edges: .bottom)
                                .overlay(alignment: .top) {
                                    Rectangle().fill(Color(.separator).opacity(0.3)).frame(height: 0.33)
                                }
                        )
                }
            }
        }
    }

    private var tabBarContent: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                Button {
                    HapticManager.selectionChanged()
                    withAnimation(DS.Motion.standard) { selectedTab = tab }
                } label: {
                    VStack(spacing: 3) {
                        ZStack {
                            if selectedTab == tab {
                                Capsule().fill(DS.Colors.accent.opacity(0.18))
                                    .frame(width: 52, height: 30)
                                    .transition(.scale.combined(with: .opacity))
                            }
                            Image(systemName: selectedTab == tab ? tab.filledIcon : tab.rawValue)
                                .font(.system(size: tab == .create ? 24 : 18,
                                               weight: selectedTab == tab ? .semibold : .regular))
                                .foregroundStyle(
                                    selectedTab == tab
                                    ? AnyShapeStyle(DS.Gradients.accent)
                                    : AnyShapeStyle(Color(.tertiaryLabel))
                                )
                        }
                        .frame(height: 30)

                        Text(tab.title)
                            .font(.system(size: 10, weight: selectedTab == tab ? .semibold : .regular))
                            .foregroundColor(selectedTab == tab ? Color(.label) : Color(.tertiaryLabel))
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
            }
        }
    }
}

#Preview {
    DashboardContentView().environmentObject(DataManager())
}
