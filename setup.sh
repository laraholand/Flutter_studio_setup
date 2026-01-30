#!/data/data/com.termux/files/usr/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"
echo " Changed directory to script location: $SCRIPT_DIR"

echo " Updating Termux..."
pkg update && pkg upgrade -y
pkg install git nodejs-lts -y

echo " Enabling allow-external-apps..."
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
echo " allow-external-apps enabled"

echo " Checking AcodeX server (axs)..."
if ! command -v axs >/dev/null 2>&1; then
  echo "Installing axs..."
  curl -sL https://raw.githubusercontent.com/bajrangCoder/acode-plugin-acodex/main/installServer.sh | bash
else
  echo " axs already installed"
fi

echo " Checking extended Termux repo..."
if [ ! -f "$PREFIX/etc/apt/sources.list.d/termuxvoid.list" ]; then
  curl -sL https://termuxvoid.github.io/repo/install.sh | bash
else
  echo " Extended repo already installed"
fi

pkg update && pkg upgrade -y

echo "🚀 Checking Flutter..."
if ! command -v flutter >/dev/null 2>&1; then
  pkg install flutter -y
else
  echo " Flutter already installed"
fi

pkg install dart -y

ANDROID_SDK="$PREFIX/opt/android-sdk"
if [ ! -d "$ANDROID_SDK" ]; then
  pkg install android-sdk -y
else
  echo " Android SDK already installed"
fi

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
echo "Environment variables configured"

flutter config --flutter-sdk "$PREFIX/opt/flutter"
flutter config --android-sdk "$ANDROID_SDK"

yes | flutter doctor --android-licenses

if [ -f "$SCRIPT_DIR/lsp-ws-proxy" ]; then
  chmod +x "$SCRIPT_DIR/lsp-ws-proxy"
  echo " lsp-ws-proxy ready at: $SCRIPT_DIR/lsp-ws-proxy"
else
  echo " lsp-ws-proxy not found in script directory"
fi

flutter doctor

echo " Flutter SDK: $PREFIX/opt/flutter"
echo "Android SDK: $ANDROID_SDK"
echo " lsp-ws-proxy: $SCRIPT_DIR/lsp-ws-proxy"
echo "AcodeX server: running in background"
npm install --global vscode-html-languageserver-bin
axs
