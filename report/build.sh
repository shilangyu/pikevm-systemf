#!/bin/bash

set -e
pushd "$(dirname "$0")" > /dev/null || exit 1

ARGS=$(jq -r '."tinymist.typstExtraArgs" | join(" ")' .vscode/settings.json)
LINDEN_REF=$(echo "$ARGS" | sed -n 's/.*LINDEN_REF=\([^ ]*\).*/\1/p')
REGELK_REF=$(echo "$ARGS" | sed -n 's/.*REGELK_REF=\([^ ]*\).*/\1/p')

# Download some external dependencies that will be needed by Typst during compilation
if [[ ! "$*" =~ --skip-setup ]]; then
  # Linden: contains all the Rocq source code of this project
  if [[ -d Linden ]] && [[ $(git -C Linden rev-parse HEAD) == "$LINDEN_REF" ]]; then
    echo "Linden cache hit: already at $LINDEN_REF"
  else
    echo "Linden cache miss: cloning repository"
    rm -rf Linden || true
    git clone https://github.com/LindenRegex/Linden Linden
    git -C Linden reset --hard "$LINDEN_REF"
  fi

  # RegElk: contains the regex corpora frequency analysis
  REGELK_CLONED=false
  if [[ -d RegElk ]] && [[ $(git -C RegElk rev-parse HEAD) == "$REGELK_REF" ]]; then
    echo "RegElk cache hit: already at $REGELK_REF"
  else
    echo "RegElk cache miss: cloning repository"
    rm -rf RegElk || true
    git clone https://github.com/LindenRegex/RegElk RegElk
    git -C RegElk reset --hard "$REGELK_REF"
    REGELK_CLONED=true
  fi

  # Build RegElk and generate the frequency analysis data only if needed
  STATS_FILE="regex_frequencies-$REGELK_REF.csv"
  if [[ ! -f "$STATS_FILE" ]] || [[ "$REGELK_CLONED" == true ]]; then
    echo "Building RegElk and generating statistics"
    pushd RegElk > /dev/null
      opam install . -y || true
      eval $(opam env)
      make stats
      ./stats.native > "../$STATS_FILE"
    popd > /dev/null
  else
    echo "Stats cache hit: $STATS_FILE already exists"
  fi
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
