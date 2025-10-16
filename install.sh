#!/bin/bash

# Bleach SDDM Theme Installer
# Author: Fishson
# Version: 1.0

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

THEME_NAME="bleach_login"
SDDM_THEMES_DIR="/usr/share/sddm/themes"
THEME_INSTALL_DIR="${SDDM_THEMES_DIR}/${THEME_NAME}"
SDDM_CONFIG="/etc/sddm.conf.d/theme.conf"
CURRENT_USER="${SUDO_USER:-$USER}"
USER_HOME=$(eval echo ~${CURRENT_USER})

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

check_dependencies() {
    print_info "Checking dependencies..."
    
    local missing_deps=()
    
    if ! command -v sddm &> /dev/null; then
        missing_deps+=("sddm")
    fi
    
    if ! command -v sddm-greeter-qt6 &> /dev/null; then
        missing_deps+=("sddm (Qt6 greeter)")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Missing dependencies: ${missing_deps[*]}"
        print_info "Please install them first:"
        print_info "  Arch/Manjaro: sudo pacman -S sddm"
        print_info "  Ubuntu/Debian: sudo apt install sddm"
        print_info "  Fedora: sudo dnf install sddm"
        exit 1
    fi
    
    print_success "All dependencies satisfied"
}

backup_existing() {
    if [ -d "$THEME_INSTALL_DIR" ]; then
        print_warning "Theme directory already exists"
        local backup_dir="${THEME_INSTALL_DIR}_backup_$(date +%Y%m%d_%H%M%S)"
        print_info "Creating backup at: $backup_dir"
        mv "$THEME_INSTALL_DIR" "$backup_dir"
        print_success "Backup created"
    fi
}

install_theme() {
    print_info "Installing theme to $THEME_INSTALL_DIR..."
    
    mkdir -p "$SDDM_THEMES_DIR"
    
    cp -r "$(dirname "$0")" "$THEME_INSTALL_DIR"
    
    chmod -R 755 "$THEME_INSTALL_DIR"
    chown -R root:root "$THEME_INSTALL_DIR"
    
    print_success "Theme files installed"
}

setup_user_avatar() {
    print_info "Setting up user avatar..."
    
    local avatar_found=false
    local avatar_source=""
    
    if [ -f "${USER_HOME}/.face.icon" ]; then
        avatar_source="${USER_HOME}/.face.icon"
        avatar_found=true
    elif [ -f "${USER_HOME}/.face" ]; then
        avatar_source="${USER_HOME}/.face"
        avatar_found=true
    elif [ -f "/var/lib/AccountsService/icons/${CURRENT_USER}" ]; then
        avatar_source="/var/lib/AccountsService/icons/${CURRENT_USER}"
        avatar_found=true
    fi
    
    if [ "$avatar_found" = true ]; then
        print_success "Found existing avatar at: $avatar_source"
    else
        print_warning "No avatar found for user ${CURRENT_USER}"
        
        if [ -f "${THEME_INSTALL_DIR}/avatar.png" ] || [ -f "${THEME_INSTALL_DIR}/avatar.jpg" ]; then
            print_info "Using theme default avatar"
            local theme_avatar=$(find "${THEME_INSTALL_DIR}" -name "avatar.*" | head -1)
            avatar_source="$theme_avatar"
        else
            print_info "No avatar configured. You can add one later:"
            print_info "  cp /path/to/your/image.jpg ~/.face.icon"
            return
        fi
    fi
    
    if [ -n "$avatar_source" ]; then
        local accounts_icon_dir="/var/lib/AccountsService/icons"
        local accounts_user_file="/var/lib/AccountsService/users/${CURRENT_USER}"
        
        mkdir -p "$accounts_icon_dir"
        
        cp "$avatar_source" "${accounts_icon_dir}/${CURRENT_USER}"
        chmod 644 "${accounts_icon_dir}/${CURRENT_USER}"
        
        if [ ! -f "$accounts_user_file" ]; then
            cat > "$accounts_user_file" <<EOF
[User]
Icon=${accounts_icon_dir}/${CURRENT_USER}
EOF
        else
            if grep -q "^Icon=" "$accounts_user_file"; then
                sed -i "s|^Icon=.*|Icon=${accounts_icon_dir}/${CURRENT_USER}|" "$accounts_user_file"
            else
                echo "Icon=${accounts_icon_dir}/${CURRENT_USER}" >> "$accounts_user_file"
            fi
        fi
        
        chmod 644 "$accounts_user_file"
        print_success "Avatar configured for AccountsService"
    fi
}

