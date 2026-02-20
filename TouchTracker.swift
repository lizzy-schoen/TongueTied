import CoreGraphics
import Foundation

enum TouchPattern: String {
    case circular    = "Circular"
    case upDown      = "Up & Down"
    case sideToSide  = "Side to Side"
    case sustained   = "Sustained"
    case unknown     = "—"
}

struct TouchSample {
    let position: CGPoint
    let timestamp: TimeInterval
}

class TouchTracker {
    private var samples: [TouchSample] = []
    private let maxSamples = 60          // ~1 second at 60 fps
    private let patternWindowSize = 30

    private(set) var currentSpeed: CGFloat = 0
    private(set) var averageSpeed: CGFloat = 0
    private(set) var currentPattern: TouchPattern = .unknown
    private(set) var patternConsistency: CGFloat = 0   // 0‑1

    // MARK: - Public

    func addSample(position: CGPoint, timestamp: TimeInterval) {
        samples.append(TouchSample(position: position, timestamp: timestamp))
        if samples.count > maxSamples { samples.removeFirst() }
        updateMetrics()
    }

    func reset() {
        samples.removeAll()
        currentSpeed = 0
        averageSpeed = 0
        currentPattern = .unknown
        patternConsistency = 0
    }

    /// 0 = too slow, 1 = in range, 2 = too fast
    func speedRating(idealRange: ClosedRange<CGFloat>) -> Int {
        if averageSpeed < idealRange.lowerBound { return 0 }
        if averageSpeed > idealRange.upperBound { return 2 }
        return 1
    }

    /// 0‑1 score for how close the current speed is to the ideal midpoint
    func speedScore(idealRange: ClosedRange<CGFloat>) -> CGFloat {
        let mid = (idealRange.lowerBound + idealRange.upperBound) / 2
        let half = (idealRange.upperBound - idealRange.lowerBound) / 2
        let distance = abs(averageSpeed - mid)
        return max(0, 1.0 - distance / (half * 2))
    }

    // MARK: - Private

    private func updateMetrics() {
        updateSpeed()
        if samples.count >= 10 { updatePattern() }
    }

    private func updateSpeed() {
        guard samples.count >= 2 else {
            currentSpeed = 0; averageSpeed = 0; return
        }

        let last = samples[samples.count - 1]
        let prev = samples[samples.count - 2]
        let dt = last.timestamp - prev.timestamp
        guard dt > 0 else { return }

        currentSpeed = hypot(last.position.x - prev.position.x,
                             last.position.y - prev.position.y) / CGFloat(dt)

        var totalDist: CGFloat = 0
        for i in 1..<samples.count {
            totalDist += hypot(samples[i].position.x - samples[i-1].position.x,
                               samples[i].position.y - samples[i-1].position.y)
        }
        let totalTime = samples.last!.timestamp - samples.first!.timestamp
        averageSpeed = totalTime > 0 ? totalDist / CGFloat(totalTime) : 0
    }

    private func updatePattern() {
        let window = Array(samples.suffix(patternWindowSize))
        guard window.count >= 10 else { return }

        // Build velocity vectors
        var velocities: [CGVector] = []
        for i in 1..<window.count {
            let dt = window[i].timestamp - window[i-1].timestamp
            guard dt > 0 else { continue }
            velocities.append(CGVector(
                dx: (window[i].position.x - window[i-1].position.x) / CGFloat(dt),
                dy: (window[i].position.y - window[i-1].position.y) / CGFloat(dt)
            ))
        }
        guard velocities.count >= 5 else { return }

        // Average magnitude — if very low, the finger is holding still
        let avgMag = velocities.reduce(CGFloat(0)) {
            $0 + hypot($1.dx, $1.dy)
        } / CGFloat(velocities.count)

        if avgMag < 20 {
            currentPattern = .sustained
            patternConsistency = 1.0 - (avgMag / 20.0)
            return
        }

        // Cross products → detect consistent rotation (circular)
        var crossProducts: [CGFloat] = []
        for i in 1..<velocities.count {
            crossProducts.append(
                velocities[i-1].dx * velocities[i].dy - velocities[i-1].dy * velocities[i].dx
            )
        }
        let dominant = CGFloat(max(crossProducts.filter { $0 > 0 }.count,
                                   crossProducts.filter { $0 < 0 }.count))
            / CGFloat(crossProducts.count)

        // Y‑direction changes → up/down oscillation
        var yChanges = 0
        for i in 1..<velocities.count where velocities[i].dy * velocities[i-1].dy < 0 {
            yChanges += 1
        }
        let yOsc = CGFloat(yChanges) / CGFloat(velocities.count - 1)

        // X‑direction changes → side‑to‑side oscillation
        var xChanges = 0
        for i in 1..<velocities.count where velocities[i].dx * velocities[i-1].dx < 0 {
            xChanges += 1
        }
        let xOsc = CGFloat(xChanges) / CGFloat(velocities.count - 1)

        // Pick the strongest signal
        if dominant > 0.7 {
            currentPattern = .circular
            patternConsistency = dominant
        } else if yOsc > 0.4 && yOsc > xOsc {
            currentPattern = .upDown
            patternConsistency = yOsc
        } else if xOsc > 0.4 {
            currentPattern = .sideToSide
            patternConsistency = xOsc
        } else {
            currentPattern = .unknown
            patternConsistency = 0
        }
    }
}
