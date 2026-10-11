load("@bazel_tools//tools/cpp:toolchain_utils.bzl", "find_cpp_toolchain")

def _mex_function_impl(ctx):
    # Extract the path without its current extension, then add the new one
    base_path = ctx.files.srcs[0].basename
    if ctx.files.srcs[0].extension:
        base_path = base_path[:-len("." + ctx.files.srcs[0].extension)]

    out = ctx.actions.declare_file(base_path + ".mexmaca64")
    source_paths = [f.path for f in ctx.files.srcs]
    cc_toolchain = find_cpp_toolchain(ctx)
    inputs = depset(
        direct = ctx.files.srcs,
        transitive = [cc_toolchain.all_files],
    )
    ctx.actions.run(
        executable = "/Applications/MATLAB_R2026b.app/bin/mex",
        inputs = inputs,
        outputs = [out],
        arguments = source_paths + ["-output", out.path],
    )
    return [DefaultInfo(files = depset([out]))]

mex_function = rule(
    implementation = _mex_function_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = [".c", ".cc", ".cpp", ".c++"]),
    },
    toolchains = [
        "@bazel_tools//tools/cpp:toolchain_type", 
    ],
)

