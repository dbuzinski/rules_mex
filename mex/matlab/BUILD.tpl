load("@rules_mex//mex/matlab:toolchain.bzl", "matlab_toolchain")
load("@platforms//host:constraints.bzl", "HOST_CONSTRAINTS")

package(default_visibility = ["//visibility:public"])

matlab_toolchain(
    name = "matlab-%{name}",
    matlab_root = "%{matlab_root}",
    matlab_executable = "%{matlab_executable}",
    mex_executable = "%{mex_executable}",
    mexext = "%{mexext}",
)


toolchain(
    name = "matlab-toolchain-%{name}",
    exec_compatible_with = HOST_CONSTRAINTS,
    target_compatible_with = HOST_CONSTRAINTS,
    toolchain = "@local_config_matlab//:matlab-%{name}",
    toolchain_type = "@rules_mex//mex/matlab:toolchain_type",
)
