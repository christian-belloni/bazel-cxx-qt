load("@rules_rs//rs:rust_binary.bzl", "rust_binary")
load("@rules_cc//cc:cc_library.bzl", "cc_library")
load("@bazel-cxx-qt//:rules.bzl", "cxx_qt_cmd")

cxx_qt_cmd(
  name = "_bs",
  srcs = glob(["**"]),
  crate_name = "basic",
  cargo_toml = "Cargo.toml",
  # qmake = "@qt_osx//:qmake",
  visibility = ["//visibility:public"],
  qml_modules = {
    "com.example.basic": ["qml/main.qml"],
  },
)

cc_library(
  name = "_gen",
  srcs = [":_bs"],
  alwayslink = True,
  linkstatic = True,
)

rust_binary(
  name = "basic",
  srcs = ["src/main.rs"],
  deps = [
    "@crates//:cxx-qt",
    "@crates//:cxx-qt-lib",
    ":_gen"
  ],
  alwayslink = True,
)
