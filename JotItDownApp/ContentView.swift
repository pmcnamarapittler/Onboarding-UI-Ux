//
//  ContentView.swift
//  JotItDownApp
//
//  Created by Paige McNamara-Pittler on 9/16/25.
//

import SwiftUI
import AVKit
import UIKit

struct ContentView: View {
    @State private var showingSplash = true
    
    var body: some View {
        if showingSplash {
            SplashView(showingSplash: $showingSplash)
        } else {
            OnboardingContainerView()
        }
    }
}

import Lottie

struct LottieView: UIViewRepresentable {
    let filename: String
    var loopMode: LottieLoopMode = .loop
    var speed: CGFloat = 1.0
    var contentMode: UIView.ContentMode = .scaleAspectFit

    func makeUIView(context: Context) -> LottieAnimationView {
        let view = LottieAnimationView(name: filename)
        view.loopMode = loopMode
        view.animationSpeed = speed
        view.contentMode = contentMode
        view.backgroundBehavior = .pauseAndRestore
        view.play()
        return view
    }

    func updateUIView(_ uiView: LottieAnimationView, context: Context) {}
}

// MARK: - Video Background (Aspect-Fill & Looping)
struct VideoLoopView: UIViewRepresentable {
    let url: URL
    
    func makeCoordinator() -> Coordinator { Coordinator() }
    
    func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        let item = AVPlayerItem(url: url)
        let player = AVQueuePlayer()
        context.coordinator.player = player
        
        // retain the looper on the coordinator so it doesn’t deallocate
        context.coordinator.looper = AVPlayerLooper(player: player, templateItem: item)
        view.player = player
        
        player.isMuted = true
        player.actionAtItemEnd = .none
        player.automaticallyWaitsToMinimizeStalling = false
        player.playImmediately(atRate: 1.0)
        return view
    }
    
    func updateUIView(_ uiView: PlayerView, context: Context) {
        // no-op; background video just loops
    }
    
    class Coordinator {
        var looper: AVPlayerLooper?
        var player: AVQueuePlayer?
    }
    
    class PlayerView: UIView {
        override static var layerClass: AnyClass { AVPlayerLayer.self }
        private var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
        
        var player: AVQueuePlayer? {
            get { playerLayer.player as? AVQueuePlayer }
            set {
                playerLayer.player = newValue
                playerLayer.videoGravity = .resizeAspectFill // fills like a background image
            }
        }
    }
}

// MARK: - Splash Screen
struct SplashView: View {
    @Binding var showingSplash: Bool
    @State private var revealedCount = 0
    private let title = "Brilliant Stones"
    @State private var animateTitle = false
    @State private var animateTagline = false
    
    var body: some View {
        ZStack {
            // Background video (loops, aspect-fill)
            if let url = Bundle.main.url(forResource: "splashBackground", withExtension: "mov") {
                VideoLoopView(url: url)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                
                // Optional overlay to ensure text/icon readability
                LinearGradient(
                    colors: [Color.black.opacity(0.35), Color.black.opacity(0.35)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            } else {
                // Fallback gradient if video is missing
                LinearGradient(
                    colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }
            
            VStack(spacing: 20) {
                // PNG logo instead of lightbulb/Lottie
                Image("logo") // name of your PNG in Assets.xcassets or bundle (without .png)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80) // adjust size as needed

                // Animated cursive title (reveals one letter at a time)
                HStack(spacing: 0) {
                    ForEach(Array(title).indices, id: \.self) { idx in
                        let ch = Array(title)[idx]
                        Text(String(ch))
                            .font(.custom("SnellRoundhand-Bold", size: 44)) // built-in cursive font
                            .foregroundColor(.white)
                            .opacity(idx < revealedCount ? 1 : 0)
                            .offset(y: idx < revealedCount ? 0 : 8)
                            .animation(.easeOut(duration: 0.15).delay(0.0), value: revealedCount)
                    }
                }

                Text("Engagement Rings, Made Simple")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.9))
                    .opacity(animateTagline ? 1 : 0)
                    .animation(.easeIn(duration: 0.8).delay(0.5), value: animateTagline)
            }
        }
        .onAppear {
            // Pulse the bulb while the title animates
            animateTitle = true

            // Animate the title one letter at a time
            let letters = Array(title)
            for i in 0..<letters.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.06 * Double(i)) {
                    withAnimation(.easeOut(duration: 0.12)) {
                        revealedCount = i + 1
                    }
                }
            }

            // Show tagline after the title finishes
            let titleFinishDelay = 0.06 * Double(Array(title).count) + 0.2
            DispatchQueue.main.asyncAfter(deadline: .now() + titleFinishDelay) {
                withAnimation(.easeIn(duration: 0.6)) {
                    animateTagline = true
                }
            }

            // Navigate to onboarding after everything plays
            DispatchQueue.main.asyncAfter(deadline: .now() + titleFinishDelay + 3.0) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showingSplash = false
                }
            }
        }
    }
}

// MARK: - Onboarding Container
struct OnboardingContainerView: View {
    @State private var currentPage = 0
    @State private var userData = UserData()
    
