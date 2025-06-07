//
//  SplashViewModel.swift
//  BoloNyay
//
//  Created by Yaduraj Singh on 06/06/25.
//


import SwiftUI
import Combine

@MainActor
class SplashViewModel: ObservableObject {
    // Opacity and Scale Properties
    @Published var welcomeOpacity: Double = 0.0
    @Published var welcomeScale: Double = 0.94
    @Published var welcomeBlur: Double = 2.0
    @Published var welcomeRotation: Double = -2.0
    @Published var welcomeYOffset: Double = 20.0
    
    @Published var toOpacity: Double = 0.0
    @Published var toScale: Double = 0.92
    @Published var toBlur: Double = 2.0
    @Published var toRotation: Double = 1.5
    @Published var toYOffset: Double = 15.0
    
    @Published var boloNyayOpacity: Double = 0.0
    @Published var boloNyayScale: Double = 0.90
    @Published var boloNyayBlur: Double = 2.0
    @Published var boloNyayRotation: Double = -1.0
    @Published var boloNyayYOffset: Double = 25.0
    @Published var boloNyayBreathing: Double = 1.0
    
    @Published var subtitleOpacity: Double = 0.0
    @Published var subtitleScale: Double = 0.95
    @Published var subtitleYOffset: Double = 30.0
    
    // Color Transition Properties
    @Published var welcomeColorIntensity: Double = 0.0
    @Published var toColorIntensity: Double = 0.0
    @Published var boloNyayColorIntensity: Double = 0.0
    
    // Background Effects
    @Published var backgroundGlowIntensity: Double = 0.0
    @Published var backgroundGlowScale: Double = 0.8
    @Published var particleOpacity: Double = 0.0
    
    @Published var showMainContent: Bool = false
    
    // Ultra-refined timing - even more overlapping and cinematic
    private let cinematicDuration: Double = 1.4
    private let fluidOverlapDelay: Double = 0.35        // More overlap
    private let elasticTransitionDuration: Double = 0.9
    private let breathingDuration: Double = 2.0
    private let morphingDuration: Double = 1.1
    
    private var cancellables = Set<AnyCancellable>()
    
