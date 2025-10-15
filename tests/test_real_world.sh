#!/bin/bash
# Real-world integration test

echo "╔══════════════════════════════════════════════════╗"
echo "║      REAL-WORLD INTEGRATION TEST                 ║"
echo "║      Tests actual system optimization            ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

# Safety check
echo "⚠️  WARNING: This test will actually run system optimization!"
echo "   It will:"
echo "   - Close non-protected applications"
echo "   - Clear system caches"
echo "   - Optimize memory"
echo "   - Require sudo password"
echo ""
read -p "Continue? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Test cancelled"
    exit 1
fi

# Check for sudo password
if [ -z "$SUDO_PASSWORD" ] && [ ! -f "$HOME/.workaholic/.env" ]; then
    echo "❌ SUDO_PASSWORD not set and ~/.workaholic/.env not found"
    echo "   Please set up authentication first"
    exit 1
fi

echo ""
echo "📊 CAPTURING BEFORE STATE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Memory before
echo "Memory before:"
vm_stat | head -5

# Disk before
echo ""
echo "Disk before:"
df -h / | tail -1

# Cache sizes before
echo ""
echo "Cache sizes before:"
CACHE_SIZE_BEFORE=$(du -sh ~/Library/Caches 2>/dev/null | awk '{print $1}')
echo "  ~/Library/Caches: $CACHE_SIZE_BEFORE"

LOG_SIZE_BEFORE=$(du -sh ~/Library/Logs 2>/dev/null | awk '{print $1}')
echo "  ~/Library/Logs: $LOG_SIZE_BEFORE"

echo ""
echo "⏱️  RUNNING WORKAHOLIC"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
START_TIME=$(date +%s)

# Run the optimizer
./workaholic

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo ""
echo "✅ Optimization complete in ${DURATION}s"
echo ""

echo "📊 CAPTURING AFTER STATE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Memory after
echo "Memory after:"
vm_stat | head -5

# Disk after
echo ""
echo "Disk after:"
df -h / | tail -1

# Cache sizes after
echo ""
echo "Cache sizes after:"
CACHE_SIZE_AFTER=$(du -sh ~/Library/Caches 2>/dev/null | awk '{print $1}')
echo "  ~/Library/Caches: $CACHE_SIZE_AFTER"

LOG_SIZE_AFTER=$(du -sh ~/Library/Logs 2>/dev/null | awk '{print $1}')
echo "  ~/Library/Logs: $LOG_SIZE_AFTER"

echo ""
echo "🎯 RESULTS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Execution time: ${DURATION}s"
echo "  Cache size: $CACHE_SIZE_BEFORE → $CACHE_SIZE_AFTER"
echo "  Logs size: $LOG_SIZE_BEFORE → $LOG_SIZE_AFTER"
echo ""

# Performance check
echo "🚀 PERFORMANCE VERIFICATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Testing system responsiveness..."

# Test 1: App launch time
echo -n "  App launch test: "
LAUNCH_START=$(perl -MTime::HiRes -e 'print Time::HiRes::time()')
open -a "System Preferences"
sleep 1
osascript -e 'quit app "System Preferences"'
LAUNCH_END=$(perl -MTime::HiRes -e 'print Time::HiRes::time()')
LAUNCH_TIME=$(echo "$LAUNCH_END - $LAUNCH_START" | bc)
echo "${LAUNCH_TIME}s"

# Test 2: File system responsiveness
echo -n "  File system test: "
FS_START=$(perl -MTime::HiRes -e 'print Time::HiRes::time()')
find ~/Library -name "*.log" -type f 2>/dev/null | head -100 > /dev/null
FS_END=$(perl -MTime::HiRes -e 'print Time::HiRes::time()')
FS_TIME=$(echo "$FS_END - $FS_START" | bc)
echo "${FS_TIME}s"

echo ""
echo "✅ Real-world test complete!"
echo ""
echo "💡 TIP: Compare these numbers to a run before optimization"
echo "   to see the actual performance improvement!"

