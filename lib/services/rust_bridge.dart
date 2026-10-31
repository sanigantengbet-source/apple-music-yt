import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:ffi/ffi.dart';
import '../models/song.dart';

// Typedefs for Rust C-FFI
typedef YtMusicPingC = ffi.Int32 Function();
typedef YtMusicPingDart = int Function();

typedef YtMusicSearchC = ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8> query, ffi.Pointer<Utf8> filter);
typedef YtMusicSearchDart = ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8> query, ffi.Pointer<Utf8> filter);

typedef YtMusicGetStreamUrlC = ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8> videoId);
typedef YtMusicGetStreamUrlDart = ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8> videoId);

typedef YtMusicFreeStringC = ffi.Void Function(ffi.Pointer<Utf8> ptr);
typedef YtMusicFreeStringDart = void Function(ffi.Pointer<Utf8> ptr);

class RustBridge {
  static final RustBridge _instance = RustBridge._internal();
  factory RustBridge() => _instance;

  ffi.DynamicLibrary? _dylib;
  bool _isAvailable = false;

  YtMusicPingDart? _pingFn;
  YtMusicSearchDart? _searchFn;
  YtMusicGetStreamUrlDart? _getStreamUrlFn;
  YtMusicFreeStringDart? _freeStringFn;

  RustBridge._internal() {
    _initDylib();
  }

  bool get isRustNativeAvailable => _isAvailable;

  void _initDylib() {
    try {
      if (Platform.isAndroid) {
        _dylib = ffi.DynamicLibrary.open('libytmusic_rust.so');
      } else if (Platform.isLinux) {
        try {
          _dylib = ffi.DynamicLibrary.open('libytmusic_rust.so');
        } catch (_) {
          _dylib = ffi.DynamicLibrary.open('./native/target/release/libytmusic_rust.so');
        }
      } else if (Platform.isWindows) {
        _dylib = ffi.DynamicLibrary.open('ytmusic_rust.dll');
      } else if (Platform.isMacOS || Platform.isIOS) {
        _dylib = ffi.DynamicLibrary.process();
      }

      if (_dylib != null) {
        _pingFn = _dylib!.lookupFunction<YtMusicPingC, YtMusicPingDart>('ytmusic_ping');
        _searchFn = _dylib!.lookupFunction<YtMusicSearchC, YtMusicSearchDart>('ytmusic_search');
        _getStreamUrlFn = _dylib!.lookupFunction<YtMusicGetStreamUrlC, YtMusicGetStreamUrlDart>('ytmusic_get_stream_url');
        _freeStringFn = _dylib!.lookupFunction<YtMusicFreeStringC, YtMusicFreeStringDart>('ytmusic_free_string');

        if (_pingFn != null && _pingFn!() == 42) {
          _isAvailable = true;
          // Successfully loaded Rust native core!
        }
      }
    } catch (e) {
      // Rust library not yet compiled or placed in runtime library path; fallback will handle requests
      _isAvailable = false;
    }
  }

  /// Search songs using Rust Core if available
  List<Song>? search(String query, {String filter = 'songs'}) {
    if (!_isAvailable || _searchFn == null || _freeStringFn == null) return null;

    final queryPtr = query.toNativeUtf8();
    final filterPtr = filter.toNativeUtf8();

    try {
      final resPtr = _searchFn!(queryPtr, filterPtr);
      if (resPtr == ffi.nullptr) return null;

      final jsonStr = resPtr.toDartString();
      _freeStringFn!(resPtr);

      final decoded = jsonDecode(jsonStr);
      if (decoded is List) {
        return decoded.map((item) => Song.fromJson(item as Map<String, dynamic>)).toList();
      }
      return null;
    } catch (_) {
      return null;
    } finally {
      malloc.free(queryPtr);
      malloc.free(filterPtr);
    }
  }

  /// Get direct audio stream URL using Rust Core if available
  Map<String, dynamic>? getStreamUrl(String videoId) {
    if (!_isAvailable || _getStreamUrlFn == null || _freeStringFn == null) return null;

    final idPtr = videoId.toNativeUtf8();
    try {
      final resPtr = _getStreamUrlFn!(idPtr);
      if (resPtr == ffi.nullptr) return null;

      final jsonStr = resPtr.toDartString();
      _freeStringFn!(resPtr);

      final decoded = jsonDecode(jsonStr);
      if (decoded is Map<String, dynamic> && decoded['url'] != null) {
        return decoded;
      }
      return null;
    } catch (_) {
      return null;
    } finally {
      malloc.free(idPtr);
    }
  }
}
