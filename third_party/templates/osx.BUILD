load("@bazel_skylib//rules:native_binary.bzl", "native_binary")
load("@rules_cc//cc:defs.bzl", "cc_library")

exports_files(["lib", "Frameworks", "bin"])

native_binary(
  name = "qmake",
  src = "bin/qmake",
  visibility = ["//visibility:public"],
  data = glob(["**"]),
  out = "qmake"
)

cc_library(
  name = "QtCore",
  hdrs = glob(["lib/QtCore.framework/Headers/**"], allow_empty = True),
  includes = [
      "lib/QtCore.framework/Headers" ,
  ],
  defines = select({
      "@platforms//cpu:aarch64": ["__yield=__builtin_arm_yield"],
      "//conditions:default": [],
  }),
  additional_linker_inputs = [":lib"],
  data = [":lib/QtCore.framework"],
  linkopts = ["-F", "$(location :lib)"] + [
      "-framework", "QtCore",
      "-rpath", "$(rootpath :lib)",
  ],
  include_prefix = "QtCore",
  strip_include_prefix = "lib/QtCore.framework/Headers" ,
  target_compatible_with = ["@platforms//os:osx"],
  visibility = ["//visibility:public"],
)
