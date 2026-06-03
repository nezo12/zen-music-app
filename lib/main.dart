import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const defaultLibraryUrl = 'https://shit.com.pl/zen-music';
const defaultApiUrl = 'https://shit.com.pl/zen-music/api';

enum AppSection { home, search, library, liked, playlists, profile, settings }

enum AppThemeChoice { spotify, aurora, ocean, neon, violet, amber }

enum LibrarySort { artist, title, newest }

void main() {
  runApp(const ZenMusicApp());
}

final appThemeNotifier = ValueNotifier<AppThemeChoice>(AppThemeChoice.spotify);

class ZenMusicApp extends StatelessWidget {
  const ZenMusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeChoice>(
      valueListenable: appThemeNotifier,
      builder: (context, themeChoice, _) {
        final palette = _paletteFor(themeChoice);
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Zen Music',
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: palette.background,
            colorScheme: ColorScheme.fromSeed(
              seedColor: palette.accent,
              brightness: Brightness.dark,
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: palette.background,
              centerTitle: false,
              elevation: 0,
            ),
            cardTheme: CardThemeData(
              color: palette.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: palette.input,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          home: const MusicHomePage(),
        );
      },
    );
  }
}

class AppPalette {
  const AppPalette({
    required this.accent,
    required this.background,
    required this.surface,
    required this.input,
    required this.gradientStart,
    required this.glow,
  });

  final Color accent;
  final Color background;
  final Color surface;
  final Color input;
  final Color gradientStart;
  final Color glow;
}

AppPalette _paletteFor(AppThemeChoice choice) {
  switch (choice) {
    case AppThemeChoice.ocean:
      return const AppPalette(
        accent: Color(0xff2dd4bf),
        background: Color(0xff061316),
        surface: Color(0xff0e2428),
        input: Color(0xff17383d),
        gradientStart: Color(0xff0f766e),
        glow: Color(0xff22d3ee),
      );
    case AppThemeChoice.aurora:
      return const AppPalette(
        accent: Color(0xffa7f3d0),
        background: Color(0xff07110e),
        surface: Color(0xff13231e),
        input: Color(0xff1d342c),
        gradientStart: Color(0xff047857),
        glow: Color(0xff7dd3fc),
      );
    case AppThemeChoice.neon:
      return const AppPalette(
        accent: Color(0xfffb7185),
        background: Color(0xff120811),
        surface: Color(0xff21101f),
        input: Color(0xff33182d),
        gradientStart: Color(0xffbe185d),
        glow: Color(0xff22d3ee),
      );
    case AppThemeChoice.violet:
      return const AppPalette(
        accent: Color(0xffc084fc),
        background: Color(0xff140d1f),
        surface: Color(0xff241733),
        input: Color(0xff312044),
        gradientStart: Color(0xff581c87),
        glow: Color(0xfff0abfc),
      );
    case AppThemeChoice.amber:
      return const AppPalette(
        accent: Color(0xfffbbf24),
        background: Color(0xff17120a),
        surface: Color(0xff251d10),
        input: Color(0xff332816),
        gradientStart: Color(0xff92400e),
        glow: Color(0xfffb7185),
      );
    case AppThemeChoice.spotify:
      return const AppPalette(
        accent: Color(0xff1ed760),
        background: Color(0xff121212),
        surface: Color(0xff181818),
        input: Color(0xff242424),
        gradientStart: Color(0xff1f5134),
        glow: Color(0xff86efac),
      );
  }
}

class Artist {
  const Artist({
    required this.id,
    required this.name,
    required this.tracks,
    this.imageUrl,
  });

  final String id;
  final String name;
  final List<Track> tracks;
  final Uri? imageUrl;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl?.toString(),
      'tracks': tracks.map((track) => track.toJson()).toList(),
    };
  }

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      imageUrl: _uriOrNull(json['imageUrl']?.toString()),
      tracks: (json['tracks'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => Track.fromJson(Map<String, dynamic>.from(item as Map)))
          .where((track) => track.id.isNotEmpty)
          .toList(),
    );
  }
}

class Track {
  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    required this.url,
    required this.color,
    required this.icon,
    this.coverUrl,
  });

  final String id;
  final String title;
  final String artist;
  final String album;
  final Duration duration;
  final Uri url;
  final Color color;
  final IconData icon;
  final Uri? coverUrl;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'duration': duration.inSeconds,
      'url': url.toString(),
      'color': color.toARGB32(),
      'coverUrl': coverUrl?.toString(),
    };
  }

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      artist: json['artist']?.toString() ?? '',
      album: json['album']?.toString() ?? 'Single',
      duration: Duration(
        seconds: int.tryParse('${json['duration'] ?? 180}') ?? 180,
      ),
      url: Uri.parse(json['url']?.toString() ?? ''),
      color: Color(int.tryParse('${json['color']}') ?? 0xff1ed760),
      icon: Icons.album_outlined,
      coverUrl: _uriOrNull(json['coverUrl']?.toString()),
    );
  }
}

Uri? _uriOrNull(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }
  return Uri.tryParse(value);
}

class Playlist {
  const Playlist({
    required this.id,
    required this.name,
    required this.trackIds,
  });

  final String id;
  final String name;
  final List<String> trackIds;

  Playlist copyWith({String? name, List<String>? trackIds}) {
    return Playlist(
      id: id,
      name: name ?? this.name,
      trackIds: trackIds ?? this.trackIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'trackIds': trackIds};
  }

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Playlista',
      trackIds: (json['trackIds'] as List<dynamic>? ?? <dynamic>[])
          .map((id) => id.toString())
          .toList(),
    );
  }
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.createdAt,
  });

  final int id;
  final String email;
  final String createdAt;
}

class AuthSession {
  const AuthSession({required this.token, required this.user});

  final String token;
  final UserProfile user;
}

class AuthClient {
  AuthClient(String baseUrl) : baseUri = Uri.parse(baseUrl);

  final Uri baseUri;

  Future<AuthSession> register(String email, String password) async {
    final data = await _post('register.php', {
      'email': email,
      'password': password,
    });
    return _sessionFromJson(data);
  }

  Future<AuthSession> login(String email, String password) async {
    final data = await _post('login.php', {
      'email': email,
      'password': password,
    });
    return _sessionFromJson(data);
  }

  Future<UserProfile> me(String token) async {
    final data = await _post('me.php', {'token': token});
    return _userFromJson(Map<String, dynamic>.from(data['user'] as Map));
  }

  Future<Map<String, dynamic>?> fetchLibrary(String token) async {
    final data = await _post('library_get.php', {'token': token});
    final library = data['library'];
    if (library == null) {
      return null;
    }
    return Map<String, dynamic>.from(library as Map);
  }

  Future<void> saveLibrary(String token, Map<String, dynamic> library) async {
    await _post('library_save.php', {'token': token, 'library': library});
  }

  Future<void> logout(String token) async {
    await _post('logout.php', {'token': token});
  }

  AuthSession _sessionFromJson(Map<String, dynamic> data) {
    return AuthSession(
      token: data['token'].toString(),
      user: _userFromJson(Map<String, dynamic>.from(data['user'] as Map)),
    );
  }

  UserProfile _userFromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: int.tryParse('${json['id']}') ?? 0,
      email: json['email']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  Future<Map<String, dynamic>> _post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final uri = baseUri.replace(
      pathSegments: <String>[
        ...baseUri.pathSegments.where((segment) => segment.isNotEmpty),
        endpoint,
      ],
    );
    final request = await HttpClient().postUrl(uri);
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode(body));
    final response = await request.close();
    final text = await utf8.decoder.bind(response).join();
    Map<String, dynamic> data;
    try {
      data = text.isEmpty
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(jsonDecode(text) as Map);
    } catch (_) {
      data = <String, dynamic>{
        'error': text.trim().isEmpty ? 'Pusta odpowiedz serwera.' : text.trim(),
      };
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        data['error']?.toString() ?? 'HTTP ${response.statusCode}',
        uri: uri,
      );
    }
    return data;
  }
}

class SessionStore {
  Future<File> _file() async {
    final dir = await _appDataDir();
    await dir.create(recursive: true);
    return File('${dir.path}${Platform.pathSeparator}session.json');
  }

  Future<String?> readToken() async {
    final file = await _file();
    if (!await file.exists()) {
      return null;
    }
    final json = jsonDecode(await file.readAsString()) as Map;
    return json['token']?.toString();
  }

  Future<void> writeToken(String token) async {
    final file = await _file();
    await file.writeAsString(jsonEncode({'token': token}));
  }

  Future<File> libraryFile(int userId) async {
    final dir = await _appDataDir();
    await dir.create(recursive: true);
    return File('${dir.path}${Platform.pathSeparator}library_$userId.json');
  }

  Future<File> catalogFile() async {
    final dir = await _appDataDir();
    await dir.create(recursive: true);
    return File('${dir.path}${Platform.pathSeparator}catalog.json');
  }

  Future<void> clear() async {
    final file = await _file();
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<Directory> _appDataDir() async {
    final appData = Platform.environment['APPDATA'];
    if (appData != null && appData.isNotEmpty) {
      return Directory('$appData${Platform.pathSeparator}ZenMusic');
    }

    final home = Platform.environment['HOME'] ?? Directory.systemTemp.path;
    return Directory('$home${Platform.pathSeparator}.zen_music');
  }
}

class NativeAudioPlayer {
  static const MethodChannel _channel = MethodChannel('zen_music/audio');

  void setCommandHandler(Future<void> Function(String command) handler) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'mediaCommand') {
        await handler(call.arguments?.toString() ?? '');
      }
    });
  }

  Future<void> playFile(String filePath) async {
    await _channel.invokeMethod<void>('playFile', {'path': filePath});
  }

  Future<void> pause() async {
    await _channel.invokeMethod<void>('pause');
  }

  Future<void> resume() async {
    await _channel.invokeMethod<void>('resume');
  }

  Future<void> seek(Duration position, {required bool playAfterSeek}) async {
    await _channel.invokeMethod<void>('seek', {
      'milliseconds': position.inMilliseconds,
      'play': playAfterSeek,
    });
  }

  Future<void> stop() async {
    await _channel.invokeMethod<void>('stop');
  }

  Future<void> updateNowPlaying({
    required String title,
    required String artist,
    required String album,
    required Duration duration,
    required Duration position,
    required bool playing,
  }) async {
    try {
      await _channel.invokeMethod<void>('updateNowPlaying', {
        'title': title,
        'artist': artist,
        'album': album,
        'duration': duration.inSeconds,
        'position': position.inSeconds,
        'playing': playing,
      });
    } on MissingPluginException {
      // Now playing metadata is optional; playback should keep working without it.
    }
  }
}

