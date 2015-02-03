part of binary_interop.foreign_function;

class ForeignFunction {
  static const String _TYPE_FFI_TYPE_ = "ffi_type";

  static Map<CallingConventions, FfiAbi> _ffiAbi = <CallingConventions, FfiAbi>{
    CallingConventions.DEFAULT: FfiAbi.DEFAULT,
    CallingConventions.FASTCALL: FfiAbi.FASTCALL,
    CallingConventions.CDECL: FfiAbi.MS_CDECL,
    CallingConventions.PASCAL: FfiAbi.PASCAL,
    CallingConventions.REGISTER: FfiAbi.REGISTER,
    CallingConventions.STDCALL: FfiAbi.STDCALL,
    CallingConventions.SYSV: FfiAbi.SYSV,
    CallingConventions.THISCALL: FfiAbi.THISCALL,
    CallingConventions.UNIX64: FfiAbi.UNIX64,
    CallingConventions.WIN64: FfiAbi.WIN64,
  };

  static final Map<BinaryKinds, FfiTypes> _binaryKind2FfiType = _createBinaryKind2FfiTypeMap();

  static final Map<FfiTypes, Map<int, BinaryObject>> _ffiType2BinaryObjects = new Map<FfiTypes, Map<int, BinaryObject>>();

  static Map<DataModel, BinaryTypes> _binaryTypesForModels = <DataModel, BinaryTypes>{};

  static Map<DataModel, BinaryTypes> _ffiTypesForModels = <DataModel, BinaryTypes>{};

  static Map<BinaryInterfaces, FfiInterfaces> _platforms = _getPlatforms();

  final int address;

  final BinaryInterfaces binaryInterface;

  final CallingConventions convention;

  final FunctionType functionType;

  final DataModel systemDataModel;

  int _abi;

  int _arity;

  _Context _context;

  DataModel _dataModel;

  _FfiBinaryTypes _ffiTypes;

  FfiInterfaces _interface;

  List<int> _listOfAlignsOfFfiTypes;

  List<BinaryObject> _listOfFfiTypes;

  int _recursion;

  BinaryType _returnType;

  bool _variadic;

  _Values _values;

  ForeignFunction(this.address, this.functionType, this.convention, this.binaryInterface, this.systemDataModel) {
    if (address == null || address == 0) {
      throw new ArgumentError("address: $address");
    }

    if (functionType == null) {
      throw new ArgumentError.notNull("functionType");
    }

    if (binaryInterface == null) {
      throw new ArgumentError.notNull("binaryInterface");
    }

    if (convention == null) {
      throw new ArgumentError.notNull("convention");
    }

    if (systemDataModel == null) {
      throw new ArgumentError.notNull("systemDataModel");
    }

    if (LibffiLibrary.current == null) {
      throw new StateError("To work 'foreign function' requires dynamic library 'libffi'.");
    }

    _interface = _platforms[binaryInterface];
    if (_interface == null) {
      throw new UnsupportedError("Unsupported application binary interface: $binaryInterface");
    }

    var ffiAbi = _ffiAbi[convention];
    if (ffiAbi == null) {
      throw new UnsupportedError("Unsupported calling convention: $convention");
    }

    _abi = FfitargetH.ffiAbi[_interface][ffiAbi];
    if (_abi == null) {
      throw new UnsupportedError("Unsupported calling convention: $convention");
    }

    _arity = functionType.arity;
    _dataModel = functionType.dataModel;
    _ffiTypes = _getFfiTypes(systemDataModel);
    _recursion = 0;
    _returnType = functionType.returnType;
    _variadic = functionType.variadic;
    _initialize();
  }

  dynamic invoke(List<dynamic> arguments, [List<BinaryType> vartypes]) {
    if (arguments == null) {
      arguments = const [];
    }

    if (vartypes == null) {
      vartypes = const <BinaryType>[];
    }

    var variableLength = vartypes.length;
    var totalLength = arguments.length;
    var fixedLength = totalLength - variableLength;
    if (fixedLength != _arity) {
      throw new ArgumentError("Wrong number of fixed arguments.");
    }

    var context = _context;
    var values = _values;
    if (_recursion++ != 0 || _variadic) {
      values = new _Values(functionType, _ffiTypes, vartypes);
      if (_variadic) {
        context = _buildContext(_context, vartypes);
      }
    }

    var data = values.data;
    var objects = values.objects;
    for (var i = 0; i < totalLength; i++) {
      var object = objects[i];
      var argument = arguments[i];
      object.value = arguments[i];
    }

    var returnValue = values.returnValue;
    LibffiLibrary.current.ffiCall(context.cif.address, address, returnValue.address, data.address);
    _recursion--;
    if (_returnType.size == 0) {
      return null;
    }

    return returnValue.value;
  }

