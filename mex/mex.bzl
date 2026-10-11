def _mex_function_impl(ctx):
    # Extract the path without its current extension, then add the new one
    base_path = ctx.files.srcs[0].path
    if ctx.files.srcs[0].extension:
        base_path = base_path[:-len("." + ctx.files.srcs[0].extension)]

    out = ctx.actions.declare_file(base_path + ".mexmaca64")
    # ctx.files.srcs[0]
    ctx.actions.run(
        executable = "mex",
        inputs = ctx.files.srcs,
        outputs = [out],
        arguments = [f.path for f in ctx.files.srcs],
    )
    return [DefaultInfo(files = depset([out]))]

mex_function = rule(
    implementation = _mex_function_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = [".c", ".cc", ".cpp", ".c++"]),
    }
)

