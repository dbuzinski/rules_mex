_MEXEXT = {
    "glnxa64": "mexa64",
    "win64": "mexw64",
    "maca64": "mexmaca64",
    "maci64": "mexmaci64",
}

def get_arch(repository_ctx):
    os_name = repository_ctx.os.name
    arch = repository_ctx.os.arch
    if os_name.startswith("mac os"):
        return "mac" + ("a64" if arch == "aarch64" else "i64")
    if os_name.startswith("linux"):
        return "glnxa64"
    if os_name.startswith("windows"):
        return "win64"
    fail("Unsupported Platform: " + os_name + " " + arch)

def _matlab_configure_impl(repository_ctx):
    arch = get_arch(repository_ctx)
    if arch == "win64":
        matlab_path = repository_ctx.which("matlab.exe")
        mex_path = repository_ctx.which("mex.bat")
        matlab_exe = str(matlab_path).replace("\\", "/") if matlab_path else ""
        mex_exe = str(mex_path).replace("\\", "/") if mex_path else ""
    else:
        matlab_exe = repository_ctx.which("matlab")
        mex_exe = repository_ctx.which("mex")
    mexext = _MEXEXT[arch]

    repository_ctx.template("BUILD.bazel", repository_ctx.attr._build_tpl, {
        "%{name}": "local",
        "%{matlab_root}": "",
        "%{matlab_executable}": matlab_exe,
        "%{arch}": arch,
        "%{mex_executable}": mex_exe,
        "%{mexext}": mexext,
    }, executable = False)

matlab_configure = repository_rule(
    implementation = _matlab_configure_impl,
    environ = ["MATLAB_ROOT"],
    local = True,
    configure = True,
    attrs = {"_build_tpl": attr.label(default = Label("//mex/matlab:BUILD.tpl"))},
)

def _matlab_configure_extension_impl(ctx):
    matlab_configure(name = "local_config_matlab")

matlab_configure_extension = module_extension(implementation = _matlab_configure_extension_impl)