  BinaryObject _allocFfiType(FfiTypes type, BinaryType binaryType, int align, List<BinaryObject> objects) {
    var data = _ffiTypes.ffi_type.alloc(const {});
    if (binaryType.kind == BinaryKinds.VOID) {
      data["alignment"].value = 1;
      data["size"].value = 1;
    } else {
      var size = binaryType.size;
      if (size == 0) {
        throw new ArgumentError("Unable allocate incomplete type '$binaryType'");
      }

      data["alignment"].value = align;
      data["size"].value = size;
    }

    var definedFfiType = FfiH.ffiType[_interface][type];
    if (definedFfiType == null) {
      _errorUnsupportedBinaryType(binaryType);
    }

    data["type"].value = definedFfiType;
    switch (type) {
      case FfiTypes.STRUCT:
        if (binaryType is StructType) {
          return _allocFfiTypeStruct(data, binaryType, objects);
        } else if (binaryType is UnionType) {
          return _allocFfiTypeUnion(data, binaryType, objects);
        } else {
          throw new UnsupportedError("Unsupported type '$binaryType'");
        }

        break;
      case FfiTypes.COMPLEX:
        _errorUnsupportedBinaryType(binaryType);
        break;
    }

    if (objects != null) {
      objects.add(data);
    }

    return data;
  }

  BinaryObject _allocFfiTypeStruct(BinaryObject data, StructType binaryType, List<BinaryObject> objects) {
    if (objects == null) {
      throw new ArgumentError.notNull("objects");
    }

    var storageUnits = binaryType.storageUnits.elements;
    var length = storageUnits.length;
    var elements = _ffiTypes.pffi_type.array(length + 1).alloc(const []);
    for (var i = 0; i < length; i++) {
      var storageUnit = storageUnits[i];
      var data = _getFfiTypeForBinaryType(storageUnit.type, storageUnit.align, objects);
      elements[i].value = data;
    }

    data["elements"].value = elements;
    objects.add(elements);
    return data;
  }

  BinaryObject _allocFfiTypeUnion(BinaryObject data, UnionType binaryType, List<BinaryObject> objects) {
    var storageUnits = binaryType.storageUnits.elements;
    StorageUnit storageUnit;
    for (var element in storageUnits) {
      if (storageUnit.size < element.size) {
        storageUnit = element;
      }
    }

    var elements = _ffiTypes.pffi_type.array(2).alloc(const []);
    elements[0].value = _getFfiTypeForBinaryType(storageUnit.type, storageUnit.align, objects);
    data["elements"].value = elements;
    objects.add(elements);
    return data;
  }

