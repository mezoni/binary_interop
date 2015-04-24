part of binary_interop.binary_callback;

/**
 * Binary callback is executable code that is passed as an argument to other code, which is expected to call back.
 */
class BinaryCallback {
  static final DataModel _systemDataModel = new DataModel();

  static final BinaryInterface _systemInterface = BinaryInteropHelper.getSystemInterface();

  ForeignClosure _closure;

  BinaryCallback.binary(FunctionType functionType, void callback(List<BinaryData> arguments, BinaryData returns),
      {BinaryInterface abi, CallingConvention callingConvention})
      : this._internal(functionType, callback, true, abi: abi, callingConvention: callingConvention);

  BinaryCallback(FunctionType functionType, dynamic callback(List arguments),
      {BinaryInterface abi, CallingConvention callingConvention})
      : this._internal(functionType, callback, false, abi: abi, callingConvention: callingConvention);

  BinaryCallback._internal(FunctionType functionType, Function callback, bool binary,
      {BinaryInterface abi, CallingConvention callingConvention}) {
    if (functionType == null) {
      throw new ArgumentError.notNull("functionType");
    }

    if (binary == null) {
      throw new ArgumentError.notNull("binary");
    }

    if (abi == null) {
      abi = _systemInterface;
    }

    if (callingConvention == null) {
      callingConvention = CallingConvention.DEFAULT;
    }

    var convention = BinaryInteropHelper.callingConventionToAbi[callingConvention];
    var platform = BinaryInteropHelper.binaryInterfaceToPlatform[abi];
    if (binary) {
      _closure = new ForeignClosure.binary(functionType, convention, platform, _systemDataModel, callback);
    } else {
      _closure = new ForeignClosure(functionType, convention, platform, _systemDataModel, callback);
    }
  }

  /**
   * Returns the address of executable code.
   */
  int get address {
    return _closure.address;
  }

  BinaryData get functionCode {
    return _closure.functionCode;
  }
}
