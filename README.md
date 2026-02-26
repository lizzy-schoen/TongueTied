# TongueTied

A playful iOS app that helps people practice and improve their oral sex technique. Use your phone screen as a solo training tool — haptic feedback and responsive audio guide your touch so you can build muscle memory and confidence on your own.

## Why this exists

Good technique is hard to learn from reading about it. TongueTied turns your phone into a practice tool by mapping vulvar anatomy onto the screen and giving you real-time feedback on *where* you're touching, *how* you're moving, and *whether you're doing it well* — all through vibration and sound so you can train by feel.

## How it works

The app walks you through 6 progressive levels, from gentle outer exploration to focused clitoral stimulation to freestyle. Each level teaches a different zone, motion pattern, and speed. You score points for accuracy, rhythm, and consistency.

Since you can't see the screen during actual use, the app communicates entirely through feel and sound:

- **Haptic textures** - Each anatomical zone has a distinct vibration feel (slow throb for outer labia, tight buzz for clitoris, smooth wave for clitoral hood) so you can tell where you are without looking
- **Proximity haptics** - A "warmer/colder" vibration that intensifies as you approach the target zone
- **Border bumps** - A crisp click when crossing between zones so you can feel the anatomy's boundaries
- **Synthesized audio** - Warm tones that start calm and ambient, then build in richness and intensity as your technique improves — the better you do, the better it sounds

## Tech stack

- **SpriteKit** - Game loop, touch tracking, and zone rendering
- **CoreHaptics** - Zone-textured continuous haptics with parameter curves, transient border bumps, proximity feedback
- **AVAudioEngine** - Real-time additive synthesis (5-harmonic sine oscillator) with portamento between zones, vibrato, and excitement-driven harmonic progression

## Requirements

- iOS 17.0+
- iPhone with haptic feedback support (iPhone 8 or later)
- Xcode 15+ to build

## Status

Work in progress — core gameplay, haptics, and audio synthesis are functional.

### Upcoming
- Leaderboard
- More levels and patterns

Contributions and ideas welcome.
