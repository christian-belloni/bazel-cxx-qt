load("@cxx-qt-bazel//cxx-qt-bazel:generate.bzl", generate = "cxx_qt_cmd")

def cxx_qt(*, name, visibility = []):  
  generate(
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
    visibility = visibility,
    qt_modules = ["Core", "Quick", "QuickControls2"]
  )
