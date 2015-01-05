part of binary_interop.internal.ffi_headers;

class FfiInterfaces {
  static const FfiInterfaces X86_64_UNIX = const FfiInterfaces("X86_64_UNIX");

  static const FfiInterfaces X86_64_WINDOWS = const FfiInterfaces("X86_64_WINDOWS");

  static const FfiInterfaces X86_UNIX = const FfiInterfaces("X86_UNIX");

  static const FfiInterfaces X86_WINDOWS = const FfiInterfaces("X86_WINDOWS");

  static const FfiInterfaces X86_WINDOWS_GNU = const FfiInterfaces("X86_WINDOWS_GNU");

  final String _name;

  static const List<FfiInterfaces> values = const <FfiInterfaces>[X86_64_UNIX, X86_64_WINDOWS, X86_UNIX, X86_WINDOWS, X86_WINDOWS_GNU];

  const FfiInterfaces(this._name);

  String toString() => _name;
}
