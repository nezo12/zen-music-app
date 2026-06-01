# Zen Music

Flutter music player for Windows and iOS. The app reads artists and `.wav` tracks from a cheap static hosting account.

## Hosting structure

Upload this kind of structure to your hosting, for example inside `public_html/zen-music`:

```text
zen-music/
  library.json
  Artist One/
    artist.json
    artist.jpg
    first_song.wav
    first_song.jpg
    second_song.wav
  Artist Two/
    artist.json
    another_track.wav
```

`library.json` lists artist folders:

```json
{
  "artists": [
    {
      "id": "artist_one",
      "name": "Artist One",
      "path": "Artist One"
    }
  ]
}
```

Each artist folder has `artist.json`:

```json
{
  "album": "Singles",
  "image": "artist.jpg",
  "tracks": [
    {
      "title": "First Song",
      "file": "first_song.wav",
      "cover": "first_song.jpg",
      "duration": 180
    }
  ]
}
```

Then the app can use a base URL like:

```text
https://shit.com.pl/zen-music
```

The app downloads the selected WAV to local cache and plays it from disk.

## Build Windows EXE

```powershell
flutter build windows --release
```

The executable is generated at:

```text
build/windows/x64/runner/Release/zen_music.exe
```

## Build Windows installer

```powershell
iscc installer/zen_music.iss
```

The installer is generated at:

```text
dist/ZenMusicSetup.exe
```

## Build unsigned IPA with GitHub

Push this repo to GitHub, then open:

```text
Actions -> Build Zen Music -> Run workflow
```

The workflow uploads `ZenMusic-unsigned-ipa`.
