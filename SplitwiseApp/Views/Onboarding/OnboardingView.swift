import SwiftUI

public struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @AppStorage("shouldLoadSampleData") private var shouldLoadSampleData: Bool = false
    @State private var currentTab: Int = 0
    @State private var showingDataChoice = false

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
            description: "Net balances to reduce transfers between group members using a simple pairing heuristic (not a proven global minimum).",
            badge: "Local AA Tool"
        ),
        OnboardingSlide(
            id: 2,
            iconName: "doc.text.viewfinder",
            title: "Vision OCR Receipt Scanner",
            description: "Pick a receipt photo and parse amounts on-device. If scanning fails, enter the expense manually — no fake demo data.",
            badge: "Vision OCR"
        ),
        OnboardingSlide(
            id: 3,
            iconName: "chart.bar.doc.horizontal.fill",
            title: "Analytics & PDF Statements",
            description: "Visualize your share of spending with charts and export PDF/CSV statements for trips and roommates.",
            badge: "Insights"
        )
    ]

    public var body: some View {
        ZStack {
            ColorTheme.viewBackground
                .ignoresSafeArea()

            VStack(spacing: 20) {
                HStack {
                    Spacer()
                    if currentTab < slides.count - 1 {
                        Button("Skip") {
                            showingDataChoice = true
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    }
                }

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

                VStack(spacing: 12) {
                    if currentTab == slides.count - 1 {
                        Button {
                            showingDataChoice = true
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
        .confirmationDialog("How do you want to start?", isPresented: $showingDataChoice, titleVisibility: .visible) {
            Button("Start Blank") {
                completeOnboarding(loadSample: false)
            }
            Button("Load Sample Data") {
                completeOnboarding(loadSample: true)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Blank starts with only your profile. Sample data adds demo friends, groups, and expenses.")
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

    private func completeOnboarding(loadSample: Bool) {
        shouldLoadSampleData = loadSample
        withAnimation {
            hasCompletedOnboarding = true
        }
    }
}
