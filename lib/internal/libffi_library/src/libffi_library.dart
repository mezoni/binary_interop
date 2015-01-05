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
    ForeignFucntionInterface.call(_ffiCall, cif, fn, rvalue, avalue);
    return;
  }

  int ffiPrepCif(int cif, int abi, int nargs, int rtype, int atypes) {
    return ForeignFucntionInterface.prepareCallInterface(_ffiPrepCif, cif, abi, nargs, rtype, atypes);
  }

  int ffiPrepCifVar(int cif, int abi, int nfixedargs, int ntotalargs, int rtype, int atypes) {
    return ForeignFucntionInterface.prepareCallInterfaceVariadic(_ffiPrepCifVar, cif, abi, nfixedargs, ntotalargs, rtype, atypes);
  }

  int _import(String symbol) {
    var address = Unsafe.librarySymbol(_handle, symbol);
    if (address == null) {
      throw new ArgumentError("Symbol '$symbol' not found in '$filename'");
    }

    return address;
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

    var handle = _loadFromLibffiBinaries(filename);
    if (handle == 0) {
      //handle = Unsafe.libraryLoad(filename);
    }

    if (handle == 0) {
      return null;
    }

    return new LibffiLibrary(handle, filename);
  }

  static int _loadFromLibffiBinaries(String filename) {
    var operatingSystem = Platform.operatingSystem;
    var pubCache = Platform.environment["PUB_CACHE"];
    if (pubCache == null) {
      switch (operatingSystem) {
        case "android":
        case "linux":
        case "macos":
          pubCache = pathos.join(SysInfo.userDirectory, ".pub-cache");
          break;
        case "windows":
          pubCache = pathos.join(SysInfo.userDirectory, "AppData", "Roaming", "Pub", "Cache");
          break;
        default:
          return 0;
      }
    }

    var architecture = SysInfo.processors.first.architecture;
    switch (architecture) {
      case ProcessorArchitecture.X86:
        break;
      case ProcessorArchitecture.X86_64:
        if (SysInfo.userSpaceBitness == 32) {
          architecture = ProcessorArchitecture.X86;
        }

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
}