class MusicController extends ChangeNotifier {
  final NativeAudioPlayer _player = NativeAudioPlayer();
  final SessionStore _sessionStore = SessionStore();
  final AuthClient _authClient = AuthClient(defaultApiUrl);
  Timer? _positionTimer;

  String libraryUrl = defaultLibraryUrl;
  AuthSession? session;
  List<Artist> artists = <Artist>[];
  Set<String> likedTrackIds = <String>{};
  Set<String> followedArtistIds = <String>{};
  Set<String> cachedTrackIds = <String>{};
  Set<String> offlinePlaylistIds = <String>{};
  List<Playlist> playlists = <Playlist>[];
  List<String> recentTrackIds = <String>[];
  Map<String, int> playCounts = <String, int>{};
  Track? currentTrack;
  AppSection section = AppSection.home;
  AppThemeChoice themeChoice = AppThemeChoice.spotify;
  LibrarySort sort = LibrarySort.artist;
  bool loading = true;
  bool authLoading = false;
  bool playing = false;
  bool downloading = false;
  bool offlineDownloading = false;
  bool likedTracksOffline = false;
  bool registering = false;
  String search = '';
  String? message;
  String? authMessage;
  Duration position = Duration.zero;

  bool get authenticated => session != null;

  List<Track> get allTracks =>
      artists.expand((artist) => artist.tracks).toList(growable: false);

  List<Track> get likedTracks =>
      allTracks.where((track) => likedTrackIds.contains(track.id)).toList();

  List<Artist> get followedArtists =>
      artists.where((artist) => followedArtistIds.contains(artist.id)).toList();

  List<Track> get recentTracks {
    final byId = {for (final track in allTracks) track.id: track};
    return recentTrackIds
        .where((id) => byId.containsKey(id))
        .map((id) => byId[id]!)
        .toList();
  }

  List<Track> get topTracks {
    final tracks = [...allTracks];
    tracks.sort(
      (a, b) => (playCounts[b.id] ?? 0).compareTo(playCounts[a.id] ?? 0),
    );
    return tracks
        .where((track) => (playCounts[track.id] ?? 0) > 0)
        .take(12)
        .toList();
  }

