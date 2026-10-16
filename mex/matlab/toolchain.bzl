# MATLABInfo = provider(
#     doc = "Information about how to invoke MATLAB.",
#     fields = [
#         "matlab_root",
#         "matlab_executable",
#         "mex_executable",
#         "mexext",
#     ],
# )

def _matlab_toolchain_impl(ctx):
    toolchain_info = platform_common.ToolchainInfo(
        # matlabinfo = MATLABInfo(
        matlab_root = ctx.attr.matlab_root,
        matlab_executable = ctx.attr.matlab_executable,
        mex_executable = ctx.attr.mex_executable,
        mexext = ctx.attr.mexext,
        # ),
    )
    return [toolchain_info]

matlab_toolchain = rule(
    implementation = _matlab_toolchain_impl,
    attrs = {
        "matlab_root": attr.string(),
        "matlab_executable": attr.string(),
        "mex_executable": attr.string(),
        "mexext": attr.string(),
    }
)
