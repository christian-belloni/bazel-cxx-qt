load("@cxx.rs//tools/bazel:rust_cxx_bridge.bzl", "rust_cxx_bridge")
load("@rules_cc//cc:cc_library.bzl", "cc_library")

bridge_files = [
    "src/generated/core/qmetaobject/qmetaobject.rs",
    "src/generated/core/qmetatype/qmetatype.rs",
    "src/generated/core/qmetatypeinterface/qmetatypeinterface.rs",
    "src/generated/core/qobject/qobject.rs",
    "src/generated/core/qqmllistproperty/qqmllistproperty.rs",
    "src/generated/testlib/qsignalspy/qsignalspy.rs",
]

cpp_files = [
    "src/generated/core/qmetaobject/cpp/qmetaobject.cpp",
    "src/generated/core/qmetatype/cpp/qmetatype.cpp",
    "src/generated/core/qmetatypeinterface/cpp/qmetatypeinterface.cpp",
    "src/generated/core/qobject/cpp/qobject.cpp",
    "src/generated/core/qqmllistproperty/cpp/qqmllistproperty.cpp",
    "src/generated/testlib/qsignalspy/cpp/qsignalspy.cpp",
]

def qtbridge_type_lib(*, name, visibility = [], cxx_qt_lib, rustconv_lbl):
  cc_library(
    name = rustconv_lbl,
    includes = ["src"],
    hdrs = ["src/rustconv.h"],
    visibility = ["//visibility:public"],
  )
  
  [
  rust_cxx_bridge(
    name = src.replace(".rs", "-cc"),
    src = src,
    deps = ["_cc_files_" + name, cxx_qt_lib],
  )
    for src in bridge_files
  ]
  
  cc_library(
    name = name,
    deps = [ src.replace(".rs", "-cc") for src in bridge_files ],
    linkstatic = True,
    visibility = visibility,
  )
  
  cc_library(
    name = "_cc_files_" + name,
    srcs = cpp_files,
    hdrs = native.glob(["**/*.h"], allow_empty = True),
    include_prefix = "qtbridge-type-lib",
    linkstatic = True,
    deps = [
      "@cxx.rs//:core", 
      rustconv_lbl, 
      "@qt//:QtCore",
      "@qt//:QtTest",
      "@qt//:QtQml",
      "@qt//:QtGui",
      "@qt//:QtNetwork",
    ],
  )
