#!/usr/bin/env bash
set -e

githash=$(git rev-parse --short master)
changes=$(git diff --name-only master HEAD)
noChanges=true
for file in $changes; do
  if [[ $file =~ servers/relay/* ]]; then
    echo "Found changes"
    noChanges=false
    break
  fi
done

echo "Changes: $noChanges"

if $noChanges; then
  exit 0
fi

git checkout master --quiet -- servers/relay
git reset --quiet servers/relay
rm -rf src test tstconfig.json package-lock.json package.json LICENSE READMEME.md
mv servers/relay/* .
rm -rf ./servers
git add .
git commit -m "Mirroring master@$githash"
git push --quiet origin relay
