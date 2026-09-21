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
    
    // Steering tilt value: -1.0 (hard left) to +1.0 (hard right)
    var tilt: CGFloat = 0.0
    
    // Raw tilt reading
    var rawRoll: Double = 0.0
    
    // Calibration zero-point offset
    var zeroOffset: Double = 0.0
    
    // Sensitivity multiplier
    var sensitivity: Double = 2.4
    
    // Deadzone
    var deadzone: Double = 0.02
    
    // Whether motion hardware is detected
    var isMotionAvailable: Bool = false
    
    // Manual touch steering fallback (when dragging the on-screen slider)
    var isTouchControlActive: Bool = false
    var manualTouchSteer: CGFloat = 0.0
    
    private var isUpdating: Bool = false
    
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
            // startDeviceMotionUpdates(to:) works reliably on all iPhones without reference frame restrictions
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
    
    func calibrate() {
        zeroOffset = rawRoll
    }
    
    #if canImport(CoreMotion) && !os(macOS)
    private func processDeviceMotion(_ motion: CMDeviceMotion) {
        // In portrait mode, gravity.x directly measures left/right tilt
        // Combining gravity.x and attitude.roll provides ultra-fluid steering
        let gravX = motion.gravity.x
        let rollVal = motion.attitude.roll
        
        // Use gravity.x as primary portrait tilt (positive = tilt right, negative = tilt left)
        let effectiveTilt = abs(gravX) > 0.05 ? gravX : (rollVal / (Double.pi / 3.0))
        rawRoll = effectiveTilt
        
        guard !isTouchControlActive else {
            tilt = manualTouchSteer
            return
        }
        
        let delta = effectiveTilt - zeroOffset
        var steer: Double = 0.0
        if abs(delta) > deadzone {
            steer = (delta > 0 ? (delta - deadzone) : (delta + deadzone)) * sensitivity
        }
        
        let clamped = max(-1.0, min(1.0, steer))
        
        // Exponential smoothing filter for smooth vehicle physics
        let alpha: CGFloat = 0.3
        tilt = tilt * (1.0 - alpha) + CGFloat(clamped) * alpha
    }
    
    private func processAccelerometer(_ data: CMAccelerometerData) {
        let currentX = data.acceleration.x
        rawRoll = currentX
        
        guard !isTouchControlActive else {
            tilt = manualTouchSteer
            return
        }
        
        let delta = currentX - zeroOffset
        let clamped = max(-1.0, min(1.0, delta * sensitivity))
        let alpha: CGFloat = 0.3
        tilt = tilt * (1.0 - alpha) + CGFloat(clamped) * alpha
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