  Future<void> init() async {
    _player.setCommandHandler(handleMediaCommand);
    await restoreSession();
    if (authenticated) {
      await refresh();
    } else {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> handleMediaCommand(String command) async {
    switch (command) {
      case 'toggle':
        if (currentTrack != null && !downloading) {
          await togglePlay();
        }
        break;
      case 'play':
        if (currentTrack != null && !playing && !downloading) {
          await togglePlay();
        }
        break;
      case 'pause':
        if (playing) {
          await togglePlay();
        }
        break;
      case 'stop':
        await stop();
        break;
      case 'next':
        await playAdjacent(1);
        break;
      case 'previous':
        await playAdjacent(-1);
        break;
    }
  }

  Future<void> restoreSession() async {
    final token = await _sessionStore.readToken();
    if (token == null || token.isEmpty) {
      return;
    }

    try {
      final user = await _authClient.me(token);
      session = AuthSession(token: token, user: user);
      await _loadUserLibrary();
    } catch (_) {
      await _sessionStore.clear();
      session = null;
    }
  }

  Future<void> login(String email, String password) async {
    await _authenticate(() => _authClient.login(email, password));
  }

  Future<void> register(String email, String password) async {
    await _authenticate(() => _authClient.register(email, password));
  }

  Future<void> _authenticate(Future<AuthSession> Function() action) async {
    authLoading = true;
    authMessage = null;
    notifyListeners();

    try {
      session = await action();
      await _sessionStore.writeToken(session!.token);
      await _loadUserLibrary();
      await refresh();
    } catch (error) {
      authMessage = '$error'.replaceFirst('HttpException: ', '');
    } finally {
      authLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    final token = session?.token;
    if (token != null) {
      try {
        await _authClient.logout(token);
      } catch (_) {}
    }
    await stop();
    await _sessionStore.clear();
    session = null;
    artists = <Artist>[];
    likedTrackIds = <String>{};
    followedArtistIds = <String>{};
    playlists = <Playlist>[];
    section = AppSection.home;
    message = null;
    authMessage = null;
    loading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    if (!authenticated) {
      return;
    }

    loading = true;
    message = null;
    notifyListeners();

    try {
      artists = await LibraryClient(libraryUrl).fetchArtists();
      await _saveCatalog();
      await _refreshCachedTracks();
      if (artists.isEmpty) {
        message = 'Nie znaleziono artystow. Sprawdz library.json.';
      }
    } catch (error) {
      final cached = await _loadCatalog();
      if (cached.isNotEmpty) {
        artists = cached;
        await _refreshCachedTracks();
        message = 'Tryb offline: pokazuje ostatnio zapisana biblioteke.';
      } else {
        artists = <Artist>[];
        message = 'Nie moge pobrac biblioteki: $error';
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> setLibraryUrl(String value) async {
    libraryUrl = value.trim().replaceAll(RegExp(r'/+$'), '');
    await refresh();
  }

  Future<void> setThemeChoice(AppThemeChoice value) async {
    themeChoice = value;
    appThemeNotifier.value = value;
    await _saveUserLibrary();
    notifyListeners();
  }

  Future<void> setSort(LibrarySort value) async {
    sort = value;
    await _saveUserLibrary();
    notifyListeners();
  }

  void setSection(AppSection value) {
    section = value;
    if (value == AppSection.search) {
      search = search;
    }
    notifyListeners();
  }

  void setSearch(String value) {
    search = value;
    if (value.isNotEmpty) {
      section = AppSection.search;
    }
    notifyListeners();
  }

  bool isLiked(Track track) => likedTrackIds.contains(track.id);

  bool isFollowing(Artist artist) => followedArtistIds.contains(artist.id);

  Future<void> toggleLiked(Track track) async {
    final shouldDownload = !likedTrackIds.contains(track.id);
    if (likedTrackIds.contains(track.id)) {
      likedTrackIds.remove(track.id);
    } else {
      likedTrackIds.add(track.id);
    }
    await _saveUserLibrary();
    notifyListeners();

    if (shouldDownload && likedTracksOffline) {
      await downloadTrackForOffline(track);
    }
  }

  Future<void> toggleFollowArtist(Artist artist) async {
    if (followedArtistIds.contains(artist.id)) {
      followedArtistIds.remove(artist.id);
    } else {
      followedArtistIds.add(artist.id);
    }
    await _saveUserLibrary();
    notifyListeners();
  }

  Future<void> createPlaylist(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return;
    }
    playlists = <Playlist>[
      ...playlists,
      Playlist(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: trimmed,
        trackIds: <String>[],
      ),
    ];
    section = AppSection.playlists;
    await _saveUserLibrary();
    notifyListeners();
  }

  Future<void> deletePlaylist(Playlist playlist) async {
    playlists = playlists.where((item) => item.id != playlist.id).toList();
    offlinePlaylistIds.remove(playlist.id);
    await _saveUserLibrary();
    notifyListeners();
  }

  Future<void> addToPlaylist(Playlist playlist, Track track) async {
    var added = false;
    playlists = playlists.map((item) {
      if (item.id != playlist.id || item.trackIds.contains(track.id)) {
        return item;
      }
      added = true;
      return item.copyWith(trackIds: <String>[...item.trackIds, track.id]);
    }).toList();
    await _saveUserLibrary();
    notifyListeners();

    if (added && offlinePlaylistIds.contains(playlist.id)) {
      await downloadTrackForOffline(track);
    }
  }

  Future<void> removeFromPlaylist(Playlist playlist, Track track) async {
    playlists = playlists.map((item) {
      if (item.id != playlist.id) {
        return item;
      }
      return item.copyWith(
        trackIds: item.trackIds.where((id) => id != track.id).toList(),
      );
    }).toList();
    await _saveUserLibrary();
    notifyListeners();
  }

  List<Track> tracksForPlaylist(Playlist playlist) {
    final ids = playlist.trackIds.toSet();
    return allTracks.where((track) => ids.contains(track.id)).toList();
  }

  List<Artist> visibleArtists() {
    final query = search.trim().toLowerCase();
    final source = query.isEmpty
        ? artists
        : artists
              .map((artist) {
                final artistMatches = artist.name.toLowerCase().contains(query);
                final tracks = artist.tracks
                    .where(
                      (track) =>
                          artistMatches ||
                          track.title.toLowerCase().contains(query) ||
                          track.album.toLowerCase().contains(query),
                    )
                    .toList();
                return Artist(id: artist.id, name: artist.name, tracks: tracks);
              })
              .where((artist) => artist.tracks.isNotEmpty)
              .toList();

    final sorted = [...source];
    switch (sort) {
      case LibrarySort.artist:
        sorted.sort((a, b) => a.name.compareTo(b.name));
        return sorted;
      case LibrarySort.title:
        return sorted.map((artist) {
          final tracks = [...artist.tracks]
            ..sort((a, b) => a.title.compareTo(b.title));
          return Artist(id: artist.id, name: artist.name, tracks: tracks);
        }).toList();
      case LibrarySort.newest:
        return sorted.reversed.toList();
    }
  }

  Future<void> playRandom() async {
    final tracks = allTracks;
    if (tracks.isEmpty) {
      return;
    }
    final index = DateTime.now().millisecondsSinceEpoch % tracks.length;
    await play(tracks[index]);
  }

  Future<void> playAdjacent(int offset) async {
    final track = currentTrack;
    final tracks = allTracks;
    if (track == null || tracks.isEmpty) {
      return;
    }

    final currentIndex = tracks.indexWhere((item) => item.id == track.id);
    if (currentIndex < 0) {
      return;
    }

    final nextIndex = (currentIndex + offset) % tracks.length;
    await play(tracks[nextIndex < 0 ? tracks.length - 1 : nextIndex]);
  }

  Future<void> play(Track track) async {
    currentTrack = track;
    position = Duration.zero;
    playing = false;
    downloading = true;
    message = null;
    notifyListeners();

    try {
      final localFile = await LibraryClient(libraryUrl).downloadTrack(track);
      cachedTrackIds.add(track.id);
      await _player.playFile(localFile.path);
      _recordPlay(track);
      downloading = false;
      playing = true;
      await _updateNowPlaying();
      _startPositionTimer();
    } catch (error) {
      downloading = false;
      currentTrack = null;
      message = 'Nie moge odtworzyc pliku: $error';
    }
    notifyListeners();
  }

  Future<void> downloadLikedTracks() async {
    likedTracksOffline = true;
    await _saveUserLibrary();
    await downloadTracks(likedTracks, label: 'polubione utwory');
  }

  Future<void> downloadPlaylist(Playlist playlist) async {
    offlinePlaylistIds.add(playlist.id);
    await _saveUserLibrary();
    await downloadTracks(
      tracksForPlaylist(playlist),
      label: 'playliste "${playlist.name}"',
    );
  }

  Future<void> downloadTrackForOffline(Track track) async {
    if (offlineDownloading || cachedTrackIds.contains(track.id)) {
      return;
    }

    offlineDownloading = true;
    message = 'Pobieram "${track.title}" offline...';
    notifyListeners();

    try {
      await LibraryClient(libraryUrl).downloadTrack(track);
      cachedTrackIds.add(track.id);
      message = 'Pobrano offline: ${track.title}.';
    } catch (error) {
      message = 'Nie moge pobrac offline: $error';
    } finally {
      offlineDownloading = false;
      notifyListeners();
    }
  }

  Future<void> removeOfflineTrack(Track track) async {
    final file = await LibraryClient.cachedTrackFile(track);
    if (await file.exists()) {
      await file.delete();
    }
    cachedTrackIds.remove(track.id);
    likedTracksOffline = _tracksFullyCached(likedTracks);
    offlinePlaylistIds = {
      for (final playlist in playlists)
        if (_tracksFullyCached(tracksForPlaylist(playlist))) playlist.id,
    };
    await _saveUserLibrary();
    notifyListeners();
  }

  bool isTrackCached(Track track) => cachedTrackIds.contains(track.id);

  bool areTracksCached(List<Track> tracks) => _tracksFullyCached(tracks);

  bool _tracksFullyCached(List<Track> tracks) {
    return tracks.isNotEmpty &&
        tracks.every((track) => cachedTrackIds.contains(track.id));
  }

  Future<void> downloadTracks(
    List<Track> tracks, {
    required String label,
  }) async {
    if (tracks.isEmpty || offlineDownloading) {
      return;
    }

    offlineDownloading = true;
    message = 'Pobieram $label do offline...';
    notifyListeners();

    var downloaded = 0;
    try {
      final client = LibraryClient(libraryUrl);
      for (final track in tracks) {
        await client.downloadTrack(track);
        cachedTrackIds.add(track.id);
        downloaded += 1;
        message = 'Pobrano $downloaded/${tracks.length}: $label';
        notifyListeners();
      }
      message = 'Gotowe offline: $label.';
    } catch (error) {
      message = 'Nie moge pobrac offline: $error';
    } finally {
      offlineDownloading = false;
      notifyListeners();
    }
  }

  Future<void> _recordPlay(Track track) async {
    recentTrackIds = <String>[
      track.id,
      ...recentTrackIds.where((id) => id != track.id),
    ].take(20).toList();
    playCounts[track.id] = (playCounts[track.id] ?? 0) + 1;
    await _saveUserLibrary();
  }

  Future<void> togglePlay() async {
    if (playing) {
      await _player.pause();
      playing = false;
      _positionTimer?.cancel();
    } else if (currentTrack != null) {
      await _player.resume();
      playing = true;
      _startPositionTimer();
    }
    await _updateNowPlaying();
    notifyListeners();
  }

  Future<void> seekRelative(Duration offset) async {
    await seekTo(position + offset);
  }

  Future<void> seekTo(Duration value) async {
    final track = currentTrack;
    if (track == null) {
      return;
    }

    final next = value < Duration.zero
        ? Duration.zero
        : value > track.duration
        ? track.duration
        : value;
    position = next;
    await _player.seek(next, playAfterSeek: playing);
    await _updateNowPlaying();
    notifyListeners();
  }

  Future<void> stop() async {
    await _player.stop();
    _positionTimer?.cancel();
    currentTrack = null;
    playing = false;
    downloading = false;
    position = Duration.zero;
    await _updateNowPlaying();
    notifyListeners();
  }

  Future<void> _updateNowPlaying() async {
    final track = currentTrack;
    if (track == null) {
      return;
    }

    await _player.updateNowPlaying(
      title: track.title,
      artist: track.artist,
      album: track.album,
      duration: track.duration,
      position: position,
      playing: playing,
    );
  }

  Future<void> _saveCatalog() async {
    final file = await _sessionStore.catalogFile();
    await file.writeAsString(
      jsonEncode({
        'artists': artists.map((artist) => artist.toJson()).toList(),
      }),
    );
  }

  Future<List<Artist>> _loadCatalog() async {
    final file = await _sessionStore.catalogFile();
    if (!await file.exists()) {
      return <Artist>[];
    }

    try {
      final data = Map<String, dynamic>.from(
        jsonDecode(await file.readAsString()) as Map,
      );
      return (data['artists'] as List<dynamic>? ?? <dynamic>[])
          .map(
            (item) => Artist.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .where((artist) => artist.id.isNotEmpty)
          .toList();
    } catch (_) {
      return <Artist>[];
    }
  }

  Future<void> _refreshCachedTracks() async {
    final ids = <String>{};
    for (final track in allTracks) {
      if (await LibraryClient.isTrackCached(track)) {
        ids.add(track.id);
      }
    }
    cachedTrackIds = ids;
  }

  Future<void> _loadUserLibrary() async {
    final user = session?.user;
    if (user == null) {
      return;
    }

    try {
      final remote = session == null
          ? null
          : await _authClient.fetchLibrary(session!.token);
      if (remote != null) {
        _applyLibraryJson(remote);
        await _writeLocalLibrary();
        return;
      }

      final local = await _readLocalLibrary();
      if (local != null) {
        _applyLibraryJson(local);
        await _syncUserLibrary();
        return;
      }

      _applyLibraryJson(<String, dynamic>{});
    } catch (_) {
      final local = await _readLocalLibrary();
      _applyLibraryJson(local ?? <String, dynamic>{});
    }
  }

  Future<void> _saveUserLibrary() async {
    final user = session?.user;
    if (user == null) {
      return;
    }

    await _writeLocalLibrary();
    await _syncUserLibrary();
  }

  Map<String, dynamic> _libraryJson() {
    return {
      'likedTrackIds': likedTrackIds.toList(),
      'followedArtistIds': followedArtistIds.toList(),
      'offlinePlaylistIds': offlinePlaylistIds.toList(),
      'likedTracksOffline': likedTracksOffline,
      'playlists': playlists.map((playlist) => playlist.toJson()).toList(),
      'recentTrackIds': recentTrackIds,
      'playCounts': playCounts,
      'themeChoice': themeChoice.name,
      'sort': sort.name,
    };
  }

  void _applyLibraryJson(Map<String, dynamic> data) {
    likedTrackIds = (data['likedTrackIds'] as List<dynamic>? ?? <dynamic>[])
        .map((id) => id.toString())
        .toSet();
    followedArtistIds =
        (data['followedArtistIds'] as List<dynamic>? ?? <dynamic>[])
            .map((id) => id.toString())
            .toSet();
    offlinePlaylistIds =
        (data['offlinePlaylistIds'] as List<dynamic>? ?? <dynamic>[])
            .map((id) => id.toString())
            .toSet();
    likedTracksOffline =
        data['likedTracksOffline'] == true ||
        data['likedTracksOffline']?.toString() == 'true';
    recentTrackIds = (data['recentTrackIds'] as List<dynamic>? ?? <dynamic>[])
        .map((id) => id.toString())
        .toList();
    playCounts =
        (data['playCounts'] as Map<dynamic, dynamic>? ?? <dynamic, dynamic>{})
            .map(
              (key, value) =>
                  MapEntry(key.toString(), int.tryParse('$value') ?? 0),
            );
    playlists = (data['playlists'] as List<dynamic>? ?? <dynamic>[])
        .map(
          (item) => Playlist.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .where((playlist) => playlist.id.isNotEmpty)
        .toList();
    themeChoice = AppThemeChoice.values.firstWhere(
      (theme) => theme.name == data['themeChoice']?.toString(),
      orElse: () => AppThemeChoice.spotify,
    );
    sort = LibrarySort.values.firstWhere(
      (item) => item.name == data['sort']?.toString(),
      orElse: () => LibrarySort.artist,
    );
    appThemeNotifier.value = themeChoice;
  }

  Future<Map<String, dynamic>?> _readLocalLibrary() async {
    final user = session?.user;
    if (user == null) {
      return null;
    }

    final file = await _sessionStore.libraryFile(user.id);
    if (!await file.exists()) {
      return null;
    }

    try {
      return Map<String, dynamic>.from(
        jsonDecode(await file.readAsString()) as Map,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeLocalLibrary() async {
    final user = session?.user;
    if (user == null) {
      return;
    }

    final file = await _sessionStore.libraryFile(user.id);
    await file.writeAsString(jsonEncode(_libraryJson()));
  }

  Future<void> _syncUserLibrary() async {
    final token = session?.token;
    if (token == null) {
      return;
    }

    try {
      await _authClient.saveLibrary(token, _libraryJson());
    } catch (_) {}
  }

  void _startPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(milliseconds: 250), (
      _,
    ) async {
      final track = currentTrack;
      if (!playing || track == null) {
        return;
      }

      position += const Duration(milliseconds: 250);
      if (position >= track.duration) {
        await stop();
      } else {
        if (position.inMilliseconds % 1000 == 0) {
          await _updateNowPlaying();
        }
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _positionTimer?.cancel();
    _player.stop();
    super.dispose();
  }
}

class LibraryClient {
  LibraryClient(String baseUrl) : baseUri = Uri.parse(baseUrl);

  final Uri baseUri;

  Future<List<Artist>> fetchArtists() async {
    final library = await _getJson(_resolve(<String>['library.json']));
    final rawArtists = library['artists'] as List<dynamic>? ?? <dynamic>[];

    final artists = <Artist>[];
    for (final item in rawArtists) {
      final artistMap = Map<String, dynamic>.from(item as Map);
      final id = artistMap['id']?.toString() ?? '';
      final name = artistMap['name']?.toString() ?? id;
      final path = artistMap['path']?.toString() ?? id;
      if (id.isEmpty || name.isEmpty || path.isEmpty) {
        continue;
      }

      final artistJson = await _getJson(
        _resolve(<String>[path, 'artist.json']),
      );
      final tracks = _parseTracks(name, path, artistJson);
      final image = artistJson['image']?.toString();
      artists.add(
        Artist(
          id: id,
          name: name,
          tracks: tracks,
          imageUrl: image == null || image.isEmpty
              ? null
              : _resolveFlexible(<String>[path], image),
        ),
      );
    }

    return artists;
  }

  Future<File> downloadTrack(Track track) async {
    final file = await cachedTrackFile(track);
    if (await file.exists() && await file.length() > 44) {
      return file;
    }

    final request = await HttpClient().getUrl(track.url);
    final response = await request.close();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('HTTP ${response.statusCode}', uri: track.url);
    }

    final sink = file.openWrite();
    await response.pipe(sink);
    await sink.close();
    return file;
  }

  static Future<bool> isTrackCached(Track track) async {
    final file = await cachedTrackFile(track);
    return await file.exists() && await file.length() > 44;
  }

  static Future<File> cachedTrackFile(Track track) async {
    final cacheDir = await _offlineCacheDir();
    final safeId = track.id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return File('${cacheDir.path}${Platform.pathSeparator}$safeId.wav');
  }

  static Future<Directory> _offlineCacheDir() async {
    final appData = Platform.environment['APPDATA'];
    final base = appData != null && appData.isNotEmpty
        ? '$appData${Platform.pathSeparator}ZenMusic'
        : '${Directory.systemTemp.path}${Platform.pathSeparator}ZenMusic';
    final dir = Directory('$base${Platform.pathSeparator}offline');
    await dir.create(recursive: true);
    return dir;
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final request = await HttpClient().getUrl(uri);
    final response = await request.close();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('HTTP ${response.statusCode}', uri: uri);
    }

    final body = await utf8.decoder.bind(response).join();
    return Map<String, dynamic>.from(jsonDecode(body) as Map);
  }

  List<Track> _parseTracks(
    String artist,
    String artistPath,
    Map<String, dynamic> json,
  ) {
    Track parseTrack(
      Map<String, dynamic> track,
      String album,
      String? albumImage,
    ) {
      final file = track['file']?.toString() ?? '';
      final id = '${artist.toLowerCase()}-$file'.replaceAll(
        RegExp(r'[^a-zA-Z0-9_-]'),
        '_',
      );
      final cover = track['cover']?.toString() ?? albumImage;
      return Track(
        id: id,
        title: track['title']?.toString() ?? file,
        artist: artist,
        album: track['album']?.toString() ?? album,
        duration: Duration(
          seconds: int.tryParse('${track['duration'] ?? 180}') ?? 180,
        ),
        url: _resolveFlexible(<String>[artistPath], file),
        color: _colorFor(artist),
        icon: Icons.album_outlined,
        coverUrl: cover == null || cover.isEmpty
            ? null
            : _resolveFlexible(<String>[artistPath], cover),
      );
    }

    final tracks = <Track>[];
    final defaultAlbum = json['album']?.toString() ?? 'Single';
    final rawTracks = json['tracks'] as List<dynamic>? ?? <dynamic>[];
    for (final item in rawTracks) {
      tracks.add(
        parseTrack(Map<String, dynamic>.from(item as Map), defaultAlbum, null),
      );
    }

    final rawAlbums = json['albums'] as List<dynamic>? ?? <dynamic>[];
    for (final item in rawAlbums) {
      final albumMap = Map<String, dynamic>.from(item as Map);
      final album = albumMap['album']?.toString() ?? defaultAlbum;
      final albumImage = albumMap['image']?.toString();
      final albumTracks = albumMap['tracks'] as List<dynamic>? ?? <dynamic>[];
      for (final track in albumTracks) {
        tracks.add(
          parseTrack(
            Map<String, dynamic>.from(track as Map),
            album,
            albumImage,
          ),
        );
      }
    }

    return tracks
        .where((track) => track.url.path.toLowerCase().endsWith('.wav'))
        .toList();
  }

  Uri _resolve(List<String> segments) {
    final baseSegments = baseUri.pathSegments.where(
      (segment) => segment.isNotEmpty,
    );
    return baseUri.replace(
      pathSegments: <String>[...baseSegments, ...segments],
    );
  }

  Uri _resolveFlexible(List<String> baseSegments, String value) {
    final uri = Uri.tryParse(value);
    if (uri != null && uri.hasScheme) {
      return uri;
    }
    return _resolve(<String>[...baseSegments, value]);
  }
}

class MusicHomePage extends StatefulWidget {
  const MusicHomePage({super.key});

  @override
  State<MusicHomePage> createState() => _MusicHomePageState();
}

class _MusicHomePageState extends State<MusicHomePage> {
  late final MusicController controller;

  @override
  void initState() {
    super.initState();
    controller = MusicController()..init();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (!controller.authenticated) {
          return _AuthScreen(controller: controller);
        }

        return CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.space): () {
              final focusContext = FocusManager.instance.primaryFocus?.context;
              final editingText =
                  focusContext?.widget is EditableText ||
                  focusContext?.findAncestorWidgetOfExactType<EditableText>() !=
                      null;
              if (editingText) {
                return;
              }
              controller.handleMediaCommand('toggle');
            },
            const SingleActivator(LogicalKeyboardKey.mediaPlayPause): () =>
                controller.handleMediaCommand('toggle'),
            const SingleActivator(LogicalKeyboardKey.mediaPlay): () =>
                controller.handleMediaCommand('play'),
            const SingleActivator(LogicalKeyboardKey.mediaPause): () =>
                controller.handleMediaCommand('pause'),
            const SingleActivator(LogicalKeyboardKey.mediaStop): () =>
                controller.handleMediaCommand('stop'),
            const SingleActivator(LogicalKeyboardKey.mediaTrackNext): () =>
                controller.handleMediaCommand('next'),
            const SingleActivator(LogicalKeyboardKey.mediaTrackPrevious): () =>
                controller.handleMediaCommand('previous'),
            const SingleActivator(
              LogicalKeyboardKey.arrowRight,
              control: true,
            ): () =>
                controller.seekRelative(const Duration(seconds: 10)),
            const SingleActivator(
              LogicalKeyboardKey.arrowLeft,
              control: true,
            ): () =>
                controller.seekRelative(const Duration(seconds: -10)),
          },
          child: Focus(
            autofocus: true,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Stack(
                children: [
                  _AnimatedAppBackdrop(
                    palette: _paletteFor(controller.themeChoice),
                    playing: controller.playing,
                  ),
                  SafeArea(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 1120;
                        return Row(
                          children: [
                            if (wide) _LeftLibraryPanel(controller: controller),
                            Expanded(
                              child: Column(
                                children: [
                                  _SpotifyTopNav(controller: controller),
                                  if (controller.message != null)
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        10,
                                        0,
                                        10,
                                        10,
                                      ),
                                      child: _StatusBanner(
                                        message: controller.message!,
                                      ),
                                    ),
                                  Expanded(
                                    child: controller.loading
                                        ? const Center(
                                            child: CircularProgressIndicator(),
                                          )
                                        : AnimatedSwitcher(
                                            duration: const Duration(
                                              milliseconds: 260,
                                            ),
                                            switchInCurve: Curves.easeOutCubic,
                                            switchOutCurve: Curves.easeInCubic,
                                            transitionBuilder:
                                                (child, animation) {
                                                  return FadeTransition(
                                                    opacity: animation,
                                                    child: SlideTransition(
                                                      position: Tween<Offset>(
                                                        begin: const Offset(
                                                          0.02,
                                                          0,
                                                        ),
                                                        end: Offset.zero,
                                                      ).animate(animation),
                                                      child: child,
                                                    ),
                                                  );
                                                },
                                            child: KeyedSubtree(
                                              key: ValueKey(controller.section),
                                              child: _ContentView(
                                                controller: controller,
                                              ),
                                            ),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                            if (wide) _NowPlayingPanel(controller: controller),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
              bottomNavigationBar: _PlayerBar(controller: controller),
            ),
          ),
        );
      },
    );
  }
}

class _AnimatedAppBackdrop extends StatefulWidget {
  const _AnimatedAppBackdrop({required this.palette, required this.playing});

  final AppPalette palette;
  final bool playing;

  @override
  State<_AnimatedAppBackdrop> createState() => _AnimatedAppBackdropState();
}

class _AnimatedAppBackdropState extends State<_AnimatedAppBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _BackdropPainter(
            palette: widget.palette,
            progress: _controller.value,
            energy: widget.playing ? 1 : 0.35,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _BackdropPainter extends CustomPainter {
  const _BackdropPainter({
    required this.palette,
    required this.progress,
    required this.energy,
  });

  final AppPalette palette;
  final double progress;
  final double energy;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final basePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          palette.gradientStart.withValues(alpha: 0.55),
          palette.background,
          Colors.black,
        ],
        stops: const [0, 0.48, 1],
      ).createShader(rect);
    canvas.drawRect(rect, basePaint);

    _drawWave(
      canvas,
      size,
      color: palette.accent.withValues(alpha: 0.08 + energy * 0.08),
      phase: progress * math.pi * 2,
      yFactor: 0.24,
      amplitude: 34 + energy * 18,
    );
    _drawWave(
      canvas,
      size,
      color: palette.glow.withValues(alpha: 0.06 + energy * 0.07),
      phase: progress * math.pi * 2 + math.pi,
      yFactor: 0.78,
      amplitude: 46 + energy * 20,
    );

    final sheen = Paint()
      ..shader = RadialGradient(
        center: Alignment(
          math.sin(progress * math.pi * 2) * 0.45,
          -0.78 + math.cos(progress * math.pi * 2) * 0.08,
        ),
        radius: 0.9,
        colors: [
          palette.glow.withValues(alpha: 0.14 * energy),
          Colors.transparent,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, sheen);

    final vignette = Paint()
      ..shader = RadialGradient(
        radius: 1.12,
        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.42)],
      ).createShader(rect);
    canvas.drawRect(rect, vignette);
  }

  void _drawWave(
    Canvas canvas,
    Size size, {
    required Color color,
    required double phase,
    required double yFactor,
    required double amplitude,
  }) {
    final path = Path()..moveTo(0, size.height * yFactor);
    for (double x = 0; x <= size.width; x += 22) {
      final y =
          size.height * yFactor +
          math.sin((x / size.width * math.pi * 2) + phase) * amplitude +
          math.sin((x / size.width * math.pi * 4) - phase * 0.7) *
              amplitude *
              0.38;
      path.lineTo(x, y);
    }
    path
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _BackdropPainter oldDelegate) {
    return oldDelegate.palette != palette ||
        oldDelegate.progress != progress ||
        oldDelegate.energy != energy;
  }
}

// ignore: unused_element
class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.controller});

  final MusicController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 236,
      color: Colors.black,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.graphic_eq, color: Color(0xff1ed760), size: 30),
              SizedBox(width: 10),
              Text(
                'Zen Music',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 28),
          _SidebarItem(
            icon: Icons.home_filled,
            label: 'Home',
            selected: controller.section == AppSection.home,
            onTap: () => controller.setSection(AppSection.home),
          ),
          const SizedBox(height: 10),
          _SidebarItem(
            icon: Icons.search,
            label: 'Szukaj',
            selected: controller.section == AppSection.search,
            onTap: () => controller.setSection(AppSection.search),
          ),
          const SizedBox(height: 10),
          _SidebarItem(
            icon: Icons.library_music,
            label: 'Biblioteka',
            selected: controller.section == AppSection.library,
            onTap: () => controller.setSection(AppSection.library),
          ),
          const SizedBox(height: 10),
          _SidebarItem(
            icon: Icons.favorite,
            label: 'Polubione',
            selected: controller.section == AppSection.liked,
            onTap: () => controller.setSection(AppSection.liked),
          ),
          const SizedBox(height: 10),
          _SidebarItem(
            icon: Icons.queue_music,
            label: 'Playlisty',
            selected: controller.section == AppSection.playlists,
            onTap: () => controller.setSection(AppSection.playlists),
          ),
          const SizedBox(height: 10),
          _SidebarItem(
            icon: Icons.person,
            label: 'Profil',
            selected: controller.section == AppSection.profile,
            onTap: () => controller.setSection(AppSection.profile),
          ),
          const SizedBox(height: 10),
          _SidebarItem(
            icon: Icons.tune,
            label: 'Ustawienia',
            selected: controller.section == AppSection.settings,
            onTap: () => controller.setSection(AppSection.settings),
          ),
          const Spacer(),
          if (controller.session != null) ...[
            Text(
              controller.session!.user.email,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: controller.logout,
              icon: const Icon(Icons.logout),
              label: const Text('Wyloguj'),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            controller.libraryUrl,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _LeftLibraryPanel extends StatelessWidget {
  const _LeftLibraryPanel({required this.controller});

  final MusicController controller;

  @override
  Widget build(BuildContext context) {
    final palette = _paletteFor(controller.themeChoice);
    final accent = palette.accent;
    return Container(
      width: 300,
      margin: const EdgeInsets.fromLTRB(6, 6, 6, 0),
      decoration: BoxDecoration(
        color: palette.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Biblioteka',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showCreatePlaylistDialog(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Utworz'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                _Pill(
                  label: 'Playlisty',
                  selected: controller.section == AppSection.playlists,
                  onTap: () => controller.setSection(AppSection.playlists),
                ),
                const SizedBox(width: 8),
                _Pill(
                  label: 'Artysci',
                  selected: controller.section == AppSection.library,
                  onTap: () => controller.setSection(AppSection.library),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: TextField(
              onChanged: controller.setSearch,
              decoration: const InputDecoration(
                isDense: true,
                prefixIcon: Icon(Icons.search),
                hintText: 'Szukaj w bibliotece',
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
              children: [
                _LibraryRow(
                  icon: Icons.favorite,
                  iconColor: accent,
                  title: 'Polubione utwory',
                  subtitle:
                      'Playlista - ${controller.likedTrackIds.length} utworow',
                  selected: controller.section == AppSection.liked,
                  onTap: () => controller.setSection(AppSection.liked),
                ),
                for (final playlist in controller.playlists)
                  _LibraryRow(
                    icon: Icons.queue_music,
                    iconColor: Colors.white,
                    title: playlist.name,
                    subtitle: 'Playlista - ${playlist.trackIds.length} utworow',
                    selected: false,
                    onTap: () => controller.setSection(AppSection.playlists),
                  ),
                if (controller.followedArtists.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Obserwowani artysci pojawia sie tutaj.',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  )
                else
                  for (final artist in controller.followedArtists)
                    _LibraryRow(
                      icon: Icons.person,
                      iconColor: _colorFor(artist.name),
                      imageUrl: artist.imageUrl,
                      title: artist.name,
                      subtitle: 'Wykonawca - ${artist.tracks.length} utworow',
                      selected: false,
                      onTap: () => controller.setSection(AppSection.library),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreatePlaylistDialog(BuildContext context) async {
    final textController = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nowa playlista'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(labelText: 'Nazwa'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, textController.text),
            child: const Text('Utworz'),
          ),
        ],
      ),
    );
    if (value != null) {
      await controller.createPlaylist(value);
    }
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white : const Color(0xff242424),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _LibraryRow extends StatelessWidget {
  const _LibraryRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.imageUrl,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final Uri? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xff232323) : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              _SquareImage(
                imageUrl: imageUrl,
                color: iconColor,
                icon: icon,
                size: 48,
                radius: 5,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpotifyTopNav extends StatelessWidget {
  const _SpotifyTopNav({required this.controller});

  final MusicController controller;

  @override
  Widget build(BuildContext context) {
    final palette = _paletteFor(controller.themeChoice);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;
        final tiny = constraints.maxWidth < 390;
        return Container(
          height: 58,
          margin: const EdgeInsets.fromLTRB(0, 6, 0, 0),
          padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 14),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.58),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Home',
                icon: const Icon(Icons.home_filled),
                onPressed: () => controller.setSection(AppSection.home),
              ),
              if (!tiny) const SizedBox(width: 6),
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: TextField(
                    onChanged: controller.setSearch,
                    decoration: InputDecoration(
                      isDense: true,
                      prefixIcon: const Icon(Icons.search),
                      hintText: compact ? 'Szukaj' : 'Czego chcesz posluchac?',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                tooltip: 'Losuj',
                icon: Icon(Icons.shuffle, color: palette.accent),
                onPressed: controller.playRandom,
              ),
              if (!compact)
                IconButton(
                  tooltip: 'Ustawienia',
                  icon: const Icon(Icons.tune),
                  onPressed: () => controller.setSection(AppSection.settings),
                ),
              if (!compact)
                IconButton(
                  tooltip: 'Profil',
                  icon: const Icon(Icons.person),
                  onPressed: () => controller.setSection(AppSection.profile),
                ),
              if (compact)
                PopupMenuButton<AppSection>(
                  tooltip: 'Menu',
                  icon: const Icon(Icons.more_vert),
                  onSelected: controller.setSection,
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: AppSection.settings,
                      child: Text('Ustawienia'),
                    ),
                    PopupMenuItem(
                      value: AppSection.profile,
                      child: Text('Profil'),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _NowPlayingPanel extends StatelessWidget {
  const _NowPlayingPanel({required this.controller});

  final MusicController controller;

  @override
  Widget build(BuildContext context) {
    final track = controller.currentTrack;
    final palette = _paletteFor(controller.themeChoice);
    final accent = palette.accent;
    return Container(
      width: 340,
      margin: const EdgeInsets.fromLTRB(6, 6, 6, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: track == null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Teraz odtwarzane',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
                SizedBox(height: 18),
                Text(
                  'Wybierz utwor, a tutaj pojawi sie karta wykonawcy i szczegoly odtwarzania.',
                  style: TextStyle(color: Colors.white60),
                ),
              ],
            )
          : ListView(
              children: [
                const Text(
                  'Teraz odtwarzane',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
                const SizedBox(height: 14),
                Container(
                  height: 290,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [track.color, Colors.black],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: track.coverUrl == null
                      ? Icon(track.icon, size: 110, color: Colors.black87)
                      : Image.network(
                          track.coverUrl.toString(),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            track.icon,
                            size: 110,
                            color: Colors.black87,
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            track.artist,
                            style: const TextStyle(color: Colors.white60),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Polub',
                      icon: Icon(
                        controller.isLiked(track)
                            ? Icons.favorite
                            : Icons.favorite_border,
                      ),
                      color: controller.isLiked(track) ? accent : Colors.white,
                      onPressed: () => controller.toggleLiked(track),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'O wykonawcy',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          track.artist,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Album: ${track.album}\nOdtworzenia lokalne: ${controller.playCounts[track.id] ?? 0}',
                          style: const TextStyle(color: Colors.white60),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _AuthScreen extends StatefulWidget {
  const _AuthScreen({required this.controller});

  final MusicController controller;

  @override
  State<_AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<_AuthScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool registerMode = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xff1f5134), Color(0xff121212), Colors.black],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Card(
              color: const Color(0xff181818),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.graphic_eq,
                      color: Color(0xff1ed760),
                      size: 48,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      registerMode ? 'Utworz konto' : 'Zaloguj sie',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      registerMode
                          ? 'Maksymalnie 2 konta z jednego IP.'
                          : 'Wejdz do swojej biblioteki i profilu.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white60),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      decoration: const InputDecoration(
                        labelText: 'Haslo',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                    if (widget.controller.authMessage != null) ...[
                      const SizedBox(height: 12),
                      _StatusBanner(message: widget.controller.authMessage!),
                    ],
                    const SizedBox(height: 18),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xff1ed760),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onPressed: widget.controller.authLoading ? null : _submit,
                      child: widget.controller.authLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.black,
                              ),
                            )
                          : Text(registerMode ? 'Zarejestruj' : 'Zaloguj'),
                    ),
                    TextButton(
                      onPressed: widget.controller.authLoading
                          ? null
                          : () => setState(() => registerMode = !registerMode),
                      child: Text(
                        registerMode
                            ? 'Masz juz konto? Zaloguj sie'
                            : 'Nie masz konta? Zarejestruj sie',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    if (registerMode) {
      await widget.controller.register(email, password);
    } else {
      await widget.controller.login(email, password);
    }
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xff1a1a1a) : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            children: [
              Icon(icon, color: selected ? Colors.white : Colors.white60),
              const SizedBox(width: 14),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white60,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _TopBar extends StatelessWidget {
  const _TopBar({required this.controller});

  final MusicController controller;

  @override
  Widget build(BuildContext context) {
    final trackCount = controller.artists.fold<int>(
      0,
      (count, artist) => count + artist.tracks.length,
    );
    final palette = _paletteFor(controller.themeChoice);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.gradientStart, palette.background],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: controller.setSearch,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Szukaj artysty, albumu albo utworu',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filledTonal(
                tooltip: 'Adres biblioteki',
                icon: const Icon(Icons.cloud_outlined),
                onPressed: () => _showLibraryDialog(context),
              ),
              IconButton.filledTonal(
                tooltip: 'Odswiez',
                icon: const Icon(Icons.refresh),
                onPressed: controller.refresh,
              ),
              IconButton.filledTonal(
                tooltip: 'Losuj utwor',
                icon: const Icon(Icons.shuffle),
                onPressed: controller.playRandom,
              ),
              IconButton.filledTonal(
                tooltip: 'Profil',
                icon: const Icon(Icons.person),
                onPressed: () => controller.setSection(AppSection.profile),
              ),
              IconButton.filledTonal(
                tooltip: 'Nowa playlista',
                icon: const Icon(Icons.playlist_add),
                onPressed: () => _showCreatePlaylistDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'PLAYLISTA',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Twoja muzyka',
            style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            '${controller.artists.length} artystow - $trackCount utworow',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Future<void> _showLibraryDialog(BuildContext context) async {
    final textController = TextEditingController(text: controller.libraryUrl);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adres biblioteki'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            labelText: 'URL',
            hintText: 'https://shit.com.pl/zen-music',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, textController.text),
            child: const Text('Zapisz'),
          ),
        ],
      ),
    );

    if (value != null && value.trim().isNotEmpty) {
      await controller.setLibraryUrl(value);
    }
  }

  Future<void> _showCreatePlaylistDialog(BuildContext context) async {
    final textController = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nowa playlista'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            labelText: 'Nazwa',
            hintText: 'Moja playlista',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, textController.text),
            child: const Text('Utworz'),
          ),
        ],
      ),
    );

    if (value != null) {
      await controller.createPlaylist(value);
    }
  }
}

class _LibraryView extends StatelessWidget {
  const _LibraryView({required this.artists, required this.controller});

  final List<Artist> artists;
  final MusicController controller;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 126),
      itemCount: artists.length,
      itemBuilder: (context, index) =>
          _ArtistSection(artist: artists[index], controller: controller),
    );
  }
}

class _ContentView extends StatelessWidget {
  const _ContentView({required this.controller});

  final MusicController controller;

  @override
  Widget build(BuildContext context) {
    switch (controller.section) {
      case AppSection.search:
        final artists = controller.visibleArtists();
        return artists.isEmpty
            ? const _EmptyView(message: 'Nic nie znaleziono.')
            : _LibraryView(artists: artists, controller: controller);
      case AppSection.library:
        return controller.artists.isEmpty
            ? const _EmptyView()
            : _LibraryView(artists: controller.artists, controller: controller);
      case AppSection.liked:
        return _LikedSongsView(controller: controller);
      case AppSection.playlists:
        return _PlaylistsView(controller: controller);
      case AppSection.profile:
        return _ProfileView(controller: controller);
      case AppSection.settings:
        return _SettingsView(controller: controller);
      case AppSection.home:
        return _HomeDashboard(controller: controller);
    }
  }
}

class _HomeDashboard extends StatelessWidget {
  const _HomeDashboard({required this.controller});

  final MusicController controller;

  @override
  Widget build(BuildContext context) {
    final quickTracks = controller.allTracks.take(6).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 126),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Start',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: controller.playRandom,
              icon: const Icon(Icons.shuffle),
              label: const Text('Losuj'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _QuickTileGrid(controller: controller, tracks: quickTracks),
        const SizedBox(height: 28),
        if (controller.recentTracks.isNotEmpty)
          _TrackShelf(
            title: 'Ostatnio odtwarzane',
            tracks: controller.recentTracks.take(8).toList(),
            controller: controller,
          ),
        if (controller.topTracks.isNotEmpty)
          _TrackShelf(
            title: 'Najczesciej sluchane',
            tracks: controller.topTracks,
            controller: controller,
          ),
        Text(
          'Artysci',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        if (controller.artists.isEmpty)
          const _EmptyView()
        else
          for (final artist in controller.visibleArtists().take(4)) ...[
            _ArtistSection(artist: artist, controller: controller),
          ],
      ],
    );
  }
}

class _QuickTileGrid extends StatelessWidget {
  const _QuickTileGrid({required this.controller, required this.tracks});

  final MusicController controller;
  final List<Track> tracks;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
      _QuickTile(
        title: 'Polubione utwory',
        icon: Icons.favorite,
        color: _paletteFor(controller.themeChoice).accent,
        gradient: true,
        onTap: () => controller.setSection(AppSection.liked),
      ),
      for (final playlist in controller.playlists.take(2))
        _QuickTile(
          title: playlist.name,
          icon: Icons.queue_music,
          color: const Color(0xff7c3aed),
          onTap: () => controller.setSection(AppSection.playlists),
        ),
      for (final track in tracks)
        _QuickTile(
          title: track.title,
          icon: track.icon,
          color: track.color,
          imageUrl: track.coverUrl,
          onTap: () => controller.play(track),
        ),
    ].take(8).toList();

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 900 ? 4 : 2;
        return GridView.count(
          crossAxisCount: columns,
          childAspectRatio: 3.8,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: items,
        );
      },
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    this.imageUrl,
    this.gradient = false,
  });

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final Uri? imageUrl;
  final bool gradient;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xff2a2a2a),
      borderRadius: BorderRadius.circular(5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(5),
        child: Row(
          children: [
            Container(
              width: 82,
              height: double.infinity,
              decoration: BoxDecoration(
                color: color,
                gradient: gradient
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [color, Colors.white.withValues(alpha: 0.72)],
                      )
                    : null,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(5),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: imageUrl == null
                  ? Icon(icon, color: Colors.black, size: 28)
                  : Image.network(
                      imageUrl.toString(),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(icon, color: Colors.black, size: 28),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

class _TrackShelf extends StatelessWidget {
  const _TrackShelf({
    required this.title,
    required this.tracks,
    required this.controller,
  });

  final String title;
  final List<Track> tracks;
  final MusicController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 156,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: tracks.length,
              separatorBuilder: (_, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) =>
                  _MiniTrackCard(track: tracks[index], controller: controller),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniTrackCard extends StatelessWidget {
  const _MiniTrackCard({required this.track, required this.controller});

  final Track track;
  final MusicController controller;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => controller.play(track),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 132,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xff181818),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TrackArt(track: track),
            const SizedBox(height: 10),
            Text(
              track.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            Text(
              track.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white60),
            ),
          ],
        ),
      ),
    );
  }
}

class _LikedSongsView extends StatelessWidget {
  const _LikedSongsView({required this.controller});

  final MusicController controller;

  @override
  Widget build(BuildContext context) {
    final tracks = controller.likedTracks;
    final palette = _paletteFor(controller.themeChoice);
    final totalSeconds = tracks.fold<int>(
      0,
      (sum, track) => sum + track.duration.inSeconds,
    );
    final subtitle =
        '${tracks.length} utworow - ${_formatDuration(Duration(seconds: totalSeconds))}';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 126),
      children: [
        _PlaylistHero(
          title: 'Polubione utwory',
          eyebrow: 'Playlista',
          subtitle: subtitle,
          icon: Icons.favorite,
          gradientColors: [palette.accent, palette.glow, palette.gradientStart],
        ),
        const SizedBox(height: 18),
        _PlaylistActionBar(
          tracks: tracks,
          controller: controller,
          onDownload: controller.downloadLikedTracks,
        ),
        const SizedBox(height: 12),
        if (tracks.isEmpty)
          const _EmptyView(message: 'Polubione utwory sa puste.')
        else
          _TrackTable(tracks: tracks, controller: controller),
      ],
    );
  }
}

class _PlaylistHero extends StatelessWidget {
  const _PlaylistHero({
    required this.title,
    required this.eyebrow,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
  });

  final String title;
  final String eyebrow;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 680;
        final artSize = compact ? 118.0 : 188.0;
        final art = Container(
          width: artSize,
          height: artSize,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: gradientColors.first.withValues(alpha: 0.22),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: compact ? 54 : 84),
        );
        final text = Column(
          crossAxisAlignment: compact
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            Text(
              eyebrow,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: compact ? TextAlign.center : TextAlign.start,
              style: TextStyle(
                fontSize: compact ? 36 : 62,
                height: 0.95,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            Text(subtitle, style: const TextStyle(color: Colors.white70)),
          ],
        );

        final content = compact
            ? Column(children: [art, const SizedBox(height: 16), text])
            : Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  art,
                  const SizedBox(width: 22),
                  Expanded(child: text),
                ],
              );

