part of binary_interop.internal.ffi_headers;

class FfiH {
  static final Map<FfiInterfaces, Map<FfiTypes, int>> ffiType = _generateTypes();

  static Map<FfiInterfaces, Map<FfiTypes, int>> _generateTypes() {
    var result = <FfiInterfaces, Map<FfiTypes, int>>{};
    var map = <FfiTypes, int>{};
    map[FfiTypes.VOID] = 0;
    map[FfiTypes.INT] = 1;
    map[FfiTypes.FLOAT] = 2;
    map[FfiTypes.DOUBLE] = 3;
    map[FfiTypes.LONGDOUBLE] = map[FfiTypes.DOUBLE];
    map[FfiTypes.UINT8] = 5;
    map[FfiTypes.SINT8] = 6;
    map[FfiTypes.UINT16] = 7;
    map[FfiTypes.SINT16] = 8;
    map[FfiTypes.UINT32] = 9;
    map[FfiTypes.SINT32] = 10;
    map[FfiTypes.UINT64] = 11;
    map[FfiTypes.SINT64] = 12;
    map[FfiTypes.STRUCT] = 13;
    map[FfiTypes.POINTER] = 14;
    map[FfiTypes.COMPLEX] = 15;
    for (var key in FfiInterfaces.values) {
      result[key] = map;
    }

    _Utils.checkFillingInterfaces(result);
    return result;
  }
}

class FfiStatus {
  static const int OK = 0;

  static const int BAD_TYPEDEF = 1;

  static const int BAD_ABI = 2;
}

class FfiTypes {
  static const FfiTypes COMPLEX = const FfiTypes("COMPLEX");

  static const FfiTypes DOUBLE = const FfiTypes("DOUBLE");

  static const FfiTypes FLOAT = const FfiTypes("FLOAT");

  static const FfiTypes INT = const FfiTypes("INT");

  static const FfiTypes LONGDOUBLE = const FfiTypes("LONGDOUBLE");

  static const FfiTypes POINTER = const FfiTypes("POINTER");

  static const FfiTypes SINT16 = const FfiTypes("SINT16");

  static const FfiTypes SINT32 = const FfiTypes("SINT32");

  static const FfiTypes SINT64 = const FfiTypes("SINT64");

  static const FfiTypes SINT8 = const FfiTypes("SINT8");

  static const FfiTypes STRUCT = const FfiTypes("STRUCT");

  static const FfiTypes UINT16 = const FfiTypes("UINT16");

  static const FfiTypes UINT32 = const FfiTypes("UINT32");

  static const FfiTypes UINT64 = const FfiTypes("UINT64");

  static const FfiTypes UINT8 = const FfiTypes("UINT8");

  static const FfiTypes VOID = const FfiTypes("VOID");

  final String _name;

  const FfiTypes(this._name);

  String toString() => _name;
}
