set -euo pipefail
export TMPDIR="$PWD/{SCRATCH_DIR}"
export MATLAB_PREFDIR="$TMPDIR/prefs"
export PATH="{CC_PATH}:$PATH"
mkdir -p "$MATLAB_PREFDIR"
exec "{MEX_EXE}" "$@"
