import SpriteKit

// MARK: - Color themes

struct ColorTheme {
    let name: String
    let previewColor: UIColor
    private let colors: [ZoneType: UIColor]

    func baseColor(for zone: ZoneType) -> UIColor {
        colors[zone] ?? .gray
    }

    func activeColor(for zone: ZoneType) -> UIColor {
        baseColor(for: zone).boosted()
    }

    // MARK: - Persistence

    private static let key = "selectedThemeIndex"

    static var currentIndex: Int {
        get { min(UserDefaults.standard.integer(forKey: key), all.count - 1) }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }

    static var current: ColorTheme { all[currentIndex] }

    @discardableResult
    static func cycleNext() -> ColorTheme {
        currentIndex = (currentIndex + 1) % all.count
        return current
    }

    // MARK: - Available themes

    private static func make(_ name: String, preview: UIColor,
                             outer: UIColor, inner: UIColor, vaginal: UIColor,
                             hood: UIColor, clit: UIColor) -> ColorTheme {
        ColorTheme(name: name, previewColor: preview, colors: [
            .outerLabiaLeft: outer, .outerLabiaRight: outer,
            .innerLabiaLeft: inner, .innerLabiaRight: inner,
            .vaginalOpening: vaginal,
            .clitoralHood: hood,
            .clitoris: clit,
        ])
    }

    static let all: [ColorTheme] = [
        make("Rose", preview: UIColor(red: 0.95, green: 0.60, blue: 0.65, alpha: 1),
             outer:   UIColor(red: 0.88, green: 0.72, blue: 0.74, alpha: 1),
             inner:   UIColor(red: 0.90, green: 0.62, blue: 0.66, alpha: 1),
             vaginal: UIColor(red: 0.85, green: 0.55, blue: 0.60, alpha: 1),
             hood:    UIColor(red: 0.92, green: 0.65, blue: 0.68, alpha: 1),
             clit:    UIColor(red: 0.95, green: 0.60, blue: 0.65, alpha: 1)),

        make("Light", preview: UIColor(red: 0.87, green: 0.75, blue: 0.65, alpha: 1),
             outer:   UIColor(red: 0.85, green: 0.73, blue: 0.63, alpha: 1),
             inner:   UIColor(red: 0.82, green: 0.65, blue: 0.55, alpha: 1),
             vaginal: UIColor(red: 0.78, green: 0.58, blue: 0.50, alpha: 1),
             hood:    UIColor(red: 0.84, green: 0.68, blue: 0.58, alpha: 1),
             clit:    UIColor(red: 0.88, green: 0.62, blue: 0.55, alpha: 1)),

        make("Warm", preview: UIColor(red: 0.72, green: 0.52, blue: 0.40, alpha: 1),
             outer:   UIColor(red: 0.72, green: 0.55, blue: 0.42, alpha: 1),
             inner:   UIColor(red: 0.68, green: 0.46, blue: 0.35, alpha: 1),
             vaginal: UIColor(red: 0.62, green: 0.40, blue: 0.30, alpha: 1),
             hood:    UIColor(red: 0.70, green: 0.50, blue: 0.38, alpha: 1),
             clit:    UIColor(red: 0.75, green: 0.45, blue: 0.35, alpha: 1)),

        make("Brown", preview: UIColor(red: 0.55, green: 0.38, blue: 0.28, alpha: 1),
             outer:   UIColor(red: 0.55, green: 0.38, blue: 0.28, alpha: 1),
             inner:   UIColor(red: 0.50, green: 0.32, blue: 0.22, alpha: 1),
             vaginal: UIColor(red: 0.45, green: 0.27, blue: 0.18, alpha: 1),
             hood:    UIColor(red: 0.52, green: 0.35, blue: 0.25, alpha: 1),
             clit:    UIColor(red: 0.58, green: 0.30, blue: 0.22, alpha: 1)),

        make("Deep", preview: UIColor(red: 0.38, green: 0.25, blue: 0.18, alpha: 1),
             outer:   UIColor(red: 0.38, green: 0.25, blue: 0.18, alpha: 1),
             inner:   UIColor(red: 0.34, green: 0.20, blue: 0.14, alpha: 1),
             vaginal: UIColor(red: 0.30, green: 0.16, blue: 0.11, alpha: 1),
             hood:    UIColor(red: 0.36, green: 0.22, blue: 0.16, alpha: 1),
             clit:    UIColor(red: 0.40, green: 0.18, blue: 0.14, alpha: 1)),

        make("Ocean", preview: UIColor(red: 0.45, green: 0.62, blue: 0.88, alpha: 1),
             outer:   UIColor(red: 0.55, green: 0.68, blue: 0.85, alpha: 1),
             inner:   UIColor(red: 0.48, green: 0.60, blue: 0.82, alpha: 1),
             vaginal: UIColor(red: 0.40, green: 0.52, blue: 0.78, alpha: 1),
             hood:    UIColor(red: 0.50, green: 0.63, blue: 0.84, alpha: 1),
             clit:    UIColor(red: 0.55, green: 0.58, blue: 0.90, alpha: 1)),

        make("Forest", preview: UIColor(red: 0.40, green: 0.72, blue: 0.48, alpha: 1),
             outer:   UIColor(red: 0.52, green: 0.75, blue: 0.55, alpha: 1),
             inner:   UIColor(red: 0.42, green: 0.70, blue: 0.48, alpha: 1),
             vaginal: UIColor(red: 0.35, green: 0.62, blue: 0.40, alpha: 1),
             hood:    UIColor(red: 0.45, green: 0.72, blue: 0.50, alpha: 1),
             clit:    UIColor(red: 0.50, green: 0.78, blue: 0.45, alpha: 1)),
    ]
}

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
        ColorTheme.current.baseColor(for: self)
    }

    var activeColor: UIColor {
        ColorTheme.current.activeColor(for: self)
    }

    /// Core Haptics intensity when this zone is touched (0‑1)
    var hapticIntensity: Float {
        Float(sensitivity / 3.0)
    }

    /// Base frequency for audio synthesis — musically related intervals
    var baseToneFrequency: Float {
        switch self {
        case .outerLabiaLeft, .outerLabiaRight: return 130.81  // C3
        case .innerLabiaLeft, .innerLabiaRight: return 196.00  // G3
        case .vaginalOpening:                   return 220.00  // A3
        case .clitoralHood:                     return 293.66  // D4
        case .clitoris:                         return 349.23  // F4
        }
    }
}

// MARK: - Zone sprite node

class ZoneNode: SKShapeNode {
    let zoneType: ZoneType
    private(set) var isBeingTouched = false

    var centroid: CGPoint {
        guard let path = self.path else { return .zero }
        let bounds = path.boundingBox
        return CGPoint(x: bounds.midX, y: bounds.midY)
    }

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

    func applyTheme() {
        fillColor = isBeingTouched ? zoneType.activeColor : zoneType.baseColor
        strokeColor = zoneType.baseColor.withAlphaComponent(0.3)
    }
}

// MARK: - UIColor interpolation helper

extension UIColor {
    func boosted() -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return UIColor(hue: h, saturation: min(1, s + 0.25),
                       brightness: min(1, b + 0.12), alpha: a)
    }

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
