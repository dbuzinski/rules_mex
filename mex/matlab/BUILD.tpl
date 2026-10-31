load("@rules_mex//mex/matlab:toolchain.bzl", "matlab_toolchain")
load("@platforms//host:constraints.bzl", "HOST_CONSTRAINTS")

package(default_visibility = ["//visibility:public"])

filegroup(
    name = "mex_wrapper",
    srcs = ["mex_wrapper%{wrapper_ext}"],
)

filegroup(
    name = "all_files",
    srcs = [":mex_wrapper", %{supplementary_files}],
)

matlab_toolchain(
    name = "matlab-%{name}",
    matlab_root = "%{matlab_root}",
    matlab_executable = "%{matlab_executable}",
    arch = "%{arch}",
    mex_executable = "%{mex_executable}",
    mexext = "%{mexext}",
    mex_wrapper = ":mex_wrapper",
    all_files = ":all_files",
)


toolchain(
    name = "matlab-toolchain-%{name}",
    exec_compatible_with = HOST_CONSTRAINTS,
    target_compatible_with = HOST_CONSTRAINTS,
    toolchain = "@local_config_matlab//:matlab-%{name}",
    toolchain_type = "@rules_mex//mex/matlab:toolchain_type",
)
