load("@cxx-qt-bazel//cxx-qt-bazel:cmd.bzl", "cxx_qt_cmd")
load("@rules_cc//cc:cc_library.bzl", "cc_library")

def cxx_qt(*, name, visibility = []):
  cxx_qt_cmd(
    name = name,
    crate_name = "cxx-qt",
    srcs = native.glob(["include/**", "src/**", "Cargo.toml"], allow_empty = True),
    crate_include_root = "include",
    crate_include_files = native.glob(["include/**"], allow_empty = True),
    cargo_toml = "Cargo.toml",
    bridge_files = ["src/connection.rs", "src/qobject.rs"],
    cpp_files = ["src/connection.cpp"],
    initializers = {
      "init_cxx_qt_core": "src/init.cpp"
    },
    qt = "@qt//:files",
    visibility = visibility,
  )
  
  cc_library(
    name = name + "-generated",
    srcs = [name],
    additional_linker_inputs = ["@qt//:lib"],
    linkopts = ["-F$(location @qt//:lib)", "-framework QtCore", "-Wl"],
    linkstatic = True,
    visibility = visibility,
    deps = [name + "-hdrs"],
    # data = ["@qt//:lib"]
  )
