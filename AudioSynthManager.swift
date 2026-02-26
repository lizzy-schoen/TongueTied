import AVFoundation
import Foundation

struct SynthState {
    var isActive: Bool = false
    var fundamentalFreq: Float = 220.0
    var targetFreq: Float = 220.0
    var amplitude: Float = 0.0
    var excitement: Float = 0.0           // 0 = calm, 1 = peak
    var speedModulation: Float = 0.0      // 0–1 from touch speed accuracy
    var patternModulation: Float = 0.0    // 0–1 from pattern consistency
}

class AudioSynthManager {

    private var audioEngine: AVAudioEngine?
    private var sourceNode: AVAudioSourceNode?

    // State shared between main thread and audio thread
    private var state = SynthState()
    private var renderState = SynthState()
    private var stateNeedsUpdate = false
    private let stateLock = NSLock()

    // Oscillator phase accumulators (audio thread only)
    private var phases: [Double] = [0, 0, 0, 0, 0]
    private var vibratoPhase: Double = 0
    private var currentFreq: Float = 220.0
    private var currentAmplitude: Float = 0.0
    private var currentExcitement: Float = 0.0

    private let sampleRate: Double = 44100

    // Per-harmonic relative volumes (fundamental loudest, each partial softer)
    private let harmonicVolumes: [Float] = [1.0, 0.5, 0.35, 0.25, 0.18]

    private var resignObserver: Any?
    private var activeObserver: Any?

    // MARK: - Setup

    func setup() {
        let engine = AVAudioEngine()
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!

        let srcNode = AVAudioSourceNode(format: format) { [weak self] _, _, frameCount, bufferList -> OSStatus in
            guard let self else { return noErr }
            self.renderAudio(frameCount: frameCount, bufferList: bufferList)
            return noErr
        }

        engine.attach(srcNode)
        engine.connect(srcNode, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = 0.7

        self.audioEngine = engine
        self.sourceNode = srcNode

        do {
            try engine.start()
        } catch {
            print("Audio engine start failed: \(error)")
        }

        resignObserver = NotificationCenter.default.addObserver(
            forName: .appWillResignActive, object: nil, queue: .main
        ) { [weak self] _ in self?.pause() }

        activeObserver = NotificationCenter.default.addObserver(
            forName: .appDidBecomeActive, object: nil, queue: .main
        ) { [weak self] _ in self?.resume() }
    }

    // MARK: - State updates (called from main/game thread)

    func updateState(_ newState: SynthState) {
        stateLock.lock()
        state = newState
        stateNeedsUpdate = true
        stateLock.unlock()
    }

    func silence() {
        var s = SynthState()
        s.isActive = false
        s.amplitude = 0
        updateState(s)
    }

    // MARK: - Lifecycle

    func pause() {
        audioEngine?.pause()
    }

    func resume() {
        do {
            try audioEngine?.start()
        } catch {
            print("Audio engine resume failed: \(error)")
        }
    }

    deinit {
        if let o = resignObserver { NotificationCenter.default.removeObserver(o) }
        if let o = activeObserver { NotificationCenter.default.removeObserver(o) }
        audioEngine?.stop()
    }

    // MARK: - Audio render (called on real-time audio thread)

    private func renderAudio(frameCount: UInt32, bufferList: UnsafeMutablePointer<AudioBufferList>) {
        // Snapshot state if updated
        if stateNeedsUpdate {
            stateLock.lock()
            renderState = state
            stateNeedsUpdate = false
            stateLock.unlock()
        }

        let ablPointer = UnsafeMutableAudioBufferListPointer(bufferList)
        guard let buffer = ablPointer.first,
              let data = buffer.mData?.assumingMemoryBound(to: Float.self) else { return }

        let targetAmplitude = renderState.isActive ? renderState.amplitude : 0
        let targetFreq = renderState.targetFreq
        let targetExcitement = renderState.excitement

        // Smoothing coefficients
        let ampAttack: Float = 0.002    // ~20ms attack at 44.1kHz
        let ampRelease: Float = 0.0005  // ~40ms release
        let freqGlide: Float = 0.001    // portamento speed
        let exciteSmooth: Float = 0.001

        // Vibrato parameters
        let vibratoRate: Double = 4.0 + Double(renderState.speedModulation) * 4.0
        let vibratoDepth = Double(currentExcitement) * 3.0  // Hz deviation

        let twoPi = 2.0 * Double.pi

        for frame in 0..<Int(frameCount) {
            // Smooth amplitude
            let ampCoeff = currentAmplitude < targetAmplitude ? ampAttack : ampRelease
            currentAmplitude += (targetAmplitude - currentAmplitude) * ampCoeff

            // Smooth frequency (portamento)
            currentFreq += (targetFreq - currentFreq) * freqGlide

            // Smooth excitement
            currentExcitement += (targetExcitement - currentExcitement) * exciteSmooth

            // Vibrato LFO
            vibratoPhase += vibratoRate / sampleRate
            if vibratoPhase > 1.0 { vibratoPhase -= 1.0 }
            let vibratoOffset = sin(vibratoPhase * twoPi) * vibratoDepth

            // Additive synthesis: sum harmonics
            var sample: Float = 0

            for h in 0..<5 {
                // Each harmonic fades in based on excitement level
                let fadeThreshold = Float(h) * 0.2  // 0, 0.2, 0.4, 0.6, 0.8
                let harmonicGain: Float
                if currentExcitement > fadeThreshold {
                    harmonicGain = min(1.0, (currentExcitement - fadeThreshold) / 0.2) * harmonicVolumes[h]
                } else {
                    // Fundamental always audible at minimum
                    harmonicGain = h == 0 ? harmonicVolumes[0] : 0
                }

                // Advance phase for this harmonic
                let harmonicFreq = Double(currentFreq) * Double(h + 1) + vibratoOffset * Double(h + 1)
                phases[h] += harmonicFreq / sampleRate
                if phases[h] > 1.0 { phases[h] -= Double(Int(phases[h])) }

                sample += Float(sin(phases[h] * twoPi)) * harmonicGain
            }

            // Normalize and apply envelope
            let normalizer: Float = 1.0 / harmonicVolumes.reduce(0, +)
            sample *= normalizer * currentAmplitude

            // Soft clip to prevent harsh distortion
            sample = tanh(sample)

            data[frame] = sample
        }
    }
}
