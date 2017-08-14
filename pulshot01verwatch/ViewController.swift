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

//exif情報
import ImageIO
import Photos
import MobileCoreServices

import AssetsLibrary

class ViewController: UIViewController, UITextFieldDelegate ,AVCapturePhotoCaptureDelegate{

	//各インスタンス作成
	var myHealthStore : HKHealthStore = HKHealthStore()
	
	var myReadHeartRateField: UITextField!
	//var myReadButton: UIButton!

	//bpm
	//var bpm
	@IBOutlet weak var yourbpm: UILabel!
	var i = 0
	
	
	//storyboard imageview
	@IBOutlet weak var imageView: UIImageView!
	
	var captureSession: AVCaptureSession!
	var stillImgaeOutput: AVCapturePhotoOutput!
	//ここの部分を書き換えた avcapturestillImageoutput　からAVCapturePhotoOutput
	
	
	
	@IBAction func takePhoto(_ sender: Any) {
		//takephoto設定
		let settingsForMonitoring = AVCapturePhotoSettings()
		settingsForMonitoring.flashMode = .auto
		settingsForMonitoring.isAutoStillImageStabilizationEnabled = true
		settingsForMonitoring.isHighResolutionPhotoEnabled = false
		stillImgaeOutput?.capturePhoto(with: settingsForMonitoring, delegate: self)
	}
	//    AVCapturePhotoSettingsという新しいClassがAVCapturePhotoOutputと一緒に追加された。
	//    フラッシュなどの細かい設定はAVCapturePhotoSettingsで行う
	
	override func viewDidAppear(_ animated: Bool) {
		
		super.viewDidAppear(animated)
		//Healthstoreから許可申請
		requestAuthorization()
		
	}
	

	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		captureSession = AVCaptureSession()
		captureSession.sessionPreset = AVCaptureSessionPreset1920x1080
		stillImgaeOutput = AVCapturePhotoOutput()
		
		let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
		do{
			
			let input = try AVCaptureDeviceInput(device: device)
			//入力
			if (captureSession.canAddInput(input)){
				captureSession.addInput(input)
				
				//出力
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
		
		if(i == 0){
			i = i + 1
			readData()
		}
		
		
	}

	override func didReceiveMemoryWarning() {
		
			super.didReceiveMemoryWarning()
			// Dispose of any resources that can be recreated.
	
	}
	
	
	
	//healthkitへのアクセス申請関数
	private func requestAuthorization(){
		
		//読み込みを許可する型
		let type = Set(arrayLiteral: HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!)
		
		//Healthstoreアクセス承認を行う
		myHealthStore.requestAuthorization(toShare: type, read: type, completion: {(sucess,error)in
			if let e = error{
				print("Error:\(e.localizedDescription)")
			}
			print(sucess ? "Sucess" : "Failture")
			
		})
	}
	
	//心拍データ読み出し関数
	private func readData(){
		var error : NSError!
		
		//取得したいデータのタイプを生成
		let typeOfHeartRate = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)
		
		let calender = Calendar.init(identifier: Calendar.Identifier.gregorian)
		let now = Date()
		
		let startDate = calender.startOfDay(for: now)
		let endDate = calender.date(byAdding: Calendar.Component.day,value: 1 ,to: startDate)
		
		let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [])
		
		//データ取得時に登録された時間でソートする
		let mySortDescription = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
		//query生成
		let myquery = HKSampleQuery(sampleType: typeOfHeartRate!, predicate: predicate, limit: 1, sortDescriptors: [mySortDescription])
		{ (sampleQuery, results, error) -> Void in
			
			
			//一番最近に登録されたデータ取得
			guard let myRecentSample = results!.first as? HKQuantitySample else{
				print("error")
				self.myReadHeartRateField.text = "Data is not found"
				return
			}
			
			//取得したサンプルを単位に合わせる
			DispatchQueue.main.sync {
				
				let count:HKUnit = HKUnit.count()
				let minute: HKUnit = HKUnit.minute()
				let countPerMinute:HKUnit = count.unitMultiplied(by: minute.reciprocal())
				
				let bpm = myRecentSample.quantity.doubleValue(for: countPerMinute)
				let intbpm = Int(bpm)
				self.yourbpm.text = String(intbpm)
				
				//var pulsepersec = myRecentSample.quantity
				//var pulse = pulsepersec * 60
				//print(bpm)
				//self.myReadHeartRateField.text = "\(bpm)"
				
			}
		}
		
