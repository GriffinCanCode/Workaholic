# Workaholic v2.0 - System Optimizer

A high-performance, intelligent system optimization tool built in Nim for macOS.

## 🚀 Features

### Core Capabilities
- **Intelligent Cache Scoring**: Uses heuristics to prioritize what to clean based on size, age, and access patterns
- **Parallel Processing**: Cleans multiple cache directories simultaneously using async/await
- **Safe Deletion**: Checks permissions and safety before removing anything
- **Real-time TUI**: Beautiful terminal interface with live progress updates
- **Modular Architecture**: Clean separation of concerns for maintainability

### What It Optimizes
- ✅ Browser caches (Safari, Chrome, Firefox)
- ✅ Developer caches (Xcode, npm, cargo, Homebrew)
- ✅ Application caches
- ✅ System logs
- ✅ Memory (purge inactive pages)
- ✅ Disk space
- ✅ Network (DNS cache, TCP settings)

## 📋 Prerequisites

- macOS 10.15+
- Nim 2.0.0+ (install via `brew install nim`)
- Sudo access

## 🔧 Installation

```bash
# Clone the repository
git clone <repo-url>
cd workaholic

# Build the project
nimble build

# Make it executable
chmod +x workaholic
```

## ⚙️ Configuration

Create `~/.config/workaholic/config.toml` or use the included `config.toml`:

```toml
[general]
safety_level = "balanced"  # conservative, balanced, or aggressive
parallel_jobs = 4

[protected_apps]
always_keep = ["Terminal", "Cursor", "Google Chrome"]

[cleaning]
browser_caches = true
developer_caches = true
application_caches = true
system_logs = true
age_filter_days = 7

[optimization]
memory = true
disk = true
network = true
```

### Set Sudo Password

Create `~/.workaholic/.env`:
```bash
SUDO_PASSWORD=your_password_here
```

Or set environment variable:
```bash
export SUDO_PASSWORD=your_password_here
```

## 🎯 Usage

```bash
# Run optimization
./workaholic

# Development build
nimble dev

# Production build (optimized)
nimble build
```

## 🏗️ Architecture

```
src/
├── workaholic.nim              # Main entry point
└── workaholic/
    ├── config.nim              # Configuration management
    ├── types.nim               # Type definitions
    ├── ui.nim                  # TUI interface
    ├── core/
    │   ├── pipeline.nim        # Pipeline orchestration
    │   ├── scanner.nim         # Cache discovery
    │   ├── scorer.nim          # Intelligent scoring
    │   ├── cleaner.nim         # Safe deletion
    │   └── orchestrator.nim    # Workflow coordinator
    └── system/
        ├── apps.nim            # App management
        ├── memory.nim          # Memory optimization
        ├── disk.nim            # Disk operations
        ├── network.nim         # Network optimization
        └── stats.nim           # Statistics aggregation
```

## 🧠 Intelligent Design

### Smart Scoring Algorithm

```nim
score = (size_MB × age_days × safety_factor) / (access_frequency + 1)
```

Items with higher scores are prioritized for deletion:
- Large, old caches score higher
- Recently accessed items score lower
- Safe items score higher than risky ones

### Pipeline Architecture

1. **Scan Phase**: Discover all cache candidates in parallel
2. **Score Phase**: Calculate priority scores for each item
3. **Clean Phase**: Delete items in parallel with concurrency limit
4. **Optimize Phase**: Run system optimizations (memory, disk, network)

### Performance Optimizations

- **Async I/O**: Non-blocking file operations
- **Parallel Scanning**: Multiple directories scanned simultaneously
- **Batch Processing**: Items cleaned in optimized batches
- **ORC Memory Management**: Automatic reference counting with no GC pauses

## 🔒 Safety

- ✅ Only touches cache directories and temporary files
- ✅ Never deletes user documents or application data
- ✅ Checks write permissions before deletion
- ✅ Protected apps list to prevent closing critical apps
- ✅ Configurable safety levels

## 📊 Performance

Compared to the Python version:
- **3-5x faster** cleanup due to parallel processing
- **Lower memory usage** with ORC memory management
- **No GC pauses** during execution
- **Single binary** with no runtime dependencies

## 🛠️ Development

```bash
# Build for development
nimble dev

# Clean build artifacts
nimble clean

# Run directly
nimble run
```

## 📝 License

MIT License

## 🤝 Contributing

Contributions welcome! Please ensure:
- Code follows Nim style guidelines
- Modules remain logically separated
- Safety checks are maintained
- Performance optimizations are documented

