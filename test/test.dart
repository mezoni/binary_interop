import "dart:io";

import "package:binary_interop/binary_interop.dart";
import "package:unittest/unittest.dart";

var kernel32_h_windows = '''
size_t strlen(const char *s);
''';

var msvcr100_h_windows = '''
int _sprintf_p(char *buffer, size_t sizeOfBuffer, const char *format, ...);
''';

var stdio_h_posix = '''
int snprintf(char *str, size_t size, const char *format, ...);
size_t strlen(const char *s);
''';

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
  var types = new BinaryTypes();
  var library = DynamicLibrary.load("libc.so.6", types: types);
  library.declare(stdio_h_posix);
  var helper = new BinaryTypeHelper(types);
  expect(library.handle != null, true, reason: "Library handle");
  var string = "0123456789";
  var ca = helper.allocString(string);
  var length = library.invokeEx("strlen", [ca]);
  expect(length, string.length, reason: "Call 'strlen'");
  _testVariadic(library, "snprintf", types);
  library.free();
}

void testLibraryMacos() {
  var types = new BinaryTypes();
  var library = DynamicLibrary.load("libSystem.dylib", types: types);
  library.declare(stdio_h_posix);
  var helper = new BinaryTypeHelper(types);
  expect(library.handle != null, true, reason: "Library handle");
  var string = "0123456789";
  var ca = helper.allocString(string);
  var length = library.invokeEx("strlen", [ca]);
  expect(length, string.length, reason: "Call 'strlen'");
  // Variadic
  _testVariadic(library, "snprintf", types);
  library.free();
}

void testLibraryWindows() {
  var types = new BinaryTypes();
  var library = DynamicLibrary.load("kernel32.dll", types: types);
  types["LPCTSTR"] = types["char*"];
  library.declare(kernel32_h_windows);
  var helper = new BinaryTypeHelper(types);
  expect(library.handle != null, true, reason: "Library handle");
  var string = "0123456789";
  var ca = helper.allocString(string);
  var length = library.invokeEx("lstrlen", [ca]);
  expect(length, string.length, reason: "Call 'lstrlen'");

  // Variadic
  var msvcr100 = DynamicLibrary.load("msvcr100.dll", types: types);
  expect(msvcr100.handle != null, true, reason: "Library handle");
  library.declare(msvcr100_h_windows);
  _testVariadic(library, "_sprintf_p", types);
  library.free();
}

void _testVariadic(DynamicLibrary library, String name, BinaryTypes types) {
  var helper = new BinaryTypeHelper(types);
  var bufsize = 500;
  var buffer = types["char"].array(bufsize).alloc(const []);
  var hello = helper.allocString("Hello %s");
  var world = helper.allocString("World");
  var length = library.invoke(name, [buffer, bufsize, "Hello %s", "World"]);
  var formatted = helper.readString(buffer);
  expect(formatted, "Hello World", reason: "Hello World");
  expect(length, formatted.length, reason: formatted);
}
