load("@rules_rs//rs:rust_binary.bzl", "rust_binary")
load("@rules_rs//rs:rust_library.bzl", "rust_library")
load("@cxx_qt_crates//:defs.bzl", "all_crate_deps")

rust_binary(
  name = "cxxqtcmd",
  srcs = ["src/main.rs"],
  deps = all_crate_deps(),
  visibility = ["//visibility:public"]
)
