load("@cxx.rs//tools/bazel:rust_cxx_bridge.bzl", "rust_cxx_bridge")
load("@rules_cc//cc:cc_library.bzl", "cc_library")

bridge_files = [
  "src/dynamicmetaobjectbuilder.rs",
  "src/dynamicmetaobjectdata.rs",
  "src/qmetatypeget.rs",
  "src/qmlprivate.rs",
  "src/qresource.rs",
  "src/registry.rs",
  "src/rustobjectgetter.rs",
  "src/qml_method_invoker.rs",
]

cpp_files = [
  "src/cpp/dynamicmetaobjectbuilder.cpp",
  "src/cpp/dynamicmetaobjectdata.cpp",
  #"src/cpp/qmetatypeget.cpp",
  "src/cpp/qmlprivate.cpp",
  "src/cpp/qresource.cpp",
  "src/cpp/registry.cpp",
  "src/cpp/rustobjectgetter.cpp",
  "src/cpp/qml_method_invoker.cpp",
]

def qtbridge_runtime(*, name, visibility = [], rustconv, crates_hub, qtbridge_type_lib):
  [
  rust_cxx_bridge(
    name = src.replace(".rs", "-cc"),
    src = src,
    deps = ["_cc_files_" + name],
  )
    for src in bridge_files
  ]
  
  cc_library(
    name = "_generated_" + name,
    srcs = [ src + ".cc" for src in bridge_files ],
    hdrs = [src + ".h" for src in bridge_files],
    deps = ["_cc_files_" + name],
    include_prefix = "qtbridge-runtime"
  )
  
  cc_library(
    name = name,
    srcs = cpp_files,
    deps = [ "_generated_" + name ],
    linkstatic = True,
    visibility = visibility,
  )
  
  cc_library(
    name = "_cc_files_" + name,
    # srcs = cpp_files,
    hdrs = native.glob(["**/*.h"], allow_empty = True),
    includes = ["src", "."],
    include_prefix = "qtbridge-runtime",
    linkstatic = True,
    deps = [
      crates_hub + "//:" + rustconv,
      "@cxx.rs//:core", 
      "@qt//:QtCore",
      "@qt//:QtTest",
      "@qt//:QtQml",
      "@qt//:QtGui",
      "@qt//:QtNetwork",
      "@qt//:qt_hdrs",
      crates_hub + "//:" + qtbridge_type_lib
    ],
  )
