#!/usr/bin/env bash
#
# build.sh — compile the elm-svg demo gallery to a standalone HTML file.
#
# The elm.sh wrapper chdirs to the elm-lang repo root before running, so every path passed to
# `make` must be absolute (computed here after we cd into the script's own dir). Like the other
# elm-lang example apps we compile with --no-check.
#
#   ELM=../../elm.sh ./build.sh
#
set -euo pipefail
cd "$(dirname "$0")"

ELM="${ELM:-elm}"
OUT="build"
P="$(pwd)"

mkdir -p "$OUT"
echo "Compiling elm-svg with: $ELM"
$ELM make "$P/src/Main.elm" --project="$P/elm.json" -o "$P/$OUT/elm-svg.html" --no-check

# The compiler owns the output's <head>; add a viewport meta and inline src/svg.css as a <style>
# so the page stays a single self-contained file (idempotent on re-runs).
HTML="$P/$OUT/elm-svg.html"
CSSFILE="$P/src/svg.css" perl -0pi -e '
  if (index($_, q{name="viewport"}) < 0) {
    s#<meta charset="utf-8">#<meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">#;
  }
  if (index($_, q{id="es-app-css"}) < 0) {
    open(my $f, "<", $ENV{CSSFILE}) or die "no svg.css: $!";
    local $/; my $css = <$f>; close($f);
    s#</head>#"<style id=\"es-app-css\">".$css."</style></head>"#e;
  }
' "$HTML"
echo "Done -> $OUT/elm-svg.html"
