#!/data/data/com.termux/files/usr/bin/bash
set -e

# ==============================
# Script directory → cd there
# ==============================
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"
echo "📂 Changed directory to script location: $SCRIPT_DIR"

# ==============================
# Update Termux packages
# ==============================
echo "🔄 Updating Termux..."
pkg update && pkg upgrade -y

# ==============================
# Enable allow-external-apps
# ==============================
echo ""
echo "⚙️ Enabling allow-external-apps..."
TERMUX_DIR="$HOME/.termux"
TERMUX_PROP="$TERMUX_DIR/termux.properties"

mkdir -p "$TERMUX_DIR"

if [ -f "$TERMUX_PROP" ]; then
  if grep -q "^#\s*allow-external-apps\s*=\s*true" "$TERMUX_PROP"; then
    sed -i 's/^#\s*allow-external-apps\s*=\s*true/allow-external-apps = true/' "$TERMUX_PROP"
  elif ! grep -q "^allow-external-apps\s*=\s*true" "$TERMUX_PROP"; then
    echo "allow-external-apps = true" >> "$TERMUX_PROP"
  fi
else
  echo "allow-external-apps = true" > "$TERMUX_PROP"
fi

termux-reload-settings
echo "✅ allow-external-apps enabled"

# ==============================
# Install AcodeX server (axs)
# ==============================
echo ""
echo "📦 Checking AcodeX server (axs)..."
if ! command -v axs >/dev/null 2>&1; then
  echo "Installing axs..."
  curl -sL https://raw.githubusercontent.com/bajrangCoder/acode-plugin-acodex/main/installServer.sh | bash
else
  echo "✅ axs already installed"
fi

# ==============================
# Install extended Termux repo
# ==============================
echo ""
echo "📦 Checking extended Termux repo..."
if [ ! -f "$PREFIX/etc/apt/sources.list.d/termuxvoid.list" ]; then
  curl -sL https://termuxvoid.github.io/repo/install.sh | bash
else
  echo "✅ Extended repo already installed"
fi

pkg update && pkg upgrade -y

# ==============================
# Install Flutter
# ==============================
echo ""
echo "🚀 Checking Flutter..."
if ! command -v flutter >/dev/null 2>&1; then
  pkg install flutter -y
else
  echo "✅ Flutter already installed"
fi

pkg install dart -y


# ==============================
# Install Android SDK
# ==============================
echo ""
echo "📱 Checking Android SDK..."
ANDROID_SDK="$PREFIX/opt/android-sdk"
if [ ! -d "$ANDROID_SDK" ]; then
  pkg install android-sdk -y
else
  echo "✅ Android SDK already installed"
fi

# ==============================
# Environment variables
# ==============================
echo ""
echo "🔧 Setting environment variables..."
SHELL_RC="$HOME/.bashrc"
[ -n "$ZSH_VERSION" ] && SHELL_RC="$HOME/.zshrc"

cat >> "$SHELL_RC" <<EOF

# ==== Flutter ====
export FLUTTER_ROOT=\$PREFIX/opt/flutter
export PATH=\$FLUTTER_ROOT/bin:\$PATH

# ==== Android SDK ====
export ANDROID_HOME=\$PREFIX/opt/android-sdk
export ANDROID_SDK_ROOT=\$ANDROID_HOME
export PATH=\$ANDROID_HOME/platform-tools:\$PATH
export PATH=\$ANDROID_HOME/cmdline-tools/latest/bin:\$PATH

# ==== NDK & CMake ====
export ANDROID_NDK_HOME=\$ANDROID_HOME/ndk/29.0.14206865
export CMAKE_HOME=\$ANDROID_HOME/cmake/4.1.2/bin
export PATH=\$CMAKE_HOME:\$PATH

# ==== lsp-ws-proxy ====
export LSP_WS_PROXY="$SCRIPT_DIR/lsp-ws-proxy"
EOF

source "$SHELL_RC"
echo "✅ Environment variables configured"

# ==============================
# Flutter configuration
# ==============================
echo ""
echo "🧩 Configuring Flutter..."
flutter config --flutter-sdk "$PREFIX/opt/flutter"
flutter config --android-sdk "$ANDROID_SDK"

echo ""
echo "📜 Accepting Android licenses..."
yes | flutter doctor --android-licenses

# ==============================
# lsp-ws-proxy setup
# ==============================
echo ""
echo "🔌 Checking lsp-ws-proxy..."
if [ -f "$SCRIPT_DIR/lsp-ws-proxy" ]; then
  chmod +x "$SCRIPT_DIR/lsp-ws-proxy"
  echo "✅ lsp-ws-proxy ready at: $SCRIPT_DIR/lsp-ws-proxy"
else
  echo "⚠️ lsp-ws-proxy not found in script directory"
fi

# ==============================
# Run Flutter doctor
# ==============================
echo ""
echo "🩺 Running flutter doctor..."
flutter doctor

# ==============================
# Start axs server
# ==============================
echo ""
echo "🚀 Starting AcodeX server (axs)..."

echo ""
echo "🎉 Setup complete!"
echo ""
echo "📍 Flutter SDK: $PREFIX/opt/flutter"
echo "📍 Android SDK: $ANDROID_SDK"
echo "📍 lsp-ws-proxy: $SCRIPT_DIR/lsp-ws-proxy"
echo "📍 AcodeX server: running in background"
axs
