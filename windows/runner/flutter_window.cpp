#include "flutter_window.h"

#include <optional>
#include <sstream>

#include "flutter/generated_plugin_registrant.h"
#include "flutter/method_channel.h"
#include "flutter/standard_method_codec.h"
#include "mmsystem.h"
#include "windows.h"

namespace {

std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> g_audio_channel;

std::wstring Utf8ToWide(const std::string& value) {
  if (value.empty()) {
    return std::wstring();
  }

  int size_needed = MultiByteToWideChar(CP_UTF8, 0, value.c_str(),
                                        static_cast<int>(value.size()), NULL, 0);
  std::wstring result(size_needed, 0);
  MultiByteToWideChar(CP_UTF8, 0, value.c_str(), static_cast<int>(value.size()),
                      result.data(), size_needed);
  return result;
}

std::wstring GetExecutableDirectory() {
  wchar_t path[MAX_PATH];
  GetModuleFileNameW(nullptr, path, MAX_PATH);
  std::wstring executable_path(path);
  return executable_path.substr(0, executable_path.find_last_of(L"\\/"));
}

void SendMciCommand(const std::wstring& command) {
  mciSendStringW(command.c_str(), nullptr, 0, nullptr);
}

void SendMediaCommandToFlutter(const std::string& command) {
  if (g_audio_channel) {
    g_audio_channel->InvokeMethod(
        "mediaCommand",
        std::make_unique<flutter::EncodableValue>(command));
  }
}

void RegisterAudioChannel(flutter::FlutterEngine* engine) {
  g_audio_channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      engine->messenger(), "zen_music/audio",
      &flutter::StandardMethodCodec::GetInstance());

  g_audio_channel->SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        const std::string& method = call.method_name();

        if (method == "playFile") {
          const auto* arguments =
              std::get_if<flutter::EncodableMap>(call.arguments());
          if (!arguments) {
            result->Error("bad_args", "Missing method arguments.");
            return;
          }

          const auto path_it =
              arguments->find(flutter::EncodableValue(std::string("path")));
          if (path_it == arguments->end()) {
            result->Error("bad_args", "Missing file path.");
            return;
          }

          const std::string* path =
              std::get_if<std::string>(&path_it->second);
          if (!path) {
            result->Error("bad_args", "File path must be a string.");
            return;
          }

          std::wstring full_path = Utf8ToWide(*path);

          SendMciCommand(L"close zenmusic");
          SendMciCommand(L"open \"" + full_path +
                         L"\" type waveaudio alias zenmusic");
          SendMciCommand(L"play zenmusic from 0");
          result->Success();
          return;
        }

        if (method == "pause") {
          SendMciCommand(L"pause zenmusic");
          result->Success();
          return;
        }

        if (method == "resume") {
          SendMciCommand(L"play zenmusic");
          result->Success();
          return;
        }

        if (method == "seek") {
          const auto* arguments =
              std::get_if<flutter::EncodableMap>(call.arguments());
          int milliseconds = 0;
          bool should_play = true;
          if (arguments) {
            const auto ms_it = arguments->find(
                flutter::EncodableValue(std::string("milliseconds")));
            if (ms_it != arguments->end()) {
              if (const auto* int_value = std::get_if<int>(&ms_it->second)) {
                milliseconds = *int_value;
              } else if (const auto* int64_value =
                             std::get_if<int64_t>(&ms_it->second)) {
                milliseconds = static_cast<int>(*int64_value);
              }
            }

            const auto play_it =
                arguments->find(flutter::EncodableValue(std::string("play")));
            if (play_it != arguments->end()) {
              if (const auto* bool_value = std::get_if<bool>(&play_it->second)) {
                should_play = *bool_value;
              }
            }
          }

          SendMciCommand(L"seek zenmusic to " + std::to_wstring(milliseconds));
          if (should_play) {
            SendMciCommand(L"play zenmusic");
          }
          result->Success();
          return;
        }

        if (method == "stop") {
          SendMciCommand(L"close zenmusic");
          result->Success();
          return;
        }

        result->NotImplemented();
      });
}

}  // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  RegisterAudioChannel(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_APPCOMMAND: {
      const int command = GET_APPCOMMAND_LPARAM(lparam);
      switch (command) {
        case APPCOMMAND_MEDIA_PLAY_PAUSE:
          SendMediaCommandToFlutter("toggle");
          return TRUE;
        case APPCOMMAND_MEDIA_PLAY:
          SendMediaCommandToFlutter("play");
          return TRUE;
        case APPCOMMAND_MEDIA_PAUSE:
          SendMediaCommandToFlutter("pause");
          return TRUE;
        case APPCOMMAND_MEDIA_STOP:
          SendMediaCommandToFlutter("stop");
          return TRUE;
        case APPCOMMAND_MEDIA_NEXTTRACK:
          SendMediaCommandToFlutter("next");
          return TRUE;
        case APPCOMMAND_MEDIA_PREVIOUSTRACK:
          SendMediaCommandToFlutter("previous");
          return TRUE;
      }
      break;
    }
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
