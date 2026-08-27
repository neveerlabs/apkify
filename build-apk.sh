#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'
BOLD='\033[1m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WEBAPP_DIR=""
APP_NAME=""
PACKAGE_ID=""
LOGO_PATH=""
VERSION_NAME="1.0"
VERSION_CODE=1
ANDROID_SDK_ROOT="$HOME/Android/Sdk"
CAPACITOR_DIR="$SCRIPT_DIR/capacitor-project"
FINAL_APK_DIR="$SCRIPT_DIR/output"
LOG_FILE="$SCRIPT_DIR/build-log-$(date +%Y%m%d-%H%M%S).log"
KEYSTORE_FILE="$SCRIPT_DIR/release.keystore"
KEYSTORE_PASSWORD=""
KEY_ALIAS=""
KEY_PASSWORD=""

START_TIME=$(date +%s)

log() {
    local level="$1"
    local msg="$2"
    local current_time=$(date +%s)
    local elapsed=$((current_time - START_TIME))
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local color=""
    case "$level" in
        INFO)  color=$GREEN ;;
        WARN)  color=$YELLOW ;;
        ERROR) color=$RED ;;
        DEBUG) color=$BLUE ;;
        *)     color=$NC ;;
    esac
    echo -e "${WHITE}[${timestamp}]${NC} ${color}[${level}]${NC} ${msg}${NC} ${CYAN}${elapsed}s${NC}" | tee -a "$LOG_FILE"
}

