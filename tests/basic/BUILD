load("@rules_rs//rs:rust_binary.bzl", "rust_binary")
load("@cxx-qt-bazel//cxx-qt-bazel:qml_module.bzl", "qml_module")
load("@cxx_qt_crates//:defs.bzl", "all_crate_deps")

qml_module(
  name = "main_qml",
  crate_name = "basic",
  modules = {
    "ui": glob(["qml/main.qml"]),
    "components": glob(["qml/nested/Other.qml"]),
  },
)

rust_binary(
  name = "basic",
  srcs = ["src/main.rs"],
  deps = all_crate_deps() + [
    "main_qml",
    # we are using Quick in qml
    "@qt//:QtQuick",
  ],
  alwayslink = True,
)
