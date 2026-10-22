load("@rules_rs//rs:rust_binary.bzl", "rust_binary")
load("@cxx-qt-bazel//cxx-qt-bazel:qml_module.bzl", "qml_module")
load("@crates//:defs.bzl", "all_crate_deps")

qml_module(
  name = "qml",
  crate_name = "qtbridge-basic",
  module_name = "com.example.basic",
  qml_files = ["qml/main.qml"],
)

rust_binary(
  name = "qtbridge-basic",
  srcs = ["src/main.rs"],
  deps = all_crate_deps() + [
    ":qml",
    # we are using Quick in qml
    "@qt//:QtQuick",
  ],
  alwayslink = True,
)
