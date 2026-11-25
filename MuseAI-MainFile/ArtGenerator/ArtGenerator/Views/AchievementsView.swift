import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject var manager: DataManager
    @ObservedObject private var achievements = AchievementManager.shared
    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 6) {
                        Text("\(achievements.unlockedCount) / \(achievements.totalCount)")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(Color(.label))
                        Text("Badges Unlocked").font(.subheadline).foregroundColor(.secondary)
                    }
                    .padding(.top, 8)

                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(AchievementManager.all) { achievement in
                            AchievementCard(
                                achievement: achievement,
                                unlocked: achievements.isUnlocked(achievement),
                                progress: achievements.progress(for: achievement, gallery: manager.gallery, streak: manager.streak)
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    Spacer(minLength: 40)
                }
            }
            .background(Color(.systemBackground).ignoresSafeArea())
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct AchievementCard: View {
    let achievement: Achievement
    let unlocked: Bool
    let progress: Int

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(unlocked ? AnyShapeStyle(DS.Gradients.gold) : AnyShapeStyle(Color.white.opacity(0.06)))
                    .frame(width: 56, height: 56)
                Image(systemName: achievement.icon)
                    .font(.title2)
                    .foregroundColor(unlocked ? .white : .secondary)
            }

            Text(achievement.title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(Color(.label))
                .multilineTextAlignment(.center)

            Text(achievement.subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(height: 28)

            if !unlocked {
                ProgressView(value: Double(min(progress, achievement.goal)), total: Double(achievement.goal))
                    .tint(DS.Colors.accent)
                Text("\(min(progress, achievement.goal))/\(achievement.goal)")
                    .font(.caption2.weight(.medium))
                    .foregroundColor(.secondary)
            } else {
                Text("Unlocked").font(.caption2.weight(.semibold)).foregroundColor(.green)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(unlocked ? Color.yellow.opacity(0.3) : Color.white.opacity(0.06), lineWidth: 1)
        )
        .opacity(unlocked ? 1 : 0.85)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    AchievementsView().environmentObject(DataManager())
}
