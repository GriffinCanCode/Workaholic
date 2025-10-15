#!/bin/bash
# Setup script for Workaholic

set -e

echo "🔧 Setting up Workaholic..."

# Check if Nim is installed
if ! command -v nim &> /dev/null; then
    echo "❌ Nim is not installed. Install it with: brew install nim"
    exit 1
fi

echo "✅ Nim found: $(nim --version | head -n1)"

# Create config directory
mkdir -p ~/.config/workaholic
if [ ! -f ~/.config/workaholic/config.toml ]; then
    cp config.toml ~/.config/workaholic/config.toml
    echo "✅ Created config at ~/.config/workaholic/config.toml"
fi

# Create .env directory
mkdir -p ~/.workaholic
if [ ! -f ~/.workaholic/.env ]; then
    echo "⚠️  Please create ~/.workaholic/.env with your SUDO_PASSWORD"
    echo "Example:"
    echo "  echo 'SUDO_PASSWORD=your_password' > ~/.workaholic/.env"
    echo "  chmod 600 ~/.workaholic/.env"
fi

# Build the project
echo "🔨 Building Workaholic..."
nimble build

echo "✅ Setup complete!"
echo ""
echo "To run: ./workaholic"

