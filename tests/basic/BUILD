load("@rules_rs//rs:rust_binary.bzl", "rust_binary")
load("@cxx-qt-bazel//cxx-qt-bazel:qml_module.bzl", "qml_module")
load("@cxx_qt_crates//:defs.bzl", "all_crate_deps")

qml_module(
  name = "_gen",
  crate_name = "basic",
  module_name = "com.example.basic",
  qml_files = ["qml/main.qml"],
)

rust_binary(
  name = "basic",
  srcs = ["src/main.rs"],
  deps = all_crate_deps() + [
    ":_gen",
    # we are using Quick in qml
    "@qt//:QtQuick",
  ],
  alwayslink = True,
)
