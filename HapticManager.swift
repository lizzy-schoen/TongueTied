import CoreHaptics
import UIKit

class HapticManager {
    private var engine: CHHapticEngine?
    private var continuousPlayer: CHHapticAdvancedPatternPlayer?
    private var isEngineRunning = false

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

    // MARK: - Continuous haptics (sustained touch)

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
        } catch {
            print("Haptic stop failed: \(error)")
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