  _Context _buildContext(_Context previous, List<BinaryType> vartypes) {
    var context = new _Context();
    if (vartypes == null) {
      vartypes = const <BinaryType>[];
    }

    var variableLength = vartypes.length;
    var totalLength = _arity + variableLength;
    if (previous == null) {
      var fixedTypeObjects = <BinaryObject>[];
      var fixedTypes = <BinaryObject>[];
      var parameters = functionType.parameters;
      for (var i = 0; i < _arity; i++) {
        var parameter = parameters[i];
        var data = _getFfiTypeForBinaryType(parameter, parameter.align, fixedTypeObjects);
        fixedTypes.add(data);
      }

      var returnTypeAlign = 1;
      if (_returnType is! VoidType) {
        returnTypeAlign = _returnType.align;
      }

      context.rtype = _getFfiTypeForBinaryType(_returnType, returnTypeAlign, fixedTypeObjects);
      context.fixedTypeObjects = fixedTypeObjects;
      context.fixedTypes = fixedTypes;
    } else {
      context.fixedTypeObjects = previous.fixedTypeObjects;
      context.fixedTypes = previous.fixedTypes;
      context.rtype = previous.rtype;
    }

    if (variableLength != 0) {
      var variableTypeObjects = <BinaryObject>[];
      var variableTypes = <BinaryObject>[];
      for (var i = 0; i < variableLength; i++) {
        var parameter = vartypes[i];
        var ffiType = _getFfiTypeForBinaryType(parameter, parameter.align, variableTypeObjects);
        variableTypes.add(ffiType);
      }

      context.variableTypeObjects = variableTypeObjects;
      context.variableTypes = variableTypes;
    } else {
      context.variableTypeObjects = const <BinaryObject>[];
      context.variableTypes = const <BinaryObject>[];
    }

    context.cif = _ffiTypes.ffi_cif.alloc({});
    if (totalLength != 0) {
      context.atypes = _ffiTypes["void*"].array(totalLength).alloc();
    } else {
      context.atypes = _ffiTypes["void*"].nullObject();
    }

    var currentTypes = context.fixedTypes;
    for (var i = 0; i < _arity; i++) {
      context.atypes[i].value = currentTypes[i];
    }

    currentTypes = context.variableTypes;
    for (var i = 0; i < variableLength; i++) {
      context.atypes[_arity + i].value = currentTypes[i];
    }

    var libffi = LibffiLibrary.current;
    int status;
    if (!_variadic) {
      status = libffi.ffiPrepCif(context.cif.address, _abi, totalLength, context.rtype.address, context.atypes.address);
    } else {
      status = libffi.ffiPrepCifVar(context.cif.address, _abi, _arity, totalLength, context.rtype.address, context.atypes.address);
    }

    switch (status) {
      case FfiStatus.OK:
        break;
      case FfiStatus.BAD_ABI:
        throw new StateError("Error preparing calling interface: Bad calling convention.");
      case FfiStatus.BAD_TYPEDEF:
        throw new StateError("Error preparing calling interface: Bad typedef.");
      default:
        throw new StateError("Unknown ffi_status: $status");
    }

    return context;
  }

  void _errorUnsupportedBinaryType(BinaryType type) {
    throw new UnsupportedError("Unsupported binary type: '$type'");
  }

  BinaryTypes _getBinaryTypes(DataModel dataModel) {
    var types = _binaryTypesForModels[dataModel];
    if (types == null) {
      types = new BinaryTypes(dataModel: dataModel);
      _binaryTypesForModels[dataModel] = types;
    }

    return types;
  }

  BinaryObject _getFfiTypeForBinaryType(BinaryType type, int align, List<BinaryObject> objects) {
    var kind = type.kind;
    var ffiType = _binaryKind2FfiType[type.kind];
    if (ffiType == null) {
      _errorUnsupportedBinaryType(type);
    }

    var alignments = _ffiType2BinaryObjects[ffiType];
    if (alignments == null) {
      alignments = <int, BinaryObject>{};
      _ffiType2BinaryObjects[ffiType] = alignments;
    }

    var object = alignments[align];
    if (object == null) {
      object = _allocFfiType(ffiType, type, align, objects);
      switch (kind) {
        case BinaryKinds.STRUCT:
          break;
        default:
          alignments[align] = object;
          break;
      }
    }

    return object;
  }

  _FfiBinaryTypes _getFfiTypes(DataModel dataModel) {
    var types = _ffiTypesForModels[dataModel];
    if (types != null) {
      return types;
    }

    types = new _FfiBinaryTypes(dataModel);
    _ffiTypesForModels[dataModel] = types;
    return types;
  }

  void _initialize() {
    _context = _buildContext(null, null);
    if (!_variadic) {
      _values = new _Values(functionType, _ffiTypes);
    }
  }

  static Map<BinaryKinds, FfiTypes> _createBinaryKind2FfiTypeMap() {
    var result = <BinaryKinds, FfiTypes>{};
    result[BinaryKinds.DOUBLE] = FfiTypes.DOUBLE;
    result[BinaryKinds.FLOAT] = FfiTypes.FLOAT;
    result[BinaryKinds.POINTER] = FfiTypes.POINTER;
    result[BinaryKinds.SINT16] = FfiTypes.SINT16;
    result[BinaryKinds.SINT32] = FfiTypes.SINT32;
    result[BinaryKinds.SINT64] = FfiTypes.SINT64;
    result[BinaryKinds.SINT8] = FfiTypes.SINT8;
    result[BinaryKinds.STRUCT] = FfiTypes.STRUCT;
    result[BinaryKinds.UINT16] = FfiTypes.UINT16;
    result[BinaryKinds.UINT32] = FfiTypes.UINT32;
    result[BinaryKinds.UINT64] = FfiTypes.UINT64;
    result[BinaryKinds.UINT8] = FfiTypes.UINT8;
    result[BinaryKinds.VOID] = FfiTypes.VOID;
    return result;
  }

