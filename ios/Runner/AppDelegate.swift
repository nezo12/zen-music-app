import Flutter
import AVFoundation
import MediaPlayer
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var audioPlayer: AVAudioPlayer?
  private var audioChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    application.beginReceivingRemoteControlEvents()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "zen_music/audio",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    self.audioChannel = channel
    setupRemoteCommands()

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
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        result(nil)

      case "updateNowPlaying":
        self.updateNowPlaying(call.arguments)
        result(nil)

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func setupRemoteCommands() {
    let center = MPRemoteCommandCenter.shared()

    center.playCommand.isEnabled = true
    center.pauseCommand.isEnabled = true
    center.togglePlayPauseCommand.isEnabled = true
    center.stopCommand.isEnabled = true
    center.nextTrackCommand.isEnabled = true
    center.previousTrackCommand.isEnabled = true

    center.playCommand.addTarget { [weak self] _ in
      self?.audioPlayer?.play()
      self?.audioChannel?.invokeMethod("mediaCommand", arguments: "play")
      return .success
    }

    center.pauseCommand.addTarget { [weak self] _ in
      self?.audioPlayer?.pause()
      self?.audioChannel?.invokeMethod("mediaCommand", arguments: "pause")
      return .success
    }

    center.togglePlayPauseCommand.addTarget { [weak self] _ in
      self?.audioChannel?.invokeMethod("mediaCommand", arguments: "toggle")
      return .success
    }

    center.stopCommand.addTarget { [weak self] _ in
      self?.audioPlayer?.stop()
      self?.audioChannel?.invokeMethod("mediaCommand", arguments: "stop")
      return .success
    }

    center.nextTrackCommand.addTarget { [weak self] _ in
      self?.audioChannel?.invokeMethod("mediaCommand", arguments: "next")
      return .success
    }

    center.previousTrackCommand.addTarget { [weak self] _ in
      self?.audioChannel?.invokeMethod("mediaCommand", arguments: "previous")
      return .success
    }
  }

  private func updateNowPlaying(_ arguments: Any?) {
    guard let args = arguments as? [String: Any] else {
      return
    }

    let title = args["title"] as? String ?? "Zen Music"
    let artist = args["artist"] as? String ?? ""
    let album = args["album"] as? String ?? ""
    let duration = (args["duration"] as? NSNumber)?.doubleValue ?? 0
    let position = (args["position"] as? NSNumber)?.doubleValue ?? 0
    let playing = args["playing"] as? Bool ?? false

    MPNowPlayingInfoCenter.default().nowPlayingInfo = [
      MPMediaItemPropertyTitle: title,
      MPMediaItemPropertyArtist: artist,
      MPMediaItemPropertyAlbumTitle: album,
      MPMediaItemPropertyPlaybackDuration: duration,
      MPNowPlayingInfoPropertyElapsedPlaybackTime: position,
      MPNowPlayingInfoPropertyPlaybackRate: playing ? 1.0 : 0.0,
    ]
  }
}
