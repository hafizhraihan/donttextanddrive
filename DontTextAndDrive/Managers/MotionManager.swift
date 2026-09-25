import SwiftUI
#if canImport(CoreMotion) && !os(macOS)
import CoreMotion
#endif
import Combine

@Observable
final class MotionManager {
    #if canImport(CoreMotion) && !os(macOS)
    private let motionManager = CMMotionManager()
    #endif
    
    // Normalized Steering tilt value: -1.0 (hard left) to +1.0 (hard right)
    var tilt: CGFloat = 0.0
    
    // Raw lateral gravity reading
    var rawRoll: Double = 0.0
    
    // Calibrated neutral baseline offset (persisted in UserDefaults across sessions & plays)
    var neutralOffset: Double = UserDefaults.standard.double(forKey: "DTAD_NeutralOffset")
    
    // Smoothed roll baseline for noise-free manual calibration
    private var smoothedRoll: Double = 0.0
    
    // Maximum comfortable tilt angle in radians (sin(16°) ≈ 0.28)
    var maxTiltRange: Double = 0.28
    
    // Stable deadzone around center (~1.5°) to prevent twitching when holding straight
    var deadzone: Double = 0.025
    
    // Dynamic sensitivity multiplier
    var sensitivity: Double = 1.0
    
    // Whether motion hardware is detected
    var isMotionAvailable: Bool = false
    
    // Manual touch steering fallback (for simulator or explicit touch drag)
    var isTouchControlActive: Bool = false
    var manualTouchSteer: CGFloat = 0.0
    
    private var isUpdating: Bool = false
    private var hasFirstSample: Bool = false
    
    init() {
        checkAvailability()
        start()
    }
    
    func checkAvailability() {
        #if canImport(CoreMotion) && !os(macOS)
        isMotionAvailable = motionManager.isDeviceMotionAvailable || motionManager.isAccelerometerAvailable
        #else
        isMotionAvailable = false
        #endif
    }
    
    func start() {
        guard !isUpdating else { return }
        #if canImport(CoreMotion) && !os(macOS)
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
            motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
                guard let self = self, let motion = motion else { return }
                self.processDeviceMotion(motion)
            }
            isUpdating = true
        } else if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 1.0 / 60.0
            motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
                guard let self = self, let data = data else { return }
                self.processAccelerometer(data)
            }
            isUpdating = true
        }
        #endif
    }
    
    func stop() {
        #if canImport(CoreMotion) && !os(macOS)
        if motionManager.isDeviceMotionActive {
            motionManager.stopDeviceMotionUpdates()
        }
        if motionManager.isAccelerometerActive {
            motionManager.stopAccelerometerUpdates()
        }
        #endif
        isUpdating = false
    }
    
    /// Calibrates neutral to the current smoothed resting angle and persists it
    func calibrate() {
        neutralOffset = smoothedRoll
        UserDefaults.standard.set(neutralOffset, forKey: "DTAD_NeutralOffset")
    }
    
    /// Resets calibration back to true physical upright (0.0)
    func resetCalibration() {
        neutralOffset = 0.0
        UserDefaults.standard.set(0.0, forKey: "DTAD_NeutralOffset")
    }
    
    #if canImport(CoreMotion) && !os(macOS)
    private func processDeviceMotion(_ motion: CMDeviceMotion) {
        // In portrait mode, gravity.x measures pure lateral tilt relative to Earth's gravity vector.
        let gravX = motion.gravity.x
        rawRoll = gravX
        
        if !hasFirstSample {
            smoothedRoll = gravX
            hasFirstSample = true
        } else {
            // Continuous low-pass filter for smooth resting reference
            smoothedRoll = smoothedRoll * 0.90 + gravX * 0.10
        }
        
        guard !isTouchControlActive else {
            tilt = manualTouchSteer
            return
        }
        
        // Deterministic relative tilt from the persistent neutral baseline
        let delta = gravX - neutralOffset
        
        var steer: Double = 0.0
        if abs(delta) > deadzone {
            let sign = delta > 0 ? 1.0 : -1.0
            let activeMagnitude = (abs(delta) - deadzone) / (maxTiltRange - deadzone)
            let normalized = min(1.0, max(0.0, activeMagnitude))
            
            // Progressive ergonomic curve: smooth precision near center, responsive sharp turns on full tilt
            steer = sign * pow(normalized, 1.15) * sensitivity
        }
        
        let targetTilt = CGFloat(max(-1.0, min(1.0, steer)))
        
        // 60Hz Exponential low-pass filter for silky smooth response without jitter
        let alpha: CGFloat = 0.25
        tilt = tilt * (1.0 - alpha) + targetTilt * alpha
    }
    
    private func processAccelerometer(_ data: CMAccelerometerData) {
        let currentX = data.acceleration.x
        rawRoll = currentX
        
        if !hasFirstSample {
            smoothedRoll = currentX
            hasFirstSample = true
        } else {
            smoothedRoll = smoothedRoll * 0.90 + currentX * 0.10
        }
        
        guard !isTouchControlActive else {
            tilt = manualTouchSteer
            return
        }
        
        let delta = currentX - neutralOffset
        var steer: Double = 0.0
        if abs(delta) > deadzone {
            let sign = delta > 0 ? 1.0 : -1.0
            let normalized = min(1.0, max(0.0, (abs(delta) - deadzone) / (maxTiltRange - deadzone)))
            steer = sign * pow(normalized, 1.15) * sensitivity
        }
        
        let targetTilt = CGFloat(max(-1.0, min(1.0, steer)))
        let alpha: CGFloat = 0.25
        tilt = tilt * (1.0 - alpha) + targetTilt * alpha
    }
    #endif
    
    func setTouchSteering(_ value: CGFloat) {
        isTouchControlActive = true
        manualTouchSteer = max(-1.0, min(1.0, value))
        tilt = manualTouchSteer
    }
    
    func releaseTouchSteering() {
        isTouchControlActive = false
        manualTouchSteer = 0.0
        if !isMotionAvailable {
            tilt = 0.0
        }
    }
}

