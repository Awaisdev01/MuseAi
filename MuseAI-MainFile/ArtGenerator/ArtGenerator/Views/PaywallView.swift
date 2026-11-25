import SwiftUI
import StoreKit

struct PaywallView: View {

    @EnvironmentObject var manager: DataManager
    @Environment(\.dismiss) private var dismiss
    @StateObject private var abTest = ABTestManager.shared
    @State private var selectedTier: SubscriptionTier?
    @State private var isPurchasing = false

    var body: some View {
        ZStack {
            BackgroundGradient

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    CloseButton
                    HeaderSection
                    SocialProof
                    ComparisonTable
                    PricingCards
                    PurchaseButton
                    GuaranteeSection
                    FooterLinks
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            selectedTier = abTest.paywallVariant.defaultSelection
            abTest.recordImpression()
        }
    }

    // MARK: - Liquid Glass Background
    private var BackgroundGradient: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            RadialGradient(
                colors: [DS.Colors.accent.opacity(0.12), Color.clear],
                center: .top, startRadius: 50, endRadius: 400
            ).ignoresSafeArea()
            RadialGradient(
                colors: [Color.blue.opacity(0.08), Color.clear],
                center: .bottomTrailing, startRadius: 50, endRadius: 350
            ).ignoresSafeArea()
        }
    }

    private var CloseButton: some View {
        HStack {
            Spacer()
            Button { HapticManager.tap(); dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.secondary)
                    .frame(width: 32, height: 32)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .accessibilityLabel("Close")
        }
        .padding(.top, 8)
    }

    // MARK: - Header
    private var HeaderSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 100, height: 100)
                    .overlay(Circle().strokeBorder(Color.white.opacity(0.15), lineWidth: 1))
                Image(systemName: "crown.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(DS.Gradients.gold)
            }
            .accessibilityHidden(true)

            Text(abTest.paywallVariant.headline)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(Color(.label))
                .multilineTextAlignment(.center)

            Text("Join thousands of creators making images with Muse AI every day")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Social Proof
    private var SocialProof: some View {
        HStack(spacing: 12) {
            GlassBadge(value: "4.8★", label: "Rating")
            GlassBadge(value: "50K+", label: "Creations")
            GlassBadge(value: "12", label: "AI Styles")
        }
    }

    // MARK: - Comparison
    private var ComparisonTable: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Feature").font(.caption.weight(.semibold)).foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Free").font(.caption.weight(.semibold)).foregroundColor(.secondary).frame(width: 55)
                Text("Pro").font(.caption.weight(.semibold)).foregroundColor(DS.Colors.accent).frame(width: 55)
            }
            .padding(.horizontal, 14).padding(.vertical, 10)

            CompRow(f: "Generations", free: "5/day", pro: "∞")
            CompRow(f: "Art styles", free: "3", pro: "All 12")
            CompRow(f: "Quality", free: "SD", pro: "HD/4K")
            CompRow(f: "Batch mode", free: "—", pro: "4x")
            CompRow(f: "Upscaling", free: "—", pro: "4x")
            CompRow(f: "Editor", free: "—", pro: "✓")
            CompRow(f: "Export", free: "Basic", pro: "Full")
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - Pricing
    private var PricingCards: some View {
        VStack(spacing: 12) {
            ForEach(abTest.paywallVariant.tierOrder, id: \.rawValue) { tier in
                GlassPricingCard(tier: tier, isSelected: selectedTier == tier) {
                    HapticManager.selectionChanged()
                    withAnimation(.easeInOut(duration: 0.2)) { selectedTier = tier }
                }
            }
        }
    }

    // MARK: - Purchase
    private var PurchaseButton: some View {
        VStack(spacing: 12) {
            Button {
                HapticManager.impact()
                Task { await purchase() }
            } label: {
                HStack {
                    if isPurchasing {
                        ProgressView().tint(.white)
                    } else {
                        Text(buttonText).font(.headline)
                    }
                }
                .foregroundColor(Color(.label))
                .frame(maxWidth: .infinity).frame(height: 56)
                .background(DS.Gradients.accent)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: DS.Colors.accent.opacity(0.4), radius: 16, y: 8)
            }
            .disabled(isPurchasing || selectedTier == nil)

            if selectedTier == .yearly {
                Text("That's just $0.83/month — less than a coffee")
                    .font(.caption).foregroundColor(.secondary)
            } else if selectedTier == .lifetime {
                Text("Pay once, create forever. No recurring charges.")
                    .font(.caption).foregroundColor(.secondary)
            }
        }
    }

    private var buttonText: String {
        guard let tier = selectedTier else { return "Select a plan" }
        switch tier {
        case .monthly: return "Start Monthly — $3.99/mo"
        case .yearly: return "Start Yearly — $9.99/yr"
        case .lifetime: return "Get Lifetime — $19.99"
        }
    }

    // MARK: - Guarantee
    private var GuaranteeSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "shield.checkered")
                .font(.title3).foregroundStyle(DS.Gradients.accent)
            VStack(alignment: .leading, spacing: 2) {
                Text("Satisfaction Guaranteed").font(.caption.weight(.semibold)).foregroundColor(Color(.label))
                Text("Cancel anytime from Apple subscription settings.").font(.caption2).foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Color.white.opacity(0.06), lineWidth: 1))
    }

    // MARK: - Footer
    private var FooterLinks: some View {
        VStack(spacing: 8) {
            Button("Restore Purchases") {
                HapticManager.tap()
                Task { await manager.storeKit.restorePurchases() }
            }
            .font(.footnote).foregroundColor(.secondary)

            HStack(spacing: 16) {
                Link("Privacy Policy", destination: AppConfig.privacyURL)
                Text("·").foregroundColor(.secondary)
                Link("Terms of Use", destination: AppConfig.termsAndConditionsURL)
            }
            .font(.caption).foregroundColor(.secondary)

            Text("Payment charged to Apple ID at confirmation. Subscriptions auto-renew unless canceled 24 hours before period end.")
                .font(.caption2).foregroundColor(.secondary.opacity(0.6))
                .multilineTextAlignment(.center).padding(.top, 4)
        }
    }

    private func purchase() async {
        guard let tier = selectedTier,
              let product = manager.storeKit.product(for: tier) else { return }
        isPurchasing = true
        let success = await manager.storeKit.purchase(product)
        isPurchasing = false
        if success {
            abTest.recordConversion()
            HapticManager.success()
            dismiss()
        }
    }
}

