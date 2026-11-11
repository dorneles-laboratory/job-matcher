import SwiftUI

@main
struct EMBERApp: App {
    @StateObject private var vm = JobTinderViewModel()
    @State private var isShowingSplash = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if isShowingSplash {
                    SplashScreenView()
                        .transition(.opacity)
                } else {
                    Group {
                        if !vm.isAuthenticated {
                            AuthView()
                        } else if vm.currentUser?.role == .candidate {
                            CandidateMainTabView()
                        } else {
                            CompanyMainTabView()
                        }
                    }
                    .transition(.opacity)
                }
                
                if let match = vm.activeMatchNotification {
                    MatchNotificationOverlay(
                        candidateName: match.candidateName,
                        jobTitle: match.jobTitle
                    ) {
                        vm.activeMatchNotification = nil
                    }
                }
            }
            .environmentObject(vm)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        isShowingSplash = false
                    }
                }
            }
        }
    }
}

// MARK: - Splash Screen Animada de Abertura
struct SplashScreenView: View {
    @State private var logoScale: CGFloat = 0.7
    @State private var logoOpacity: Double = 0.0
    @State private var textOffset: CGFloat = 20
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.appPurple, Color.appPurple.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 90, height: 90)
                        .shadow(color: Color.appPurple.opacity(0.4), radius: 16, x: 0, y: 8)
                    
                    Image(systemName: "briefcase.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.white)
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)
                
                VStack(spacing: 6) {
                    Text("EMBER")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .tracking(3)
                        .foregroundColor(.primary)
                    
                    Text("JOB MATCHER")
                        .font(.system(size: 13, weight: .bold))
                        .tracking(2)
                        .foregroundColor(.appPurple)
                }
                .offset(y: textOffset)
                .opacity(logoOpacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                logoScale = 1.0
                logoOpacity = 1.0
                textOffset = 0
            }
        }
    }
}