		//query発行
		self.myHealthStore.execute(myquery)
	}
	
	
	func capture(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?,previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings : AVCaptureResolvedPhotoSettings, bracketSettings : AVCaptureBracketedStillImageSettings?, error: Error?){
		
		readData()
		
		
		if let photoSampleBuffer = photoSampleBuffer {
			
			// JPEG形式で画像データを取得
			let photoData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: photoSampleBuffer, previewPhotoSampleBuffer: previewPhotoSampleBuffer)
			//let image = CGImageSourceCreateWithData((data as! CFDataRef), nil)
			
			let wi: UIImage = UIImage(data: photoData!)!
			
			
			
			let cg : CGImage = wi.cgImage!;
			
			// 画像の向きを指定
			let image = UIImage(cgImage: cg, scale: wi.scale, orientation: .up)
			
			
			//EXIFデータの作成
			let exif = NSMutableDictionary()
			//Exifにコメント情報をセットする
			let value = self.yourbpm.text
			let comment = value
			
			//print(comment)
			//print()
			
			
			//exifに情報追加
			exif.setObject("photoshot",forKey: kCGImagePropertyPNGTitle as CFString as! NSCopying)
			exif.setObject(comment!, forKey: kCGImagePropertyExifUserComment as
			CFString as! NSCopying)
			
			//exif[(kCGImagePropertyExifUserComment as CFString)] = "hoge"
			//print(value)
			print(comment!)
			print(type(of: comment))
			//print(type(of: exif))
			//
			//静止画metadata作成
			let metadata = NSMutableDictionary()
			metadata.setObject(exif,forKey:kCGImagePropertyExifDictionary as! NSCopying);
			/*
			//サンプル
			//ワイキキビーチの位置情報を作成する
			let gps = NSMutableDictionary()
			gps.setObject("N",forKey:kCGImagePropertyGPSLatitudeRef as! NSCopying)
			gps.setObject(21.275468,forKey:kCGImagePropertyGPSLatitude as! NSCopying)
			gps.setObject("W",forKey:kCGImagePropertyGPSLongitudeRef as! NSCopying)
			gps.setObject(157.825294,forKey:kCGImagePropertyGPSLongitude as! NSCopying)
			gps.setObject(0,forKey:kCGImagePropertyGPSAltitudeRef as! NSCopying)
			gps.setObject(0,forKey:kCGImagePropertyGPSAltitude as! NSCopying)
			//ExifにGPS情報をセットする
			metadata.setObject(gps,forKey:kCGImagePropertyGPSDictionary as! NSCopying);
			*/
			
			
			//フォト保存
			//メタデータ保存のためにphotoframework使用
			let tmpName = ProcessInfo.processInfo.globallyUniqueString
			let tmpUrl = NSURL.fileURL(withPath: NSTemporaryDirectory() + tmpName + ".jpg")
			//print(type(of: tmpUrl))
			//print(tmpUrl)
			//一時保存
			//addNewAssetImage(with: cg,withpath: tmpUrl as URL!)
			
			if let dest = CGImageDestinationCreateWithURL(tmpUrl as CFURL, kUTTypeJPEG, 1, nil) {
				
				CGImageDestinationAddImage(dest,cg, (metadata as CFDictionary))
				CGImageDestinationFinalize(dest)
				//CFRelease(dest)
				//print(dest)
				//print(exif)
				print(exif)
				//保存処理
				let library = PHPhotoLibrary.shared()
				library.performChanges({ PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: tmpUrl) },completionHandler: { (ok, err) in print(ok, err)
					let _ = try? FileManager.default.removeItem(at:tmpUrl)
				})
				
				
				//pulselabel.text = String(photovalue)
				print("photo save ok")
				
			}
			//exif確認処理
			//let photourl = tmpUrl.absoluteString
			print(tmpUrl)
			
			
			
			// フォトライブラリに保存
			//print("photo save ok")
			//UIImageWriteToSavedPhotosAlbum(image!, nil, nil, dest)
			//
			
		}
		
	}
	
	
	
	
	


}

