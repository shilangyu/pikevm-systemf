#!/bin/bash

set -e
pushd "$(dirname "$0")" > /dev/null || exit 1

ARGS=$(jq -r '."tinymist.typstExtraArgs" | join(" ")' .vscode/settings.json)
LINDEN_REF=$(echo "$ARGS" | sed -n 's/.*LINDEN_REF=\([^ ]*\).*/\1/p')

# Download Linden at the specified ref. This will be used by typst during compilation.
rm -rf Linden || true
git clone https://github.com/epfl-systemf/Linden Linden
git -C Linden reset --hard "$LINDEN_REF"

typst compile thesis.typ thesis.pdf $ARGS

popd > /dev/null
