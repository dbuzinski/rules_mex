"""This module defines the auto config for the MATLAB toolchain."""

load("@bazel_skylib//lib:paths.bzl", "paths")

_MEXEXT = {
    "glnxa64": ".mexa64",
    "maca64": ".mexmaca64",
    "maci64": ".mexmaci64",
    "win64": ".mexw64",
}

_WRAPPER_EXT = {
    "glnxa64": ".sh",
    "maca64": ".sh",
    "maci64": ".sh",
    "win64": ".bat",
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

def _should_disable_toolchain(repository_ctx):
    env = repository_ctx.os.environ
    if env.get("BAZEL_DO_NOT_DETECT_MATLAB_TOOLCHAIN") == "1":
        return True
    return False

def _matlab_configure_impl(repository_ctx):
    if not _should_disable_toolchain(repository_ctx):
        arch = _get_arch(repository_ctx)
        mexext = _MEXEXT[arch]
        wrapper_ext = _WRAPPER_EXT[arch]
        matlab_root = repository_ctx.getenv("MATLAB_ROOT")
        if arch == "win64":
            mex_wrapper_tpl = repository_ctx.attr._windows_mex_wrapper
        else:
            mex_wrapper_tpl = repository_ctx.attr._unix_mex_wrapper

        if matlab_root:
            matlab_exe = paths.join(matlab_root, "bin", "matlab")
            mex_exe = paths.join(matlab_root, "bin", "mex")
            if arch == "win64":
                mex_exe = paths.replace_extension(mex_exe, ".bat")
            matlab_exe = str(matlab_exe)
            mex_exe = str(mex_exe)
        else:
            matlab_exe = repository_ctx.which("matlab")
            if not matlab_exe:
                fail("Unable to find MATLAB toolchain.")
            # Follow symlinks to find real matlabroot
            matlab_exe = str(matlab_exe.realpath)
            matlab_root = paths.dirname(paths.dirname(matlab_exe))
            mex_exe = paths.join(matlab_root, "bin", "mex")
            if arch == "win64":
                mex_exe = paths.replace_extension(mex_exe, ".bat")

        repository_ctx.template(
            "mex_wrapper" + wrapper_ext,
            mex_wrapper_tpl,
            substitutions = {
                "%{mex_exe}": mex_exe,
            },
        )

        # Additional files to track in order to detect changes to installed products or versions
        # Use it if available but don't fail otherwise
        supplementary_list = []
        supplementary_files = ""
        installedProductData = repository_ctx.path(paths.join(matlab_root, "appdata", "installedProductData.json"))
        if installedProductData.exists:
            repository_ctx.symlink(installedProductData, "installedProductData.json")
            supplementary_list.append("installedProductData.json")
        versionInfo = repository_ctx.path(paths.join(matlab_root, "VersionInfo.xml"))
        if versionInfo.exists:
            repository_ctx.symlink(versionInfo, "VersionInfo.xml")
            supplementary_list.append("VersionInfo.xml")
        if supplementary_list:
           supplementary_files = "\"" + "\", \"".join(supplementary_list) + "\""

        repository_ctx.template("BUILD.bazel", repository_ctx.attr._build_tpl, {
            "%{name}": "local",
            "%{matlab_root}": str(matlab_root),
            "%{matlab_executable}": matlab_exe,
            "%{arch}": arch,
            "%{mex_executable}": mex_exe,
            "%{mexext}": mexext,
            "%{wrapper_ext}": wrapper_ext,
            "%{supplementary_files}": supplementary_files,
        }, executable = False)
    else:
        repository_ctx.file("BUILD", "# MATLAB toolchain autoconfiguration was disabled by BAZEL_DO_NOT_DETECT_MATLAB_TOOLCHAIN=1.")

matlab_configure = repository_rule(
    implementation = _matlab_configure_impl,
    environ = ["MATLAB_ROOT", "PATH"],
    local = True,
    configure = True,
    attrs = {
        "_build_tpl": attr.label(default = Label("//mex/matlab:BUILD.tpl")),
        "_unix_mex_wrapper": attr.label(default = Label("//mex/matlab:mex_wrapper.sh.tpl")),
        "_windows_mex_wrapper": attr.label(default = Label("//mex/matlab:mex_wrapper.bat.tpl")),
    },
)

def _matlab_configure_extension_impl(_):
    matlab_configure(name = "local_config_matlab")

matlab_configure_extension = module_extension(implementation = _matlab_configure_extension_impl)
