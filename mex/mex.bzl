# load("@bazel_skylib//rules:expand_template.bzl", "expand_template")
load("@rules_cc//cc:find_cc_toolchain.bzl", "CC_TOOLCHAIN_ATTRS", "find_cpp_toolchain", "use_cc_toolchain")
load("@rules_cc//cc:action_names.bzl", "C_COMPILE_ACTION_NAME")
load("@rules_cc//cc/common:cc_common.bzl", "cc_common")

DISABLED_FEATURES = [
    # "module_maps",  # copybara-comment-this-out-please
]

def _mex_function_impl(ctx):
    src = ctx.files.srcs[0]
    # TODO clean up file naming logic. Allow custom naming via attr
    name = src.basename[:-len(src.extension) - 1] if src.extension else src.basename
    # TODO use toolchain to determine mexext
    out = ctx.actions.declare_file(name + ".mexmaca64")
    scratch = ctx.actions.declare_directory(ctx.label.name + "_mex_scratch")
    # TODO PATH management via toolchain
    # path = "/usr/local/bin:/usr/bin:/bin:/Applications/MATLAB_R2026b.app/bin"

    # TODO use template script pattern from cc_rules
    # TODO reconsider use of -outdir. currently using as easiest to allow
    # sandboxed builds due to tmp file creation
    cc_toolchain = find_cpp_toolchain(ctx)
    feature_configuration = cc_common.configure_features(
        ctx = ctx,
        cc_toolchain = cc_toolchain,
        requested_features = ctx.features,
        unsupported_features = DISABLED_FEATURES + ctx.disabled_features,
    )
    c_compiler_path = cc_common.get_tool_for_action(
        feature_configuration = feature_configuration,
        action_name = C_COMPILE_ACTION_NAME,
    )
    ctx.actions.run_shell(
        inputs = ctx.files.srcs,
        outputs = [out, scratch],
        command = """
set -euo pipefail
export TMPDIR="$PWD/{scratch}"
export MATLAB_PREFDIR="$TMPDIR/prefs"
export PATH="$PATH:{c_compiler_path}"
mkdir -p "$MATLAB_PREFDIR"
exec /Applications/MATLAB_R2026b.app/bin/mex "$@"
""".format(scratch = scratch.path, c_compiler_path = c_compiler_path),
        arguments = [f.path for f in ctx.files.srcs] + [
            "-outdir", out.dirname, "-output", name,
        ],
    )
    return [DefaultInfo(files = depset([out]))]

mex_function = rule(
    implementation = _mex_function_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = [".c", ".cc", ".cpp", ".c++"]),
    } | CC_TOOLCHAIN_ATTRS,
    toolchains = use_cc_toolchain(),
    fragments = ["cpp"],
)
