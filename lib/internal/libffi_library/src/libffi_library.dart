part of binary_interop.internal.libffi_library;

class LibffiLibrary {
  static const LIBFFI_VERSION = 6;

  static final LibffiLibrary current = _load();

  final String filename;

  int _ffiCall;

  int _ffiPrepCif;

  int _ffiPrepCifVar;

  int _handle;

  LibffiLibrary(int handle, this.filename) {
    if (handle == null) {
      throw new ArgumentError.notNull("handle");
    }

    if (filename == null) {
      throw new ArgumentError.notNull("filename");
    }

    _handle = handle;
    _ffiCall = _import("ffi_call");
    _ffiPrepCif = _import("ffi_prep_cif");
    _ffiPrepCifVar = _import("ffi_prep_cif_var");
  }

  void ffiCall(int cif, int fn, int rvalue, int avalue) {
    ForeignFunctionInterface.callFunction(_ffiCall, cif, fn, rvalue, avalue);
    return;
  }

  int ffiPrepCif(int cif, int abi, int nargs, int rtype, int atypes) {
    return ForeignFunctionInterface.prepareCallInterface(_ffiPrepCif, cif, abi, nargs, rtype, atypes);
  }

  int ffiPrepCifVar(int cif, int abi, int nfixedargs, int ntotalargs, int rtype, int atypes) {
    return ForeignFunctionInterface.prepareCallInterfaceVariadic(
        _ffiPrepCifVar, cif, abi, nfixedargs, ntotalargs, rtype, atypes);
  }

  static String _findAlternativePubCache() {
    var sdk = _findPathToDartVM();
    if (sdk == null) {
      return null;
    }

    var parts = sdk.split("/");
    if (parts.length < 4) {
      return null;
    }

    if (parts[1] != "home") {
      return null;
    }

    var user = parts[2];
    return "/home/$user/.pub-cache";
  }

  int _import(String symbol) {
    var address = Unsafe.librarySymbol(_handle, symbol);
    if (address == null) {
      throw new ArgumentError("Symbol '$symbol' not found in '$filename'");
    }

    return address;
  }

  static String _getPubCachePath() {
    if (Platform.environment.containsKey('PUB_CACHE')) {
      return pathos.normalize(Platform.environment['PUB_CACHE']);
    } else if (Platform.isWindows) {
      var path = Platform.environment['APPDATA'];
      return pathos.join(path, 'Pub', 'Cache');
    } else {
      return pathos.join(Platform.environment['HOME'], ".pub-cache");
    }
  }

  static LibffiLibrary _load() {
    String filename;
    switch (Platform.operatingSystem) {
      case "android":
      case "linux":
        filename = "libffi.so.$LIBFFI_VERSION";
        break;
      case "macos":
        filename = "libffi.$LIBFFI_VERSION.dylib";
        break;
      case "windows":
        filename = "libffi-$LIBFFI_VERSION.dll";
        break;
      default:
        return null;
    }

    var cache = _getPubCachePath();
    var handle = _loadFromLibffiBinaries(cache, filename);
    if (handle == 0) {
      cache = _findAlternativePubCache();
      if (cache != null) {
        handle = _loadFromLibffiBinaries(cache, filename);
      }

      //handle = Unsafe.libraryLoad(filename);
    }

    if (handle == 0) {
      return null;
    }

    return new LibffiLibrary(handle, filename);
  }

  static int _loadFromLibffiBinaries(String pubCache, String filename) {
    var operatingSystem = Platform.operatingSystem;
    var architecture = SysInfo.processors.first.architecture;
    switch (architecture) {
      case ProcessorArchitecture.X86:
        break;
      case ProcessorArchitecture.X86_64:
        if (SysInfo.userSpaceBitness == 32) {
          architecture = ProcessorArchitecture.X86;
        }

        break;
      case ProcessorArchitecture.ARM:
        break;
      default:
        return 0;
    }

    var platform = pathos.join("lib", "compiled", architecture.toString(), operatingSystem, filename);
    var repository = pathos.join(pubCache, "hosted", "pub.dartlang.org");
    var mask = pathos.join(repository, "libffi_binaries*");
    mask = _pathToPosix(mask);
    var paths = FileUtils.glob(mask);
    var versions = <Version, String>{};
    for (var path in paths) {
      var basename = pathos.basename(path);
      var versionString = basename.replaceFirst("libffi_binaries-", "");
      Version version;
      try {
        version = new Version.parse(versionString);
      } catch (e) {
        continue;
      }

      if (version.minor == LIBFFI_VERSION) {
        versions[version] = path;
      }
    }

    var keys = versions.keys.toList();
    keys.sort((a, b) => b.compareTo(a));
    for (var key in keys) {
      var path = versions[key];
      var binary = pathos.join(path, platform);
      if (FileUtils.testfile(binary, "exists")) {
        binary = pathos.normalize(binary);
        var handle = Unsafe.libraryLoad(binary);
        if (handle != 0) {
          return handle;
        }
      }
    }

    return 0;
  }

  static String _pathToPosix(String path) {
    if (Platform.isWindows) {
      return path.replaceAll("\\", "/");
    }

    return path;
  }

  static String _findPathToDartVM() {
    var executable = Platform.executable;
    var s = Platform.pathSeparator;
    if (!executable.contains(s)) {
      if (Platform.isLinux) {
        executable = new Link("/proc/$pid/exe").resolveSymbolicLinksSync();
      } else {
        return null;
      }
    }

    var file = new File(executable);
    if (file.existsSync()) {
      var parent = file.absolute.parent;
      parent = parent.parent;
      var path = parent.path;
      var dartAPI = "$path${s}include${s}dart_api.h";
      if (new File(dartAPI).existsSync()) {
        return path;
      }
    }

    return null;
  }
}
