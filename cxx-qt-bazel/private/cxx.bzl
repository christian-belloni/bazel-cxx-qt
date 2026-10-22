load("@rules_cc//cc:cc_library.bzl", "cc_library")

def cxx(*, name, visibility):
  cc_library(
    name = name,
    srcs = ["src/cxx.cc", "include/cxx.h"],
    visibility = visibility,
    linkstatic = True,
  )