    var body: some View {
        ZStack {
            // Current screen
            TabView(selection: $currentPage) {
                WelcomeView(currentPage: $currentPage)
                    .tag(0)
                
                FeatureOneView(currentPage: $currentPage)
                    .tag(1)
                
                FeatureTwoView(currentPage: $currentPage)
                    .tag(2)
                
                RegistrationView(userData: $userData)
                    .tag(3)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)
        }
        .ignoresSafeArea() // ensure full-bleed background
        .overlay(alignment: .bottomLeading) {
            // Page indicator pinned bottom-left (hide on signup)
            if currentPage < 3 {
                HStack {
                    ForEach(0..<4) { index in
                        Circle()
                            .fill(index == currentPage ? Color.white : Color.gray.opacity(0.3))
                            .frame(width: 10, height: 10)
                    }
                }
                .padding(.leading, 20)
                .padding(.bottom, 30)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if currentPage == 0 {
                Button(action: {
                    withAnimation { currentPage = 1 }
                }) {
                    Text("Next")
                        .font(.headline)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.6), radius: 2, x: 0, y: 1)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 30) // match dots baseline
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if currentPage == 1 {
                Button(action: {
                    withAnimation { currentPage = 2 }
                }) {
                    Text("Next")
                        .font(.headline)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.6), radius: 2, x: 0, y: 1)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 30)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if currentPage == 2 {
                Button(action: {
                    withAnimation { currentPage = 3 }
                }) {
                    Text("Next")
                        .font(.headline)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.6), radius: 2, x: 0, y: 1)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 30)
            }
        }
    }
}

// MARK: - Welcome Screen
struct WelcomeView: View {
    @Binding var currentPage: Int

    var body: some View {
        ZStack {
            // Keep layout exactly as-is
            VStack(alignment: .leading, spacing: 12) {
                Text("Welcome to Brilliant Stones")
                    .font(.custom("SnellRoundhand-Bold", size: 38))
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.primary)
                
                Text("Finding the perfect engagement ring shouldn't be overwhelming. Discover stunning, ethically-sourced diamonds with expert guidance every step of the way.")
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.top, 100)
        }
        // Put the image as a true background so it won't push/clip the content
        .background(
            Image("welcomeBackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        )
    }
}

// MARK: - Feature One Screen
struct FeatureOneView: View {
    @Binding var currentPage: Int
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("Ring Shopping, Simplified")
                    .font(.custom("SnellRoundhand-Bold", size: 38))
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.white)

                Text("No pressure, no confusion, just the perfect ring for your perfect moment")
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.top, 100)
        }
        .background(
            Image("featureone")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        )
    }
}

// MARK: - Feature Two Screen
struct FeatureTwoView: View {
    @Binding var currentPage: Int
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("Your Personal Ring Expert")
                    .font(.custom("SnellRoundhand-Bold", size: 38))
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.white)

                Text("Professional guidance and support that makes choosing the one as easy as saying yes")
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.top, 100)
        }
        .background(
            Image("featuretwo")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        )
    }
}

// MARK: - Registration Screen
struct RegistrationView: View {
    @Binding var userData: UserData
    @State private var showingMainApp = false
    
    var body: some View {
        ZStack {
            if let url = Bundle.main.url(forResource: "splashBackground", withExtension: "mov") {
                VideoLoopView(url: url)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            } else {
                LinearGradient(
                    colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }
            // Subtle transparent overlay for readability
            LinearGradient(
                colors: [Color.black.opacity(0.0), Color.black.opacity(0.3)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            VStack(spacing: 30) {
                Spacer()
                
            
                
                VStack(spacing: 16) {
                    Text("Let's find your perfect ring")
                        .font(.custom("SnellRoundhand-Bold", size: 44))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)

                    Text("Sync your ideas across all devices")
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("", text: $userData.name, prompt: Text("Full Name").foregroundColor(.white.opacity(0.7)))
                            .padding()
                            .background(Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white, lineWidth: 1.5)
                            )
                            .font(.body)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .accentColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("", text: $userData.username, prompt: Text("Username").foregroundColor(.white.opacity(0.7)))
                            .padding()
                            .background(Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white, lineWidth: 1.5)
                            )
                            .font(.body)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .accentColor(.white)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        SecureField("", text: $userData.password, prompt: Text("Password (min 6 characters)").foregroundColor(.white.opacity(0.7)))
                            .padding()
                            .background(Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white, lineWidth: 1.5)
                            )
                            .font(.body)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .accentColor(.white)
                        
                        if !userData.password.isEmpty && userData.password.count < 6 {
                            Text("Password must be at least 6 characters")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                Button(action: {
                    userData.saveToUserDefaults()
                    // In a real app, navigate to main app interface
                    showingMainApp = true
                }) {
                    Text("Begin My Search")
                        .font(.headline)
                        .foregroundColor(Color(.darkGray))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(userData.isValid ? Color.blue : Color.white)
                        .cornerRadius(12)
                }
                .disabled(!userData.isValid)
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
            .padding()
            .alert("Welcome to Jot It Down!", isPresented: $showingMainApp) {
                Button("Let's Go!") { }
            } message: {
                Text("Your account has been created successfully. Start capturing your brilliant ideas!")
            }
        }
    }
}

// MARK: - Helper Views
struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            Text(text)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

// MARK: - User Data Model
class UserData: ObservableObject {
    @Published var name: String = ""
    @Published var username: String = ""
    @Published var password: String = ""
    
    func saveToUserDefaults() {
        UserDefaults.standard.set(name, forKey: "userName")
        UserDefaults.standard.set(username, forKey: "userUsername")
        // TODO: In production, use Keychain for password storage
        // For assignment purposes, using UserDefaults
        UserDefaults.standard.set(password, forKey: "userPassword")
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
    
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        password.count >= 6
    }
}


#Preview {
    ContentView()
}
