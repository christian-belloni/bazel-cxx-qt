TEMPLATE = """
load("@bazel_skylib//rules/directory:directory.bzl", "directory")
load("@bazel_skylib//rules:native_binary.bzl", "native_binary")
load("@rules_cc//cc:cc_library.bzl", "cc_library")


directory(
  name = "files",
  srcs = glob(["**"]),
  visibility = ["//visibility:public"]
)

native_binary(
  name = "qmake",
  src = "bin/qmake",
  data = glob(["**"]),
  out = "qmake",
  visibility = ["//visibility:public"]
)

exports_files(["lib", "include"])

cc_library(
  name = "qt_hdrs",
  hdrs = glob(["include/**"]),
  includes = ["include"],
  visibility = ["//visibility:public"],
)

{libs}
"""

LIB_TEMPLATE = """
cc_library(
    name = "{framework}",
    hdrs = glob(["lib/{framework}.framework/Headers/**"], allow_empty = True),
    includes = [
        "include",
        "lib/{framework}.framework/Headers",
        "lib/{framework}.framework/Headers/6.12.0",
        "lib/{framework}.framework/Headers/6.12.0/{framework}",
    ],
    defines = select({{
        "@platforms//cpu:aarch64": ["__yield=__builtin_arm_yield"],
        "//conditions:default": [],
    }}),
    additional_linker_inputs = [":lib"],
    linkopts = ["-F $(location :lib)"] + [
        "-framework {framework}",
        "-rpath $(rootpath :lib)",
    ],
    include_prefix = "{framework}",
    strip_include_prefix = "lib/{framework}.framework/Headers",
    target_compatible_with = ["@platforms//os:osx"],
    visibility = ["//visibility:public"],
    data = [
      "lib/{framework}.framework/{framework}",
      "lib/{framework}.framework/Versions/A/{framework}",
    ]
)
"""

BASE_URL = "https://download.qt.io/online/qtsdkrepository/mac_x64/desktop"

def _qt_download_impl(repo_ctx):

  libs = ["QtCore", "QtTest", "QtQml", "QtGui", "QtNetwork", "QtQuickTest", "QtQuick"]
  
  templates = []
  for f in libs:
    templates.append(LIB_TEMPLATE.format(framework = f))
  
  libs = "\n".join(templates)

  repo_ctx.download_and_extract(
    url = BASE_URL + "/qt6_6120/qt6_6120/qt.qt6.6120.clang_64/6.12.0-0-202609280346qtbase-MacOS-MacOS_26-Clang-MacOS-MacOS_26-X86_64-ARM64.7z"
  )
  repo_ctx.download_and_extract(
    url = BASE_URL + "/qt6_6120/qt6_6120/qt.qt6.6120.clang_64/6.12.0-0-202609280346qtdeclarative-MacOS-MacOS_26-Clang-MacOS-MacOS_26-X86_64-ARM64.7z"
  )
  repo_ctx.download_and_extract(
    url = BASE_URL + "/qt6_6120/qt6_6120/qt.qt6.6120.clang_64/6.12.0-0-202609280346qttools-MacOS-MacOS_26-Clang-MacOS-MacOS_26-X86_64-ARM64.7z"
  )

  for binary in repo_ctx.path("bin").readdir():
    repo_ctx.execute(["chmod", "+x", "%s" % binary])
  
  for binary in repo_ctx.path("libexec").readdir():
    repo_ctx.execute(["chmod", "+x", "%s" % binary])

  lib_dir = repo_ctx.path("lib")

  for framework in lib_dir.readdir():
    if not ("%s" % framework).endswith(".framework"):
      continue

    framework = framework.basename
    framework_name = framework.split(".")[0]
    repo_ctx.delete("lib/%s/Headers" % framework)
    repo_ctx.delete("lib/%s/Resources" % framework)
    repo_ctx.delete("lib/%s/%s" % (framework, framework_name))
    repo_ctx.symlink("lib/%s/Versions/A/Headers" % framework, "lib/%s/Headers" % framework)
    repo_ctx.symlink("lib/%s/Versions/A/Resources" % framework, "lib/%s/Resources" % framework)
    repo_ctx.symlink("lib/%s/Versions/A/%s" % (framework, framework_name), "lib/%s/%s" % (framework, framework_name))



  repo_ctx.file("BUILD.bazel", content = TEMPLATE.format(libs = libs))


qt_download = repository_rule(
  implementation = _qt_download_impl
)


