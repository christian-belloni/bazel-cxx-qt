load("//cxx-qt-bazel/private:qtbridge-type-lib.bzl", _qtbridge_type_lib = "qtbridge_type_lib")
load("//cxx-qt-bazel/private:qtbridge-runtime.bzl", _qtbridge_runtime = "qtbridge_runtime")
load("//cxx-qt-bazel/private:qtbridge-interfaces.bzl", _qtbridge_interfaces = "qtbridge_interfaces")
load("//cxx-qt-bazel/private:cxx-qt.bzl", _cxx_qt = "cxx_qt")
load("//cxx-qt-bazel/private:cxx-qt-lib.bzl", _cxx_qt_lib = "cxx_qt_lib")
load("//cxx-qt-bazel/private:cxx.bzl", _cxx = "cxx")

qtbridge_type_lib = _qtbridge_type_lib
qtbridge_runtime = _qtbridge_runtime
qtbridge_interfaces = _qtbridge_interfaces
cxx_qt = _cxx_qt
cxx_qt_lib = _cxx_qt_lib
cxx = _cxx

def build_scripts(*, prefix, visibility = [], crates_hub = "@crates", rustconv = "rustconv"):
  cxx(name = prefix + "_cxx", visibility = visibility)
  cxx_qt(name = prefix + "_cxx-qt", visibility = visibility)
  cxx_qt_lib(
    name = prefix + "_cxx-qt-lib",
    features = ["full"],
    cxx_qt =  crates_hub + "//:" + prefix + "_cxx-qt",
    visibility = visibility,
  )
  qtbridge_type_lib(
    name = prefix + "_qtbridge_type_lib", 
    visibility = visibility, 
    cxx_qt_lib = crates_hub + "//:" + prefix + "_cxx-qt-lib-generated",
    rustconv_lbl = rustconv,
  )
  qtbridge_runtime(
    name = prefix + "_qtbridge_runtime", 
    visibility = visibility, 
    crates_hub = crates_hub, 
    rustconv = rustconv,
    qtbridge_type_lib = prefix + "_qtbridge_type_lib"
  )
  qtbridge_interfaces(
    name = prefix + "_qtbridge_interfaces", 
    visibility = visibility,
    crates_hub = crates_hub, 
    rustconv = "rustconv",
    qtbridge_runtime = prefix + "_qtbridge_runtime",
  ) 
