"""This module defines the rule for building MEX functions."""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("@rules_cc//cc:action_names.bzl", "C_COMPILE_ACTION_NAME")
load("@rules_cc//cc:find_cc_toolchain.bzl", "CC_TOOLCHAIN_ATTRS", "find_cpp_toolchain", "use_cc_toolchain")
load("@rules_cc//cc/common:cc_common.bzl", "cc_common")

DISABLED_FEATURES = []
_MATLAB_TC_TYPE = Label("//mex/matlab:toolchain_type")

def _mex_function_impl(ctx):
    matlab_toolchain = ctx.toolchains[_MATLAB_TC_TYPE]

    mexext = matlab_toolchain.mexext
    output = ctx.attr.output
    if output:
        ext_start = output.rfind(".")
        if ext_start == -1:
            output += mexext
        else:
            output = output.replace(output[ext_start:], mexext)
        out = ctx.actions.declare_file(output)
    else:
        src = ctx.files.srcs[0]
        name, _ = paths.split_extension(src.basename)
        output = name + mexext
        out = ctx.actions.declare_file(output)

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
        # Pass env vars to help mex locate compiler
        _COMPILER_LOC_VARS = ["MW_MINGW64_LOC", "PROGRAMFILES(X86)", "PROGRAMFILES"]

        shell_env = ctx.configuration.default_shell_env
        env = {e: shell_env[e] for e in _COMPILER_LOC_VARS if e in shell_env}
        env.update(cc_env)
    else:
        env = {"BAZEL_MEX_CC_PATH": c_compiler_path}
        env.update(cc_env)

    ctx.actions.run(
        inputs = depset(
            direct = ctx.files.srcs,
            transitive = [
                cc_toolchain.all_files,
                matlab_toolchain.all_files,
            ],
        ),
        outputs = [out],
        executable = matlab_toolchain.mex_wrapper,
        env = env,
        # Include user specified options before -outdir and -output because
        # last specified win if specified twice.
        arguments = [f.path for f in ctx.files.srcs] + ctx.attr.options + [
            "-outdir",
            out.dirname,
            "-output",
            output,
        ],
    )
    return [DefaultInfo(files = depset([out]))]

mex_function = rule(
    implementation = _mex_function_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = True),
        "output": attr.string(),
        "options": attr.string_list(),
    } | CC_TOOLCHAIN_ATTRS,
    toolchains = use_cc_toolchain() + [_MATLAB_TC_TYPE],
    fragments = ["cpp"],
)
