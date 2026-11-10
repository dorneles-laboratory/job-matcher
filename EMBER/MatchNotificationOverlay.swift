import SwiftUI

struct MatchNotificationOverlay: View {
    let candidateName: String
    let jobTitle: String
    let onDismiss: () -> Void
    
    @State private var animatePulse = false

    var body: some View {
        ZStack {
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.appPurple.opacity(0.45),
                    Color(hex: "#0F0C1B").opacity(0.96)
                ]),
                center: .center,
                startRadius: 40,
                endRadius: 450
            )
            .ignoresSafeArea()
            .background(.ultraThinMaterial)

            VStack(spacing: 24) {
                Spacer()
                
                HStack(spacing: -22) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.appPurple, .appSilver], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 86, height: 86)
                            .shadow(color: .appPurple.opacity(0.6), radius: 12, x: 0, y: 4)
                        
                        Image(systemName: "person.fill")
                            .font(.system(size: 38))
                            .foregroundColor(.white)
                    }
                    
                    ZStack {
                        Circle()
                            .fill(Color.appSilver)
                            .frame(width: 44, height: 44)
                            .shadow(color: .white.opacity(0.8), radius: 8)
                        
                        Image(systemName: "bolt.heart.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.appPurple)
                    }
                    .zIndex(1)
                    .scaleEffect(animatePulse ? 1.15 : 1.0)
                    
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.appSilver, .appPurple], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 86, height: 86)
                            .shadow(color: .appPurple.opacity(0.6), radius: 12, x: 0, y: 4)
                        
                        Image(systemName: "briefcase.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.white)
                    }
                }
                .padding(.bottom, 8)

                VStack(spacing: 6) {
                    Text("DEU MATCH!")
                        .font(.system(size: 38, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color.appSilver],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: .appPurple.opacity(0.8), radius: 14, x: 0, y: 4)

                    Text("Sua afinidade profissional deu resultado")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.appSilver.opacity(0.9))
                }

                VStack(spacing: 10) {
                    Text(candidateName)
                        .font(.title3)
                        .bold()
                        .foregroundColor(.white)

                    Text("Demonstrou interesse mútuo na vaga")
                        .font(.caption)
                        .foregroundColor(.appSilver.opacity(0.85))

                    Text("“\(jobTitle)”")
                        .font(.headline)
                        .bold()
                        .foregroundColor(.appPurple)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 10)
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.black.opacity(0.45))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    LinearGradient(
                                        colors: [.appPurple.opacity(0.7), .appSilver.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                )

                Spacer()

                Button(action: onDismiss) {
                    Text("Continuar Explorando")
                        .font(.headline)
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [.appPurple, Color(hex: "#5C46E5")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .shadow(color: .appPurple.opacity(0.55), radius: 12, x: 0, y: 6)
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 20)
            }
            .padding(28)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                animatePulse = true
            }
        }
    }
}
