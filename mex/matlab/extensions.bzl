"""This module defines the auto config for the MATLAB toolchain."""

load("@bazel_skylib//lib:paths.bzl", "paths")

_MEXEXT = {
    "glnxa64": ".mexa64",
    "win64": ".mexw64",
    "maca64": ".mexmaca64",
    "maci64": ".mexmaci64",
}

def _get_arch(repository_ctx):
    os_name = repository_ctx.os.name
    arch = repository_ctx.os.arch
    if os_name.startswith("mac os"):
        return "mac" + ("a64" if arch == "aarch64" else "i64")
    if os_name.startswith("linux"):
        return "glnxa64"
    if os_name.startswith("windows"):
        return "win64"
    fail("Unsupported Platform: " + os_name + " " + arch)

def _which(repository_ctx, cmd, default = None):
    result = repository_ctx.which(cmd)
    return default if result == None else str(result)

def _should_disable_toolchain(repository_ctx):
    env = repository_ctx.os.environ
    if env.get("BAZEL_DO_NOT_DETECT_MATLAB_TOOLCHAIN") == "1":
        return True
    return False

def _matlab_configure_impl(repository_ctx):
    if not _should_disable_toolchain(repository_ctx):
        arch = _get_arch(repository_ctx)
        mexext = _MEXEXT[arch]
        matlab_root = repository_ctx.getenv("MATLAB_ROOT")

        if matlab_root:
            matlab_exe = paths.join(matlab_root, "bin", "matlab")
            mex_exe = paths.join(matlab_root, "bin", "mex")
            if arch == "win64":
                mex_exe = paths.replace_extension(mex_exe, ".bat")
            matlab_exe = str(matlab_exe)
            mex_exe = str(mex_exe)
        else:
            mex_script = "mex"
            if arch == "win64":
                mex_script = mex_script + ".bat"
            matlab_exe = _which(repository_ctx, "matlab")
            mex_exe = _which(repository_ctx, mex_script)

            if not matlab_exe or not mex_exe:
                fail("Unable to find MATLAB toolchain.")
            matlab_root = paths.dirname(paths.dirname(matlab_exe))

        repository_ctx.template("BUILD.bazel", repository_ctx.attr._build_tpl, {
            "%{name}": "local",
            "%{matlab_root}": str(matlab_root),
            "%{matlab_executable}": matlab_exe,
            "%{arch}": arch,
            "%{mex_executable}": mex_exe,
            "%{mexext}": mexext,
        }, executable = False)
    else:
        repository_ctx.file("BUILD", "# MATLAB toolchain autoconfiguration was disabled by BAZEL_DO_NOT_DETECT_MATLAB_TOOLCHAIN=1.")

matlab_configure = repository_rule(
    implementation = _matlab_configure_impl,
    environ = ["MATLAB_ROOT", "PATH"],
    local = True,
    configure = True,
    attrs = {"_build_tpl": attr.label(default = Label("//mex/matlab:BUILD.tpl"))},
)

def _matlab_configure_extension_impl(_):
    matlab_configure(name = "local_config_matlab")

matlab_configure_extension = module_extension(implementation = _matlab_configure_extension_impl)