  static Map<BinaryInterfaces, FfiInterfaces> _getPlatforms() {
    var result = <BinaryInterfaces, FfiInterfaces>{};
    result[BinaryInterfaces.X86_64_UNIX] = FfiInterfaces.X86_64_UNIX;
    result[BinaryInterfaces.X86_64_WINDOWS] = FfiInterfaces.X86_64_WINDOWS;
    result[BinaryInterfaces.X86_UNIX] = FfiInterfaces.X86_UNIX;
    result[BinaryInterfaces.X86_WINDOWS] = FfiInterfaces.X86_WINDOWS;
    result[BinaryInterfaces.X86_WINDOWS_GNU] = FfiInterfaces.X86_WINDOWS_GNU;
    for (var platform in FfiInterfaces.values) {
      if (!result.containsValue(platform)) {
        throw new StateError("Mising platform '$platform'.");
      }
    }

    return result;
  }
}

class _Context {
  BinaryObject atypes;

  BinaryObject cif;

  List<BinaryObject> fixedTypeObjects;

  List<BinaryObject> fixedTypes;

  BinaryObject rtype;

  List<BinaryObject> types;

  List<BinaryObject> variableTypes;

  List<BinaryObject> variableTypeObjects;
}

class _FfiBinaryTypes extends BinaryTypes {
  static const String _ffi_header = '''
typedef int ffi_abi;

typedef struct _ffi_type {
  size_t size;
  unsigned short alignment;
  unsigned short type;
  struct _ffi_type **elements;
} ffi_type;

typedef struct {
  ffi_abi abi;
  unsigned int nargs;
  ffi_type **arg_types;
  ffi_type *rtype;
  unsigned int bytes;
  unsigned int flags;
#if defined(FFI_EXTRA_CIF_FIELDS_MIPS)
  unsigned int rstruct_flag;
#elif defined(FFI_EXTRA_CIF_FIELDS_ARM)
  int vfp_used;
  short vfp_reg_free;
  short vfp_nargs;
  signed char vfp_args[16];
#endif
} ffi_cif;
''';

  _FfiBinaryTypes(DataModel dataModel) : super(dataModel: dataModel) {
    var environment = <String, String>{};
    var helper = new BinaryTypeHelper(this);
    var architecture = SysInfo.processors.first.architecture;
    switch (architecture) {
      case ProcessorArchitecture.X86:
      case ProcessorArchitecture.X86_64:
        break;
      case ProcessorArchitecture.MIPS:
        environment["FFI_EXTRA_CIF_FIELDS_MIPS"] = "";
        break;
      case ProcessorArchitecture.ARM:
        environment["FFI_EXTRA_CIF_FIELDS_ARM"] = "";
        break;
      //case ProcessorArchitecture.ARM64:
      //  break;
      default:
        throw new UnsupportedError("Unsupported processor architecture: $architecture");
    }

    helper.declare(_ffi_header, environment: environment);
  }

  BinaryType get ffi_cif => this["ffi_cif"];

  BinaryType get ffi_type => this["ffi_type"];

  BinaryType get pffi_type => this["ffi_type*"];
}

class _Values {
  BinaryObject data;

  List<BinaryObject> objects;

  BinaryObject returnValue;

  _Values(FunctionType functionType, BinaryTypes systemTypes, [List<BinaryType> vartypes]) {
    if (functionType == null) {
      throw new ArgumentError.notNull("functionType");
    }

    if (systemTypes == null) {
      throw new ArgumentError.notNull("systemTypes");
    }

    if (vartypes == null) {
      vartypes = const <BinaryType>[];
    }

    var fixedParameters = functionType.parameters;
    var fixedLength = functionType.arity;
    var variableLength = vartypes.length;
    var totalLength = fixedLength + variableLength;
    if (totalLength != 0) {
      data = systemTypes["void*"].array(totalLength).alloc();
    } else {
      data = systemTypes["void*"].nullObject();
    }

    objects = new List<BinaryObject>(totalLength);
    for (var i = 0; i < fixedLength; i++) {
      var object = fixedParameters[i].alloc();
      objects[i] = object;
      data[i].value = object;
    }

    for (var i = 0,
        k = fixedLength; i < variableLength; i++, k++) {
      var object = vartypes[i].alloc();
      objects[k] = object;
      data[k].value = object;
    }

    var returnType = functionType.returnType;
    if (returnType.size != 0) {
      returnValue = functionType.returnType.alloc();
    } else {
      returnValue = functionType.returnType.nullObject();
    }
  }
}
