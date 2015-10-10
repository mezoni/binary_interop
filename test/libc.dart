import "package:binary_interop/binary_interop.dart";

const Map<String, String> HEADERS = const <String, String>{"header.h": _header};

const String _header = '''
#include <stddef.h>

int printf(const char *format, ...);
#if __OS == windows
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
