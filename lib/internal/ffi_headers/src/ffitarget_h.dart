part of binary_interop.internal.ffi_headers;

class FfiAbi {
  static const FfiAbi DEFAULT = const FfiAbi("DEFAULT");

  static const FfiAbi FASTCALL = const FfiAbi("FASTCALL");

  static const FfiAbi MS_CDECL = const FfiAbi("MS_CDECL");

  static const FfiAbi PASCAL = const FfiAbi("PASCAL");

  static const FfiAbi REGISTER = const FfiAbi("REGISTER");

  static const FfiAbi STDCALL = const FfiAbi("STDCALL");

  static const FfiAbi SYSV = const FfiAbi("SYSVCALL");

  static const FfiAbi THISCALL = const FfiAbi("THISCALL");

  static const FfiAbi UNIX64 = const FfiAbi("UNIX64");

  static const FfiAbi WIN64 = const FfiAbi("WIN64");

  final String _name;

  const FfiAbi(this._name);

  String toString() => _name;
}

class FfitargetH {
  static final Map<FfiInterfaces, Map<FfiAbi, int>> ffiAbi = _generateAbi();

  static Map<FfiAbi, int> _buildAbi(List<FfiAbi> conventions, FfiAbi defaultConvention) {
    var map = <FfiAbi, int>{};
    var length = conventions.length;
    for (var i = 0; i < length; i++) {
      var convention = conventions[i];
      map[convention] = i + 1;
    }

    var abi = map[defaultConvention];
    if (abi == null) {
      throw new ArgumentError("Default convention '$defaultConvention' not found in list of conventions.");
    }

    map[FfiAbi.DEFAULT] = abi;
    return new UnmodifiableMapView<FfiAbi, int>(map);
  }

  static Map<FfiInterfaces, Map<FfiAbi, int>> _generateAbi() {
    var result = <FfiInterfaces, Map<FfiAbi, int>>{};
    // X86 windows
    var conventions = <FfiAbi>[];
    conventions.add(FfiAbi.SYSV);
    conventions.add(FfiAbi.STDCALL);
    conventions.add(FfiAbi.THISCALL);
    conventions.add(FfiAbi.FASTCALL);
    conventions.add(FfiAbi.MS_CDECL);
    conventions.add(FfiAbi.PASCAL);
    conventions.add(FfiAbi.REGISTER);
    result[FfiInterfaces.X86_WINDOWS] = _buildAbi(conventions, FfiAbi.MS_CDECL);
    // Special case
    result[FfiInterfaces.X86_WINDOWS_GNU] = _buildAbi(conventions, FfiAbi.SYSV);
    // X86_64 windows
    conventions.clear();
    conventions.add(FfiAbi.WIN64);
    result[FfiInterfaces.X86_64_WINDOWS] = _buildAbi(conventions, FfiAbi.WIN64);
    // X86 Unix
    conventions.clear();
    conventions.add(FfiAbi.SYSV);
    conventions.add(FfiAbi.UNIX64);
    conventions.add(FfiAbi.THISCALL);
    conventions.add(FfiAbi.FASTCALL);
    conventions.add(FfiAbi.STDCALL);
    conventions.add(FfiAbi.PASCAL);
    conventions.add(FfiAbi.REGISTER);
    result[FfiInterfaces.X86_UNIX] = _buildAbi(conventions, FfiAbi.SYSV);
    // X86_64 Unix
    result[FfiInterfaces.X86_64_UNIX] = _buildAbi(conventions, FfiAbi.UNIX64);
    // Check filling interfaces
    _Utils.checkFillingInterfaces(result);
    return new UnmodifiableMapView<FfiInterfaces, Map<FfiAbi, int>>(result);
  }
}
