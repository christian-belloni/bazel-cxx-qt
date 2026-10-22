load("@rules_cc//cc:find_cc_toolchain.bzl", "use_cc_toolchain")#, "find_cc_toolchain")
load("@rules_cc//cc:cc_library.bzl", "cc_library")
load("@bazel_skylib//rules/directory:providers.bzl", "DirectoryInfo")
load(":providers.bzl", "CxxQtInclude")

def _cxx_qt_cmd_impl(ctx):
  out_lib = ctx.actions.declare_file("out/lib%s-cxxqt-generated.a" % ctx.attr.crate_name)
  init_lib = ctx.actions.declare_file("out/libcxx-qt-call-init-crate_%s.a" % ctx.attr.crate_name.replace("-", "_"))
  cxx_header = ctx.actions.declare_file("out/cxxqtbuild/include/rust/cxx.h")
  toml_dir = ctx.file.cargo_toml.dirname
  args = ctx.actions.args()
  out_dir = out_lib.dirname

  qt = ctx.attr.qt[DirectoryInfo]

  args.add("--out-dir", out_dir)
  args.add("--qmake", "%s/bin/qmake" % qt.path)
  args.add("--host-triple", "aarch64-apple-darwin")
  args.add("--target-triple", "aarch64-apple-darwin")
  args.add("--opt-level", "3")
  args.add("--crate-directory", toml_dir)
  args.add("--crate-name", ctx.attr.crate_name)
  if ctx.attr.crate_include_root != "":
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

  args.add("build")
  ctx.actions.run(
    outputs = [out_lib, init_lib, cxx_header] + extra_headers,
    inputs = ctx.files.srcs + include_headers + additional_files + qt.glob(["**"]).to_list(),# + toolchain.all_files.to_list(),
    executable = ctx.executable._tool,
    arguments = [args],
    env = {
      "CXXFLAGS": flags
    },
  )

  copied_extra_headers = []
  for extra_header in extra_headers:
    filename = extra_header.basename
    new_file = ctx.actions.declare_file("headers/include/%s/%s" % (ctx.attr.crate_name, filename))
    copied_extra_headers.append(new_file)
    ctx.actions.run_shell(
      command = "cp %s %s" % (extra_header.path, new_file.path),
      inputs = [extra_header],
      outputs = [new_file],
    )
    

  providers = [DefaultInfo(files = depset([out_lib, init_lib]))]
  if len(include_headers + extra_headers) != 0:
    providers += [CxxQtInclude(include = depset(include_headers + copied_extra_headers))]

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
    "qt": attr.label(providers = [DirectoryInfo]),
    "_tool": attr.label(executable = True, cfg = "exec", default = Label("@cxx-qt-bazel//:cxxqtcmd"))
  },
  fragments = ["cpp"],
  toolchains = use_cc_toolchain()
)


def _extract_headers_impl(ctx):
  include = ctx.attr.cxx_qt_cmd[CxxQtInclude]
  return DefaultInfo(files = include.include)

_extract_headers = rule(
  implementation = _extract_headers_impl,
  attrs = {
    "cxx_qt_cmd": attr.label(providers = [CxxQtInclude])
  }
)

def cxx_qt_cmd(*, name, visibility = [], **kwargs):
  _cxx_qt_cmd(name = name, visibility = visibility, **kwargs)
  _extract_headers(
    name = "%s-files" % name,
    cxx_qt_cmd = name,
    visibility = visibility,
  )

  cc_library(
    name = "%s-hdrs" % name,
    hdrs = ["%s-files" % name],
    visibility = visibility,
    strip_include_prefix = "headers/include"
  )

  cc_library(
    name = "%s-cc" % name,
    srcs = [":%s" % name],
    visibility = visibility,
    deps = ["%s-hdrs"]
  )
