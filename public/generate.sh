#!/usr/bin/env bash

set -e
pushd "$(dirname "$0")" || exit 1

index=`mktemp -d`/index.md

cat > "$index" <<- EOM
---
title: "PikeVM optimizations and regex features formalization"
description: "TODO"
---
EOM

echo "## Proposal" >> "$index"
rm -r proposal || true; mkdir -p proposal
pandoc ../proposal/proposal.md -H headers.html --katex -s -o "proposal/proposal.html"
echo "[proposal](proposal/proposal.html)" >> "$index"

echo "" >> "$index"

echo "## Progress presentation" >> "$index"
rm -r progress || true; mkdir -p progress
pandoc ../progress_presentation/script.md -H headers.html --katex -s -o "progress/script.html"
cp ../progress_presentation/presentation.svg progress/
echo "[script](progress/script.html)" >> "$index"

echo "" >> "$index"

rm -r meeting-notes || true; mkdir -p meeting-notes
echo "## Meeting notes" >> "$index"
for f in ../meeting_notes/*.md; do
	filename=$(basename -- "$f")
	filename_no_ext="${filename%.*}"
	pandoc "$f" -H headers.html --katex -s -o "meeting-notes/${filename_no_ext}.html"
	echo "- [${filename_no_ext}](meeting-notes/${filename_no_ext}.html)" >> "$index"
done

echo "" >> "$index"

echo "## Report" >> "$index"
rm -r report || true; mkdir -p report
../report/build.sh
mv ../report/thesis.pdf report/
echo "[report](report/thesis.pdf)" >> "$index"

pandoc "$index" -H headers.html --katex -s -o index.html

popd
