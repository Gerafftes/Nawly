#include "utils.h"

#include <flutter_windows.h>
#include <climits>
#include <cstddef>
#include <io.h>
#include <stdio.h>
#include <windows.h>

#include <iostream>

namespace {
constexpr size_t kMaxCommandLineArgumentLength = 1024 * 1024;

size_t BoundedWideStringLength(const wchar_t* value) {
  size_t length = 0;
  while (length <= kMaxCommandLineArgumentLength && value[length] != L'\0') {
    ++length;
  }
  return length;
}
}  // namespace

void CreateAndAttachConsole() {
  if (::AllocConsole()) {
    FILE *unused;
    if (freopen_s(&unused, "CONOUT$", "w", stdout)) {
      _dup2(_fileno(stdout), 1);
    }
    if (freopen_s(&unused, "CONOUT$", "w", stderr)) {
      _dup2(_fileno(stdout), 2);
    }
    std::ios::sync_with_stdio();
    FlutterDesktopResyncOutputStreams();
  }
}

std::vector<std::string> GetCommandLineArguments() {
  // Convert the UTF-16 command line arguments to UTF-8 for the Engine to use.
  int argc;
  wchar_t** argv = ::CommandLineToArgvW(::GetCommandLineW(), &argc);
  if (argv == nullptr) {
    return std::vector<std::string>();
  }

  std::vector<std::string> command_line_arguments;

  // Skip the first argument as it's the binary name.
  for (int i = 1; i < argc; i++) {
    command_line_arguments.push_back(Utf8FromUtf16(argv[i]));
  }

  ::LocalFree(argv);

  return command_line_arguments;
}

std::string Utf8FromUtf16(const wchar_t* utf16_string) {
  if (utf16_string == nullptr) {
    return std::string();
  }

  const size_t input_length = BoundedWideStringLength(utf16_string);
  if (input_length > kMaxCommandLineArgumentLength || input_length > INT_MAX) {
    return std::string();
  }

  const int input_length_for_conversion = static_cast<int>(input_length);
  const int target_length_with_null = ::WideCharToMultiByte(
      CP_UTF8, WC_ERR_INVALID_CHARS, utf16_string,
      -1, nullptr, 0, nullptr, nullptr);
  if (target_length_with_null <= 0) {
    return std::string();
  }

  const int target_length = target_length_with_null - 1;
  if (target_length <= 0) {
    return std::string();
  }

  std::string utf8_string;
  if (static_cast<size_t>(target_length) > kMaxCommandLineArgumentLength ||
      static_cast<size_t>(target_length) > utf8_string.max_size()) {
    return std::string();
  }
  utf8_string.resize(static_cast<size_t>(target_length));
  const int converted_length = ::WideCharToMultiByte(
      CP_UTF8, WC_ERR_INVALID_CHARS, utf16_string,
      input_length_for_conversion, utf8_string.data(), target_length,
      nullptr, nullptr);
  if (converted_length != target_length) {
    return std::string();
  }
  return utf8_string;
}
