part of binary_interop.dynamic_library;

class _Metadata {
  static final _Metadata empty = new _Metadata(const <Metadata>[]);

  Map<String, List<List<dynamic>>> _attributes;

  _Metadata(List<Metadata> metadataList) {
    if (metadataList == null) {
      throw new ArgumentError.notNull("metadataList");
    }

    _attributes = _joinMetadata(metadataList);
  }

  String get alias {
    var values = getLastValues(_attributes, "alias");
    if (values == null) {
      return null;
    }

    if (values.isEmpty) {
      _wrongNumberOfArguments("alias");
    }

    var parameter = values.first;
    if (parameter is! String) {
      _wrongArgumentType("alias", "string");
    }

    return parameter;
  }

  List<String> getLastValues(Map<String, List<List<String>>> attributes, String name) {
    var values = attributes[name];
    if (values == null) {
      return null;
    }

    return values.last;
  }

  Map<String, List<List<dynamic>>> _getAttributes(Metadata metadata, Map<String, List<List<String>>> attributes) {
    if (attributes == null) {
      attributes = <String, List<List<dynamic>>>{};
    }

    if (metadata == null) {
      return attributes;
    }

    for (var attributeList in metadata.attributeList) {
      for (var value in attributeList.attributes) {
        var name = value.name;
        var list = attributes[name];
        if (list == null) {
          list = <List<dynamic>>[];
          attributes[name] = list;
        }

        list.add(value.parameters);
      }
    }

    return attributes;
  }

  Map<String, List<List<dynamic>>> _joinMetadata(List<Metadata> metadataList) {
    Map<String, List<List<dynamic>>> result;
    for (var metadata in metadataList) {
      result = _getAttributes(metadata, result);
    }

    return result;
  }

  void _wrongArgumentType(String name, String type) {
    throw new StateError("Attribute '$name' argument not a $type");
  }

  void _wrongNumberOfArguments(String name) {
    throw new StateError("Wrong number of arguments specified for '$name' attribute");
  }
}
