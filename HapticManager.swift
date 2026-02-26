import CoreHaptics
import UIKit

class HapticManager {
    private var engine: CHHapticEngine?
    private var continuousPlayer: CHHapticAdvancedPatternPlayer?
    private var proximityPlayer: CHHapticAdvancedPatternPlayer?
    private var isEngineRunning = false
    private var currentProfile: ZoneHapticProfile?

    init() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }

        do {
            engine = try CHHapticEngine()
            engine?.stoppedHandler = { [weak self] _ in
                self?.isEngineRunning = false
            }
            engine?.resetHandler = { [weak self] in
                do {
                    try self?.engine?.start()
                    self?.isEngineRunning = true
                } catch {
                    print("Failed to restart haptic engine: \(error)")
                }
            }
            try engine?.start()
            isEngineRunning = true
        } catch {
            print("Haptic engine creation failed: \(error)")
        }
    }

    // MARK: - Transient (tap) haptics

    func playTap(intensity: Float, sharpness: Float) {
        guard isEngineRunning, let engine else { return }

        do {
            let event = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
                ],
                relativeTime: 0
            )
            let player = try engine.makePlayer(with: CHHapticPattern(events: [event], parameters: []))
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("Haptic tap failed: \(error)")
        }
    }

    /// Sharp click when crossing between zones
    func playBorderBump() {
        playTap(intensity: 0.6, sharpness: 0.9)
    }

    // MARK: - Zone-textured continuous haptics

    func startContinuousForZone(_ profile: ZoneHapticProfile) {
        guard isEngineRunning, let engine else { return }
        stopContinuous()

        currentProfile = profile

        do {
            let event = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: profile.baseIntensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: profile.baseSharpness)
                ],
                relativeTime: 0,
                duration: 100
            )

            // Build intensity oscillation curve for the zone's texture
            let curveDuration: TimeInterval = 2.0
            let steps = 20
            var controlPoints: [CHHapticParameterCurve.ControlPoint] = []
            for i in 0...steps {
                let t = Float(i) / Float(steps) * Float(curveDuration)
                let sine = sinf(2.0 * .pi * profile.pulseFrequency * t)
                let modulation = sine * profile.pulseDepth
                controlPoints.append(
                    CHHapticParameterCurve.ControlPoint(relativeTime: TimeInterval(t), value: modulation)
                )
            }
            let intensityCurve = CHHapticParameterCurve(
                parameterID: .hapticIntensityControl,
                controlPoints: controlPoints,
                relativeTime: 0
            )

            let pattern = try CHHapticPattern(events: [event], parameterCurves: [intensityCurve])
            continuousPlayer = try engine.makeAdvancedPlayer(with: pattern)
            continuousPlayer?.loopEnabled = true
            continuousPlayer?.loopEnd = curveDuration
            try continuousPlayer?.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("Zone haptic failed: \(error)")
        }
    }

    // MARK: - Continuous haptics (basic — used for proximity)

    func startContinuous(intensity: Float, sharpness: Float) {
        guard isEngineRunning, let engine else { return }

        do {
            let event = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
                ],
                relativeTime: 0,
                duration: 100
            )
            continuousPlayer = try engine.makeAdvancedPlayer(with: CHHapticPattern(events: [event], parameters: []))
            try continuousPlayer?.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("Continuous haptic failed: \(error)")
        }
    }

    func updateContinuous(intensity: Float, sharpness: Float) {
        guard let player = continuousPlayer else { return }

        do {
            try player.sendParameters([
                CHHapticDynamicParameter(parameterID: .hapticIntensityControl, value: intensity, relativeTime: 0),
                CHHapticDynamicParameter(parameterID: .hapticSharpnessControl, value: sharpness, relativeTime: 0)
            ], atTime: CHHapticTimeImmediate)
        } catch {
            print("Haptic update failed: \(error)")
        }
    }

    func stopContinuous() {
        do {
            try continuousPlayer?.stop(atTime: CHHapticTimeImmediate)
            continuousPlayer = nil
            currentProfile = nil
        } catch {
            print("Haptic stop failed: \(error)")
        }
    }

    // MARK: - Proximity (hot/cold) haptics

    func playProximityFeedback(distance: CGFloat, maxDistance: CGFloat) {
        let proximity = Float(max(0, 1.0 - distance / maxDistance))

        guard proximity > 0.05 else {
            stopProximity()
            return
        }

        if proximityPlayer == nil {
            guard isEngineRunning, let engine else { return }
            do {
                let event = CHHapticEvent(
                    eventType: .hapticContinuous,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: proximity * 0.3),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1)
                    ],
                    relativeTime: 0,
                    duration: 100
                )
                proximityPlayer = try engine.makeAdvancedPlayer(
                    with: CHHapticPattern(events: [event], parameters: []))
                try proximityPlayer?.start(atTime: CHHapticTimeImmediate)
            } catch {
                print("Proximity haptic failed: \(error)")
            }
        } else {
            do {
                try proximityPlayer?.sendParameters([
                    CHHapticDynamicParameter(parameterID: .hapticIntensityControl,
                                             value: proximity * 0.3, relativeTime: 0),
                    CHHapticDynamicParameter(parameterID: .hapticSharpnessControl,
                                             value: proximity * 0.15, relativeTime: 0)
                ], atTime: CHHapticTimeImmediate)
            } catch {
                print("Proximity update failed: \(error)")
            }
        }
    }

    func stopProximity() {
        do {
            try proximityPlayer?.stop(atTime: CHHapticTimeImmediate)
            proximityPlayer = nil
        } catch {
            print("Proximity stop failed: \(error)")
        }
    }

    // MARK: - Pattern haptics

    /// Three ascending taps — played when completing a milestone
    func playSuccess() {
        guard isEngineRunning, let engine else { return }

        let events = [
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
            ], relativeTime: 0),
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
            ], relativeTime: 0.1),
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
            ], relativeTime: 0.2)
        ]

        do {
            let player = try engine.makePlayer(with: CHHapticPattern(events: events, parameters: []))
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("Success haptic failed: \(error)")
        }
    }

    /// Evenly spaced taps at a given BPM — used to guide the player's rhythm
    func playRhythm(bpm: Double, count: Int) {
        guard isEngineRunning, let engine else { return }

        let interval = 60.0 / bpm
        var events: [CHHapticEvent] = []

        for i in 0..<count {
            events.append(CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: i == 0 ? 0.8 : 0.5),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
                ],
                relativeTime: Double(i) * interval
            ))
        }

        do {
            let player = try engine.makePlayer(with: CHHapticPattern(events: events, parameters: []))
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("Rhythm haptic failed: \(error)")
        }
    }

    func stopEngine() {
        engine?.stop()
        isEngineRunning = false
    }
}
