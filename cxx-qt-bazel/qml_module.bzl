load("@cxx-qt-bazel//cxx-qt-bazel:cmd.bzl", "cxx_qt_cmd")
load("@rules_cc//cc:cc_library.bzl", "cc_library")

def qml_module(
  *, 
  name, 
  crate_name, 
  module_name, 
  qml_files, 
  visibility = [], 
  qt_files = "@qt//:files"
):
  cxx_qt_cmd(
    name = "_bs_" + name,
    srcs = native.glob(["**"]),
    crate_name = crate_name,
    cargo_toml = "Cargo.toml",
    qt = qt_files,
    qml_modules = {
      module_name: qml_files,
    },
  )
  cc_library(
    name = name,
    srcs = [":_bs_" + name],
    alwayslink = True,
    linkstatic = True,
    visibility = visibility,
  )