print_header() {
    clear
    local term_width=$(tput cols 2>/dev/null || echo 80)
    local text1="UNIVERSAL APK BUILDER"
    local text2="Build and sign your web app into a release APK"
    local padding1=$(( (term_width - ${#text1}) / 2 ))
    local padding2=$(( (term_width - ${#text2}) / 2 ))
    echo -e "$(printf "%${padding1}s" "")${BOLD}${WHITE}${text1}${NC}"
    echo -e "$(printf "%${padding2}s" "")${WHITE}${text2}${NC}"
    echo ""
}

show_guide() {
    local guide_file="$SCRIPT_DIR/main.md"
    if [ ! -f "$guide_file" ]; then
        log WARN "File panduan (main.md) tidak ditemukan. Lewati tampilan panduan."
        return
    fi

    print_header
    echo -e "${BOLD}${WHITE}MARKDOWN PREVIEW (raw)${NC}  ${CYAN}─${NC}  ${WHITE}\033[3mPanduan penggunaan script...\033[0m${NC}"
    echo -e "${CYAN}──────────────────────────────────────────────────────────────────${NC}"

    while IFS= read -r line; do
        if [[ "$line" =~ [Ee][Nn][Dd] ]]; then
            continue
        fi
        line=$(echo "$line" | sed -E 's/(<[^>]*>)/\\033[1;31m\1\\033[0m/g')
        line=$(echo "$line" | sed -E 's/^(#{1,3})\s+/\\033[1;34m\1 \\033[0m/')
        line=$(echo "$line" | sed -E 's/\*\*([^*]+)\*\*/\\033[1;37m\1\\033[0m/g')
        line=$(echo "$line" | sed -E 's/\*([^*]+)\*/\\033[3;36m\1\\033[0m/g')
        line=$(echo "$line" | sed -E 's/^(\s*)[*-]\s+/\\033[1;33m\1• \\033[0m/')
        line=$(echo "$line" | sed -E 's/^(\s*)([0-9]+)\.\s+/\\033[1;33m\1\2. \\033[0m/')
        line=$(echo "$line" | sed -E 's/\[([^\]]+)\]\(([^)]+)\)/\\033[4;34m\1\\033[0m (\\033[36m\2\\033[0m)/g')
        echo -e "$line"
    done < "$guide_file"

    echo -e "${CYAN}──────────────────────────────────────────────────────────────────${NC}"
    echo -e "${BOLD}${WHITE}Tekan ENTER untuk melanjutkan proses build, atau Ctrl+C untuk batal / menghentikan.${NC}"
    read -r
}

trap 'echo -e "\n${YELLOW}Proses dibatalkan oleh pengguna.${NC}"; stty sane; exit 1' INT

check_java() {
    if ! command -v java &> /dev/null; then
        log ERROR "Java not found. Please install OpenJDK 17 or 21."
        exit 1
    fi
    local java_version=$(java -version 2>&1 | head -1 | cut -d '"' -f2 | cut -d'.' -f1)
    if [[ "$java_version" != "17" && "$java_version" != "21" ]]; then
        log ERROR "Java version $java_version is not supported. Use Java 17 or 21."
        log INFO "Run: sudo apt install openjdk-21-jdk && export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64"
        exit 1
    fi
    log INFO "Java version $java_version (OK)"
}

check_android_sdk() {
    if [ ! -d "$ANDROID_SDK_ROOT" ]; then
        log WARN "Android SDK not found at $ANDROID_SDK_ROOT. Installing..."
        mkdir -p "$ANDROID_SDK_ROOT/cmdline-tools"
        cd "$ANDROID_SDK_ROOT/cmdline-tools"
        wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
        unzip -q commandlinetools-linux-*.zip
        rm commandlinetools-linux-*.zip
        mv cmdline-tools latest
        cd "$SCRIPT_DIR"
        yes | "$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager" --licenses > /dev/null 2>&1
        "$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager" "platform-tools" "platforms;android-35" "build-tools;35.0.0" > /dev/null 2>&1
        log INFO "Android SDK installed successfully."
    else
        log INFO "Android SDK found at $ANDROID_SDK_ROOT"
    fi
    export ANDROID_HOME="$ANDROID_SDK_ROOT"
    export PATH="$PATH:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$ANDROID_SDK_ROOT/build-tools"
}

check_node_npm() {
    if ! command -v node &> /dev/null; then
        log ERROR "Node.js not found. Please install Node.js."
        exit 1
    fi
    if ! command -v npm &> /dev/null; then
        log ERROR "npm not found. Please install npm."
        exit 1
    fi
    log INFO "Node.js $(node -v) and npm $(npm -v) (OK)"
}

setup_keystore() {
    if [ -f "$KEYSTORE_FILE" ]; then
        log INFO "Existing keystore found at $KEYSTORE_FILE"
        read -e -sp "Enter keystore password: " KEYSTORE_PASSWORD
        echo
        read -e -p "Enter key alias (default: release): " KEY_ALIAS
        KEY_ALIAS=${KEY_ALIAS:-release}
        read -e -sp "Enter key password (leave blank if same as keystore): " KEY_PASSWORD
        echo
        if [ -z "$KEY_PASSWORD" ]; then
            KEY_PASSWORD="$KEYSTORE_PASSWORD"
        fi
    else
        log INFO "No keystore found. Generating new one..."
        read -e -sp "Enter keystore password: " KEYSTORE_PASSWORD
        echo
        read -e -p "Enter key alias (default: release): " KEY_ALIAS
        KEY_ALIAS=${KEY_ALIAS:-release}
        read -e -sp "Enter key password (leave blank if same as keystore): " KEY_PASSWORD
        echo
        if [ -z "$KEY_PASSWORD" ]; then
            KEY_PASSWORD="$KEYSTORE_PASSWORD"
        fi
        read -e -p "Enter your full name (CN): " CN
        CN=${CN:-"Unknown"}
        read -e -p "Enter organizational unit (OU): " OU
        OU=${OU:-"Unknown"}
        read -e -p "Enter organization (O): " O
        O=${O:-"Unknown"}
        read -e -p "Enter city/locality (L): " L
        L=${L:-"Unknown"}
        read -e -p "Enter state/province (ST): " ST
        ST=${ST:-"Unknown"}
        read -e -p "Enter country code (C, two letters): " C
        C=${C:-"US"}
        keytool -genkey -v -keystore "$KEYSTORE_FILE" -alias "$KEY_ALIAS" -keyalg RSA -keysize 2048 -validity 10000 -storepass "$KEYSTORE_PASSWORD" -keypass "$KEY_PASSWORD" -dname "CN=$CN, OU=$OU, O=$O, L=$L, ST=$ST, C=$C" > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            log INFO "Keystore generated successfully: $KEYSTORE_FILE"
        else
            log ERROR "Failed to generate keystore."
            exit 1
        fi
    fi
}

prepare_capacitor_project() {
    local webapp_dir="$1"
    log INFO "Preparing Capacitor project in $CAPACITOR_DIR"
    rm -rf "$CAPACITOR_DIR"
    mkdir -p "$CAPACITOR_DIR/www"
    cp -r "$webapp_dir"/* "$CAPACITOR_DIR/www/" 2>/dev/null || true
    cd "$CAPACITOR_DIR"
    if [ ! -f "package.json" ]; then
        npm init -y > /dev/null 2>&1
    fi
    npm install @capacitor/core @capacitor/cli @capacitor/android > /dev/null 2>&1
    npx cap init "$APP_NAME" "$PACKAGE_ID" --web-dir www > /dev/null 2>&1
    npx cap add android > /dev/null 2>&1
    npm install @capacitor/assets > /dev/null 2>&1
    cd "$SCRIPT_DIR"
    log INFO "Capacitor project ready at $CAPACITOR_DIR"

    # ---- 🔧 FIX: Create local.properties with SDK path ----
    local local_prop="$CAPACITOR_DIR/android/local.properties"
    if [ ! -f "$local_prop" ]; then
        echo "sdk.dir=$ANDROID_SDK_ROOT" > "$local_prop"
        log INFO "Created local.properties with SDK path: $ANDROID_SDK_ROOT"
    else
        log INFO "local.properties already exists, skipping."
    fi
}

update_android_icons() {
    local logo_input="$1"
    if [ -z "$logo_input" ] || [ ! -f "$logo_input" ]; then
        return
    fi

    if ! command -v convert &> /dev/null; then
        log WARN "ImageMagick (convert) not found. Cannot generate icons. Install with: sudo apt install imagemagick"
        log WARN "Skipping icon update. APK will have default icon."
        return
    fi

    local android_res="$CAPACITOR_DIR/android/app/src/main/res"
    if [ ! -d "$android_res" ]; then
        log ERROR "Android resource folder not found: $android_res"
        return
    fi

    # ---- 🔧 FIX: Remove adaptive icon folder to avoid duplicate resources ----
    local adaptive_dir="$android_res/mipmap-anydpi-v26"
    if [ -d "$adaptive_dir" ]; then
        rm -rf "$adaptive_dir"
        log INFO "Removed existing mipmap-anydpi-v26 to avoid duplication with capacitor-assets"
    fi

    log INFO "Generating Android icons with ImageMagick..."
    declare -A sizes=(
        ["mipmap-mdpi"]=48
        ["mipmap-hdpi"]=72
        ["mipmap-xhdpi"]=96
        ["mipmap-xxhdpi"]=144
        ["mipmap-xxxhdpi"]=192
    )

    for folder in "${!sizes[@]}"; do
        local size=${sizes[$folder]}
        local target_dir="$android_res/$folder"
        mkdir -p "$target_dir"
        convert "$logo_input" -resize ${size}x${size} -background transparent -gravity center -extent ${size}x${size} "$target_dir/ic_launcher.png" 2>/dev/null || true
        cp "$target_dir/ic_launcher.png" "$target_dir/ic_launcher_round.png" 2>/dev/null || true
    done

    # Adaptive icon (512x512) for Play Store – now in its own folder without XML conflict
    mkdir -p "$adaptive_dir"
    convert "$logo_input" -resize 512x512 -background transparent -gravity center -extent 512x512 "$adaptive_dir/ic_launcher.png" 2>/dev/null || true
    cp "$adaptive_dir/ic_launcher.png" "$adaptive_dir/ic_launcher_round.png" 2>/dev/null || true

    log INFO "Android icons updated successfully."
}

handle_logo() {
    local logo_input="$1"
    if [ -z "$logo_input" ] || [ ! -f "$logo_input" ]; then
        log WARN "No valid logo provided. Skipping custom icon."
        return
    fi
    log INFO "Processing logo: $logo_input"
    cd "$CAPACITOR_DIR" || { log ERROR "Gagal masuk ke $CAPACITOR_DIR"; exit 1; }
    mkdir -p www/assets
    cp "$logo_input" www/assets/icon.png || log WARN "Gagal menyalin logo ke www/assets"

    if [ -f "node_modules/.bin/capacitor-assets" ]; then
        npx capacitor-assets generate --iconBackgroundColor '#FFFFFF' --splashBackgroundColor '#FFFFFF' --imagePath "$logo_input" > /dev/null 2>&1 || true
        if [ $? -eq 0 ]; then
            log INFO "Icons generated successfully using capacitor-assets."
        else
            log WARN "capacitor-assets generation failed, falling back to manual icon copy."
            local res_dir="android/app/src/main/res"
            mkdir -p "$res_dir"
            cp "$logo_input" "$res_dir/drawable/icon.png" || log WARN "Gagal copy ke drawable"
            mkdir -p "$res_dir/mipmap-hdpi" && cp "$logo_input" "$res_dir/mipmap-hdpi/icon.png" || true
            mkdir -p "$res_dir/mipmap-mdpi" && cp "$logo_input" "$res_dir/mipmap-mdpi/icon.png" || true
            mkdir -p "$res_dir/mipmap-xhdpi" && cp "$logo_input" "$res_dir/mipmap-xhdpi/icon.png" || true
            mkdir -p "$res_dir/mipmap-xxhdpi" && cp "$logo_input" "$res_dir/mipmap-xxhdpi/icon.png" || true
            mkdir -p "$res_dir/mipmap-xxxhdpi" && cp "$logo_input" "$res_dir/mipmap-xxxhdpi/icon.png" || true
        fi
    else
        log WARN "capacitor-assets not found, skipping automatic icon generation."
    fi

    update_android_icons "$logo_input"

    cd "$SCRIPT_DIR"
    log INFO "Logo processed."
}

build_apk_release() {
    local build_dir="$CAPACITOR_DIR/android"
    local gradlew="$build_dir/gradlew"
    chmod +x "$gradlew"
    sed -i "s/versionName .*/versionName \"$VERSION_NAME\"/" "$build_dir/app/build.gradle" 2>/dev/null || true
    sed -i "s/versionCode .*/versionCode $VERSION_CODE/" "$build_dir/app/build.gradle" 2>/dev/null || true
    cat >> "$build_dir/app/build.gradle" << EOF

android {
    signingConfigs {
        release {
            storeFile file('$KEYSTORE_FILE')
            storePassword '$KEYSTORE_PASSWORD'
            keyAlias '$KEY_ALIAS'
            keyPassword '$KEY_PASSWORD'
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled false
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
        }
    }
}
EOF
    log INFO "Building RELEASE APK (signed) for Play Store..."
    cd "$build_dir"
    ./gradlew assembleRelease --info
    if [ $? -ne 0 ]; then
        log ERROR "Gradle build failed. Check logs for details."
        exit 1
    fi
    cd "$SCRIPT_DIR"
    local apk_file="$build_dir/app/build/outputs/apk/release/app-release.apk"
    if [ -f "$apk_file" ]; then
        mkdir -p "$FINAL_APK_DIR"
        local final_name="${APP_NAME// /_}.apk"
        cp "$apk_file" "$FINAL_APK_DIR/$final_name"
        log INFO "Release APK built successfully: $FINAL_APK_DIR/$final_name"
    else
        log ERROR "Release APK build failed. Output not found."
        exit 1
    fi
}

cleanup() {
    log INFO "Cleaning up temporary files..."
    rm -rf "$CAPACITOR_DIR" 2>/dev/null || true
    log INFO "Cleanup complete."
}

main() {
    touch "$LOG_FILE"
    log INFO "=== Universal APK Builder Started ==="
    log INFO "Script directory: $SCRIPT_DIR"
    log INFO "Log file: $LOG_FILE"

    if [ $# -lt 1 ]; then
        log ERROR "Usage: $0 <path-to-webapp>"
        log ERROR "Example: $0 /path/to/your/webapp"
        exit 1
    fi
    WEBAPP_DIR="$(realpath "$1")"
    if [ ! -d "$WEBAPP_DIR" ]; then
        log ERROR "Webapp directory not found: $WEBAPP_DIR"
        exit 1
    fi
    log INFO "Webapp directory: $WEBAPP_DIR"

    show_guide

    read -e -p "Enter App Name (e.g., MyApp): " APP_NAME
    if [ -z "$APP_NAME" ]; then
        log ERROR "App Name cannot be empty."
        exit 1
    fi

    read -e -p "Enter Package ID (e.g., com.example.myapp): " PACKAGE_ID
    if [ -z "$PACKAGE_ID" ]; then
        log ERROR "Package ID cannot be empty."
        exit 1
    fi

    read -e -p "Enter Logo file path (optional, e.g., /path/to/logo.png): " LOGO_PATH
    if [ -n "$LOGO_PATH" ] && [ ! -f "$LOGO_PATH" ]; then
        log WARN "Logo file not found: $LOGO_PATH. Proceeding without custom logo."
        LOGO_PATH=""
    fi

    read -e -p "Enter version name (e.g., 1.0) [default: 1.0]: " VERSION_NAME
    VERSION_NAME=${VERSION_NAME:-1.0}

    read -e -p "Enter version code (integer) [default: 1]: " VERSION_CODE
    if ! [[ "$VERSION_CODE" =~ ^[0-9]+$ ]]; then
        log WARN "Version code must be integer. Using default: 1"
        VERSION_CODE=1
    fi

    log INFO "Configuration Summary:"
    log INFO "  App Name: $APP_NAME"
    log INFO "  Package ID: $PACKAGE_ID"
    log INFO "  Version: $VERSION_NAME ($VERSION_CODE)"
    log INFO "  Logo: ${LOGO_PATH:-'None'}"
    log INFO "  Webapp: $WEBAPP_DIR"

    log INFO "=== Phase 1: Checking Dependencies ==="
    check_java
    check_node_npm
    check_android_sdk

    log INFO "=== Phase 2: Keystore Setup for Play Store Signing ==="
    setup_keystore

    log INFO "=== Phase 3: Setting up Capacitor ==="
    prepare_capacitor_project "$WEBAPP_DIR"

    if [ -n "$LOGO_PATH" ]; then
        log INFO "=== Phase 4: Processing Logo ==="
        handle_logo "$LOGO_PATH"
    else
        log INFO "No logo provided. Skipping logo customization."
    fi

    log INFO "=== Phase 5: Building Release APK ==="
    build_apk_release

    log INFO "=== Phase 6: Cleanup ==="
    cleanup

    log INFO "=== Build Completed Successfully ==="
    log INFO "Output APK located at: $FINAL_APK_DIR"
    log INFO "Log saved to: $LOG_FILE"
    echo ""
    echo -e "${GREEN}Build complete! Your release-ready APK is ready for Play Store.${NC}"
    echo -e "Location: ${YELLOW}$FINAL_APK_DIR${NC}"
    echo -e "Log file: ${YELLOW}$LOG_FILE${NC}"
    echo -e "${BLUE}Note: Keep your keystore file ($KEYSTORE_FILE) safe. You'll need it for future updates.${NC}"
}

main "$@"
