//
//  ViewController.swift
//  pulshot01verwatch
//
//  Created by oshitahayato on 2017/03/29.
//  Copyright © 2017年 oshitahayato. All rights reserved.
//
import UIKit
import HealthKit

import AVFoundation


class ViewController: UIViewController, UITextFieldDelegate ,AVCapturePhotoCaptureDelegate{
	
	//storyboard imageview
	@IBOutlet weak var imageView: UIImageView!
	
	var captureSession: AVCaptureSession!
	var stillImgaeOutput: AVCapturePhotoOutput!
	//ここの部分を書き換えた avcapturestillImageoutput　からAVCapturePhotoOutput
	
	
	@IBAction func takePhoto(_ sender: Any) {
		let settingsForMonitoring = AVCapturePhotoSettings()
		settingsForMonitoring.flashMode = .auto
		settingsForMonitoring.isAutoStillImageStabilizationEnabled = true
		settingsForMonitoring.isHighResolutionPhotoEnabled = false
		stillImgaeOutput?.capturePhoto(with: settingsForMonitoring, delegate: self)
	}
	//    AVCapturePhotoSettingsという新しいClassがAVCapturePhotoOutputと一緒に追加された。
	//    フラッシュなどの細かい設定はAVCapturePhotoSettingsで行う
	
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		captureSession = AVCaptureSession()
		captureSession.sessionPreset = AVCaptureSessionPreset1920x1080
		stillImgaeOutput = AVCapturePhotoOutput()
		
		let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
		do{
			let input = try AVCaptureDeviceInput(device: device)
			if (captureSession.canAddInput(input)){
				captureSession.addInput(input)
				if (captureSession.canAddOutput(stillImgaeOutput)){
					captureSession.addOutput(stillImgaeOutput)
					captureSession.startRunning()
					let captureVideoLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer.init(session: captureSession)
					captureVideoLayer.frame = self.imageView.bounds
					captureVideoLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
					self.imageView.layer.addSublayer(captureVideoLayer)
				}
			}
		}
		catch{
			print(error)
		}
		
	}
	
	func capture(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?,previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings : AVCaptureResolvedPhotoSettings, bracketSettings : AVCaptureBracketedStillImageSettings?, error: Error?){
		
		if let photoSampleBuffer = photoSampleBuffer{
			//jpeg形式に保存
			let photoData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: photoSampleBuffer, previewPhotoSampleBuffer:previewPhotoSampleBuffer)
			
			
			let image = UIImage(data: photoData!)
			//フォトライブラリに保存
			UIImageWriteToSavedPhotosAlbum(image!, nil, nil, nil)
			
		}
		
	}
	
	
	
	


}

