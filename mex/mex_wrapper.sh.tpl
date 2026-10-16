#!/bin/bash
set -euo pipefail

export TMPDIR="$PWD/%{scratch_dir}"
export MATLAB_PREFDIR="$TMPDIR/prefs"
export PATH="%{cc_path}:$PATH"

mkdir -p "$MATLAB_PREFDIR"

exec "%{mex_exe}" "$@"