        return Container(
          padding: EdgeInsets.all(compact ? 18 : 26),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                gradientColors.last.withValues(alpha: 0.95),
                gradientColors.first.withValues(alpha: 0.45),
                Colors.black.withValues(alpha: 0.12),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: content,
        );
      },
    );
  }
}

class _PlaylistActionBar extends StatelessWidget {
  const _PlaylistActionBar({
    required this.tracks,
    required this.controller,
    this.onDownload,
  });

  final List<Track> tracks;
  final MusicController controller;
  final Future<void> Function()? onDownload;

  @override
  Widget build(BuildContext context) {
    final palette = _paletteFor(controller.themeChoice);
    final active = _isTrackGroupActive(tracks, controller);
    final playing = active && controller.playing;
    final cached = controller.areTracksCached(tracks);
    return Row(
      children: [
        IconButton.filled(
          tooltip: playing ? 'Pauza' : 'Odtworz',
          style: IconButton.styleFrom(
            backgroundColor: palette.accent,
            foregroundColor: Colors.black,
            fixedSize: const Size(54, 54),
          ),
          icon: Icon(playing ? Icons.pause : Icons.play_arrow, size: 30),
          onPressed: tracks.isEmpty
              ? null
              : active
              ? controller.togglePlay
              : () => controller.play(tracks.first),
        ),
        const SizedBox(width: 10),
        IconButton(
          tooltip: cached ? 'Pobrane offline' : 'Pobierz offline',
          icon: controller.offlineDownloading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                )
              : Icon(
                  cached
                      ? Icons.download_done
                      : Icons.download_for_offline_outlined,
                ),
          color: cached ? palette.accent : Colors.white60,
          onPressed: tracks.isEmpty || controller.offlineDownloading
              ? null
              : onDownload,
        ),
        const Spacer(),
      ],
    );
  }
}

