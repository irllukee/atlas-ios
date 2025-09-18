import Foundation
import SwiftUI

/// Service for managing advanced animations and transitions
@MainActor
class AnimationService: ObservableObject {
    static let shared = AnimationService()
    
    @Published var isAnimating = false
    @Published var currentAnimation: AnimationType?
    
    private init() {}
    
    // MARK: - Animation Types
    
    enum AnimationType: String, CaseIterable {
        case fadeIn = "fadeIn"
        case slideUp = "slideUp"
        case slideDown = "slideDown"
        case slideLeft = "slideLeft"
        case slideRight = "slideRight"
        case scale = "scale"
        case bounce = "bounce"
        case spring = "spring"
        case ripple = "ripple"
        case shimmer = "shimmer"
        case pulse = "pulse"
        case glow = "glow"
        case morph = "morph"
        case flip = "flip"
        case rotate = "rotate"
        case elastic = "elastic"
    }
    
    // MARK: - Animation Presets
    
    struct AnimationPreset {
        let type: AnimationType
        let duration: Double
        let delay: Double
        let curve: AnimationCurve
        let repeatCount: Int?
        let autoReverse: Bool
        
        init(type: AnimationType, duration: Double = 0.3, delay: Double = 0.0, curve: AnimationCurve = .easeInOut, repeatCount: Int? = nil, autoReverse: Bool = false) {
            self.type = type
            self.duration = duration
            self.delay = delay
            self.curve = curve
            self.repeatCount = repeatCount
            self.autoReverse = autoReverse
        }
    }
    
    enum AnimationCurve {
        case easeInOut
        case easeIn
        case easeOut
        case linear
        case spring
        case bounce
        case elastic
        
        var swiftUIAnimation: Animation {
            switch self {
            case .easeInOut:
                return .easeInOut
            case .easeIn:
                return .easeIn
            case .easeOut:
                return .easeOut
            case .linear:
                return .linear
            case .spring:
                return .spring(response: 0.5, dampingFraction: 0.7)
            case .bounce:
                return .bouncy(duration: 0.6)
            case .elastic:
                return .interpolatingSpring(stiffness: 100, damping: 10)
            }
        }
    }
    
    // MARK: - Predefined Animation Presets
    
    static let quickFade = AnimationPreset(type: .fadeIn, duration: 0.2)
    static let smoothSlide = AnimationPreset(type: .slideUp, duration: 0.4, curve: .spring)
    static let bouncyScale = AnimationPreset(type: .scale, duration: 0.5, curve: .bounce)
    static let elasticBounce = AnimationPreset(type: .bounce, duration: 0.8, curve: .elastic)
    static let shimmerEffect = AnimationPreset(type: .shimmer, duration: 1.5, repeatCount: -1, autoReverse: true)
    static let pulseEffect = AnimationPreset(type: .pulse, duration: 1.0, repeatCount: -1, autoReverse: true)
    static let glowEffect = AnimationPreset(type: .glow, duration: 2.0, repeatCount: -1, autoReverse: true)
    
    // MARK: - Animation Execution
    
    func executeAnimation(_ preset: AnimationPreset, completion: (() -> Void)? = nil) {
        currentAnimation = preset.type
        isAnimating = true
        
        let animation = preset.curve.swiftUIAnimation
        
        withAnimation(animation) {
            // Animation will be handled by the view modifiers
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + preset.duration + preset.delay) {
            self.isAnimating = false
            self.currentAnimation = nil
            completion?()
        }
    }
    
    func executeSequence(_ presets: [AnimationPreset], completion: (() -> Void)? = nil) {
        guard !presets.isEmpty else {
            completion?()
            return
        }
        
        var remainingPresets = presets
        let currentPreset = remainingPresets.removeFirst()
        
        executeAnimation(currentPreset) {
            self.executeSequence(remainingPresets, completion: completion)
        }
    }
}

// MARK: - Animation View Modifiers

struct FadeInModifier: ViewModifier {
    @State private var opacity: Double = 0
    
    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.3)) {
                    opacity = 1
                }
            }
    }
}

struct SlideUpModifier: ViewModifier {
    @State private var offset: CGFloat = 50
    @State private var opacity: Double = 0
    
    func body(content: Content) -> some View {
        content
            .offset(y: offset)
            .opacity(opacity)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    offset = 0
                    opacity = 1
                }
            }
    }
}

struct SlideDownModifier: ViewModifier {
    @State private var offset: CGFloat = -50
    @State private var opacity: Double = 0
    
    func body(content: Content) -> some View {
        content
            .offset(y: offset)
            .opacity(opacity)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    offset = 0
                    opacity = 1
                }
            }
    }
}

struct ScaleModifier: ViewModifier {
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.bouncy(duration: 0.6)) {
                    scale = 1
                    opacity = 1
                }
            }
    }
}

