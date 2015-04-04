part of binary_interop.dynamic_library;

/**
 * Dynamic library is dynamically loadable library.
 */
class DynamicLibrary {
  static Map<DataModel, _BasicTypes> _basicTypesCache = <DataModel, _BasicTypes>{};

  static final DataModel _systemDataModel = new DataModel();

  static final BinaryInterfaces _systemInterface = _getSystemInterface();

  /**
   * Application binary interface.
   */
  final BinaryInterfaces binaryInterface;

  /**
   * Name of the file.
   */
  final String filename;

  CallingConventions _convention;

  _BasicTypes _basicTypes;

  DataModel _dataModel;

  Map<String, _FunctionInfo> _declaredFunctions = <String, _FunctionInfo>{};

  int _handle;

  Map<String, ForeignFunction> _functions = <String, ForeignFunction>{};

  bool _lazy;

  BinaryTypes _types;

  DynamicLibrary._internal(int handle, this.filename, this.binaryInterface,
      {CallingConventions convention, bool lazy, BinaryTypes types}) {
    if (handle == null) {
      throw new ArgumentError.notNull("handle");
    }

    if (filename == null) {
      throw new ArgumentError.notNull("filename");
    }

    if (binaryInterface == null) {
      throw new ArgumentError.notNull("binaryInterface");
    }

    if (lazy == null) {
      throw new ArgumentError.notNull("lazy");
    }

    _convention = convention;
    _lazy = lazy;
    _handle = handle;
    _types = types;

    if (types != null) {
      _setDataModel(types["int"].dataModel);
    }
  }

  /**
   * Handle.
   */
  int get handle => _handle;

  /**
   * Returns binary types.
   */
  BinaryTypes get types => _types;

  /**
   * Sets binary types.
   */
  void set types(BinaryTypes types) {
    if (types == null) {
      throw new ArgumentError.notNull("types");
    }

    if (_types != null) {
      throw new StateError("Unable repeatedly set binary types");
    }

    _types = types;
    _setDataModel(types["int"].dataModel);
  }

  /**
   * Links to the function prototypes declared in specified header files.
   * Does not declare anything. The header files should be declared before the linkage.
   *
   * Parameters:
   *   [List<String>] headers
   *   A list of names of header files.
   */
  void link(Iterable<String> headers) {
    if (headers == null) {
      throw new ArgumentError.notNull("headers");
    }

    var files = new Set<String>();
    for (var header in headers) {
      if (header == null) {
        throw new ArgumentError("List of the headers contains an invalid elements");
      }

      files.add(header);
    }

    if (types == null) {
      _errorTypesNotDefined();
    }

    var helper = new BinaryTypeHelper(types);
    var prototypes = helper.prototypes;
    for (var name in prototypes.keys) {
      var prototype = prototypes[name];
      var filename = prototype.filename;
      if (files.contains(filename)) {
        var alias = prototype.alias;
        var type = prototype.type;
        // TODO: Add support of individual calling convention
        function(name, type.returnType, type.parameters,
            alias: alias, convention: _convention, variadic: type.variadic);
      }
    }
  }

  /**
   * Frees this dynamic library.
   *
   * Parameters:
   */
  void free() {
    if (_handle == null) {
      _errorLibraryNotLoaded();
    }

    Unsafe.libraryFree(_handle);
    _handle = null;
  }

  /**
     * Imports and creates a foreign function with given name and stores it in
     * the function table for further use.
     *
     * Parameters:
     *   [String] name
     *   Function name.
     *
     *   [BinaryType] returnType
     *   Binary type of the return value.
     *
     *   [List]<[BinaryType]> parameters
     *   Binary types of the parameters.
     *
     *   [String] alias
     *   Real name of the foreign function.
     *
     *   [bool] variadic
     *   Indicates that the function can accept a variable number of arguments.
     *
     *   [CallingConventions] convention
     *   Calling convention.
     */
  void function(String name, BinaryType returnType, List<BinaryType> parameters,
      {String alias, CallingConventions convention, bool variadic: false}) {
    if (name == null) {
      throw new ArgumentError.notNull("name");
    }

    if (returnType == null) {
      throw new ArgumentError.notNull("returnType");
    }

    if (parameters == null) {
      throw new ArgumentError.notNull("parameters");
    }

    if (variadic == null) {
      throw new ArgumentError.notNull("variadic");
    }

    if (convention == null) {
      convention = _convention;
      if (convention == null) {
        convention = CallingConventions.DEFAULT;
      }
    }

    if (alias == null) {
      alias = name;
    }

    if (_handle == null) {
      _errorLibraryNotLoaded();
    }

    var dataModel = returnType.dataModel;
    for (var parameter in parameters) {
      if (parameter is! BinaryType) {
        throw new ArgumentError("List of parameters contains invalid elements.");
      }
    }

    var functionType = new FunctionType(name, returnType, parameters, variadic, dataModel);
    var address = Unsafe.librarySymbol(handle, alias);
    if (address == 0) {
      throw new ArgumentError("Symbol '$alias' not found.");
    }

    if (_lazy) {
      _declaredFunctions[name] = new _FunctionInfo(address, functionType, convention);
    } else {
      _functions[name] = new ForeignFunction(address, functionType, convention, binaryInterface, _systemDataModel);
    }
  }

