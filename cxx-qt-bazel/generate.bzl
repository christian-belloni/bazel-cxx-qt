load("@rules_cc//cc:find_cc_toolchain.bzl", "use_cc_toolchain")#, "find_cc_toolchain")
load("@rules_cc//cc:cc_library.bzl", "cc_library")
load("@bazel_skylib//rules/directory:providers.bzl", "DirectoryInfo")
load(":providers.bzl", "CxxQtInclude", "CxxQtQmlPlugin")

def _out_path(ctx, path):
  return ctx.actions.declare_file("%s/out/%s" % (ctx.label.name, path))

def _copy_include_files(ctx):
  include_headers = []
  for header in ctx.files.crate_include_files:
    basepath = ctx.file.cargo_toml.dirname
    header_path = header.path.removeprefix("%s/%s" % (basepath, ctx.attr.crate_include_root))
    include_header = _out_path(ctx, "cxxqtbuild/include/%s/%s" % (ctx.attr.crate_name, header_path))
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
  return include_headers

def _generated_sources(*, ctx, args, include_prefix, toml_dir):
  generated_headers = []
  generated_cpps = []

  for bridge in ctx.files.bridge_files:
    args.add("--file", bridge)
    relative_path = bridge.path.removeprefix("%s/" % toml_dir)
    new_header = _out_path(ctx, "cxxqtbuild/include/%s/%s" % (include_prefix, relative_path.replace(".rs", ".cxx.h")))
    new_cxxqt_header = _out_path(ctx, "cxxqtbuild/include/%s/%s" % (include_prefix, relative_path.replace(".rs", ".cxxqt.h")))
    generated_headers.append(new_header)
    generated_headers.append(new_cxxqt_header)
    new_cpp = _out_path(ctx, "cxxqtgen/%s" % relative_path.replace(".rs", ".cxx.cpp"))
    generated_cpps.append(new_cpp)
  return (generated_headers, generated_cpps)

def _generate_qml_module(ctx, args):
  moc_files = []
  if len(ctx.attr.qml_modules) != 0 and ctx.attr.include_builtins:
    moc_builtins = _out_path(ctx, "moc/moc_builtins.h.cpp")
    builtins = _out_path(ctx, "builtins.h")
    moc_files += [builtins, moc_builtins]

  moc_plugin_headers = []
  for module_name, qml_files in ctx.attr.qml_modules.items():
    args.add("--new-qml-module", module_name)
    public = _out_path(ctx,
      "cxx-qt-build/initializers/qml_module_%s/public-initializer.cpp" % module_name.replace(".", "_")
    )
    call = _out_path(ctx,
      "cxx-qt-build/initializers/qml_module_%s/call-initializers.cpp" % module_name.replace(".", "_")
    )
    mod = _out_path(ctx, "rcc/qml_module_resources_%s.cpp" % module_name.replace(".", "_"))
    res = _out_path(ctx, "qt-build-utils/qml_plugin/%s_plugin.cpp" % module_name.replace(".", "_"))
    moc_plugin = _out_path(ctx, "moc/moc_%s_plugin.cpp.cpp" % module_name.replace(".", "_"))
    typeregister = _out_path(ctx, "qmltyperegistrar/%s_qmltyperegistration.cpp" % module_name.replace(".", "_"))

    cachegen = _out_path(ctx, "qmlcachegen/%s/qmlcache_loader.cpp" % module_name.replace(".", "/"))
    moc_files += [public, call, mod, res, typeregister, cachegen]
    moc_plugin_headers.append(moc_plugin)
    for f in qml_files:
      args.add("--qml-file", f)
      qml = _out_path(ctx, "qmlcachegen/%s/%s.cpp" % (module_name.replace(".", "/"), f.split("/").pop()))
      moc_files.append(qml)
  return (moc_files, moc_plugin_headers)

def _generate_extra_headers(ctx, args):
  extra_headers = []
  for filename, content in ctx.attr.extra_headers.items():
    header = _out_path(ctx, "include/%s/%s" % (ctx.attr.crate_name, filename))
    args.add("--extra-header-file", header)
    extra_headers.append(header)
    
    for line in content:
      args.add("--extra-header-line", line)
  return extra_headers

