load("@cxx-qt-bazel//cxx-qt-bazel:cmd.bzl", "cxx_qt_cmd")
load("@cxx-qt-bazel//cxx-qt-bazel:generate.bzl", generate = "cxx_qt_cmd")
load("@rules_cc//cc:cc_library.bzl", "cc_library")

def cxx_qt(*, name, visibility = []):  
  cc_library(
    name = name + "-generated",
    srcs = [name] + ["src/connection.cpp"],
    visibility = visibility,
    includes = [
      "out/cxxqtbuild/include",
      "out/include",
    ],
    deps = ["@qt//:QtCore", "@qt//:QtQuick", "@qt//:QtQuickControls2"]
  )

  generate(
    name = name,
    crate_name = "cxx-qt",
    srcs = native.glob(["include/**", "src/**", "Cargo.toml"], allow_empty = True),
    crate_include_root = "include",
    crate_include_files = native.glob(["include/**"], allow_empty = True),
    cargo_toml = "Cargo.toml",
    bridge_files = ["src/connection.rs", "src/qobject.rs"],
    cpp_files = ["src/connection.cpp"],
    initializers = {
      "init_cxx_qt_core": "src/init.cpp"
    },
    qt = "@qt//:files",
    visibility = visibility,
  )
