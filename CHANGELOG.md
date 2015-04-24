## 0.0.31

- Added support of the `binary callbacks` (libffi closures)

## 0.0.30

- Intial use of the `headers` from `libc` package. In the future, most of the `ffi` wrappers will be completely rewritten to use the `binary headers`

## 0.0.29

- Added new method `DynamicLibrary.link()`
- Breaking changes: Removed method `DynamicLibrary.declare()`
- Made adaptations to the new version of package `binary_declarations`
- Made adaptations to the new version of package `binary_types`

## 0.0.27

- Fixed bug on ARM

## 0.0.26

- Initial support of Unix (ARM)

## 0.0.25

- Initial support of Android (ARM) 

## 0.0.24

- Made adaptations to the new version of package `unsafe_extension`

## 0.0.23

- Improved performance of the `DynamicLibrary.invoke()` with a variable parameters through the precompilation of the commonly used binary types (`bool`, `char`, `char *`,`int`, `double`)

## 0.0.22

- Added possibility for the "root" user to load `libffi.so` from the user `pub cache` if `dart vm` executed from the user home directory (eg. /home/user/tools/dart)

## 0.0.21

- Added possibility to set the `binary types` for `DynamicLibrary` if they were not specified in the constructor

## 0.0.20

- Breaking changes. Added parameter `variadic` to the function `DynamicLibrary.function()`
- Breaking changes. Removed support of the `VaListType`(in the function parameters declaration) in favor to the new specification where the functions with variable number of arguments should be declared through the additional parameter `variadic`
- Made adaptations to the new version of package `binary_declarations`

## 0.0.19

- Made adaptations to the new version of package `binary_declarations`

## 0.0.18

- Made adaptations to the new version of package `binary_declarations`

## 0.0.17

- Made adaptations to the new version of package `binary_declarations`

## 0.0.16

- Improved the performance of `DynamicLibrary.declare()` through the avoiding double parsing of declarations

## 0.0.15

- Added parameter `alias` to the the function `DynamicLibrary.function()`
- Added support of the attribute `alias`. Eg. `snprintf() __attribute__((alias(_sprintf_p)))` 
- Breaking changes. The optional parameters of the function `DynamicLibrary.function()` are the named parameters now
- Made adaptations to the new version of package `binary_declarations`
- Made adaptations to the new version of package `binary_types`

## 0.0.14

- Made adaptations to the new version of package `binary_declarations`
- Made adaptations to the new version of package `binary_types`

## 0.0.12

- Improved error reporting in `DynamicLibrary.declare()`

## 0.0.11

- Added support for macro processing

## 0.0.10

- Added parameter `lazy` to `DynamicLibrary.load`. It is turned on by default. This feature allows declare very big number of exported functions in libraries. These libraries will be loaded very fast and they will not consume an additional unmanaged memory on the unused declared functions.

## 0.0.9

- Made adaptations to the changes in package `binary_types` 

## 0.0.8

- From now the test are performed on a `multi-platform` wrapper over the C language `libc`. Thanks to the tool `binary generator`

## 0.0.5

- Made adaptations to the new version of package `binary_types`
- Made adaptations to the new version of package `unsafe_extension`

## 0.0.4

- Added possibility declare functions using textual form

## 0.0.3

- Added test of the variadic function
- Removed an unnecessary allocation of values in instantiation of the variadic foreign function. Variadic function always re-allocates them on each invocation
- Removed unused class `_FfiTypes`
- Renamed method `exec` to `invoke` in `ForeignFunction`

## 0.0.2

- Make available the source code

## 0.0.1

- Initial release

