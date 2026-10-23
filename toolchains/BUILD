
load(":toolchain.bzl", "qt_toolchain")

package(default_visibility = ["//visibility:public"])


toolchain_type(name = "toolchain_type")

qt_toolchain(
  name = "osx_qt",
  qmake= "@qt//:qmake",
)

toolchain(
  name = "osx_qt_toolchain",
  exec_compatible_with = ["@platforms//os:osx"],
  target_compatible_with = ["@platforms//os:osx", "@platforms//cpu:arm64"],
  toolchain = ":osx_qt",
  toolchain_type = "@cxx-qt-bazel//toolchains:toolchain_type"
)
