//
//  ARCameraView.swift
//  COLDFRAME
//

import SwiftUI
import AVFoundation

struct ARCameraView: UIViewRepresentable {
    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.startSession()
        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {}

    static func dismantleUIView(_ uiView: CameraPreviewUIView, coordinator: ()) {
        uiView.stopSession()
    }
}

final class CameraPreviewUIView: UIView {
    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCamera()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCamera()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
        if let connection = previewLayer?.connection, connection.isVideoOrientationSupported {
            connection.videoOrientation = .landscapeRight
        }
    }

    private func setupCamera() {
        backgroundColor = .black

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else {
            return
        }

        session.beginConfiguration()
        session.sessionPreset = .high
        if session.canAddInput(input) {
            session.addInput(input)
        }

        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        self.layer.addSublayer(layer)
        self.previewLayer = layer

        session.commitConfiguration()
    }

    func startSession() {
        guard !session.isRunning else { return }
        Task.detached(priority: .userInitiated) { [session] in
            session.startRunning()
        }
    }

    func stopSession() {
        guard session.isRunning else { return }
        Task.detached(priority: .background) { [session] in
            session.stopRunning()
        }
    }
}
