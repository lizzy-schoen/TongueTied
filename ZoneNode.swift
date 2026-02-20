import SpriteKit

// MARK: - Zone type definitions

enum ZoneType: String, CaseIterable {
    case clitoris
    case clitoralHood
    case innerLabiaLeft
    case innerLabiaRight
    case outerLabiaLeft
    case outerLabiaRight
    case vaginalOpening

    var displayName: String {
        switch self {
        case .clitoris:        return "Clitoris"
        case .clitoralHood:    return "Clitoral Hood"
        case .innerLabiaLeft:  return "Inner Labia (L)"
        case .innerLabiaRight: return "Inner Labia (R)"
        case .outerLabiaLeft:  return "Outer Labia (L)"
        case .outerLabiaRight: return "Outer Labia (R)"
        case .vaginalOpening:  return "Vaginal Opening"
        }
    }

    /// Scoring multiplier — higher‑sensitivity zones award more points
    var sensitivity: CGFloat {
        switch self {
        case .clitoris:                                return 3.0
        case .clitoralHood:                            return 2.0
        case .innerLabiaLeft, .innerLabiaRight:        return 1.5
        case .vaginalOpening:                          return 1.5
        case .outerLabiaLeft, .outerLabiaRight:        return 1.0
        }
    }

    var baseColor: UIColor {
        switch self {
        case .clitoris:        return UIColor(red: 0.95, green: 0.60, blue: 0.65, alpha: 1)
        case .clitoralHood:    return UIColor(red: 0.92, green: 0.65, blue: 0.68, alpha: 1)
        case .innerLabiaLeft,
             .innerLabiaRight: return UIColor(red: 0.90, green: 0.62, blue: 0.66, alpha: 1)
        case .outerLabiaLeft,
             .outerLabiaRight: return UIColor(red: 0.88, green: 0.72, blue: 0.74, alpha: 1)
        case .vaginalOpening:  return UIColor(red: 0.85, green: 0.55, blue: 0.60, alpha: 1)
        }
    }

    var activeColor: UIColor {
        switch self {
        case .clitoris:        return UIColor(red: 1.00, green: 0.40, blue: 0.50, alpha: 1)
        case .clitoralHood:    return UIColor(red: 0.98, green: 0.45, blue: 0.53, alpha: 1)
        case .innerLabiaLeft,
             .innerLabiaRight: return UIColor(red: 0.95, green: 0.42, blue: 0.50, alpha: 1)
        case .outerLabiaLeft,
             .outerLabiaRight: return UIColor(red: 0.93, green: 0.55, blue: 0.60, alpha: 1)
        case .vaginalOpening:  return UIColor(red: 0.92, green: 0.38, blue: 0.48, alpha: 1)
        }
    }

    /// Core Haptics intensity when this zone is touched (0‑1)
    var hapticIntensity: Float {
        Float(sensitivity / 3.0)
    }
}

// MARK: - Zone sprite node

class ZoneNode: SKShapeNode {
    let zoneType: ZoneType
    private(set) var isBeingTouched = false

    init(zoneType: ZoneType, path: CGPath) {
        self.zoneType = zoneType
        super.init()
        self.path = path
        self.fillColor = zoneType.baseColor
        self.strokeColor = zoneType.baseColor.withAlphaComponent(0.3)
        self.lineWidth = 1
        self.name = zoneType.rawValue
        self.isUserInteractionEnabled = false   // parent scene handles touches
    }

    required init?(coder aDecoder: NSCoder) { fatalError("Not implemented") }

    func setTouched(_ touched: Bool) {
        isBeingTouched = touched
        fillColor = touched ? zoneType.activeColor : zoneType.baseColor
    }
}

// MARK: - UIColor interpolation helper

extension UIColor {
    func interpolated(to other: UIColor, fraction: CGFloat) -> UIColor {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        other.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        let t = max(0, min(1, fraction))
        return UIColor(red:   r1 + (r2 - r1) * t,
                       green: g1 + (g2 - g1) * t,
                       blue:  b1 + (b2 - b1) * t,
                       alpha: a1 + (a2 - a1) * t)
    }
}
