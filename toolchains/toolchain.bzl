QtToolchainInfo = provider(
  fields = ["qmake", "cxxqtbuild"]
)

def _qt_toolchain_impl(ctx):
  return platform_common.ToolchainInfo(
    qtinfo = QtToolchainInfo(
      qmake = ctx.attr.qmake[DefaultInfo],
      cxxqtbuild = ctx.attr._cxxqtbuild[DefaultInfo],
    )
  )

qt_toolchain = rule(
  implementation = _qt_toolchain_impl,
  attrs = {
    "qmake": attr.label(executable = True, mandatory = True, cfg = "exec"),
    "_cxxqtbuild": attr.label(executable = True, default = "@cxx-qt-bazel//:cxxqtcmd", cfg = "exec")
  }
)
