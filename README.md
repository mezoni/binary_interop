binary_interop
=====

Binary interop is a library that allows load shared libraries, invoke their functions and get access to their data.

Version: 0.0.32

[Donate to binary interop for dart](https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=binary.dart@gmail.com&item_name=binary.interop.for.dart&currency_code=USD)

**Interrelated (binary) software**

- [Binary declarations](https://pub.dartlang.org/packages/binary_declarations)
- [Binary generator](https://pub.dartlang.org/packages/binary_generator)
- [Binary interop](https://pub.dartlang.org/packages/binary_interop)
- [Binary marshalling](https://pub.dartlang.org/packages/binary_marshalling)
- [Binary types](https://pub.dartlang.org/packages/binary_types)

**Limitations**

- Binary type "long double" not supported

**Supportedd platforms**

- ARM Android (Initial support)
- ARM Linux (Initial support)
- X86 Linux
- X86 Mac OS (Will be removed)
- X86 Windows
- X86_64 Linux
- X86_64 Mac OS
- X86_64 Windows

Binary interop is a low-level way of interacting with dynamic loadable libraries.  
It support interaction only through the low level binary types and binary objects.

**Examples**

```dart
import "dart:io";

import "package:libc/headers.dart";
import "package:binary_interop/binary_interop.dart";
import "package:test/test.dart";

import "libc.dart";

void main() {
  test("Test binary interop", () {
    var helper = new BinaryTypeHelper(_t);
    helper.addHeaders(LIBC_HEADERS);
    helper.addHeaders(HEADERS);
    helper.declare(HEADERS.keys.first);
    var libc = loadLibc();

    // Strlen
    var string = "0123456789";
    var length = libc.strlen(string);
    expect(length, string.length, reason: "Call 'strlen'");

    string = "Hello Dartisans 2015\n";

    // printf
    length = libc.printf("Hello %s %i\n", ["Dartisans", 2015]);
    expect(length, string.length, reason: "Wrong length");

    // sprintf
    var buffer = alloc(_t["char[500]"]);
    length = libc.snprintf(buffer, 500, "Hello %s %i\n", ["Dartisans", 2015]);
    var string2 = helper.readString(buffer);
    expect(length, string.length, reason: "Wrong length");
    expect(string, string2, reason: "Wrong string");

    // sprintf (w/o direct alloc binary buffer)
    var buffer2 = new List<int>(500);
    length = libc.snprintf(buffer2, buffer2.length, "Hello %s %i\n", ["Dartisans", 2015]);
    string2 = stringFromArray(buffer2);
    expect(length, string.length, reason: "Wrong length");
    expect(string, string2, reason: "Wrong string");

    // printf
    length = libc.printf("True is %i\n", [true]);
    expect(length, 10, reason: "Wrong length");
  });
}

final BinaryTypes _t = new BinaryTypes();

BinaryObject alloc(BinaryType type, [value]) => type.alloc(value);

Libc loadLibc() {
  String libname;
  var operatingSystem = Platform.operatingSystem;
  switch (operatingSystem) {
    case "macos":
      libname = "libSystem.dylib";
      break;
    case "android":
    case "linux":
      libname = "libc.so.6";
      break;
    case "windows":
      libname = "msvcr100.dll";
      break;
    default:
      throw new UnsupportedError("Unsupported operating system: $operatingSystem");
  }

  var library = DynamicLibrary.load(libname, types: _t);
  if (library == null) {
    throw new StateError("Failed to load library: $libname");
  }

  return new Libc(library);
}

String stringFromArray(List array) {
  var index = array.indexOf(0);
  if (index == -1) {
    return "";
  }

  return new String.fromCharCodes(array.sublist(0, index));
}

```

Library wrapper for `libc`.

```dart
import "package:binary_interop/binary_interop.dart";

const Map<String, String> HEADERS = const <String, String>{"header.h": _header};

const String _header = '''
#include <stddef.h>

int printf(const char *format, ...);
#if OS == windows
int snprintf(char *s, size_t n, const char *format, ...) __attribute__((alias(_sprintf_p)));
#else
int snprintf(char *s, size_t n, const char *format, ...);
#endif
size_t strlen(const char *s);''';

class Libc {
  DynamicLibrary _library;

  /**
   *
   */
  Libc(DynamicLibrary library) {
    if (library == null) {
      throw new ArgumentError.notNull("library");
    }

    library.link(HEADERS.keys);
    _library = library;
  }

  /**
   * int printf(const char* format, ...)
   */
  dynamic printf(format, [List params]) {
    var arguments = [format];
    if (params != null) {
      arguments.addAll(params);
    }

    return _library.invoke("printf", arguments);
  }

  /**
   * int snprintf(char* s, size_t n, const char* format, ...)
   */
  dynamic snprintf(s, int n, format, [List params]) {
    var arguments = [s, n, format];
    if (params != null) {
      arguments.addAll(params);
    }

    return _library.invoke("snprintf", arguments);
  }

  /**
   * size_t strlen(const char* s)
   */
  dynamic strlen(s) {
    return _library.invoke("strlen", [s]);
  }
}

```
