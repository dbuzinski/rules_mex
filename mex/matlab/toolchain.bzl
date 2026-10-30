"""This module defines the MATLAB toolchain rule."""

def _matlab_toolchain_impl(ctx):
    toolchain_info = platform_common.ToolchainInfo(
        matlab_root = ctx.attr.matlab_root,
        matlab_executable = ctx.attr.matlab_executable,
        arch = ctx.attr.arch,
        mex_executable = ctx.attr.mex_executable,
        mexext = ctx.attr.mexext,
    )
    return [toolchain_info]

matlab_toolchain = rule(
    implementation = _matlab_toolchain_impl,
    attrs = {
        "matlab_root": attr.string(),
        "matlab_executable": attr.string(),
        "arch": attr.string(),
        "mex_executable": attr.string(),
        "mexext": attr.string(),
    },
)
