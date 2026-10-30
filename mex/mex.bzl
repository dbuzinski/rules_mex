"""This module defines the rule for building MEX functions."""

load("@rules_cc//cc:action_names.bzl", "C_COMPILE_ACTION_NAME")
load("@rules_cc//cc:find_cc_toolchain.bzl", "CC_TOOLCHAIN_ATTRS", "find_cpp_toolchain", "use_cc_toolchain")
load("@rules_cc//cc/common:cc_common.bzl", "cc_common")

DISABLED_FEATURES = []
_MATLAB_TC_TYPE = Label("//mex/matlab:toolchain_type")

def _mex_function_impl(ctx):
    unused = "wtf"
    matlab_toolchain = ctx.toolchains[_MATLAB_TC_TYPE]

    # TODO clean up file naming logic. Allow custom naming via attr
    src = ctx.files.srcs[0]
    name = src.basename[:-len(src.extension) - 1] if src.extension else src.basename
    mexext = matlab_toolchain.mexext
    out = ctx.actions.declare_file(name + "." + mexext)

    cc_toolchain = find_cpp_toolchain(ctx)
    action = C_COMPILE_ACTION_NAME
    feature_configuration = cc_common.configure_features(
        ctx = ctx,
        cc_toolchain = cc_toolchain,
        requested_features = ctx.features,
        unsupported_features = DISABLED_FEATURES + ctx.disabled_features,
    )
    c_compiler_path = cc_common.get_tool_for_action(
        feature_configuration = feature_configuration,
        action_name = action,
    )
    variables = cc_common.create_compile_variables(
        feature_configuration = feature_configuration,
        cc_toolchain = cc_toolchain,
    )
    cc_env = cc_common.get_environment_variables(
        feature_configuration = feature_configuration,
        action_name = action,
        variables = variables,
    )

    if matlab_toolchain.arch == "win64":
        mex_wrapper_tpl = ctx.file._mex_wrapper_tpl_windows
        mex_wrapper = ctx.actions.declare_file("mex_wrapper.bat")

        # Pass env vars to help mex locate compiler
        _COMPILER_LOC_VARS = ["MW_MINGW64_LOC", "PROGRAMFILES(X86)", "PROGRAMFILES"]

        shell_env = ctx.configuration.default_shell_env
        env = {e: shell_env[e] for e in _COMPILER_LOC_VARS if e in shell_env}
        env.update(cc_env)
    else:
        mex_wrapper_tpl = ctx.file._mex_wrapper_tpl_unix
        mex_wrapper = ctx.actions.declare_file("mex_wrapper.sh")
        env = cc_env

    ctx.actions.expand_template(
        template = mex_wrapper_tpl,
        output = mex_wrapper,
        substitutions = {
            "%{mex_exe}": matlab_toolchain.mex_executable,
            "%{cc_path}": c_compiler_path,
        },
        is_executable = True,
    )

    # TODO reconsider use of -outdir. currently using as easiest to allow
    # sandboxed builds due to tmp file creation
    # TODO fix inputs. cc_toolchain.all_files? matlab_toolchain.all_files?
    ctx.actions.run(
        inputs = ctx.files.srcs + [mex_wrapper],
        outputs = [out],
        executable = mex_wrapper.path,
        env = env,
        arguments = [f.path for f in ctx.files.srcs] + [
            "-outdir",
            out.dirname,
            "-output",
            name,
        ],
    )
    return [DefaultInfo(files = depset([out]))]

mex_function = rule(
    implementation = _mex_function_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = True),
        "_mex_wrapper_tpl_unix": attr.label(
            default = ":mex_wrapper_tpl_unix",
            allow_single_file = True,
        ),
        "_mex_wrapper_tpl_windows": attr.label(
            default = ":mex_wrapper_tpl_windows",
            allow_single_file = True,
        ),
    } | CC_TOOLCHAIN_ATTRS,
    toolchains = use_cc_toolchain() + [_MATLAB_TC_TYPE],
    fragments = ["cpp"],
)