class _TrackTable extends StatelessWidget {
  const _TrackTable({required this.tracks, required this.controller});

  final List<Track> tracks;
  final MusicController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Row(
            children: [
              SizedBox(width: 28, child: Text('#')),
              SizedBox(width: 58),
              Expanded(flex: 3, child: Text('Tytul')),
              Expanded(flex: 2, child: Text('Album')),
              SizedBox(width: 74, child: Icon(Icons.schedule, size: 18)),
              SizedBox(width: 150),
            ],
          ),
        ),
        Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
        const SizedBox(height: 6),
        for (var i = 0; i < tracks.length; i++) ...[
          _TrackTile(index: i + 1, track: tracks[i], controller: controller),
          const SizedBox(height: 4),
        ],
      ],
    );
  }
}

bool _isTrackGroupActive(List<Track> tracks, MusicController controller) {
  final current = controller.currentTrack;
  if (current == null) {
    return false;
  }
  return tracks.any((track) => track.id == current.id);
}

class _PlaylistsView extends StatelessWidget {
  const _PlaylistsView({required this.controller});

  final MusicController controller;

  @override
  Widget build(BuildContext context) {
    final palette = _paletteFor(controller.themeChoice);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 126),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Playlisty',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: () => _showCreatePlaylistDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Nowa'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _PinnedLikedPlaylistCard(controller: controller),
        const SizedBox(height: 18),
        if (controller.playlists.isEmpty)
          Card(
            margin: EdgeInsets.zero,
            color: palette.surface.withValues(alpha: 0.72),
            child: const Padding(
              padding: EdgeInsets.all(18),
              child: Text('Nie masz jeszcze playlist. Utworz pierwsza u gory.'),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 900 ? 2 : 1;
              return GridView.count(
                crossAxisCount: columns,
                childAspectRatio: columns == 2 ? 2.35 : 3.6,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (final playlist in controller.playlists)
                    _PlaylistCard(playlist: playlist, controller: controller),
                ],
              );
            },
          ),
      ],
    );
  }

  Future<void> _showCreatePlaylistDialog(BuildContext context) async {
    final textController = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nowa playlista'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(labelText: 'Nazwa'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, textController.text),
            child: const Text('Utworz'),
          ),
        ],
      ),
    );
    if (value != null) {
      await controller.createPlaylist(value);
    }
  }
}

