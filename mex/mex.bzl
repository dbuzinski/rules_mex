load("@bazel_skylib//rules:expand_template.bzl", "expand_template")
load("@rules_cc//cc:find_cc_toolchain.bzl", "CC_TOOLCHAIN_ATTRS", "find_cpp_toolchain", "use_cc_toolchain")
load("@rules_cc//cc:action_names.bzl", "C_COMPILE_ACTION_NAME")
load("@rules_cc//cc/common:cc_common.bzl", "cc_common")

DISABLED_FEATURES = []
_MATLAB_TC_TYPE = Label("//mex/matlab:toolchain_type")

def _mex_function_impl(ctx):
    matlab_toolchain = ctx.toolchains[_MATLAB_TC_TYPE]

    src = ctx.files.srcs[0]
    # TODO clean up file naming logic. Allow custom naming via attr
    name = src.basename[:-len(src.extension) - 1] if src.extension else src.basename
    mexext = matlab_toolchain.mexext
    out = ctx.actions.declare_file(name + "." + mexext)
    scratch = ctx.actions.declare_directory("mex_scratch")

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

    mex_wrapper = ctx.actions.declare_file("mex_wrapper.sh")
    ctx.actions.expand_template(
        template = ctx.file._template,
        output = mex_wrapper,
        substitutions = {
            "{MEX_EXE}": matlab_toolchain.mex_executable,
            "{SCRATCH_DIR}": scratch.path,
            "{CC_PATH}": c_compiler_path,
        },
        is_executable = True,
    )

    ctx.actions.run(
        inputs = ctx.files.srcs + [mex_wrapper],
        outputs = [out, scratch],
        executable = mex_wrapper.path,
        arguments = [f.path for f in ctx.files.srcs] + [
            "-outdir", out.dirname, "-output", name,
        ],
    )
    return [DefaultInfo(files = depset([out]))]

mex_function = rule(
    implementation = _mex_function_impl,
    attrs = {
        # TODO get more complete list
        "srcs": attr.label_list(allow_files = [".c", ".cc", ".cpp", ".c++"]),
        "_template": attr.label(
            default = ":mex_wrapper.sh.tpl",
            allow_single_file = True,
        ),
    } | CC_TOOLCHAIN_ATTRS,
    toolchains = use_cc_toolchain() + [_MATLAB_TC_TYPE],
    fragments = ["cpp"],
)
