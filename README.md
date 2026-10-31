# Bazel Rules for MEX

This rule compiles C/C++ code into a [MEX file](https://www.mathworks.com/help/matlab/call-mex-file-functions.html) which can be called as a MATLAB function.

## Getting Started

The following are required to use this rule:
- Bazel 7 or later using [bzlmod](https://bazel.build/external/overview#bzlmod)
- A MATLAB installation
- A supported C/C++ compiler for your OS

Include `rules_mex` as a dependency in your `MODULE.bazel` file. Check the Bazel Central Registry for the latest released version of the rule.

```python
bazel_dep(name = "rules_mex", version = "...")
```

## Examples

There is a basic example in the [examples folder](https://github.com/dbuzinski/rules_mex/tree/main/examples). See the smoke tests in [ci.yml](https://github.com/dbuzinski/rules_mex/blob/main/.github/workflows/ci.yml) for an example of how to run the rule in GitHub Actions workflows on GitHub-hosted Linux, Windows, and macOS runners.

## Usage

This rule is not hermetic by deafult. It automatically configures a sandboxed MATLAB toolchain from the host environment using the MATLAB installation at the top of the system path, similar to how the C++ toolchain in `rules_cc` works. If you don't have MATLAB on path or need to manage multiple MATLAB installations, you can set the `MATLAB_ROOT` environment variable to the MATLAB installation directory (the directory that is output if you run `matlabroot` in the MATLAB Command Window).

This rule builds on the C++ toolchain defined in `rules_cc`. You must use a [supported compiler](https://www.mathworks.com/support/requirements/supported-compilers.html). By default, it will automatically configure the toolchain from the host. For more information on how to configure the C++ toolchain, see [Bazel Tutorial: Configure C++ Toolchains](https://bazel.build/tutorials/ccp-toolchain-config).

On Windows, the `mex` command sometimes finds different compilers than the one provided by the C++ toolchain. If this happens, you can set the `MW_MINGW64_LOC` environment variable to the MinGW root folder for MinGW or the `PROGRAMFILES(X86)` or `PROGRAMFILES` environment variables for Microsoft Visual C++. See [ci.yml](https://github.com/dbuzinski/rules_mex/blob/main/.github/workflows/ci.yml) for example usage of these variables.

### Parameters
| Name | Type | Description | Default | Required |
| ---------- | -----| ------ | ------- | -------- |
| `name`     | string |A unique name for this target. | | Yes |
| `srcs`     | label | A list of C/C++ source files to compile. | | Yes |
| `output`   | string | The name of the created MEX file. The rule always creates a file with the correct `mexext` for your system. | The base name of first file in srcs | No |
| `options`  | string list | Build options to pass to the `mex` command. See [MEX documentation](https://www.mathworks.com/help/matlab/ref/mex.html#btw17rw-1-option1optionN) for a full list of supported options. | `[]` | No |

## Notes

For any feature requests or bugs, please [create an issue](https://github.com/dbuzinski/rules_mex/issues/new/choose). The following are things I'm considering as next steps:
- MATLAB toolchain not hermetic and not documented.
- A MATLAB toolchain included but might be worth separating from this repository for use in other rules.
- Detecting supported compilers on Windows is a little janky at the moment.
