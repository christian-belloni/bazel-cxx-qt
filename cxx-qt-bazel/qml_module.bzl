load("@cxx-qt-bazel//cxx-qt-bazel:generate.bzl", generate = "cxx_qt_cmd")
load("@rules_cc//cc:cc_library.bzl", "cc_library")
load(":generate.bzl", "extract_plugin_headers")


def qml_module(
  *, 
  name, 
  crate_name, 
  module_name, 
  qml_files, 
  visibility = [], 
  qt_files = "@qt//:files"
):
  generate(
    name = "_bs_gen" + name,
    srcs = native.glob(["**"]),
    crate_name = crate_name,
    cargo_toml = "Cargo.toml",
    qt = qt_files,
    qml_modules = {
      module_name: qml_files,
    },
  )

  extract_plugin_headers(
    name = "_hdrs_" + name,
    cxx_qt_cmd = "_bs_gen" + name,
  )

  cc_library(
    name = name,
    hdrs = ["_hdrs_" + name],
    srcs = [":_bs_gen" + name],
    alwayslink = True,
    linkstatic = True,
    visibility = visibility,
    includes = [
      "out/moc",
    ],
    defines = ["QT_STATICPLUGIN"],
    deps = [
      "@qt//:QtCore",
      "@qt//:QtQml", 
      "@qt//:QtNetwork",
      "@qt//:qt_hdrs"
    ]
  )
