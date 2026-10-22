load(":repository.bzl", _qt_download = "qt_download")




def _qt_download_impl(_mod_ctx):
  _qt_download(
    name = "qt",
  )

qt_download = module_extension(
  implementation = _qt_download_impl
)