configure_sddm() {
    print_info "Configuring SDDM..."
    
    mkdir -p "$(dirname "$SDDM_CONFIG")"
    
    if [ -f "$SDDM_CONFIG" ]; then
        local backup_config="${SDDM_CONFIG}.backup_$(date +%Y%m%d_%H%M%S)"
        print_info "Backing up existing config to: $backup_config"
        cp "$SDDM_CONFIG" "$backup_config"
    fi
    
    cat > "$SDDM_CONFIG" <<EOF
[Theme]
Current=${THEME_NAME}
CursorTheme=breeze_cursors

[General]
Numlock=on
EOF
    
    print_success "SDDM configured to use ${THEME_NAME} theme"
}

test_theme() {
    print_info "Would you like to test the theme before applying? (y/n)"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        print_info "Starting theme test mode..."
        print_warning "Press Ctrl+C to exit test mode"
        sleep 2
        sddm-greeter-qt6 --test-mode --theme "$THEME_INSTALL_DIR" || true
    fi
}

enable_sddm() {
    print_info "Enabling SDDM service..."
    
    systemctl enable sddm.service
    
    print_success "SDDM service enabled"
}

post_install_info() {
    echo ""
    print_success "Installation complete!"
    echo ""
    print_info "Next steps:"
    echo "  1. Review the configuration in: $SDDM_CONFIG"
    echo "  2. Restart SDDM to apply changes:"
    echo "     ${GREEN}sudo systemctl restart sddm${NC}"
    echo "  3. Or reboot your system"
    echo ""
    print_info "Customization:"
    echo "  • Change background: Edit ${THEME_INSTALL_DIR}/theme.conf"
    echo "  • Set user avatar: cp /path/to/image.jpg ~/.face.icon"
    echo "  • Theme files location: ${THEME_INSTALL_DIR}"
    echo ""
    print_info "Troubleshooting:"
    echo "  • View logs: sudo journalctl -u sddm -b"
    echo "  • Test theme: sddm-greeter-qt6 --test-mode --theme ${THEME_INSTALL_DIR}"
    echo ""
}

uninstall() {
    print_info "Uninstalling ${THEME_NAME}..."
    
    if [ -d "$THEME_INSTALL_DIR" ]; then
        rm -rf "$THEME_INSTALL_DIR"
        print_success "Theme files removed"
    fi
    
    if [ -f "$SDDM_CONFIG" ]; then
        rm -f "$SDDM_CONFIG"
        print_success "SDDM config removed"
    fi
    
    print_info "Please set another theme in your SDDM configuration"
}

show_help() {
    cat <<EOF
Bleach SDDM Theme Installer

Usage: sudo ./install.sh [OPTION]

Options:
  install       Install the theme (default)
  uninstall     Remove the theme
  test          Test the theme without installing
  help          Show this help message

Examples:
  sudo ./install.sh
  sudo ./install.sh install
  sudo ./install.sh uninstall
  sudo ./install.sh test

EOF
}

main() {
    local action="${1:-install}"
    
    case "$action" in
        install)
            print_info "Starting Bleach SDDM Theme installation..."
            check_root
            check_dependencies
            backup_existing
            install_theme
            setup_user_avatar
            configure_sddm
            test_theme
            enable_sddm
            post_install_info
            ;;
        uninstall)
            check_root
            uninstall
            ;;
        test)
            if [ ! -d "$THEME_INSTALL_DIR" ]; then
                print_error "Theme is not installed. Run './install.sh install' first"
                exit 1
            fi
            sddm-greeter-qt6 --test-mode --theme "$THEME_INSTALL_DIR"
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "Unknown option: $action"
            show_help
            exit 1
            ;;
    esac
}

main "$@"