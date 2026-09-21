import SwiftUI
import AVFoundation
import AudioToolbox

#if canImport(UIKit)
import UIKit
#endif

@Observable
final class SoundManager {
    static let shared = SoundManager()
    
    private var engine: AVAudioEngine?
    private var isAudioSetup = false
    
    // Haptic generators (available on iOS / UIKit)
    #if canImport(UIKit) && !os(watchOS) && !os(tvOS)
    private let lightHaptic = UIImpactFeedbackGenerator(style: .light)
    private let mediumHaptic = UIImpactFeedbackGenerator(style: .medium)
    private let heavyHaptic = UIImpactFeedbackGenerator(style: .heavy)
    private let rigidHaptic = UIImpactFeedbackGenerator(style: .rigid)
    private let notificationHaptic = UINotificationFeedbackGenerator()
    #endif
    
    var isMuted: Bool = false
    
    init() {
        prepareHaptics()
        setupAudioSession()
    }
    
    private func prepareHaptics() {
        #if canImport(UIKit) && !os(watchOS) && !os(tvOS)
        lightHaptic.prepare()
        mediumHaptic.prepare()
        heavyHaptic.prepare()
        rigidHaptic.prepare()
        notificationHaptic.prepare()
        #endif
    }
    
    private func setupAudioSession() {
        #if canImport(AVFoundation) && !os(macOS)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("Audio session configuration error: \(error)")
        }
        #endif
    }
    
    // MARK: - Procedural Sound Generation
    
    /// Dual tone car horn (440Hz + 554Hz) with harmonic envelope
    func playHonk() {
        #if canImport(UIKit) && !os(watchOS) && !os(tvOS)
        heavyHaptic.impactOccurred(intensity: 0.9)
        #endif
        guard !isMuted else { return }
        
        playTone(frequencies: [440.0, 554.37, 880.0], duration: 0.35, volumes: [0.35, 0.3, 0.15])
    }
    
    /// Tactile iOS keyboard tap click
    func playKeyClick() {
        #if canImport(UIKit) && !os(watchOS) && !os(tvOS)
        lightHaptic.impactOccurred(intensity: 0.5)
        #endif
        guard !isMuted else { return }
        
        // System click or short tone
        AudioServicesPlaySystemSound(1104) // Standard iOS keyboard click ID
    }
    
    /// Monkeytype typo error buzz tone and haptic
    func playTypoError() {
        #if canImport(UIKit) && !os(watchOS) && !os(tvOS)
        rigidHaptic.impactOccurred(intensity: 0.9)
        #endif
        guard !isMuted else { return }
        
        // Short low dissonant buzz (330Hz + 311Hz)
        playTone(frequencies: [330.0, 311.13], duration: 0.12, volumes: [0.35, 0.35])
    }
    
    /// Incoming text notification chime
    func playIncomingMessage() {
        #if canImport(UIKit) && !os(watchOS) && !os(tvOS)
        mediumHaptic.impactOccurred(intensity: 0.7)
        #endif
        guard !isMuted else { return }
        
        // Play melodious 3-tone arpeggio (C5 -> E5 -> G5)
        playSequence(tones: [
            (523.25, 0.08, 0.25),
            (659.25, 0.08, 0.25),
            (783.99, 0.18, 0.35)
        ])
    }
    
    /// Outgoing message sent swoosh/ping
    func playMessageSent() {
        #if canImport(UIKit) && !os(watchOS) && !os(tvOS)
        rigidHaptic.impactOccurred(intensity: 0.8)
        #endif
        guard !isMuted else { return }
        
        playSequence(tones: [
            (659.25, 0.06, 0.2),
            (1046.50, 0.16, 0.3)
        ])
    }
    
    /// Near-miss or pedestrian saved alert ping
    func playPedestrianSaved() {
        #if canImport(UIKit) && !os(watchOS) && !os(tvOS)
        mediumHaptic.impactOccurred(intensity: 0.6)
        #endif
        guard !isMuted else { return }
        
        playSequence(tones: [
            (587.33, 0.06, 0.2),
            (880.0, 0.14, 0.3)
        ])
    }
    
    /// Dramatic crash explosion rumble
    func playCrash() {
        #if canImport(UIKit) && !os(watchOS) && !os(tvOS)
        notificationHaptic.notificationOccurred(.error)
        heavyHaptic.impactOccurred(intensity: 1.0)
        #endif
        guard !isMuted else { return }
        
        // Low frequency discord crash
        playTone(frequencies: [110.0, 116.54, 130.81, 65.0], duration: 0.8, volumes: [0.4, 0.35, 0.3, 0.4])
    }
    
    // MARK: - Tone Synthesizer Helper
    
    private func playTone(frequencies: [Double], duration: Double, volumes: [Float]) {
        DispatchQueue.global(qos: .userInteractive).async {
            let sampleRate = 44100.0
            let numSamples = Int(sampleRate * duration)
            var samples = [Float](repeating: 0.0, count: numSamples)
            
            for i in 0..<numSamples {
                let time = Double(i) / sampleRate
                // Attack and exponential decay envelope
                let progress = Double(i) / Double(numSamples)
                let attack = min(1.0, progress * 20.0) // 5% attack
                let decay = exp(-progress * 3.5)
                let envelope = Float(attack * decay)
                
                var mixedSample: Float = 0.0
                for (idx, freq) in frequencies.enumerated() {
                    let vol = idx < volumes.count ? volumes[idx] : 0.2
                    let sine = sin(2.0 * Double.pi * freq * time)
                    mixedSample += Float(sine) * vol
                }
                samples[i] = mixedSample * envelope
            }
            
            self.renderAndPlayPCM(samples: samples, sampleRate: sampleRate)
        }
    }
    
    private func playSequence(tones: [(freq: Double, duration: Double, vol: Float)]) {
        DispatchQueue.global(qos: .userInteractive).async {
            var allSamples: [Float] = []
            let sampleRate = 44100.0
            
            for tone in tones {
                let numSamples = Int(sampleRate * tone.duration)
                for i in 0..<numSamples {
                    let time = Double(i) / sampleRate
                    let progress = Double(i) / Double(numSamples)
                    let attack = min(1.0, progress * 15.0)
                    let decay = exp(-progress * 4.0)
                    let envelope = Float(attack * decay)
                    let sine = Float(sin(2.0 * Double.pi * tone.freq * time))
                    allSamples.append(sine * tone.vol * envelope)
                }
            }
            
            self.renderAndPlayPCM(samples: allSamples, sampleRate: sampleRate)
        }
    }
    
    private func renderAndPlayPCM(samples: [Float], sampleRate: Double) {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        guard let pcmBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count)) else {
            return
        }
        pcmBuffer.frameLength = AVAudioFrameCount(samples.count)
        
        let channelData = pcmBuffer.floatChannelData![0]
        for (i, sample) in samples.enumerated() {
            channelData[i] = sample
        }
        
        let player = AVAudioPlayerNode()
        let localEngine = AVAudioEngine()
        localEngine.attach(player)
        localEngine.connect(player, to: localEngine.mainMixerNode, format: format)
        
        do {
            try localEngine.start()
            player.play()
            player.scheduleBuffer(pcmBuffer, at: nil, options: []) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    localEngine.stop()
                    localEngine.detach(player)
                }
            }
        } catch {
            print("Failed to start sound engine: \(error)")
        }
    }
}
