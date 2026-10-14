def _mex_function_impl(ctx):
    src = ctx.files.srcs[0]
    # TODO clean up file naming logic. Allow custom naming via attr
    name = src.basename[:-len(src.extension) - 1] if src.extension else src.basename
    # TODO use toolchain to determine mexext
    out = ctx.actions.declare_file(name + ".mexmaca64")
    scratch = ctx.actions.declare_directory(ctx.label.name + "_mex_scratch")
    # TODO PATH management via toolchain
    path = "/usr/local/bin:/usr/bin:/bin:/Applications/MATLAB_R2026b.app/bin"

    # TODO use template script pattern from cc_rules
    # TODO reconsider use of -outdir. currently using as easiest to allow
    # sandboxed builds due to tmp file creation
    ctx.actions.run_shell(
        inputs = ctx.files.srcs,
        outputs = [out, scratch],
        env = {
            "PATH": path
        },
        command = """
set -euo pipefail
export TMPDIR="$PWD/{scratch}"
export MATLAB_PREFDIR="$TMPDIR/prefs"
mkdir -p "$MATLAB_PREFDIR"
exec mex "$@"
""".format(scratch = scratch.path),
        arguments = [f.path for f in ctx.files.srcs] + [
            "-outdir", out.dirname, "-output", name,
        ],
    )
    return [DefaultInfo(files = depset([out]))]

mex_function = rule(
    implementation = _mex_function_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = [".c", ".cc", ".cpp", ".c++"]),
    },
)