    func startAnimation() {
        // Phase 1: "Welcome" - Cinematic entrance with rotation and offset
        withAnimation(.interpolatingSpring(stiffness: 60, damping: 20, initialVelocity: 0.1).delay(0.1)) {
            welcomeOpacity = 1.0
            welcomeBlur = 0.0
            welcomeColorIntensity = 1.0
        }
        withAnimation(.interpolatingSpring(stiffness: 55, damping: 25, initialVelocity: 0.05).delay(0.2)) {
            welcomeScale = 1.0
            welcomeRotation = 0.0
            welcomeYOffset = 0.0
        }
        
        // Phase 2: Background glow activation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.timingCurve(0.25, 0.46, 0.45, 0.94, duration: 1.5)) {
                self.backgroundGlowIntensity = 1.0
                self.backgroundGlowScale = 1.0
            }
        }
        
        // Phase 3: "to" - Overlapping with "Welcome" still visible
        DispatchQueue.main.asyncAfter(deadline: .now() + fluidOverlapDelay) {
            withAnimation(.timingCurve(0.19, 1.0, 0.22, 1.0, duration: self.cinematicDuration)) {
                self.toOpacity = 1.0
                self.toBlur = 0.0
                self.toColorIntensity = 1.0
            }
            withAnimation(.interpolatingSpring(stiffness: 65, damping: 22, initialVelocity: 0.08).delay(0.12)) {
                self.toScale = 1.0
                self.toRotation = 0.0
                self.toYOffset = 0.0
            }
        }
        
        // Phase 4: Particle effects activation
        DispatchQueue.main.asyncAfter(deadline: .now() + (fluidOverlapDelay + 0.2)) {
            withAnimation(.timingCurve(0.09, 0.57, 0.49, 0.9, duration: 2.0)) {
                self.particleOpacity = 1.0
            }
        }
        
        // Phase 5: "Welcome" graceful morphing exit
        DispatchQueue.main.asyncAfter(deadline: .now() + (fluidOverlapDelay + 0.25)) {
            withAnimation(.timingCurve(0.23, 1.0, 0.32, 1.0, duration: self.morphingDuration)) {
                self.welcomeOpacity = 0.0
                self.welcomeBlur = 2.0
                self.welcomeColorIntensity = 0.0
            }
            withAnimation(.interpolatingSpring(stiffness: 50, damping: 30, initialVelocity: -0.02).delay(0.08)) {
                self.welcomeScale = 0.88
                self.welcomeRotation = -3.0
                self.welcomeYOffset = -15.0
            }
        }
        
        // Phase 6: "BoloNyay" - Cinematic entrance with breathing effect
        DispatchQueue.main.asyncAfter(deadline: .now() + (fluidOverlapDelay * 2)) {
            withAnimation(.timingCurve(0.16, 1.0, 0.18, 1.0, duration: self.cinematicDuration)) {
                self.boloNyayOpacity = 1.0
                self.boloNyayBlur = 0.0
                self.boloNyayColorIntensity = 1.0
            }
            withAnimation(.interpolatingSpring(stiffness: 70, damping: 25, initialVelocity: 0.15).delay(0.1)) {
                self.boloNyayScale = 1.0
                self.boloNyayRotation = 0.0
                self.boloNyayYOffset = 0.0
            }
        }
        
        // Phase 7: "to" elegant morphing exit
        DispatchQueue.main.asyncAfter(deadline: .now() + (fluidOverlapDelay * 2.2)) {
            withAnimation(.timingCurve(0.77, 0.0, 0.175, 1.0, duration: self.morphingDuration)) {
                self.toOpacity = 0.0
                self.toBlur = 2.5
                self.toColorIntensity = 0.0
            }
            withAnimation(.interpolatingSpring(stiffness: 55, damping: 35, initialVelocity: -0.03).delay(0.06)) {
                self.toScale = 0.92
                self.toRotation = 2.5
                self.toYOffset = -10.0
            }
        }
        
        // Phase 8: BoloNyay breathing effect
        DispatchQueue.main.asyncAfter(deadline: .now() + (fluidOverlapDelay * 2.5)) {
            withAnimation(.timingCurve(0.25, 0.46, 0.45, 0.94, duration: self.breathingDuration).repeatForever(autoreverses: true)) {
                self.boloNyayBreathing = 1.03
            }
        }
        
        // Phase 9: Subtitle - Elegant entrance with offset
        DispatchQueue.main.asyncAfter(deadline: .now() + (fluidOverlapDelay * 2.8)) {
            withAnimation(.timingCurve(0.09, 0.57, 0.49, 0.9, duration: 1.6)) {
                self.subtitleOpacity = 1.0
            }
            withAnimation(.interpolatingSpring(stiffness: 45, damping: 35, initialVelocity: 0.06).delay(0.15)) {
                self.subtitleScale = 1.0
                self.subtitleYOffset = 0.0
            }
        }
        
        // Phase 10: Hold the complete scene with breathing
        DispatchQueue.main.asyncAfter(deadline: .now() + (fluidOverlapDelay * 4.5)) {
            // Enhanced breathing effect
            withAnimation(.timingCurve(0.42, 0.0, 0.58, 1.0, duration: 1.5).repeatForever(autoreverses: true)) {
                self.backgroundGlowScale = 1.05
            }
        }
        
        // Phase 11: "BoloNyay" prominence boost
        DispatchQueue.main.asyncAfter(deadline: .now() + (fluidOverlapDelay * 5.0)) {
            withAnimation(.timingCurve(0.25, 0.46, 0.45, 0.94, duration: self.elasticTransitionDuration)) {
                self.boloNyayOpacity = 0.98
                self.boloNyayScale = 1.04
            }
        }
        
        // Phase 12: Final cinematic exit sequence
        DispatchQueue.main.asyncAfter(deadline: .now() + (fluidOverlapDelay * 6.5)) {
            // Stop breathing
            withAnimation(.timingCurve(0.55, 0.06, 0.68, 0.19, duration: 0.8)) {
                self.boloNyayBreathing = 1.0
            }
            
            // Graceful exit
            withAnimation(.timingCurve(0.55, 0.06, 0.68, 0.19, duration: 1.4)) {
                self.boloNyayOpacity = 0.0
                self.boloNyayBlur = 3.0
                self.boloNyayColorIntensity = 0.0
            }
            withAnimation(.interpolatingSpring(stiffness: 35, damping: 40, initialVelocity: -0.02).delay(0.12)) {
                self.boloNyayScale = 0.85
                self.boloNyayRotation = -2.0
                self.boloNyayYOffset = -20.0
            }
        }
        
        // Phase 13: Subtitle and effects exit
        DispatchQueue.main.asyncAfter(deadline: .now() + (fluidOverlapDelay * 7.0)) {
            withAnimation(.timingCurve(0.6, 0.04, 0.98, 0.335, duration: 1.2)) {
                self.subtitleOpacity = 0.0
                self.particleOpacity = 0.0
                self.backgroundGlowIntensity = 0.0
            }
            withAnimation(.interpolatingSpring(stiffness: 40, damping: 45, initialVelocity: -0.01).delay(0.08)) {
                self.subtitleScale = 0.9
                self.subtitleYOffset = 20.0
                self.backgroundGlowScale = 0.8
            }
        }
        
        // Phase 14: Navigate to main content
        DispatchQueue.main.asyncAfter(deadline: .now() + (fluidOverlapDelay * 8.5)) {
            NotificationCenter.default.post(name: NSNotification.Name("SplashCompleted"), object: nil)
        }
    }
    
    func resetAnimation() {
        welcomeOpacity = 0.0
        welcomeScale = 0.94
        welcomeBlur = 2.0
        welcomeRotation = -2.0
        welcomeYOffset = 20.0
        welcomeColorIntensity = 0.0
        
        toOpacity = 0.0
        toScale = 0.92
        toBlur = 2.0
        toRotation = 1.5
        toYOffset = 15.0
        toColorIntensity = 0.0
        
        boloNyayOpacity = 0.0
        boloNyayScale = 0.90
        boloNyayBlur = 2.0
        boloNyayRotation = -1.0
        boloNyayYOffset = 25.0
        boloNyayBreathing = 1.0
        boloNyayColorIntensity = 0.0
        
        subtitleOpacity = 0.0
        subtitleScale = 0.95
        subtitleYOffset = 30.0
        
        backgroundGlowIntensity = 0.0
        backgroundGlowScale = 0.8
        particleOpacity = 0.0
        
        showMainContent = false
    }
}