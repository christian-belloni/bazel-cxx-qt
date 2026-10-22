load("@cxx.rs//tools/bazel:rust_cxx_bridge.bzl", "rust_cxx_bridge")
load("@rules_cc//cc:cc_library.bzl", "cc_library")

bridge_files = [
    "src/qabstract_item_model/proxy_cpp_bridge.rs",
    "src/qabstract_item_model/proxy_rust_bridge.rs",
    "src/qlist_model/proxy_cpp_bridge.rs",
    "src/qlist_model/proxy_rust_bridge.rs",
    "src/qobject/proxy_cpp_bridge.rs",
    "src/qobject/proxy_rust_bridge.rs",
    "src/qparser_status/proxy_cpp_bridge.rs",
    "src/qparser_status/proxy_rust_bridge.rs",
    "src/qtable_model/proxy_cpp_bridge.rs",
    "src/qtable_model/proxy_rust_bridge.rs",
]
cpp_files = [
    "src/qabstract_item_model/cpp/QAbstractItemModelProxyCpp.cpp",
    "src/qlist_model/cpp/QListModelProxyCpp.cpp",
    "src/qobject/cpp/QObjectProxyCpp.cpp",
    "src/qparser_status/cpp/QParserStatusProxyCpp.cpp",
    "src/qtable_model/cpp/QTableModelProxyCpp.cpp",
]

def qtbridge_interfaces(*, name, rustconv, crates_hub, qtbridge_runtime, visibility = []):
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
    include_prefix = "qtbridge-interfaces"
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
    include_prefix = "qtbridge-interfaces",
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
      crates_hub + "//:" + qtbridge_runtime,
    ],
  )
