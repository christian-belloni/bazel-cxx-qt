load("@rules_cc//cc:find_cc_toolchain.bzl", "use_cc_toolchain")#, "find_cc_toolchain")
load("@rules_cc//cc:cc_library.bzl", "cc_library")
# load("@rules_cc//cc/common:cc_common.bzl", "cc_common")
# load("@rules_cc//cc:action_names.bzl", "C_COMPILE_ACTION_NAME")

# bazel run //:cxxqtcmd -- \
#   --out-dir $(pwd)/target/tmp/cxx-qt \
#   --qmake $(which qmake) \
#   --host-triple aarch64-apple-darwin \
#   --target-triple aarch64-apple-darwin \
#   --opt-level 3 \
#   --file $CXX_QT_ROOT/crates/cxx-qt/src/connection.rs \
#   --file $CXX_QT_ROOT/crates/cxx-qt/src/qobject.rs \
#   --crate-directory $CXX_QT_ROOT/crates/cxx-qt \
#   --crate-include-root include \
#   --cpp-file $CXX_QT_ROOT/crates/cxx-qt/src/connection.cpp \
#   --crate-name cxx-qt \
#   --initializer "init_cxx_qt_core;$CXX_QT_ROOT/crates/cxx-qt/src/init.cpp"
#
#
#   --extra-header-file $(pwd)/target/tmp/cxx-qt-lib/include/cxx-qt-lib/definitions.h \
#   --extra-header-line "#define CXX_QT_GUI_FEATURE" \
#   --extra-header-line "#define CXX_QT_QML_FEATURE" \
#   --extra-header-line "#define CXX_QT_QUICKCONTROLS_FEATURE" \

CxxQtInclude = provider("",
  fields = ["include"]
)

def _cxx_qt_cmd_impl(ctx):
  out_lib = ctx.actions.declare_file("out/lib%s-cxxqt-generated.a" % ctx.attr.crate_name)
  init_lib = ctx.actions.declare_file("out/libcxx-qt-call-init-crate_%s.a" % ctx.attr.crate_name.replace("-", "_"))
  cxx_header = ctx.actions.declare_file("out/cxxqtbuild/include/rust/cxx.h")
  toml_dir = ctx.file.cargo_toml.dirname
  args = ctx.actions.args()
  out_dir = out_lib.dirname
  args.add("--out-dir", out_dir)
  args.add("--qmake", "/opt/homebrew/bin/qmake")
  args.add("--host-triple", "aarch64-apple-darwin")
  args.add("--target-triple", "aarch64-apple-darwin")
  args.add("--opt-level", "3")
  args.add("--crate-directory", toml_dir)
  args.add("--crate-name", ctx.attr.crate_name)
  args.add("--crate-include-root", ctx.attr.crate_include_root)

  
  for bridge in ctx.files.bridge_files:
    args.add("--file", bridge)
  for cpp in ctx.files.cpp_files:
    args.add("--cpp-file", cpp)

  for k in ctx.attr.initializers:
    v = ctx.attr.initializers[k][DefaultInfo].files.to_list()[0]
    args.add("--initializer", "%s;%s" % (k, v.path))

  include_headers = []

  for header in ctx.files.crate_include_files:
    basepath = ctx.file.cargo_toml.dirname
    header_path = header.path.removeprefix("%s/%s" % (basepath, ctx.attr.crate_include_root))
    include_header = ctx.actions.declare_file("headers/include/%s/%s" % (ctx.attr.crate_name, header_path))
    cp_args = ctx.actions.args()
    cp_args.add(header)
    cp_args.add(include_header)
    out = [include_header]

    ctx.actions.run_shell(
      inputs = ctx.files.srcs,
      outputs = out,
      command = "cp -a %s %s" % (header.path, include_header.path),
    )
    include_headers += out

  # We change current directory while compiling, adjust the include directory accordingly
  prefix = "/".join([ ".." for _ in toml_dir.split("/") ])
  flags = ""
  if len(include_headers) != 0:
    flags = "-I %s/%s" % (prefix, include_headers[0].dirname.removesuffix("/%s" % ctx.attr.crate_name))

  additional_files = []
  for dependency in ctx.attr.cxxqt_dependency:
    dep = dependency[CxxQtInclude]
    files = dep.include.to_list()
    tmp = files[0].path.split("/")
    tmp.pop()
    tmp.pop()
    dep = "/".join(tmp)

    args.add("--cxxqt-dependency", dep)
    additional_files += files

  if ctx.attr.include_prefix != None:
    args.add("--include-prefix", ctx.attr.include_prefix)
  
  extra_headers = []
  for filename, content in ctx.attr.extra_headers.items():
    header = ctx.actions.declare_file("out/cxxqtbuild/%s" % filename)
    args.add("--extra-header-file", header)
    extra_headers.append(header)
    
    for line in content:
      args.add("--extra-header-line", line)

  for module_name, qml_files in ctx.attr.qml_modules.items():
    args.add("--new-qml-module", module_name)
    for f in qml_files:
      args.add("--qml-file", f)

  ctx.actions.run(
    outputs = [out_lib, init_lib, cxx_header] + extra_headers,
    inputs = ctx.files.srcs + include_headers + additional_files,# + toolchain.all_files.to_list(),
    executable = ctx.executable._tool,
    arguments = [args],
    env = {
      "CXXFLAGS": flags
    }
  )

  providers = [DefaultInfo(files = depset([out_lib, init_lib]))]
  if len(include_headers + extra_headers) != 0:
    providers += [CxxQtInclude(include = depset(include_headers + extra_headers))]

  return providers



_cxx_qt_cmd = rule(
  implementation = _cxx_qt_cmd_impl,
  attrs = {
    "crate_name": attr.string(mandatory = True),
    "srcs": attr.label_list(allow_files = True),
    "cargo_toml": attr.label(allow_single_file = True, mandatory = True),
    "bridge_files": attr.label_list(allow_files = True),
    "cpp_files": attr.label_list(allow_files = True),
    "initializers": attr.string_keyed_label_dict(allow_files = True),
    "crate_include_root": attr.string(),
    "crate_include_files": attr.label_list(allow_files = True),
    "include_dirs": attr.string_list(),
    "qt_modules": attr.string_list(),
    "include_prefix": attr.string(),
    "cxxqt_dependency": attr.label_list(providers = [CxxQtInclude]),
    "extra_headers": attr.string_list_dict(),
    "qml_modules": attr.string_list_dict(),
    # "qmake": attr.label(allow_single_file = True, mandatory = True, executable = True, cfg = "exec"),
    "_tool": attr.label(executable = True, cfg = "exec", default = Label("@bazel-cxx-qt//:cxxqtcmd"))
  },
  fragments = ["cpp"],
  toolchains = use_cc_toolchain()
)

def cxx_qt_cmd(*, name, visibility, **kwargs):
  _cxx_qt_cmd(name = name, visibility = visibility, **kwargs)
  cc_library(
    name = "%s-cc" % name,
    srcs = [":%s" % name],
    visibility = visibility,
  )
