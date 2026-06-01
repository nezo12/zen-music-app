import Flutter
import AVFoundation
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var audioPlayer: AVAudioPlayer?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "zen_music/audio",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )

    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(nil)
        return
      }

      switch call.method {
      case "playFile":
        guard
          let args = call.arguments as? [String: Any],
          let path = args["path"] as? String
        else {
          result(FlutterError(code: "bad_args", message: "Missing file path.", details: nil))
          return
        }

        do {
          try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
          try AVAudioSession.sharedInstance().setActive(true)
          self.audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
          self.audioPlayer?.prepareToPlay()
          self.audioPlayer?.play()
          result(nil)
        } catch {
          result(FlutterError(code: "audio_error", message: error.localizedDescription, details: nil))
        }

      case "pause":
        self.audioPlayer?.pause()
        result(nil)

      case "resume":
        self.audioPlayer?.play()
        result(nil)

      case "seek":
        var shouldPlay = true
        if
          let args = call.arguments as? [String: Any],
          let milliseconds = args["milliseconds"] as? NSNumber
        {
          self.audioPlayer?.currentTime = milliseconds.doubleValue / 1000
          shouldPlay = (args["play"] as? Bool) ?? true
        }
        if shouldPlay {
          self.audioPlayer?.play()
        }
        result(nil)

      case "stop":
        self.audioPlayer?.stop()
        self.audioPlayer = nil
        result(nil)

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
