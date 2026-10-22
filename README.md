# CXX-QT-Bazel

cxx-qt-bazel is a wrapper on [cxx-qt](https://github.com/KDAB/cxx-qt) to enable bazel based projects to compile cxx-qt-\* crates and qtbridge-\* crates

## Quickstart

### Add a dependency on cxx-qt-bazel:

 - MODULE.bazel
 ```starlark
bazel_dep(name = "cxx-qt-bazel")

git_override(
  module_name = "cxx-qt-bazel",
  remote = "https://github.com/christian-belloni/cxx-qt-bazel.git",
  branch = "master"
)
 ```

### Define the project generator

 - BUILD.bazel
 ```starlark
load("@cxx-qt-bazel//tools:init_project.bzl", "qtbridge_project")

qtbridge_project(
  name = "refresh_project",
  crates_hub = "crates",
  prefix = "_bs",
)
 ```

[!NOTE]
crates_hub should match your crates hub name when defining your cargo dependencies

in this case the matching definition should look like this
```starlark
crate = use_extension("@rules_rs//rs:extensions.bzl", "crate")
crate.from_cargo(
    name = "crates",
    cargo_lock = "//:Cargo.lock",
    cargo_toml = "//:Cargo.toml",
    platform_triples = [
        ...
    ],
)
use_repo(crate, "crates")
```

### Run the generator with the desired output directory

```bash
bazel run //:refresh_project -- $(pwd)/third_party
```

[!NOTE]
The "$pwd" is needed since bazel rules run from the bazel-bin directory, not the workspace directory

### Include the generated include.MODULE.bazel file in your main MODULE.bazel

 - MODULE.bazel
 ```starlark
include("//third_party:include.MODULE.bazel")
 ```

## Detailed usage 

TODO!