class _PinnedLikedPlaylistCard extends StatelessWidget {
  const _PinnedLikedPlaylistCard({required this.controller});

  final MusicController controller;

  @override
  Widget build(BuildContext context) {
    final palette = _paletteFor(controller.themeChoice);
    final tracks = controller.likedTracks;
    final active = _isTrackGroupActive(tracks, controller);
    final playing = active && controller.playing;
    final cached = controller.areTracksCached(tracks);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => controller.setSection(AppSection.liked),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                palette.gradientStart.withValues(alpha: 0.95),
                palette.accent.withValues(alpha: 0.5),
                palette.surface.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [palette.accent, palette.glow],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: 34,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Przypiete',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Polubione utwory',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${tracks.length} utworow - zawsze na gorze',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              IconButton.filled(
                tooltip: playing ? 'Pauza' : 'Odtworz polubione',
                style: IconButton.styleFrom(
                  backgroundColor: palette.accent,
                  foregroundColor: Colors.black,
                ),
                icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                onPressed: tracks.isEmpty
                    ? null
                    : active
                    ? controller.togglePlay
                    : () => controller.play(tracks.first),
              ),
              IconButton(
                tooltip: cached ? 'Pobrane offline' : 'Pobierz offline',
                icon: Icon(
                  cached
                      ? Icons.download_done
                      : Icons.download_for_offline_outlined,
                ),
                color: cached ? palette.accent : Colors.white60,
                onPressed: tracks.isEmpty || controller.offlineDownloading
                    ? null
                    : controller.downloadLikedTracks,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  const _PlaylistCard({required this.playlist, required this.controller});

  final Playlist playlist;
  final MusicController controller;

  @override
  Widget build(BuildContext context) {
    final tracks = controller.tracksForPlaylist(playlist);
    final palette = _paletteFor(controller.themeChoice);
    final cover = tracks.isEmpty ? null : tracks.first.coverUrl;
    final active = _isTrackGroupActive(tracks, controller);
    final playing = active && controller.playing;
    final cached = controller.areTracksCached(tracks);
    return Container(
      decoration: BoxDecoration(
        color: palette.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: tracks.isEmpty ? null : () => controller.play(tracks.first),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _SquareImage(
                      imageUrl: cover,
                      color: palette.gradientStart,
                      icon: Icons.queue_music,
                      size: 72,
                      radius: 8,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            playlist.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            '${tracks.length} utworow',
                            style: const TextStyle(color: Colors.white60),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'Opcje playlisty',
                      icon: const Icon(Icons.more_horiz),
                      onSelected: (value) async {
                        if (value == 'delete') {
                          await _confirmDelete(context);
                          return;
                        }
                        if (value == 'download') {
                          await controller.downloadPlaylist(playlist);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'download',
                          child: Text('Pobierz offline'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Usun playliste'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: tracks.isEmpty
                      ? const Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            'Dodaj utwory przez menu przy piosence.',
                            style: TextStyle(color: Colors.white60),
                          ),
                        )
                      : Column(
                          children: [
                            for (final track in tracks.take(3))
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        track.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _formatDuration(track.duration),
                                      style: const TextStyle(
                                        color: Colors.white54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (tracks.length > 3)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '+${tracks.length - 3} wiecej',
                                  style: const TextStyle(color: Colors.white54),
                                ),
                              ),
                          ],
                        ),
                ),
                Row(
                  children: [
                    IconButton.filled(
                      tooltip: playing ? 'Pauza' : 'Odtworz',
                      style: IconButton.styleFrom(
                        backgroundColor: palette.accent,
                        foregroundColor: Colors.black,
                      ),
                      icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                      onPressed: tracks.isEmpty
                          ? null
                          : active
                          ? controller.togglePlay
                          : () => controller.play(tracks.first),
                    ),
                    IconButton(
                      tooltip: 'Pobierz offline',
                      icon: controller.offlineDownloading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              cached
                                  ? Icons.download_done
                                  : Icons.download_for_offline_outlined,
                            ),
                      color: cached ? palette.accent : Colors.white60,
                      onPressed: tracks.isEmpty || controller.offlineDownloading
                          ? null
                          : () => controller.downloadPlaylist(playlist),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Usun playliste',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _confirmDelete(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final delete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usun playliste?'),
        content: Text('Playlista "${playlist.name}" zostanie usunieta.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Usun'),
          ),
        ],
      ),
    );
    if (delete == true) {
      await controller.deletePlaylist(playlist);
    }
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({required this.controller});

  final MusicController controller;

  @override
  Widget build(BuildContext context) {
    final user = controller.session?.user;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 126),
      children: [
        Text(
          'Profil',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Email: ${user?.email ?? '-'}'),
                const SizedBox(height: 8),
                Text('ID: ${user?.id ?? '-'}'),
                const SizedBox(height: 8),
                Text('Konto utworzone: ${user?.createdAt ?? '-'}'),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: controller.logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Wyloguj'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView({required this.controller});

  final MusicController controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 126),
      children: [
        Text(
          'Ustawienia',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 18),
        Text(
          'Motyw aplikacji',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _ThemeTile(
              label: 'Spotify',
              choice: AppThemeChoice.spotify,
              controller: controller,
            ),
            _ThemeTile(
              label: 'Aurora',
              choice: AppThemeChoice.aurora,
              controller: controller,
            ),
            _ThemeTile(
              label: 'Ocean',
              choice: AppThemeChoice.ocean,
              controller: controller,
            ),
            _ThemeTile(
              label: 'Neon',
              choice: AppThemeChoice.neon,
              controller: controller,
            ),
            _ThemeTile(
              label: 'Violet',
              choice: AppThemeChoice.violet,
              controller: controller,
            ),
            _ThemeTile(
              label: 'Amber',
              choice: AppThemeChoice.amber,
              controller: controller,
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text(
          'Sortowanie biblioteki',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        SegmentedButton<LibrarySort>(
          segments: const [
            ButtonSegment(
              value: LibrarySort.artist,
              icon: Icon(Icons.person),
              label: Text('Artysta'),
            ),
            ButtonSegment(
              value: LibrarySort.title,
              icon: Icon(Icons.sort_by_alpha),
              label: Text('Tytul'),
            ),
            ButtonSegment(
              value: LibrarySort.newest,
              icon: Icon(Icons.fiber_new),
              label: Text('Najnowsze'),
            ),
          ],
          selected: {controller.sort},
          onSelectionChanged: (selection) =>
              controller.setSort(selection.first),
        ),
        const SizedBox(height: 28),
        Card(
          child: ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Dane lokalne'),
            subtitle: Text(
              '${controller.likedTrackIds.length} polubionych, ${controller.playlists.length} playlist, ${controller.recentTrackIds.length} ostatnich utworow',
            ),
          ),
        ),
      ],
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.label,
    required this.choice,
    required this.controller,
  });

  final String label;
  final AppThemeChoice choice;
  final MusicController controller;

  @override
  Widget build(BuildContext context) {
    final palette = _paletteFor(choice);
    final selected = controller.themeChoice == choice;
    return InkWell(
      onTap: () => controller.setThemeChoice(choice),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? palette.accent : Colors.white12,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Swatch(color: palette.accent),
                const SizedBox(width: 6),
                _Swatch(color: palette.gradientStart),
                const SizedBox(width: 6),
                _Swatch(color: palette.input),
              ],
            ),
            const SizedBox(height: 14),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
            if (selected)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'Aktywny',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _ArtistSection extends StatelessWidget {
  const _ArtistSection({required this.artist, required this.controller});

  final Artist artist;
  final MusicController controller;

  @override
  Widget build(BuildContext context) {
    final following = controller.isFollowing(artist);
    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ArtistAvatar(artist: artist),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      artist.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      '${artist.tracks.length} utworow',
                      style: const TextStyle(color: Colors.white60),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => controller.toggleFollowArtist(artist),
                icon: Icon(following ? Icons.check : Icons.add),
                label: Text(following ? 'Obserwujesz' : 'Obserwuj'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < artist.tracks.length; i++) ...[
            _TrackTile(
              index: i + 1,
              track: artist.tracks[i],
              controller: controller,
              playlist: null,
            ),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _ArtistAvatar extends StatelessWidget {
  const _ArtistAvatar({required this.artist});

  final Artist artist;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: _SquareImage(
        imageUrl: artist.imageUrl,
        color: artist.tracks.isEmpty
            ? const Color(0xff1ed760)
            : artist.tracks.first.color,
        icon: Icons.person,
        size: 62,
        radius: 31,
        fallbackText: artist.name.isEmpty ? '?' : artist.name[0].toUpperCase(),
      ),
    );
  }
}

class _TrackTile extends StatelessWidget {
  const _TrackTile({
    required this.index,
    required this.track,
    required this.controller,
    this.playlist,
  });

  final int index;
  final Track track;
  final MusicController controller;
  final Playlist? playlist;

  @override
  Widget build(BuildContext context) {
    final isCurrent = controller.currentTrack?.id == track.id;
    final busy = isCurrent && controller.downloading;
    final liked = controller.isLiked(track);
    final cached = controller.isTrackCached(track);

    return Material(
      color: isCurrent ? const Color(0xff243829) : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: busy ? null : () => controller.play(track),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        '$index',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white54),
                      ),
              ),
              const SizedBox(width: 12),
              _TrackArt(track: track),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isCurrent
                            ? const Color(0xff1ed760)
                            : Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      track.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white60),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  track.album,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white60),
                ),
              ),
              Text(
                _formatDuration(track.duration),
                style: const TextStyle(color: Colors.white60),
              ),
              const SizedBox(width: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: IconButton(
                  key: ValueKey('offline-${track.id}-$cached'),
                  tooltip: cached
                      ? 'Usun z pobranych'
                      : 'Pobierz ten utwor offline',
                  icon: Icon(
                    cached
                        ? Icons.download_done
                        : Icons.download_for_offline_outlined,
                    size: 20,
                  ),
                  color: cached ? const Color(0xff1ed760) : Colors.white54,
                  onPressed: controller.offlineDownloading
                      ? null
                      : cached
                      ? () => controller.removeOfflineTrack(track)
                      : () => controller.downloadTrackForOffline(track),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: liked ? 'Usun z polubionych' : 'Dodaj do polubionych',
                icon: Icon(liked ? Icons.favorite : Icons.favorite_border),
                color: liked ? const Color(0xff1ed760) : Colors.white70,
                onPressed: () => controller.toggleLiked(track),
              ),
              PopupMenuButton<String>(
                tooltip: 'Opcje',
                icon: const Icon(Icons.more_horiz),
                onSelected: (value) async {
                  if (value == '__download__') {
                    await controller.downloadTrackForOffline(track);
                    return;
                  }
                  if (value == '__remove_download__') {
                    await controller.removeOfflineTrack(track);
                    return;
                  }
                  if (value == '__remove__' && playlist != null) {
                    await controller.removeFromPlaylist(playlist!, track);
                    return;
                  }
                  Playlist? selected;
                  for (final item in controller.playlists) {
                    if (item.id == value) {
                      selected = item;
                      break;
                    }
                  }
                  if (selected != null) {
                    await controller.addToPlaylist(selected, track);
                  }
                },
                itemBuilder: (context) => [
                  if (playlist != null)
                    const PopupMenuItem(
                      value: '__remove__',
                      child: Text('Usun z playlisty'),
                    ),
                  PopupMenuItem(
                    value: cached ? '__remove_download__' : '__download__',
                    child: Text(
                      cached ? 'Usun z pobranych' : 'Pobierz offline',
                    ),
                  ),
                  if (controller.playlists.isEmpty)
                    const PopupMenuItem(
                      enabled: false,
                      value: '__empty__',
                      child: Text('Brak playlist'),
                    )
                  else
                    for (final item in controller.playlists)
                      PopupMenuItem(
                        value: item.id,
                        child: Text('Dodaj do: ${item.name}'),
                      ),
                ],
              ),
              IconButton(
                tooltip: 'Odtworz',
                icon: Icon(isCurrent ? Icons.graphic_eq : Icons.play_arrow),
                color: isCurrent ? const Color(0xff1ed760) : Colors.white,
                onPressed: busy ? null : () => controller.play(track),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrackArt extends StatelessWidget {
  const _TrackArt({super.key, required this.track});

  final Track track;

  @override
  Widget build(BuildContext context) {
    return _SquareImage(
      imageUrl: track.coverUrl,
      color: track.color,
      icon: track.icon,
      size: 46,
      radius: 6,
    );
  }
}

class _SquareImage extends StatelessWidget {
  const _SquareImage({
    super.key,
    required this.imageUrl,
    required this.color,
    required this.icon,
    required this.size,
    required this.radius,
    this.fallbackText,
  });

  final Uri? imageUrl;
  final Color color;
  final IconData icon;
  final double size;
  final double radius;
  final String? fallbackText;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Center(
        child: fallbackText == null
            ? Icon(icon, color: Colors.black87)
            : Text(
                fallbackText!,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                ),
              ),
      ),
    );

    final url = imageUrl;
    if (url == null) {
      return fallback;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.network(
        url.toString(),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallback,
      ),
    );
  }
}

