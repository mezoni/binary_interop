import "dart:io";

import "package:binary_interop/binary_interop.dart";
import "package:unittest/unittest.dart";

void main() {
  testLibrary();
}

void testLibrary() {
  var operatingSystem = Platform.operatingSystem;
  switch (operatingSystem) {
    case "macos":
      testLibraryMacos();
      break;
    case "android":
    case "linux":
      testLibraryLinux();
      break;
    case "windows":
      testLibraryWindows();
      break;
    default:
      throw new UnsupportedError("Unsupported operating system: $operatingSystem");
  }
}

void testLibraryLinux() {
  var library = DynamicLibrary.load("libc.so.6");
  var types = new BinaryTypes();
  var helper = new BinaryTypeHelper(types);
  expect(library.handle != null, true, reason: "Library handle");
  library.function("strlen", types["int"], [types["char*"]]);
  var string = "0123456789";
  var ca = helper.allocString(string);
  var length = library.invokeEx("strlen", [~ca]);
  expect(length, string.length, reason: "Call 'strlen'");
  _testVariadic(library, "snprintf", types);
  library.free();
}

void testLibraryMacos() {
  var library = DynamicLibrary.load("libSystem.dylib");
  var types = new BinaryTypes();
  var helper = new BinaryTypeHelper(types);
  expect(library.handle != null, true, reason: "Library handle");
  library.function("strlen", types["int"], [types["char*"]]);
  var string = "0123456789";
  var ca = helper.allocString(string);
  var length = library.invokeEx("strlen", [~ca]);
  expect(length, string.length, reason: "Call 'strlen'");
  // Variadic
  _testVariadic(library, "snprintf", types);
  library.free();
}

void testLibraryWindows() {
  var library = DynamicLibrary.load("kernel32.dll");
  var types = new BinaryTypes();
  var helper = new BinaryTypeHelper(types);
  expect(library.handle != null, true, reason: "Library handle");
  const WINAPI = CallingConventions.STDCALL;
  types["LPCTSTR"] = types["char*"];
  library.function("lstrlen", types["int"], [types["LPCTSTR"]], WINAPI);
  var string = "0123456789";
  var ca = helper.allocString(string);
  var length = library.invokeEx("lstrlen", [~ca]);
  expect(length, string.length, reason: "Call 'lstrlen'");
  // Variadic
  var msvcr100 = DynamicLibrary.load("msvcr100.dll");
  expect(msvcr100.handle != null, true, reason: "Library handle");
  _testVariadic(library, "_sprintf_p", types);
  library.free();
}

void _testVariadic(DynamicLibrary library, String name, BinaryTypes types) {
  library.function(name, types["int"], [types["char*"], types["size_t"], types["char*"], types["..."]]);
  var helper = new BinaryTypeHelper(types);
  var bufsize = 500;
  var buffer = types["char"].array(bufsize).alloc(const []);
  var hello = helper.allocString("Hello %s");
  var world = helper.allocString("World");
  var length = library.invoke(name, [~buffer, bufsize, "Hello %s", "World"]);
  var formatted = helper.readString(~buffer);
  expect(formatted, "Hello World", reason: "Hello World");
  expect(length, formatted.length, reason: formatted);
}
