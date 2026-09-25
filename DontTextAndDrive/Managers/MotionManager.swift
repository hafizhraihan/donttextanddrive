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
    
    // Auto-centering adaptive neutral offset
    var adaptiveNeutralOffset: Double = 0.0
    
    // Maximum comfortable tilt in radians (sin(20°) ≈ 0.342)
    var maxTiltRange: Double = 0.34
    
    // Minimal deadband for finger tremors (~0.8°)
    var deadzone: Double = 0.015
    
    // Dynamic sensitivity multiplier
    var sensitivity: Double = 1.0
    
    // Whether motion hardware is detected
    var isMotionAvailable: Bool = false
    
    // Manual touch steering fallback (when dragging on-screen controls)
    var isTouchControlActive: Bool = false
    var manualTouchSteer: CGFloat = 0.0
    
    private var isUpdating: Bool = false
    private var isInitialSampleCaptured: Bool = false
    
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
            // startDeviceMotionUpdates with main queue for 60Hz ultra-low latency response
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
    
    /// Auto-calibrates immediately to the current hand orientation
    func calibrate() {
        adaptiveNeutralOffset = rawRoll
        isInitialSampleCaptured = true
    }
    
    #if canImport(CoreMotion) && !os(macOS)
    private func processDeviceMotion(_ motion: CMDeviceMotion) {
        // In portrait mode, gravity.x measures pure lateral tilt relative to Earth's gravity vector.
        // It is drift-free, absolute, and independent of whether the phone is tilted toward or away from the face.
        let gravX = motion.gravity.x
        rawRoll = gravX
        
        if !isInitialSampleCaptured {
            // First frame auto-snap neutral position
            adaptiveNeutralOffset = gravX
            isInitialSampleCaptured = true
        }
        
        guard !isTouchControlActive else {
            tilt = manualTouchSteer
            return
        }
        
        // Dynamic Adaptive Auto-Centering (Self-Calibrating Neutral Learning):
        // When the device is held relatively steady (low rotational speed) and near center,
        // gently adapt the resting neutral point to accommodate shifting hand positions seamlessly.
        let rotSpeedZ = abs(motion.rotationRate.z)
        let distanceFromNeutral = abs(gravX - adaptiveNeutralOffset)
        if rotSpeedZ < 0.18 && distanceFromNeutral < 0.15 {
            // Gentle learning rate: smoothly tracks resting position over 2-3 seconds
            adaptiveNeutralOffset += (gravX - adaptiveNeutralOffset) * 0.015
        }
        
        // Calculate true relative tilt from adaptive neutral
        let delta = gravX - adaptiveNeutralOffset
        
        var steer: Double = 0.0
        if abs(delta) > deadzone {
            let sign = delta > 0 ? 1.0 : -1.0
            let activeMagnitude = (abs(delta) - deadzone) / (maxTiltRange - deadzone)
            let normalized = min(1.0, max(0.0, activeMagnitude))
            
            // Progressive ergonomic curve: smooth precision near center, responsive sharp turns on full tilt
            steer = sign * pow(normalized, 1.22) * sensitivity
        }
        
        let targetTilt = CGFloat(max(-1.0, min(1.0, steer)))
        
        // 60Hz Exponential low-pass smoothing filter (eradicates hand jitter without perceived latency)
        let alpha: CGFloat = 0.28
        tilt = tilt * (1.0 - alpha) + targetTilt * alpha
    }
    
    private func processAccelerometer(_ data: CMAccelerometerData) {
        let currentX = data.acceleration.x
        rawRoll = currentX
        
        if !isInitialSampleCaptured {
            adaptiveNeutralOffset = currentX
            isInitialSampleCaptured = true
        }
        
        guard !isTouchControlActive else {
            tilt = manualTouchSteer
            return
        }
        
        let delta = currentX - adaptiveNeutralOffset
        var steer: Double = 0.0
        if abs(delta) > deadzone {
            let sign = delta > 0 ? 1.0 : -1.0
            let normalized = min(1.0, max(0.0, (abs(delta) - deadzone) / (maxTiltRange - deadzone)))
            steer = sign * pow(normalized, 1.22) * sensitivity
        }
        
        let targetTilt = CGFloat(max(-1.0, min(1.0, steer)))
        let alpha: CGFloat = 0.28
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