class _PlayerBar extends StatelessWidget {
  const _PlayerBar({required this.controller});

  final MusicController controller;

  @override
  Widget build(BuildContext context) {
    final track = controller.currentTrack;
    final palette = _paletteFor(controller.themeChoice);
    final total = track?.duration ?? Duration.zero;
    final max = total.inMilliseconds.toDouble().clamp(1.0, double.infinity);
    final value = controller.position.inMilliseconds.toDouble().clamp(0.0, max);
    final compact = MediaQuery.sizeOf(context).width < 760;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      height: 120,
      decoration: BoxDecoration(
        color: Color.lerp(
          palette.surface,
          Colors.black,
          controller.playing ? 0.1 : 0.34,
        )!.withValues(alpha: 0.96),
        border: Border(
          top: BorderSide(color: palette.accent.withValues(alpha: 0.22)),
        ),
        boxShadow: [
          BoxShadow(
            color: palette.glow.withValues(
              alpha: controller.playing ? 0.18 : 0.04,
            ),
            blurRadius: controller.playing ? 32 : 12,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: Row(
            children: [
              SizedBox(
                width: compact ? 190 : 280,
                child: Row(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: track == null
                          ? _SquareImage(
                              key: const ValueKey('empty-art'),
                              imageUrl: null,
                              color: palette.gradientStart,
                              icon: Icons.graphic_eq,
                              size: 52,
                              radius: 8,
                            )
                          : _TrackArt(key: ValueKey(track.id), track: track),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: Column(
                          key: ValueKey(track?.id ?? 'empty-text'),
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              track?.title ?? 'Wybierz utwor',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              track?.artist ?? 'Muzyka z shit.com.pl',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white60),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!compact && track != null)
                      IconButton(
                        tooltip: controller.isLiked(track)
                            ? 'Usun z polubionych'
                            : 'Dodaj do polubionych',
                        icon: Icon(
                          controller.isLiked(track)
                              ? Icons.favorite
                              : Icons.favorite_border,
                        ),
                        color: controller.isLiked(track)
                            ? palette.accent
                            : Colors.white70,
                        onPressed: () => controller.toggleLiked(track),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          tooltip: 'Poprzedni',
                          icon: const Icon(Icons.skip_previous),
                          onPressed: track == null
                              ? null
                              : () => controller.playAdjacent(-1),
                        ),
                        IconButton(
                          tooltip: 'Cofnij 10 sekund',
                          icon: const Icon(Icons.replay_10),
                          onPressed: track == null
                              ? null
                              : () => controller.seekRelative(
                                  const Duration(seconds: -10),
                                ),
                        ),
                        IconButton.filled(
                          tooltip: controller.playing ? 'Pauza' : 'Odtworz',
                          style: IconButton.styleFrom(
                            backgroundColor: palette.accent,
                            foregroundColor: Colors.black,
                            fixedSize: const Size(48, 48),
                          ),
                          icon: controller.downloading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: Colors.black,
                                  ),
                                )
                              : Icon(
                                  controller.playing
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                ),
                          onPressed: track == null || controller.downloading
                              ? null
                              : controller.togglePlay,
                        ),
                        IconButton(
                          tooltip: 'Dalej 10 sekund',
                          icon: const Icon(Icons.forward_10),
                          onPressed: track == null
                              ? null
                              : () => controller.seekRelative(
                                  const Duration(seconds: 10),
                                ),
                        ),
                        IconButton(
                          tooltip: 'Nastepny',
                          icon: const Icon(Icons.skip_next),
                          onPressed: track == null
                              ? null
                              : () => controller.playAdjacent(1),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(_formatDuration(controller.position)),
                        Expanded(
                          child: Slider(
                            value: value,
                            max: max,
                            activeColor: palette.accent,
                            onChanged: track == null || controller.downloading
                                ? null
                                : (value) => controller.seekTo(
                                    Duration(milliseconds: value.round()),
                                  ),
                          ),
                        ),
                        Text(_formatDuration(total)),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: compact ? 0 : 280),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xff2a2013),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xfff59e0b)),
      ),
      child: Text(message),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({
    this.message =
        'Brak muzyki. Wrzuc library.json, foldery artystow i pliki WAV na hosting.',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}

Color _colorFor(String text) {
  final colors = <Color>[
    const Color(0xff1ed760),
    const Color(0xff5eead4),
    const Color(0xff93c5fd),
    const Color(0xfff472b6),
    const Color(0xfffacc15),
  ];
  final index = text.codeUnits.fold<int>(0, (sum, code) => sum + code);
  return colors[index % colors.length];
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString();
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
