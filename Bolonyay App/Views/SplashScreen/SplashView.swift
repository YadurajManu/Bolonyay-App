//
//  SplashView.swift
//  BoloNyay
//
//  Created by Yaduraj Singh on 06/06/25.
//


import SwiftUI

struct SplashView: View {
    @StateObject private var viewModel = SplashViewModel()
    
    var body: some View {
        ZStack {
            // Ultra-cinematic gradient background with dynamic glow
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black,
                        Color.black.opacity(0.98),
                        Color.black.opacity(0.95),
                        Color.black.opacity(0.92)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Dynamic background glow that responds to animations
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                .white.opacity(viewModel.backgroundGlowIntensity * 0.03),
                                .blue.opacity(viewModel.backgroundGlowIntensity * 0.01),
                                .clear
                            ]),
                            center: .center,
                            startRadius: 100,
                            endRadius: 400
                        )
                    )
                    .scaleEffect(viewModel.backgroundGlowScale)
                    .animation(.timingCurve(0.25, 0.46, 0.45, 0.94, duration: 1.5), value: viewModel.backgroundGlowIntensity)
                    .animation(.timingCurve(0.42, 0.0, 0.58, 1.0, duration: 1.5), value: viewModel.backgroundGlowScale)
            }
            
            // Floating particle effects
            ForEach(0..<8, id: \.self) { index in
                Circle()
                    .fill(Color.white.opacity(viewModel.particleOpacity * 0.15))
                    .frame(width: CGFloat.random(in: 2...4), height: CGFloat.random(in: 2...4))
                    .offset(
                        x: CGFloat.random(in: -200...200),
                        y: CGFloat.random(in: -400...400)
                    )
                    .animation(
                        .timingCurve(0.09, 0.57, 0.49, 0.9, duration: Double.random(in: 3...5))
                        .repeatForever(autoreverses: true) 
                        .delay(Double.random(in: 0...2)),
                        value: viewModel.particleOpacity
                    )
            }
            
            VStack(spacing: 28) {
                Spacer()
                
                // Main title section with ultra-cinematic liquid effects
                VStack(spacing: 25) {
                    // Welcome text - Ultra cinematic with rotation and morphing
                    Text("Welcome")
                        .font(.system(size: 42, weight: .light, design: .default))
                        .foregroundColor(
                            Color.white.opacity(0.7 + (viewModel.welcomeColorIntensity * 0.3))
                        )
                        .tracking(3.0)
                        .opacity(viewModel.welcomeOpacity)
                        .scaleEffect(viewModel.welcomeScale)
                        .blur(radius: viewModel.welcomeBlur)
                        .rotationEffect(.degrees(viewModel.welcomeRotation))
                        .offset(y: viewModel.welcomeYOffset)
                        .shadow(color: .white.opacity(viewModel.welcomeOpacity * viewModel.welcomeColorIntensity * 0.12), radius: 15)
                        .shadow(color: .white.opacity(viewModel.welcomeOpacity * viewModel.welcomeColorIntensity * 0.06), radius: 30)
                        .shadow(color: .blue.opacity(viewModel.welcomeOpacity * viewModel.welcomeColorIntensity * 0.04), radius: 45)
                        .animation(.timingCurve(0.25, 0.46, 0.45, 0.94, duration: 1.4), value: viewModel.welcomeOpacity)
                        .animation(.interpolatingSpring(stiffness: 55, damping: 25), value: viewModel.welcomeScale)
                        .animation(.timingCurve(0.23, 1.0, 0.32, 1.0, duration: 1.1), value: viewModel.welcomeBlur)
                        .animation(.interpolatingSpring(stiffness: 50, damping: 30), value: viewModel.welcomeRotation)
                        .animation(.interpolatingSpring(stiffness: 55, damping: 25), value: viewModel.welcomeYOffset)
                    
                    // To text - Enhanced with cinematic morphing
                    Text("to")
                        .font(.system(size: 46, weight: .regular, design: .default))
                        .foregroundColor(
                            Color.gray.opacity(0.6 + (viewModel.toColorIntensity * 0.3))
                        )
                        .tracking(4.0)
                        .opacity(viewModel.toOpacity)
                        .scaleEffect(viewModel.toScale)
                        .blur(radius: viewModel.toBlur)
                        .rotationEffect(.degrees(viewModel.toRotation))
                        .offset(y: viewModel.toYOffset)
                        .shadow(color: .gray.opacity(viewModel.toOpacity * viewModel.toColorIntensity * 0.15), radius: 12)
                        .shadow(color: .gray.opacity(viewModel.toOpacity * viewModel.toColorIntensity * 0.08), radius: 25)
                        .shadow(color: .purple.opacity(viewModel.toOpacity * viewModel.toColorIntensity * 0.05), radius: 40)
                        .animation(.timingCurve(0.19, 1.0, 0.22, 1.0, duration: 1.4), value: viewModel.toOpacity)
                        .animation(.interpolatingSpring(stiffness: 65, damping: 22), value: viewModel.toScale)
                        .animation(.timingCurve(0.77, 0.0, 0.175, 1.0, duration: 1.1), value: viewModel.toBlur)
                        .animation(.interpolatingSpring(stiffness: 55, damping: 35), value: viewModel.toRotation)
                        .animation(.interpolatingSpring(stiffness: 65, damping: 22), value: viewModel.toYOffset)
                        .padding(.vertical, 12)
                    
                    // BoloNyay text - Premium cinematic with breathing and morphing
                    Text("BoloNyay")
                        .font(.system(size: 48, weight: .semibold, design: .default))
                        .foregroundColor(
                            Color.white.opacity(0.8 + (viewModel.boloNyayColorIntensity * 0.2))
                        )
                        .tracking(2.5)
                        .opacity(viewModel.boloNyayOpacity)
                        .scaleEffect(viewModel.boloNyayScale * viewModel.boloNyayBreathing)
                        .blur(radius: viewModel.boloNyayBlur)
                        .rotationEffect(.degrees(viewModel.boloNyayRotation))
                        .offset(y: viewModel.boloNyayYOffset)
                        .shadow(color: .white.opacity(viewModel.boloNyayOpacity * viewModel.boloNyayColorIntensity * 0.18), radius: 20)
                        .shadow(color: .white.opacity(viewModel.boloNyayOpacity * viewModel.boloNyayColorIntensity * 0.1), radius: 40)
                        .shadow(color: .white.opacity(viewModel.boloNyayOpacity * viewModel.boloNyayColorIntensity * 0.06), radius: 60)
                        .shadow(color: .cyan.opacity(viewModel.boloNyayOpacity * viewModel.boloNyayColorIntensity * 0.08), radius: 80)
                        .animation(.timingCurve(0.16, 1.0, 0.18, 1.0, duration: 1.4), value: viewModel.boloNyayOpacity)
                        .animation(.interpolatingSpring(stiffness: 70, damping: 25), value: viewModel.boloNyayScale)
                        .animation(.timingCurve(0.25, 0.46, 0.45, 0.94, duration: 2.0), value: viewModel.boloNyayBreathing)
                        .animation(.timingCurve(0.55, 0.06, 0.68, 0.19, duration: 1.4), value: viewModel.boloNyayBlur)
                        .animation(.interpolatingSpring(stiffness: 35, damping: 40), value: viewModel.boloNyayRotation)
                        .animation(.interpolatingSpring(stiffness: 70, damping: 25), value: viewModel.boloNyayYOffset)
                }
                
                Spacer()
                
                // Enhanced subtitle section with ultra-smooth morphing
                VStack(spacing: 14) {
                    Text("Personalized legal assistance")
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .foregroundColor(.gray.opacity(0.85))
                        .tracking(1.2)
                    
                    Text("to help you file complaints in any language.")
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .foregroundColor(.gray.opacity(0.85))
                        .tracking(1.2)
                    
                    Text("Powered by Bhashini API.")
                        .font(.system(size: 14, weight: .light, design: .default))
                        .foregroundColor(.gray.opacity(0.7))
                        .tracking(1.8)
                        .padding(.top, 10)
                }
                .opacity(viewModel.subtitleOpacity)
                .scaleEffect(viewModel.subtitleScale)
                .offset(y: viewModel.subtitleYOffset)
                .blur(radius: viewModel.subtitleOpacity == 0 ? 2.0 : 0)
                .shadow(color: .gray.opacity(viewModel.subtitleOpacity * 0.1), radius: 10)
                .shadow(color: .blue.opacity(viewModel.subtitleOpacity * 0.05), radius: 20)
                .animation(.timingCurve(0.09, 0.57, 0.49, 0.9, duration: 1.6), value: viewModel.subtitleOpacity)
                .animation(.interpolatingSpring(stiffness: 45, damping: 35), value: viewModel.subtitleScale)
                .animation(.interpolatingSpring(stiffness: 45, damping: 35), value: viewModel.subtitleYOffset)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 70)
            }
            .multilineTextAlignment(.center)
            
            // Enhanced ambient effects layer
            ZStack {
                // Primary ambient glow
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                .white.opacity(viewModel.boloNyayOpacity * viewModel.boloNyayColorIntensity * 0.02),
                                .cyan.opacity(viewModel.boloNyayOpacity * viewModel.boloNyayColorIntensity * 0.01),
                                .clear
                            ]),
                            center: .center,
                            startRadius: 80,
                            endRadius: 350
                        )
                    )
                    .scaleEffect(viewModel.boloNyayScale * viewModel.boloNyayBreathing)
                    .animation(.timingCurve(0.16, 1.0, 0.18, 1.0, duration: 1.4), value: viewModel.boloNyayOpacity)
                    .animation(.timingCurve(0.25, 0.46, 0.45, 0.94, duration: 2.0), value: viewModel.boloNyayBreathing)
                
                // Secondary ethereal glow
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                .blue.opacity(viewModel.backgroundGlowIntensity * 0.015),
                                .purple.opacity(viewModel.backgroundGlowIntensity * 0.008),
                                .clear
                            ]),
                            center: .center,
                            startRadius: 120,
                            endRadius: 450
                        )
                    )
                    .scaleEffect(viewModel.backgroundGlowScale)
                    .animation(.timingCurve(0.42, 0.0, 0.58, 1.0, duration: 1.5), value: viewModel.backgroundGlowScale)
            }
        }
        .onAppear {
            viewModel.startAnimation()
        }
    }
}

// MARK: - Preview
#Preview {
    SplashView()
}