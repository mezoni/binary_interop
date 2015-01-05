part of binary_interop.internal.ffi_headers;

class _Utils {
  static final ProcessorArchitecture processorArchitecture = SysInfo.processors.first.architecture;

  static void checkFillingInterfaces(Map<FfiInterfaces, dynamic> interfaces) {
    for (var interface in FfiInterfaces.values) {
      if (interfaces[interface] == null) {
        throw new StateError("Mising application binary interface '$interface'.");
      }
    }
  }
}
