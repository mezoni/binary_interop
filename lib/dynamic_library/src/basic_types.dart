part of binary_interop.dynamic_library;

class _BasicTypes {
  final BinaryType boolType;

  final BinaryType charPointerType;

  final BinaryType charType;

  final BinaryType doubleType;

  final BinaryType intType;

  _BasicTypes._internal({this.boolType, this.charPointerType, this.charType, this.doubleType, this.intType});

  factory _BasicTypes(DataModel dataModel) {
    var boolType = new BoolType(dataModel);
    var charType = IntType.create(dataModel.sizeOfChar, dataModel.isCharSigned, dataModel);
    var charPointerType = charType.ptr();
    var doubleType = new DoubleType(dataModel);
    var intType = IntType.create(dataModel.sizeOfInt, true, dataModel);
    return new _BasicTypes._internal(
        boolType: boolType,
        charPointerType: charPointerType,
        charType: charType,
        doubleType: doubleType,
        intType: intType);
  }
}