// MARK: - Glass Components
private struct GlassBadge: View {
    let value: String; let label: String
    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.system(size: 17, weight: .bold, design: .rounded)).foregroundColor(Color(.label))
            Text(label).font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
    }
}

private struct CompRow: View {
    let f: String; let free: String; let pro: String
    var body: some View {
        HStack {
            Text(f).font(.caption).foregroundColor(.white.opacity(0.8)).frame(maxWidth: .infinity, alignment: .leading)
            Text(free).font(.caption).foregroundColor(.secondary).frame(width: 55)
            Text(pro).font(.caption.weight(.semibold)).foregroundColor(DS.Colors.accent).frame(width: 55)
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
    }
}

private struct GlassPricingCard: View {
    let tier: SubscriptionTier; let isSelected: Bool; let action: () -> Void
    @StateObject private var store = StoreKitManager.shared

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(tier.displayName).font(.system(size: 17, weight: .semibold)).foregroundColor(Color(.label))
                        if let badge = tier.badge {
                            Text(badge).font(.caption2.bold()).foregroundColor(.black)
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(Capsule().fill(DS.Gradients.gold))
                        }
                    }
                    Text(priceText).font(.subheadline).foregroundColor(.secondary)
                    if tier == .yearly {
                        Text("Save 79% vs monthly").font(.caption2.weight(.semibold)).foregroundColor(.green)
                    }
                }
                Spacer()
                ZStack {
                    Circle().strokeBorder(isSelected ? DS.Colors.accent : Color.white.opacity(0.3), lineWidth: 2).frame(width: 24, height: 24)
                    if isSelected { Circle().fill(DS.Gradients.accent).frame(width: 16, height: 16) }
                }.accessibilityHidden(true)
            }
            .padding(16)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(DS.Colors.accent.opacity(0.5), lineWidth: 1.5))
                    } else {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.white.opacity(0.04))
                            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.06), lineWidth: 1))
                    }
                }
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(tier.displayName) plan, \(priceText)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var priceText: String {
        if let product = store.product(for: tier) {
            return product.displayPrice + (tier == .lifetime ? " once" : "/" + (tier == .monthly ? "month" : "year"))
        }
        return tier.description
    }
}
