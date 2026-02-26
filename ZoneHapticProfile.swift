import CoreHaptics

struct ZoneHapticProfile {
    let baseIntensity: Float
    let baseSharpness: Float
    let pulseFrequency: Float       // Hz — how fast the texture oscillates
    let pulseDepth: Float           // 0–1 amplitude modulation depth
    let attackTime: Float           // seconds to ramp up
    let sustainSharpnessRange: ClosedRange<Float>
}

extension ZoneType {
    var hapticProfile: ZoneHapticProfile {
        switch self {
        case .outerLabiaLeft, .outerLabiaRight:
            // Slow gentle pulse
            return ZoneHapticProfile(
                baseIntensity: 0.35,
                baseSharpness: 0.15,
                pulseFrequency: 2.0,
                pulseDepth: 0.3,
                attackTime: 0.15,
                sustainSharpnessRange: 0.10...0.25
            )
        case .innerLabiaLeft, .innerLabiaRight:
            // Quicker flutter
            return ZoneHapticProfile(
                baseIntensity: 0.50,
                baseSharpness: 0.35,
                pulseFrequency: 5.0,
                pulseDepth: 0.4,
                attackTime: 0.10,
                sustainSharpnessRange: 0.25...0.45
            )
        case .clitoralHood:
            // Smooth wave
            return ZoneHapticProfile(
                baseIntensity: 0.65,
                baseSharpness: 0.20,
                pulseFrequency: 1.5,
                pulseDepth: 0.25,
                attackTime: 0.08,
                sustainSharpnessRange: 0.15...0.30
            )
        case .clitoris:
            // Tight fast buzz
            return ZoneHapticProfile(
                baseIntensity: 1.0,
                baseSharpness: 0.70,
                pulseFrequency: 12.0,
                pulseDepth: 0.15,
                attackTime: 0.05,
                sustainSharpnessRange: 0.55...0.80
            )
        case .vaginalOpening:
            // Deep steady throb
            return ZoneHapticProfile(
                baseIntensity: 0.55,
                baseSharpness: 0.25,
                pulseFrequency: 3.0,
                pulseDepth: 0.35,
                attackTime: 0.12,
                sustainSharpnessRange: 0.20...0.35
            )
        }
    }
}
