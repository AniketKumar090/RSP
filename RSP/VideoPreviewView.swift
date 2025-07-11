import SwiftUI
import AVFoundation

struct FullScreenVideoPreviewView: UIViewRepresentable {
    @ObservedObject var cameraManager: CameraManager
    @ObservedObject var borderColorManager: BorderColorManager
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        
        // Create preview layer that fills the entire view
        let previewLayer = AVCaptureVideoPreviewLayer(session: cameraManager.captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = UIScreen.main.bounds
        
        view.layer.addSublayer(previewLayer)
        
        context.coordinator.previewLayer = previewLayer
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update frame if needed
        if let previewLayer = context.coordinator.previewLayer {
            previewLayer.frame = uiView.bounds
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject {
        var previewLayer: AVCaptureVideoPreviewLayer?
    }
}

// MARK: - Enhanced Border Color
class BorderColorManager: ObservableObject {
    @Published var borderColor: UIColor = .white
    private var timer: Timer?
    private let animationColors: [UIColor] = [.systemRed, .systemYellow, .systemGreen, .systemBlue, .systemPurple]
    private var currentIndex = 0
    
    func startColorAnimation() {
        timer?.invalidate()
        currentIndex = 0
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.borderColor = self.animationColors[self.currentIndex]
                self.currentIndex = (self.currentIndex + 1) % self.animationColors.count
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            self.stopColorAnimation()
        }
    }
    
    func stopColorAnimation() {
        timer?.invalidate()
        timer = nil
        DispatchQueue.main.async {
            self.borderColor = .white
        }
    }
    
    func updateBorderColor(to color: UIColor) {
        DispatchQueue.main.async {
            self.borderColor = color
        }
    }
}
