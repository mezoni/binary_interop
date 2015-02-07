part of binary_interop.dynamic_library;

class _Metadata {
  static final _Metadata empty = new _Metadata(const <Metadata>[]);

  Map<String, List<List<String>>> _attributes;

  _Metadata(List<Metadata> metadataList) {
    if (metadataList == null) {
      throw new ArgumentError.notNull("metadataList");
    }

    _attributes = _joinMetadata(metadataList);
  }

  String get alias {
    var values = _getLastValues(_attributes, "alias");
    if (values == null) {
      return null;
    }

    if (values.isEmpty) {
      return null;
    }

    return values.first.trim();
  }

  Map<String, List<List<String>>> _getAttributes(Metadata metadata, Map<String, List<List<String>>> attributes) {
    if (attributes == null) {
      attributes = <String, List<List<String>>>{};
    }

    if (metadata == null) {
      return attributes;
    }

    for (var attributeList in metadata.attributeList) {
      for (var value in attributeList.attributes) {
        var name = value.name;
        var list = attributes[name];
        if (list == null) {
          list = <List<String>>[];
          attributes[name] = list;
        }

        list.add(value.parameters);
      }
    }

    return attributes;
  }

  List<String> _getLastValues(Map<String, List<List<String>>> attributes, String name) {
    var values = attributes[name];
    if (values == null) {
      return null;
    }

    return values.last;
  }

  Map<String, List<List<String>>> _joinMetadata(List<Metadata> metadataList) {
    Map<String, List<List<String>>> result;
    for (var metadata in metadataList) {
      result = _getAttributes(metadata, result);
    }

    return result;
  }
}
