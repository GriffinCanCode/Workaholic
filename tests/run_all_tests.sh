#!/bin/bash
# Run all test suites

set -e

echo "╔══════════════════════════════════════════════════╗"
echo "║        WORKAHOLIC TEST SUITE RUNNER              ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

cd "$(dirname "$0")/.."

# Compile tests
echo "🔨 Compiling test suites..."
nim c -d:release --mm:orc -o:tests/test_performance tests/test_performance.nim
nim c -d:release --mm:orc -o:tests/test_system_impact tests/test_system_impact.nim
echo "✅ Tests compiled"
echo ""

# Run performance tests
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PERFORMANCE TESTS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
./tests/test_performance
echo ""

# Run system impact tests
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "SYSTEM IMPACT TESTS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
./tests/test_system_impact
echo ""

echo "╔══════════════════════════════════════════════════╗"
echo "║             ALL TESTS COMPLETE                   ║"
echo "╚══════════════════════════════════════════════════╝"

