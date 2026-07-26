import SwiftUI

public struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var currentTab: Int = 0

    struct OnboardingSlide: Identifiable {
        let id: Int
        let iconName: String
        let title: String
        let description: String
        let badge: String
    }

    private let slides: [OnboardingSlide] = [
        OnboardingSlide(
            id: 0,
            iconName: "person.3.sequence.fill",
            title: "Split Bills Effortlessly",
            description: "Easily track shared expenses for trips, roommates, couples, and events with 5 flexible split modes: Equal, Exact, %, Shares, and Itemized.",
            badge: "Group & Friend Billing"
        ),
        OnboardingSlide(
            id: 1,
            iconName: "arrow.triangle.merge",
            title: "Smart Debt Simplification",
            description: "Our min-flow algorithm automatically combines net balances, reducing dozens of messy debts into the minimum possible transfer payments.",
            badge: "Graph Algorithm"
        ),
        OnboardingSlide(
            id: 2,
            iconName: "doc.text.viewfinder",
            title: "Vision OCR Receipt Scanner",
            description: "Snap a photo of your paper receipt! Splitwise Pro automatically extracts amounts, items, and tax to fill out your bill instantly.",
            badge: "Vision AI OCR"
        ),
        OnboardingSlide(
            id: 3,
            iconName: "chart.bar.doc.horizontal.fill",
            title: "Analytics & PDF Statements",
            description: "Visualize spending trends with Swift Charts and export professional PDF/CSV statements for taxes, trips, and roommates.",
            badge: "Splitwise Pro"
        )
    ]

    public var body: some View {
        ZStack {
            ColorTheme.viewBackground
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Top Bar Skip Button
                HStack {
                    Spacer()
                    if currentTab < slides.count - 1 {
                        Button("Skip") {
                            completeOnboarding()
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    }
                }

                // Carousel Page View
                TabView(selection: $currentTab) {
                    ForEach(slides) { slide in
                        slideView(slide)
                            .tag(slide.id)
                    }
                }
                #if os(iOS)
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                #endif

                // Bottom Action Button
                VStack(spacing: 12) {
                    if currentTab == slides.count - 1 {
                        Button {
                            completeOnboarding()
                        } label: {
                            Text("Get Started")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(ColorTheme.brandTeal)
                                .cornerRadius(16)
                                .shadow(color: ColorTheme.brandTeal.opacity(0.35), radius: 8, x: 0, y: 4)
                        }
                    } else {
                        Button {
                            withAnimation {
                                currentTab += 1
                            }
                        } label: {
                            HStack {
                                Text("Next")
                                Image(systemName: "arrow.right")
                            }
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(ColorTheme.brandTeal)
                            .cornerRadius(16)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
            }
        }
    }

    private func slideView(_ slide: OnboardingSlide) -> some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(ColorTheme.brandTeal.opacity(0.12))
                    .frame(width: 140, height: 140)

                Image(systemName: slide.iconName)
                    .font(.system(size: 64, weight: .bold))
                    .foregroundColor(ColorTheme.brandTeal)
            }

            Text(slide.badge.uppercased())
                .font(.caption2)
                .fontWeight(.bold)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(ColorTheme.brandTeal.opacity(0.15))
                .foregroundColor(ColorTheme.brandTeal)
                .cornerRadius(6)

            Text(slide.title)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)

            Text(slide.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()
        }
    }

    private func completeOnboarding() {
        withAnimation {
            hasCompletedOnboarding = true
        }
    }
}
