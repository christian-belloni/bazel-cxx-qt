load("@cxx-qt-bazel//cxx-qt-bazel:generate.bzl", generate = "cxx_qt_cmd")
load("@rules_cc//cc:cc_library.bzl", "cc_library")


def qml_module(
  *, 
  name, 
  crate_name, 
  modules, 
  visibility = [], 
):
  include_builtins = True
  for module, files in modules.items():
    generate(
      name = name + "_" + module,
      srcs = native.glob(["**"]),
      crate_name = crate_name,
      cargo_toml = "Cargo.toml",
      qml_modules = {
        module: files
      },
      qt_modules = ["Core", "Qml", "Network"],
      include_builtins = include_builtins,
    )
    include_builtins = False
  cc_library(
    name = name,
    deps = [ name + "_" + module for module in modules ],
    visibility = visibility
  )
