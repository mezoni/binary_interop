import "dart:io";

import "package:binary_interop/binary_interop.dart";
import "package:unittest/unittest.dart";

import "libc.dart";

void main() {
  var libc = loadLibc();
  var helper = new BinaryTypeHelper(_t);

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