  /**
   * Executes a specific function and returns the result with type promotions.
   *
   * Limitation of "va_arg" (only) type promotion:
   * - Integer values are always promoted only to "int" binary type ("long"
   *   type and type with greater size is not supported).
   * - Binary types with a non-default alignment is not supported.
   *
   * For the above described cases, when using "va_arg" arguments, use method
   * [invoke] instead.
   *
   * Parameters:
   *   [String] name
   *   Function name.
   *
   *   [List] arguments
   *   Function araguments.
   */
  dynamic invoke(String name, [List arguments]) {
    if (_handle == null) {
      _errorLibraryNotLoaded();
    }

    var function = _functions[name];
    if (function == null) {
      function = _compile(name);
    }

    var functionType = function.functionType;
    var dataModel = functionType.dataModel;
    var parameters = functionType.parameters;
    var fixedLength = functionType.arity;
    var totalLength = arguments.length;
    var variableLength = totalLength - fixedLength;
    if (totalLength < fixedLength) {
      throw new ArgumentError("Wrong number of arguments.");
    }

    _BasicTypes basicTypes;
    if (_dataModel == dataModel) {
      basicTypes = _basicTypes;
    } else {
      basicTypes = _basicTypesCache[dataModel];
      if (basicTypes == null) {
        basicTypes = new _BasicTypes(dataModel);
        _basicTypesCache[dataModel] = basicTypes;
      }
    }

    List<BinaryType> vartypes;
    if (variableLength != 0) {
      vartypes = new List<BinaryType>(variableLength);
    }

    List buffers;
    var newArguments = new List(totalLength);
    List<BinaryObject> strings;
    for (var i = 0; i < totalLength; i++) {
      var argument = arguments[i];
      if (i >= fixedLength) {
        if (argument is int) {
          vartypes[i - fixedLength] = basicTypes.intType;
        } else if (argument is String) {
          if (strings == null) {
            strings = <BinaryObject>[];
          }

          var string = basicTypes.charType.array(argument.length + 1).alloc(argument.codeUnits);
          strings.add(string);
          argument = string;
          vartypes[i - fixedLength] = basicTypes.charPointerType;
        } else if (argument is double) {
          vartypes[i - fixedLength] = basicTypes.doubleType;
        } else if (argument is bool) {
          vartypes[i - fixedLength] = basicTypes.boolType;
        } else if (argument is BinaryData) {
          vartypes[i - fixedLength] = new PointerType(argument.type, dataModel);
        } else {
          throw new ArgumentError("Unable to convert variable argument $i: $argument");
        }

        newArguments[i] = argument;
      } else {
        var parameter = parameters[i];
        if (argument is String) {
          if (parameter is PointerType) {
            var valueType = parameter.type;
            if (valueType.kind == basicTypes.charType.kind) {
              if (strings == null) {
                strings = <BinaryObject>[];
              }

              var string = valueType.array(argument.length + 1).alloc(argument.codeUnits);
              strings.add(string);
              newArguments[i] = string;
            } else {
              _errorUnableToConvert("'String'", i, parameter);
            }
          }
        } else if (argument is List) {
          if (parameter is PointerType) {
            var valueType = parameter.type;
            if (buffers == null) {
              buffers = [];
            }

            var length = argument.length;
            if (length == 0) {
              _errorUnableToConvert("an empty 'List'", i, parameter);
            }

            var array = valueType.array(length).alloc(const []);
            buffers.add([argument, array]);
            newArguments[i] = array;
          } else {
            _errorUnableToConvert("'List'", i, parameter);
          }
        } else if (argument == null) {
          _errorUnableToConvert("null", i, parameter);
        } else {
          newArguments[i] = argument;
        }
      }
    }

    var result = function.invoke(newArguments, vartypes);
    if (buffers != null) {
      var count = buffers.length;
      for (var i = 0; i < count; i++) {
        List buffer = buffers[i];
        List list = buffer[0];
        BinaryData array = buffer[1];
        var length = list.length;
        List value = array.value;
        for (var j = 0; j < length; j++) {
          list[j] = value[j];
        }
      }
    }

    return result;
  }

