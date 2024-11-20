import SwiftUI
import AVFoundation

struct VideoPreviewView: UIViewRepresentable {
    @ObservedObject var cameraManager: CameraManager
    @ObservedObject var borderColorManager: BorderColorManager
    var previewSize: CGSize
   

    func makeUIView(context: Context) -> UIView {
        let screenSize = UIScreen.main.bounds.size
        let x = (screenSize.width - previewSize.width) / 2
        let y = (screenSize.height - previewSize.height) / 2
        let frame = CGRect(x: x, y: y, width: previewSize.width, height: previewSize.height)
        let view = UIView(frame: frame)

       
        
        // Configure the glowing border
        let borderLayer = CALayer()
        borderLayer.frame = view.bounds
        borderLayer.borderWidth = 7.0
        borderLayer.shadowOffset = CGSize(width: 0, height: 0)
        borderLayer.shadowOpacity = 10.0
        borderLayer.shadowRadius = 50.0

        // Add the border layer to the view's layer
        view.layer.addSublayer(borderLayer)
        
        // Add the preview layer
        let previewLayer = AVCaptureVideoPreviewLayer(session: cameraManager.captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        
        // Store the borderLayer in the coordinator to access it in the updateUIView method
        context.coordinator.borderLayer = borderLayer
        
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let borderLayer = context.coordinator.borderLayer {
            borderLayer.borderColor = borderColorManager.borderColor.cgColor
            borderLayer.shadowColor = borderColorManager.borderColor.cgColor
        }
       
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject {
        var borderLayer: CALayer?
    }
}

class BorderColorManager: ObservableObject {
    @Published var borderColor: UIColor = .white
    private var timer: Timer?
    let colors: [UIColor] = [.red, .yellow, .green]
    var currentIndex = 0
    
    func startColorAnimation() {
        
        // Invalidate any existing timer
        timer?.invalidate()
        
        
        timer = Timer.scheduledTimer(withTimeInterval: 5.0 / Double(colors.count), repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.borderColor = colors[currentIndex]
            currentIndex = (currentIndex + 1) % colors.count
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5){
            self.stopColorAnimation()
        }
    }
    
    func stopColorAnimation() {
        timer?.invalidate()
        timer = nil
    }
    func updateBorderColor(to color: UIColor) {
           self.borderColor = color
       }
}
