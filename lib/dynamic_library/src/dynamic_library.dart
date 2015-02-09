part of binary_interop.dynamic_library;

/**
 * Dynamic library is dynamically loadable library.
 */
class DynamicLibrary {
  /**
   * System data model.
   */
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

  bool _lazy;

  CallingConventions _convention;

  int _handle;

  Map<String, _FunctionInfo> _declaredFunctions = <String, _FunctionInfo>{};

  Map<String, ForeignFunction> _functions = <String, ForeignFunction>{};

  BinaryTypes _types;

  DynamicLibrary._internal(int handle, this.filename, this.binaryInterface, {CallingConventions convention, bool lazy, BinaryTypes types}) {
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
   * Declares the functions and binary types in textual format.
   *
   * Parameters:
   *   [String] text
   *   Declarations in textual format.
   *
   *   [Map]<[String], [String]> environment
   *   Environment values for preprocessing declarations.
   */
  void declare(String text, {CallingConventions convention, Map<String, String> environment}) {
    if (text == null) {
      throw new ArgumentError.notNull("text");
    }

    if (types == null) {
      _errorTypesNotDefined();
    }

    if (convention == null) {
      if (_convention != null) {
        convention = _convention;
      }
    }

    var helper = new BinaryTypeHelper(types);
    var declarations = helper.declare(text, environment: environment);
    Declaration declaration;
    try {
      for (declaration in declarations) {
        if (declaration is FunctionDeclaration) {
          var name = declaration.identifier.name;
          var returnType = types[declaration.returnType.name];
          var parameters = <dynamic>[];
          var metadata = new _Metadata([declaration.parameters.metadata]);
          for (var paramater in declaration.parameters.parameters) {
            var name = paramater.type.name;
            parameters.add(types[paramater.type.name]);
          }

          var alias = metadata.alias;
          if (alias is String) {
            alias = alias.trim();
          }

          function(name, returnType, parameters, alias: alias, convention: convention);
        }
      }
    } catch (e, s) {
      throw new StateError("Declaration '$declaration' has error: $e\n$s");
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
     *   [CallingConventions] convention
     *   Calling convention.
     */
  void function(String name, BinaryType returnType, List<BinaryType> parameters, {String alias, CallingConventions convention}) {
    if (name == null) {
      throw new ArgumentError.notNull("name");
    }

    if (returnType == null) {
      throw new ArgumentError.notNull("returnType");
    }

    if (parameters == null) {
      throw new ArgumentError.notNull("parameters");
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

    var functionType = new FunctionType(name, returnType, parameters, dataModel);
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

    BinaryType charType;
    BinaryType charPointerType;
    BinaryType doubleType;
    BinaryType intType;
    List<BinaryType> vartypes;
    if (variableLength != 0) {
      vartypes = new List<BinaryType>(variableLength);
    }

    var newArguments = new List(totalLength);
    List<BinaryObject> strings;
    for (var i = 0; i < totalLength; i++) {
      var argument = arguments[i];
      if (i >= fixedLength) {
        if (argument is int) {
          if (intType == null) {
            intType = IntType.create(dataModel.sizeOfInt, true, dataModel);
          }

          vartypes[i - fixedLength] = intType;
        } else if (argument is String) {
          if (strings == null) {
            strings = <BinaryObject>[];
          }

          if (charType == null) {
            charType = IntType.create(dataModel.sizeOfChar, dataModel.isCharSigned, dataModel);
          }

          if (charPointerType == null) {
            charPointerType = charType.ptr();
          }

          var string = charType.array(argument.length + 1).alloc(argument.codeUnits);
          strings.add(string);
          argument = string;
          vartypes[i - fixedLength] = charPointerType;
        } else if (argument is double) {
          if (doubleType == null) {
            doubleType = new DoubleType(dataModel);
          }

          vartypes[i - fixedLength] = doubleType;
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
            if (charType == null) {
              charType = IntType.create(dataModel.sizeOfChar, dataModel.isCharSigned, dataModel);
            }

            if (valueType.kind == charType.kind) {
              if (strings == null) {
                strings = <BinaryObject>[];
              }

              var string = valueType.array(argument.length + 1).alloc(argument.codeUnits);
              strings.add(string);
              newArguments[i] = string;
            } else {
              throw new ArgumentError("Unable to allocate string object for parameter $i: $parameter");
            }
          }

        } else if (argument == null) {
          throw new UnimplementedError("Promoting NULL values not implemented yet");
        } else {
          newArguments[i] = argument;
        }
      }
    }

    return function.invoke(newArguments, vartypes);
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
        function = new ForeignFunction(info.address, info.functionType, info.convention, binaryInterface, _systemDataModel);
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

  void _errorUnableToParse(String declration, [int position]) {
    var atPosition = "";
    if (position != null) {
      atPosition = " at position $position";
    }

    throw new StateError("Unable to parse declaration '$deprecated'$atPosition");
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
  static DynamicLibrary load(String filename, {BinaryInterfaces abi, CallingConventions convention, bool lazy: true, BinaryTypes types}) {
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

class _CharTypeInfo {
  BinaryType charType;

  BinaryKinds charTypeKind;

  _CharTypeInfo(DataModel dataModel) {
    if (dataModel == null) {
      throw new ArgumentError.notNull("dataModel");
    }

    charType = IntType.create(dataModel.sizeOfChar, dataModel.isCharSigned, dataModel);
  }
}

class _FunctionInfo {
  final int address;

  final CallingConventions convention;

  final FunctionType functionType;

  _FunctionInfo(this.address, this.functionType, this.convention);
}
