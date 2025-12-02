import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Google Maps API 키 초기화는 반드시 메인 스레드에서, 앱 시작 시 가장 먼저 수행
    // Info.plist에서 API 키를 읽어와서 초기화
    if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String,
       !apiKey.isEmpty && apiKey != "YOUR_API_KEY" {
      // 메인 스레드에서 동기적으로 초기화 (완료될 때까지 기다림)
      GMSServices.provideAPIKey(apiKey)
      print("✅ Google Maps API 키 설정 완료: \(apiKey.prefix(10))...")
    } else {
      print("⚠️ Google Maps API 키를 찾을 수 없습니다.")
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