struct BounceModifier: ViewModifier {
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.interpolatingSpring(stiffness: 100, damping: 10)) {
                    scale = 1
                    opacity = 1
                }
            }
    }
}

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(0.3),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .rotationEffect(.degrees(30))
                    .offset(x: phase)
                    .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: phase)
            )
            .onAppear {
                phase = 200
            }
    }
}

struct PulseModifier: ViewModifier {
    @State private var scale: CGFloat = 1.0
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: scale)
            .onAppear {
                scale = 1.1
            }
    }
}

struct GlowModifier: ViewModifier {
    @State private var glowIntensity: Double = 0.5
    
    func body(content: Content) -> some View {
        content
            .shadow(color: Color.white.opacity(glowIntensity), radius: 10)
            .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: glowIntensity)
            .onAppear {
                glowIntensity = 1.0
            }
    }
}

struct RippleModifier: ViewModifier {
    @State private var rippleScale: CGFloat = 0
    @State private var rippleOpacity: Double = 1
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(rippleOpacity), lineWidth: 2)
                    .scaleEffect(rippleScale)
                    .animation(.easeOut(duration: 0.6), value: rippleScale)
                    .animation(.easeOut(duration: 0.6), value: rippleOpacity)
            )
            .onAppear {
                rippleScale = 2
                rippleOpacity = 0
            }
    }
}

struct FlipModifier: ViewModifier {
    @State private var rotationY: Double = 0
    
    func body(content: Content) -> some View {
        content
            .rotation3DEffect(.degrees(rotationY), axis: (x: 0, y: 1, z: 0))
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    rotationY = 360
                }
            }
    }
}

struct RotateModifier: ViewModifier {
    @State private var rotation: Double = 0
    
    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}

// MARK: - View Extensions

extension View {
    func fadeIn() -> some View {
        self.modifier(FadeInModifier())
    }
    
    func slideUp() -> some View {
        self.modifier(SlideUpModifier())
    }
    
    func slideDown() -> some View {
        self.modifier(SlideDownModifier())
    }
    
    func scaleIn() -> some View {
        self.modifier(ScaleModifier())
    }
    
    func bounceIn() -> some View {
        self.modifier(BounceModifier())
    }
    
    func shimmer() -> some View {
        self.modifier(ShimmerModifier())
    }
    
    func pulse() -> some View {
        self.modifier(PulseModifier())
    }
    
    func glow() -> some View {
        self.modifier(GlowModifier())
    }
    
    func ripple() -> some View {
        self.modifier(RippleModifier())
    }
    
    func flip() -> some View {
        self.modifier(FlipModifier())
    }
    
    func rotate() -> some View {
        self.modifier(RotateModifier())
    }
    
    func animateWithPreset(_ preset: AnimationService.AnimationPreset) -> some View {
        switch preset.type {
        case .fadeIn:
            return AnyView(self.fadeIn())
        case .slideUp:
            return AnyView(self.slideUp())
        case .slideDown:
            return AnyView(self.slideDown())
        case .scale:
            return AnyView(self.scaleIn())
        case .bounce:
            return AnyView(self.bounceIn())
        case .shimmer:
            return AnyView(self.shimmer())
        case .pulse:
            return AnyView(self.pulse())
        case .glow:
            return AnyView(self.glow())
        case .ripple:
            return AnyView(self.ripple())
        case .flip:
            return AnyView(self.flip())
        case .rotate:
            return AnyView(self.rotate())
        default:
            return AnyView(self.fadeIn())
        }
    }
}

// MARK: - Staggered Animation

struct StaggeredAnimationModifier: ViewModifier {
    let delay: Double
    let animation: AnimationService.AnimationPreset
    
    @State private var isVisible = false
    
    func body(content: Content) -> some View {
        content
            .animateWithPreset(animation)
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation {
                        isVisible = true
                    }
                }
            }
    }
}

extension View {
    func staggeredAnimation(delay: Double, preset: AnimationService.AnimationPreset = AnimationService.quickFade) -> some View {
        self.modifier(StaggeredAnimationModifier(delay: delay, animation: preset))
    }
}

// MARK: - Interactive Animations

struct InteractiveScaleModifier: ViewModifier {
    @State private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
            }
    }
}

struct InteractiveGlowModifier: ViewModifier {
    @State private var isHovered = false
    
    func body(content: Content) -> some View {
        content
            .shadow(color: isHovered ? Color.white.opacity(0.5) : Color.clear, radius: isHovered ? 15 : 5)
            .animation(.easeInOut(duration: 0.3), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

extension View {
    func interactiveScale() -> some View {
        self.modifier(InteractiveScaleModifier())
    }
    
    func interactiveGlow() -> some View {
        self.modifier(InteractiveGlowModifier())
    }
}
