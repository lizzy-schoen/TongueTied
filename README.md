# TongueTied

An iOS game that teaches touch technique through haptic feedback and real-time audio synthesis. Built with SpriteKit, CoreHaptics, and AVAudioEngine.

## What it does

TongueTied guides players through 6 progressive levels, each targeting different zones and touch patterns (circular, up-and-down, side-to-side). Since the screen isn't visible during actual use, the app communicates entirely through:

- **Haptic textures** - Each zone has a distinct feel (slow throb, quick flutter, tight buzz, etc.)
- **Proximity haptics** - A "warmer/colder" haptic that intensifies as your finger approaches the target zone
- **Border bumps** - A crisp click when crossing between zones so you can feel the anatomy
- **Synthesized audio** - Warm additive tones that start relaxing and build in richness as your combo and score grow

## Tech stack

- **SpriteKit** - Game loop and rendering
- **CoreHaptics** - Zone-textured continuous haptics with parameter curves, transient border bumps, proximity feedback
- **AVAudioEngine** - Real-time additive synthesis (5-harmonic sine oscillator) with portamento, vibrato, and excitement-driven harmonic progression

## Requirements

- iOS 17.0+
- iPhone with haptic feedback support
- Xcode 15+

## Status

Work in progress.
