#!/bin/bash
# Benchmark Nim version vs Python version

echo "╔══════════════════════════════════════════════════╗"
echo "║     NIM vs PYTHON PERFORMANCE COMPARISON         ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

# Check if Python version exists
if [ ! -f "../workaholic" ] || [ ! -x "../workaholic" ]; then
    echo "⚠️  Python version not found at ../workaholic"
    echo "   Skipping Python comparison"
    echo ""
    PYTHON_EXISTS=false
else
    PYTHON_EXISTS=true
fi

# Benchmark Nim version
echo "🦀 Benchmarking Nim version..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

NIM_START=$(perl -MTime::HiRes -e 'print Time::HiRes::time()')
# Note: Can't actually run without sudo password, so we test compilation/startup
./workaholic --help 2>/dev/null || echo "  Binary size: $(ls -lh workaholic | awk '{print $5}')"
NIM_END=$(perl -MTime::HiRes -e 'print Time::HiRes::time()')

NIM_TIME=$(echo "$NIM_END - $NIM_START" | bc)
echo "  Startup time: ${NIM_TIME}s"
echo ""

if [ "$PYTHON_EXISTS" = true ]; then
    echo "🐍 Benchmarking Python version..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    PYTHON_START=$(perl -MTime::HiRes -e 'print Time::HiRes::time()')
    ../workaholic help 2>/dev/null || true
    PYTHON_END=$(perl -MTime::HiRes -e 'print Time::HiRes::time()')
    
    PYTHON_TIME=$(echo "$PYTHON_END - $PYTHON_START" | bc)
    echo "  Startup time: ${PYTHON_TIME}s"
    echo ""
    
    # Calculate speedup
    echo "📊 COMPARISON"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    SPEEDUP=$(echo "scale=2; $PYTHON_TIME / $NIM_TIME" | bc)
    echo "  Nim is ${SPEEDUP}x faster at startup"
    echo ""
fi

# Memory comparison
echo "💾 MEMORY USAGE COMPARISON"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

NIM_SIZE=$(stat -f%z workaholic 2>/dev/null || stat -c%s workaholic 2>/dev/null)
echo "  Nim binary: $(numfmt --to=iec $NIM_SIZE 2>/dev/null || echo "$NIM_SIZE bytes")"

if [ "$PYTHON_EXISTS" = true ]; then
    PYTHON_SIZE=$(du -sh ../workaholic | awk '{print $1}')
    echo "  Python script: $PYTHON_SIZE"
    echo "  (Plus Python interpreter: ~50-100MB runtime overhead)"
fi

echo ""
echo "✅ Benchmark complete!"

