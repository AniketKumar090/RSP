import Foundation
import AVFoundation
import Vision

final class CameraManager: NSObject, ObservableObject {
    let captureSession = AVCaptureSession()
    private var deviceInput: AVCaptureDeviceInput?
    private var videoOutput: AVCaptureVideoDataOutput?
    private let systemPreferredCamera = AVCaptureDevice.default(for: .video)
    private let sessionQueue = DispatchQueue(label: "video.preview.session")
    
    private let handPoseRequest = VNDetectHumanHandPoseRequest()
    private let handPoseClassifier: HandPose_
    
    @Published var handPrediction: String?
    @Published var predictionConfidence: Float = 0.0
    @Published var errorMessage: String?
    @Published var isSessionRunning = false
    
    // Enhanced detection parameters
    private var recentPredictions: [String] = []
    private let maxRecentPredictions = 5
    
    // Session configuration state
    private var isConfigured = false
    
    override init() {
        do {
            handPoseClassifier = try HandPose_(configuration: MLModelConfiguration())
            super.init()
            
            // Configure hand pose request for better accuracy
            handPoseRequest.maximumHandCount = 1
            handPoseRequest.revision = VNDetectHumanHandPoseRequestRevision1
            
            Task {
                await configureSession()
            }
        } catch {
            fatalError("Failed to load MLModel: \(error.localizedDescription)")
        }
    }
    
    private func configureSession() async {
        guard await isAuthorized(),
              let camera = systemPreferredCamera else {
            DispatchQueue.main.async {
                self.errorMessage = "Camera setup failed"
            }
            return
        }
        
        do {
            let deviceInput = try AVCaptureDeviceInput(device: camera)
            let videoOutput = AVCaptureVideoDataOutput()
            
            // Configure video output for better performance
            videoOutput.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
            ]
            videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
            
            await MainActor.run {
                captureSession.beginConfiguration()
                
                // Set session preset for better quality
                if captureSession.canSetSessionPreset(.high) {
                    captureSession.sessionPreset = .high
                }
                
                guard captureSession.canAddInput(deviceInput) else {
                    self.errorMessage = "Input addition failed"
                    captureSession.commitConfiguration()
                    return
                }
                captureSession.addInput(deviceInput)
                
                guard captureSession.canAddOutput(videoOutput) else {
                    self.errorMessage = "Output addition failed"
                    captureSession.commitConfiguration()
                    return
                }
                captureSession.addOutput(videoOutput)
                
                captureSession.commitConfiguration()
                
                self.deviceInput = deviceInput
                self.videoOutput = videoOutput
                self.isConfigured = true
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to configure session: \(error.localizedDescription)"
            }
        }
    }
    
    func startSession() {
        guard isConfigured else {
            Task {
                await configureSession()
                if isConfigured {
                    startSessionInternal()
                }
            }
            return
        }
        
        startSessionInternal()
    }
    
    private func startSessionInternal() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
                
                DispatchQueue.main.async {
                    self.isSessionRunning = true
                    // Clear previous predictions when starting new session
                    self.handPrediction = nil
                    self.recentPredictions.removeAll()
                }
            }
        }
    }
    
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
                
                DispatchQueue.main.async {
                    self.isSessionRunning = false
                    // Don't clear hand prediction when stopping - let it remain locked
                }
            }
        }
    }
    
    private func isAuthorized() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        default:
            return false
        }
    }
    
    // Enhanced prediction stabilization
    private func stabilizePrediction(_ newPrediction: String, confidence: Float) -> String? {
        // Only consider predictions with reasonable confidence
        guard confidence > 0.5 else { return nil }
        
        recentPredictions.append(newPrediction)
        if recentPredictions.count > maxRecentPredictions {
            recentPredictions.removeFirst()
        }
        
        // Return most common prediction if we have enough samples
        if recentPredictions.count >= 3 {
            let predictionCounts = Dictionary(grouping: recentPredictions, by: { $0 })
                .mapValues { $0.count }
            
            if let mostCommon = predictionCounts.max(by: { $0.value < $1.value }),
               mostCommon.value >= 2 {
                return mostCommon.key
            }
        }
        
        return newPrediction
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Only process frames if session is running
        guard isSessionRunning else { return }
        
        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, options: [:])
        
        do {
            try handler.perform([handPoseRequest])
            
            if let handObservation = handPoseRequest.results?.first {
                do {
                    let keypointsMultiArray = try handObservation.keypointsMultiArray()
                    let prediction = try handPoseClassifier.prediction(poses: keypointsMultiArray)
                    
                    // Get prediction confidence
                    let confidence = prediction.labelProbabilities[prediction.label] ?? 0.0
                    
                    // Stabilize prediction
                    if let stablePrediction = stabilizePrediction(prediction.label, confidence: Float(confidence)) {
                        DispatchQueue.main.async {
                            self.handPrediction = stablePrediction
                            self.predictionConfidence = Float(confidence)
                        }
                    }
                } catch {
                    print("Error processing hand pose: \(error)")
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Error processing frame: \(error.localizedDescription)"
            }
        }
    }
}

enum CameraManagerError: Error {
    case cameraSetupFailed
    case inputAdditionFailed
    case outputAdditionFailed
    case sessionStartFailed
}
