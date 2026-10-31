#!/bin/bash
set -euo pipefail

export MATLAB_PREFDIR="$TMPDIR/prefs"
mkdir -p "$MATLAB_PREFDIR"

export PATH="$BAZEL_MEX_CC_PATH:$PATH"

exec "%{mex_exe}" "$@"
