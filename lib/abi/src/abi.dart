part of binary_interop.internal.abi;

class BinaryInterfaces {
  static const BinaryInterfaces ARM_ANDROID = const BinaryInterfaces("ARM_ANDROID");

  static const BinaryInterfaces X86_64_UNIX = const BinaryInterfaces("X86_64_UNIX");

  static const BinaryInterfaces X86_64_WINDOWS = const BinaryInterfaces("X86_64_WINDOWS");

  static const BinaryInterfaces X86_UNIX = const BinaryInterfaces("X86_UNIX");

  static const BinaryInterfaces X86_WINDOWS = const BinaryInterfaces("X86_WINDOWS");

  static const BinaryInterfaces X86_WINDOWS_GNU = const BinaryInterfaces("X86_WINDOWS_GNU");

  static const List<BinaryInterfaces> values = const <BinaryInterfaces>[
    ARM_ANDROID,
    X86_64_UNIX,
    X86_64_WINDOWS,
    X86_UNIX,
    X86_WINDOWS,
    X86_WINDOWS_GNU
  ];

  final String _name;

  const BinaryInterfaces(this._name);

  String toString() => _name;
}

class CallingConventions {
  static const CallingConventions DEFAULT = const CallingConventions("DEFAULT");

  static const CallingConventions FASTCALL = const CallingConventions("FASTCALL");

  static const CallingConventions CDECL = const CallingConventions("CDECL");

  static const CallingConventions PASCAL = const CallingConventions("PASCAL");

  static const CallingConventions REGISTER = const CallingConventions("REGISTER");

  static const CallingConventions STDCALL = const CallingConventions("STDCALL");

  static const CallingConventions SYSV = const CallingConventions("SYSV");

  static const CallingConventions THISCALL = const CallingConventions("THISCALL");

  static const CallingConventions UNIX64 = const CallingConventions("UNIX64");

  static const CallingConventions VFP = const CallingConventions("VFP");

  static const CallingConventions WIN64 = const CallingConventions("WIN64");

  final String _name;

  const CallingConventions(this._name);

  String toString() => _name;
}
