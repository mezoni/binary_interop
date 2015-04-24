part of binary_interop.internal.helper;

class BinaryInteropHelper {
  static final Map<BinaryInterface, FfiPlatform> binaryInterfaceToPlatform = <BinaryInterface, FfiPlatform>{
    BinaryInterface.ARM_ANDROID: FfiPlatform.ARM_ANDROID,
    BinaryInterface.ARM_UNIX: FfiPlatform.ARM_UNIX,
    BinaryInterface.X86_64_UNIX: FfiPlatform.X86_64_UNIX,
    BinaryInterface.X86_64_WINDOWS: FfiPlatform.X86_64_WINDOWS,
    BinaryInterface.X86_UNIX: FfiPlatform.X86_UNIX,
    BinaryInterface.X86_WINDOWS: FfiPlatform.X86_WINDOWS
  };

  static final Map<CallingConvention, FfiAbi> callingConventionToAbi = <CallingConvention, FfiAbi>{
    CallingConvention.CDECL: FfiAbi.CDECL,
    CallingConvention.DEFAULT: FfiAbi.DEFAULT,
    CallingConvention.FASTCALL: FfiAbi.FASTCALL,
    CallingConvention.PASCAL: FfiAbi.PASCAL,
    CallingConvention.REGISTER: FfiAbi.REGISTER,
    CallingConvention.STDCALL: FfiAbi.STDCALL,
    CallingConvention.SYSV: FfiAbi.SYSV,
    CallingConvention.THISCALL: FfiAbi.THISCALL,
    CallingConvention.UNIX64: FfiAbi.UNIX64,
    CallingConvention.VFP: FfiAbi.VFP,
    CallingConvention.WIN64: FfiAbi.WIN64
  };

  static BinaryInterface getSystemInterface() {
    var operatingSystem = Platform.operatingSystem;
    var userSpaceBitness = SysInfo.userSpaceBitness;
    switch (SysInfo.processors.first.architecture) {
      case ProcessorArchitecture.ARM:
        switch (operatingSystem) {
          case "android":
            return BinaryInterface.ARM_ANDROID;
          case "linux":
            return BinaryInterface.ARM_UNIX;
        }

        break;
      case ProcessorArchitecture.X86:
        switch (operatingSystem) {
          case "android":
          case "linux":
          case "macos":
            return BinaryInterface.X86_UNIX;
          case "windows":
            return BinaryInterface.X86_WINDOWS;
        }

        break;
      case ProcessorArchitecture.X86_64:
        switch (operatingSystem) {
          case "android":
          case "linux":
          case "macos":
            switch (userSpaceBitness) {
              case 32:
                return BinaryInterface.X86_UNIX;
              case 64:
                return BinaryInterface.X86_64_UNIX;
            }

            break;
          case "windows":
            switch (userSpaceBitness) {
              case 32:
                return BinaryInterface.X86_WINDOWS;
              case 64:
                return BinaryInterface.X86_64_WINDOWS;
            }

            break;
        }

        break;
    }

    return null;
  }
}
