#!/usr/bin/env bash
#
# test.sh — run the elm-svg headless test suite (the pure Scale maths behind the charts).
#
# The elm.sh wrapper chdirs to the elm-lang repo root before running, so every path passed to
# the runner must be absolute (computed here after we cd into the script's own dir).
#
#   ELM=../../elm.sh ./test.sh
#
set -euo pipefail
cd "$(dirname "$0")"

ELM="${ELM:-elm}"
P="$(pwd)"

$ELM test "$P/test/SvgTest.elm" "$P/src/Scale.elm" "$P/src/Arc.elm" "$P/src/Curve.elm" "$P/src/Stat.elm" "$P/src/Format.elm" "$P/src/Layout.elm"
