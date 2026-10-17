#!/bin/bash
set -euo pipefail

export MATLAB_PREFDIR="$TMPDIR/prefs"
mkdir -p "$MATLAB_PREFDIR"

echo "%{cc_path}"
export PATH="%{cc_path}:$PATH"

exec "%{mex_exe}" -v "$@"