  /**
   * Executes a specific function and returns the result.
   *
   * Parameters:
   *   [String] name
   *   Function name.
   *
   *   [List] arguments
   *   Function araguments.
   *
   *   [List]<[BinaryType]> vartypes
   *   Types of variadic arguments.
   */
  dynamic invokeEx(String name, [List arguments, List<BinaryType> vartypes]) {
    if (_handle == null) {
      _errorLibraryNotLoaded();
    }

    var function = _functions[name];
    if (function == null) {
      function = _compile(name);
    }

    return function.invoke(arguments, vartypes);
  }

  /**
   * Returns the address of the symbol.
   *
   * Parameters:
   *   [String] name
   *   Name to get the address.
   */
  int symbol(String name) {
    if (symbol == null) {
      throw new ArgumentError.notNull("name");
    }

    if (_handle == null) {
      _errorLibraryNotLoaded();
    }

    return Unsafe.librarySymbol(handle, name);
  }

  /**
   * Return the string representation.
   *
   * Parameters:
   */
  String toString() => filename;

  ForeignFunction _compile(String name) {
    ForeignFunction function;
    if (_lazy) {
      var info = _declaredFunctions[name];
      if (info != null) {
        function =
            new ForeignFunction(info.address, info.functionType, info.convention, binaryInterface, _systemDataModel);
        _functions[name] = function;
        _declaredFunctions[name] = null;
      }
    }

    if (function == null) {
      throw new ArgumentError("Function '$name' not found.");
    }

    return function;
  }

  void _errorLibraryNotLoaded() {
    throw new StateError("Library '$filename' not loaded");
  }

  void _errorTypesNotDefined() {
    throw new StateError("Binary types are not defined for '$filename'");
  }

  void _errorUnableToConvert(String subject, int index, BinaryType binaryType) {
    throw new ArgumentError("Unable to convert $subject for parameter $index ($binaryType)");
  }

  String _getAliasAttribute(List<DeclarationSpecifiers> specifiers) {
    var aliases = [];
    for (var specifier in specifiers) {
      if (specifier != null) {
        var reader = new AttributeReader([specifier]);
        var alias = reader.getArgument("alias", 0, null, minLength: 1, maxLength: 1);
        if (alias is Identifier) {
          aliases.add(alias.name);
        }
      }
    }

    if (aliases.length > 1) {
      throw new StateError("Multiple aliases are not allowed");
    }

    if (aliases.length == 0) {
      return null;
    }

    return aliases.first;
  }

  void _setDataModel(DataModel dataModel) {
    _dataModel = dataModel;
    _basicTypes = new _BasicTypes(dataModel);
  }

  /**
   * Loads and returns the dynamic library.
   *
   * Parameters:
   *   [String] filename
   *   Path to the dynamic library.
   *
   *   [BinaryInterfaces] abi
   *   Binary interface
   *
   *   [BinaryTypes] types
   *   Binary types
   */
  static DynamicLibrary load(String filename,
      {BinaryInterfaces abi, CallingConventions convention, bool lazy: true, BinaryTypes types}) {
    if (filename == null) {
      throw new ArgumentError.notNull("filename");
    }

    var handle = Unsafe.libraryLoad(filename);
    if (handle == 0) {
      return null;
    }

    if (abi == null) {
      abi = _systemInterface;
    }

    if (abi == null) {
      throw new UnsupportedError("Unsupported binary interface: $abi");
    }

    if (lazy == null) {
      throw new ArgumentError.notNull("lazy");
    }

    return new DynamicLibrary._internal(handle, filename, abi, convention: convention, lazy: lazy, types: types);
  }

  static BinaryInterfaces _getSystemInterface() {
    var operatingSystem = Platform.operatingSystem;
    var userSpaceBitness = SysInfo.userSpaceBitness;
    switch (SysInfo.processors.first.architecture) {
      case ProcessorArchitecture.ARM:
        switch (operatingSystem) {
          case "android":
            return BinaryInterfaces.ARM_ANDROID;
          case "linux":
            return BinaryInterfaces.ARM_UNIX;
        }

        break;
      case ProcessorArchitecture.X86:
        switch (operatingSystem) {
          case "android":
          case "linux":
          case "macos":
            return BinaryInterfaces.X86_UNIX;
          case "windows":
            return BinaryInterfaces.X86_WINDOWS;
        }

        break;
      case ProcessorArchitecture.X86_64:
        switch (operatingSystem) {
          case "android":
          case "linux":
          case "macos":
            switch (userSpaceBitness) {
              case 32:
                return BinaryInterfaces.X86_UNIX;
              case 64:
                return BinaryInterfaces.X86_64_UNIX;
            }

            break;
          case "windows":
            switch (userSpaceBitness) {
              case 32:
                return BinaryInterfaces.X86_WINDOWS;
              case 64:
                return BinaryInterfaces.X86_64_WINDOWS;
            }

            break;
        }

        break;
    }

    return null;
  }
}

class _FunctionInfo {
  final int address;

  final CallingConventions convention;

  final FunctionType functionType;

  _FunctionInfo(this.address, this.functionType, this.convention);
}
