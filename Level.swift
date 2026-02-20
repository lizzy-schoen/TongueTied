import CoreGraphics
import Foundation

struct Level {
    let number: Int
    let name: String
    let description: String
    let targetZones: [ZoneType]
    let targetPattern: TouchPattern
    let idealSpeedRange: ClosedRange<CGFloat>   // points/sec of finger movement
    let duration: TimeInterval                  // seconds
    let targetScore: Int

    static let all: [Level] = [
        Level(
            number: 1,
            name: "First Touch",
            description: "Start gentle. Explore the outer labia\nwith slow up-and-down strokes.",
            targetZones: [ZoneType.outerLabiaLeft, ZoneType.outerLabiaRight],
            targetPattern: TouchPattern.upDown,
            idealSpeedRange: 50...150,
            duration: 30,
            targetScore: 1000
        ),
        Level(
            number: 2,
            name: "Getting Warmer",
            description: "Move inward. Try gentle\nside-to-side motions on the inner labia.",
            targetZones: [ZoneType.innerLabiaLeft, ZoneType.innerLabiaRight],
            targetPattern: TouchPattern.sideToSide,
            idealSpeedRange: 60...180,
            duration: 30,
            targetScore: 1400
        ),
        Level(
            number: 3,
            name: "The Approach",
            description: "Focus on the clitoral hood\nwith slow circular motions.",
            targetZones: [ZoneType.clitoralHood],
            targetPattern: TouchPattern.circular,
            idealSpeedRange: 80...200,
            duration: 45,
            targetScore: 2000
        ),
        Level(
            number: 4,
            name: "Center Stage",
            description: "Gentle circles on the clitoris.\nKeep a steady rhythm.",
            targetZones: [ZoneType.clitoris],
            targetPattern: TouchPattern.circular,
            idealSpeedRange: 100...250,
            duration: 45,
            targetScore: 2800
        ),
        Level(
            number: 5,
            name: "The Combo",
            description: "Alternate between the clitoris\nand vaginal opening. Mix it up!",
            targetZones: [ZoneType.clitoris, ZoneType.vaginalOpening],
            targetPattern: TouchPattern.upDown,
            idealSpeedRange: 100...300,
            duration: 60,
            targetScore: 3500
        ),
        Level(
            number: 6,
            name: "Freestyle",
            description: "Use everything you've learned.\nAll zones. Any pattern. High score time!",
            targetZones: Array(ZoneType.allCases),
            targetPattern: TouchPattern.unknown,        // any pattern counts
            idealSpeedRange: 50...400,
            duration: 90,
            targetScore: 5000
        )
    ]
}
