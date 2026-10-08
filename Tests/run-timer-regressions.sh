#!/bin/bash
set -euo pipefail
project_root="$(cd "$(dirname "$0")/.." && pwd)"
test_directory="$(mktemp -d "${TMPDIR:-/tmp}/ddnotice-tests.XXXXXX")"
trap 'rm -rf "$test_directory"' EXIT
xcrun swiftc -swift-version 5 -module-cache-path "$test_directory/module-cache" \
    "$project_root/DDNotice/Models/DDTimer.swift" \
    "$project_root/DDNotice/Models/DDConst.swift" \
    "$project_root/Tests/TimerRegression/main.swift" \
    -o "$test_directory/timer-regressions"
"$test_directory/timer-regressions"
