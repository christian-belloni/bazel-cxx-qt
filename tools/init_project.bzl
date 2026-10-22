
tpl = """
#!/bin/sh

mkdir -p $1

touch $1/BUILD

echo '''load("@cxx-qt-bazel//cxx-qt-bazel:build_scripts.bzl", "build_scripts")

build_scripts(
  prefix = "{prefix}",
  visibility = ["//visibility:public"],
  crates_hub = "@{crates_hub}",
  rustconv = "rustconv",
)
''' > $1/qt.additive.BUILD

echo '''bazel_dep(name = "cxx.rs", version = "1.0.205")

qt_download = use_extension("@cxx-qt-bazel//cxx-qt-bazel:extensions.bzl", "qt_download")
use_repo(qt_download, "qt")

crate = use_extension("@rules_rs//rs:extensions.bzl", "crate")

crate.annotation(
  crate = "cxx",
  gen_build_script = "off",
  additive_build_file = "//third_party:qt.additive.BUILD",
  extra_aliased_targets = {{
    "{prefix}_cxx": "{prefix}_cxx",
  }},
  link_deps = ["@{crates_hub}//:{prefix}_cxx"]
)

crate.annotation(
  crate = "cxx-qt",
  additive_build_file = "//third_party:qt.additive.BUILD",
  extra_aliased_targets = {{
    "{prefix}_cxx-qt": "{prefix}_cxx-qt",
    "{prefix}_cxx-qt-generated": "{prefix}_cxx-qt-generated",
  }},
  rustc_flags = ["--cfg", "cxxqt_qt_version_major=\\"6\\""],
  gen_build_script = "off",
  link_deps = ["@{crates_hub}//:{prefix}_cxx-qt-generated"],
)

crate.annotation(
  crate = "cxx-qt-lib",
  additive_build_file = "//third_party:qt.additive.BUILD",
  extra_aliased_targets = {{
    "{prefix}_cxx-qt-lib-generated": "{prefix}_cxx-qt-lib-generated",
  }},
  rustc_flags = ["--cfg", "cxxqt_qt_version_major=\\"6\\""],
  gen_build_script = "off",
  link_deps = ["@{crates_hub}//:{prefix}_cxx-qt-lib-generated"],
)

crate.annotation(
  crate = "qtbridge-type-lib",
  gen_build_script = "off",
  additive_build_file = "//third_party:qt.additive.BUILD",
  extra_aliased_targets = {{
    "{prefix}_qtbridge_type_lib": "{prefix}_qtbridge_type_lib",
    "rustconv": "rustconv",
  }},
  link_deps = ["@{crates_hub}//:{prefix}_qtbridge_type_lib"],
)

crate.annotation(
  crate = "qtbridge-runtime",
  gen_build_script = "off",
  additive_build_file = "//third_party:qt.additive.BUILD",
  extra_aliased_targets = {{
    "{prefix}_qtbridge_runtime": "{prefix}_qtbridge_runtime",
  }},
  link_deps = ["@{crates_hub}//:{prefix}_qtbridge_runtime"],
)

crate.annotation(
  crate = "qtbridge-interfaces",
  gen_build_script = "off",
  additive_build_file = "//third_party:qt.additive.BUILD",
  extra_aliased_targets = {{
    "{prefix}_qtbridge_interfaces": "{prefix}_qtbridge_interfaces",
  }},
  link_deps = ["@{crates_hub}//:{prefix}_qtbridge_interfaces"],
)

inject_repo(crate, "cxx-qt-bazel")
inject_repo(crate, "qt")
inject_repo(crate, "cxx.rs")
''' > $1/include.MODULE.bazel

echo "Project generation successfull, add:\n"
echo "  include(\\"//third_party:include.MODULE.bazel\\")\n"
echo "to your MODULE.bazel"
"""


def _qtbridge_project_impl(ctx):
  script = ctx.actions.declare_file(ctx.label.name)
  script_template = tpl.format(
    prefix = ctx.attr.prefix,
    crates_hub = ctx.attr.crates_hub
  )
  ctx.actions.write(script, script_template, is_executable = True)

  print(ctx.file._build)
  return DefaultInfo(executable = script)

qtbridge_project = rule(
  implementation = _qtbridge_project_impl,
  attrs = {
    "prefix": attr.string(mandatory = True),
    "crates_hub": attr.string(mandatory = True),
    "_build": attr.label(allow_single_file = True, default = "BUILD")
  },
  executable = True,
)
