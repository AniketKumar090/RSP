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
    @Published var predictionResult: String?
    @Published var errorMessage: String?
    
    private var addToPreviewStream: ((CGImage) -> Void)?
    
    lazy var previewStream: AsyncStream<CGImage> = {
        AsyncStream { continuation in
            self.addToPreviewStream = { cgImage in
                continuation.yield(cgImage)
            }
        }
    }()
    
    override init() {
        do {
            handPoseClassifier = try HandPose_(configuration: MLModelConfiguration())
            super.init()
            Task {
                do {
                    try await configureSession()
                    try await startSession()
                } catch {
                    self.errorMessage = "Failed to configure or start session: \(error.localizedDescription)"
                }
            }
        } catch {
            fatalError("Failed to load MLModel: \(error.localizedDescription)")
        }
    }
    
    private func configureSession() async throws {
        guard  await isAuthorized(),
              let camera = systemPreferredCamera else {
            throw CameraManagerError.cameraSetupFailed
        }
        
        let deviceInput = try AVCaptureDeviceInput(device: camera)
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }
        
        guard captureSession.canAddInput(deviceInput) else {
            throw CameraManagerError.inputAdditionFailed
        }
        captureSession.addInput(deviceInput)
        
        guard captureSession.canAddOutput(videoOutput) else {
            throw CameraManagerError.outputAdditionFailed
        }
        captureSession.addOutput(videoOutput)
        
        self.deviceInput = deviceInput
        self.videoOutput = videoOutput
    }
    
    private func startSession() async throws {
        guard  await isAuthorized() else {
            throw CameraManagerError.sessionStartFailed
        }
        captureSession.startRunning()
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
    
    private func buildInputAttribute(from recognizedPoints: [VNHumanHandPoseObservation.JointName: VNRecognizedPoint]) -> MLMultiArray {
        let joints: [VNHumanHandPoseObservation.JointName] = [
            .wrist, .thumbCMC, .thumbMP, .thumbIP, .thumbTip,
            .indexMCP, .indexPIP, .indexDIP, .indexTip,
            .middleMCP, .middlePIP, .middleDIP, .middleTip,
            .ringMCP, .ringPIP, .ringDIP, .ringTip,
            .littleMCP, .littlePIP, .littleDIP, .littleTip
        ]
        
        let attributeArray = joints.flatMap { buildRow(from: recognizedPoints[$0]) }
        let mlArray = try! MLMultiArray(shape: [1, 3, 21], dataType: .float32)
        mlArray.dataPointer.initializeMemory(as: Float.self, from: attributeArray, count: attributeArray.count)
        
        return mlArray
    }
    
    private func buildRow(from recognizedPoint: VNRecognizedPoint?) -> [Float] {
        guard let point = recognizedPoint else {
            return [0.0, 0.0, 0.0]
        }
        return [Float(point.x), Float(point.y), Float(point.confidence)]
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, options: [:])
        do {
            try handler.perform([handPoseRequest])
            if let handObservation = handPoseRequest.results?.first {
                if let keypointsMultiArray = try? handObservation.keypointsMultiArray() {
                    let prediction = try handPoseClassifier.prediction(poses: keypointsMultiArray)
                    DispatchQueue.main.async {
                        self.handPrediction = prediction.label
                    }
                }
            }
//            if let currentFrame = sampleBuffer.cgImage {
//                addToPreviewStream?(currentFrame)
//            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Error processing frame: \(error.localizedDescription)"
            }
            captureSession.stopRunning()
        }
    }
}

enum CameraManagerError: Error {
    case cameraSetupFailed
    case inputAdditionFailed
    case outputAdditionFailed
    case sessionStartFailed
}

