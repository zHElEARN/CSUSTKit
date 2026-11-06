#!/bin/bash
set -e

cd "$(dirname "$0")/.."

swift package --allow-writing-to-directory docs \
    generate-documentation --target CSUSTKit \
    --transform-for-static-hosting \
    --hosting-base-path CSUSTKit \
    --output-path docs

if [[ ! -s docs/data/documentation/csustkit.json ]]; then
    echo "DocC did not generate the CSUSTKit module page." >&2
    exit 1
fi
