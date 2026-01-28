#!/bin/bash

set -e
pushd "$(dirname "$0")" > /dev/null || exit 1

ARGS=$(jq -r '."tinymist.typstExtraArgs" | join(" ")' .vscode/settings.json)
LINDEN_REF=$(echo "$ARGS" | sed -n 's/.*LINDEN_REF=\([^ ]*\).*/\1/p')
REGELK_REF=$(echo "$ARGS" | sed -n 's/.*REGELK_REF=\([^ ]*\).*/\1/p')

# Download some external dependencies that will be needed by Typst during compilation
if [[ ! "$*" =~ --skip-setup ]]; then
  # Linden: contains all the Rocq source code of this project
  rm -rf Linden || true
  git clone https://github.com/LindenRegex/Linden Linden
  git -C Linden reset --hard "$LINDEN_REF"

  # RegElk: contains the regex corpora frequency analysis
  rm -rf RegElk || true
  git clone https://github.com/LindenRegex/RegElk RegElk
    git -C RegElk reset --hard "$REGELK_REF"
  # Build RegElk and generate the frequency analysis data
  pushd RegElk > /dev/null
    opam install . -y || true
    eval $(opam env)
    make stats
    ./stats.native > ../regex_frequencies-$REGELK_REF.csv
  popd > /dev/null
fi

# Add FINAL flag
if [[ "$*" =~ --final ]]; then
  ARGS="$ARGS --input FINAL="
fi
# Add BOOK flag
if [[ "$*" =~ --book ]]; then
  ARGS="$ARGS --input BOOK="
fi

typst compile thesis.typ thesis.pdf $ARGS

popd > /dev/null
