part of binary_interop.internal.ffi_headers;

const String FFI_H = """
#ifndef LIBFFI_H
#define LIBFFI_H

#include <ffitarget.h>
#include <stddef.h>

typedef struct _ffi_type {
  size_t size;
  unsigned short alignment;
  unsigned short type;
  struct _ffi_type **elements;
} ffi_type;

typedef enum {
  FFI_OK = 0,
  FFI_BAD_TYPEDEF,
  FFI_BAD_ABI
} ffi_status;

typedef struct {
  ffi_abi abi;
  unsigned nargs;
  ffi_type **arg_types;
  ffi_type *rtype;
  unsigned bytes;
  unsigned flags;
#ifdef FFI_EXTRA_CIF_FIELDS
  FFI_EXTRA_CIF_FIELDS;
#endif
} ffi_cif;


#endif
""";

const Map<String, String> FFI_HEADERS = const <String, String>{"ffi.h": FFI_H, "ffitarget.h": FFITARGET_H};

const String FFITARGET_H = """
#ifndef LIBFFI_TARGET_H
#define LIBFFI_TARGET_H

#ifndef LIBFFI_H
#error "Please do not include ffitarget.h directly into your source.  Use ffi.h instead."
#endif

typedef enum ffi_abi {
  FFI_FIRST_ABI = 0,

#if __ARCH__ == X86 && __OS__ == windows
  FFI_SYSV,
  FFI_STDCALL,
  FFI_THISCALL,
  FFI_FASTCALL,
  FFI_MS_CDECL,
  FFI_PASCAL,
  FFI_REGISTER,
  FFI_LAST_ABI,
  FFI_DEFAULT_ABI = FFI_MS_CDECL

#elif __ARCH__ == X86_64 && __OS__ == windows
  FFI_WIN64,
  FFI_LAST_ABI,
  FFI_DEFAULT_ABI = FFI_WIN64

#elif __ARCH__ == X86 || __ARCH__ == X86_64
  FFI_SYSV,
  FFI_UNIX64,   /* Unix variants all use the same ABI for x86-64  */
  FFI_THISCALL,
  FFI_FASTCALL,
  FFI_STDCALL,
  FFI_PASCAL,
  FFI_REGISTER,
  FFI_LAST_ABI, 
#if __ARCH__ == X86
  FFI_DEFAULT_ABI = FFI_SYSV
#else
  FFI_DEFAULT_ABI = FFI_UNIX64
#endif

#elif __ARCH__ == ARM
  FFI_SYSV,
  FFI_VFP,
  FFI_LAST_ABI,
  FFI_DEFAULT_ABI = FFI_SYSV,
#endif
} ffi_abi;

#if __ARCH__ == ARM 
#define FFI_EXTRA_CIF_FIELDS int vfp_used; short vfp_reg_free, vfp_nargs; signed char vfp_args[16];
#endif

#endif
""";