def _cxx_qt_cmd_impl(ctx):
  cxx_header = _out_path(ctx, "cxxqtbuild/include/rust/cxx.h")
  toml_dir = ctx.file.cargo_toml.dirname
  args = ctx.actions.args()
  out_dir = cxx_header.path.removesuffix("/cxxqtbuild/include/rust/cxx.h")

  args.add("--out-dir", out_dir)
  
  info = ctx.toolchains["@cxx-qt-bazel//toolchains:toolchain_type"].qtinfo

  args.add("--qmake", info.qmake.files_to_run.executable.path)
 
  args.add("--crate-directory", toml_dir)
  args.add("--crate-name", ctx.attr.crate_name)
  if ctx.attr.crate_include_root != "":
    args.add("--crate-include-root", ctx.attr.crate_include_root)
  
  if ctx.attr.include_prefix != None:
    args.add("--include-prefix", ctx.attr.include_prefix)

  include_prefix = ctx.attr.crate_name

  if not ctx.attr.include_prefix.isspace():
    include_prefix = ctx.attr.include_prefix

  (generated_headers, generated_cpps) = _generated_sources(
    ctx = ctx,
    args = args,
    include_prefix = include_prefix,
    toml_dir = toml_dir
  )

  for k in ctx.attr.initializers:
    v = ctx.attr.initializers[k][DefaultInfo].files.to_list()[0]
    args.add("--initializer", "%s;%s" % (k, v.path))

  include_headers = _copy_include_files(ctx)
  
  extra_headers = _generate_extra_headers(ctx, args)

  (moc_files, moc_plugin_headers) = _generate_qml_module(ctx, args)

  args.add("generate")

  public_initializer = _out_path(ctx, "cxx-qt-build/initializers/crate_%s/public-initializer.cpp" % ctx.attr.crate_name.replace("-", "_"))

  initializer = _out_path(ctx, "cxx-qt-build/initializers/crate_%s/call-initializers.cpp" % ctx.attr.crate_name.replace("-", "_"))

  ctx.actions.run(
    outputs = [cxx_header] + extra_headers + generated_headers + generated_cpps + [public_initializer, initializer] + moc_files + moc_plugin_headers,
    inputs = ctx.files.srcs + include_headers,
    executable = info.cxxqtbuild.files_to_run.executable,
    arguments = [args],
    mnemonic = "CxxQtGenerate",
    tools = [info.qmake.files_to_run]
  )

  files = [cxx_header] + include_headers + extra_headers + generated_headers + generated_cpps + moc_files
  files = depset(files, transitive = [depset(ctx.files.cpp_files)])

  providers = [DefaultInfo(files = files), CxxQtQmlPlugin(plugin_headers = depset(moc_plugin_headers))]
  providers += [CxxQtInclude(include = depset([]))]

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
    "extra_headers": attr.string_list_dict(),
    "qml_modules": attr.string_list_dict(),
    "include_builtins": attr.bool(default = True),
  },
  fragments = ["cpp"],
  toolchains = use_cc_toolchain() + ["@cxx-qt-bazel//toolchains:toolchain_type"]
)

def _extract_plugin_headers_impl(ctx):
  include = ctx.attr.cxx_qt_cmd[CxxQtQmlPlugin]
  return DefaultInfo(files = include.plugin_headers)

_extract_plugin_headers = rule(
  implementation = _extract_plugin_headers_impl,
  attrs = {
    "cxx_qt_cmd": attr.label(providers = [CxxQtQmlPlugin])
  }
)

def cxx_qt_cmd(*, name, visibility = [], qt_modules = [], cc_deps = [], **kwargs):
  _cxx_qt_cmd(name = name + "-gen", visibility = visibility, qt_modules = qt_modules, **kwargs)
  _extract_plugin_headers(
    name = "_plugin_headers_%s" % name,
    cxx_qt_cmd = name + "-gen",
  )
  cc_library(
    name = name,
    srcs = [name + "-gen"],
    hdrs = ["_plugin_headers_%s" % name],
    visibility = visibility,
    includes = [
      "%s-gen/out/cxxqtbuild/include" % name,
      "%s-gen/out/include" % name,
      "%s-gen/out/moc" % name,
    ],
    alwayslink = True,
    linkstatic = True,
    defines = ["QT_STATICPLUGIN"],
    deps = [ "@qt//:Qt%s" % mod for mod in qt_modules ] + [ "@qt//:qt_hdrs" ] + [ "%s" % dep for dep in cc_deps ]
  )

 
