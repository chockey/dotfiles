#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
COLOR_OFF='\033[0m'

declare -a CARGO_TOOLS
CARGO_TOOLS=(
    bat
    ripgrep
    fd-find
)

function message() {
    local color="$1"
    local message="$2"
    echo -e "${color}[INSTALLER] ${message}${COLOR_OFF}"
}

function progress_msg() {
    message "${GREEN}" "${1}"
}

function warning_msg() {
    message "${YELLOW}" "${1}"
}

function error_msg() {
    message "${RED}" "${1}"
}

function cmd_exists() {
    cmd=$1
    command -v ${cmd} >/dev/null 2>&1
}

function install_or_update_dotbot() {
    python3 -m pip install --user --upgrade dotbot
}

function install_or_update_rust() {
    if cmd_exists rustup; then
        rustup update
    else
        mkdir -p ${SCRIPT_DIR}/.tmp
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs > ${SCRIPT_DIR}/.tmp/rustup-installer.sh
        sh ${SCRIPT_DIR}/.tmp/rustup-installer.sh -y --no-modify-path
    fi
}

function install_cargo_tools() {
    for tool in "${CARGO_TOOLS[@]}"; do
        "$HOME/.cargo/bin/cargo" install "${tool}"
    done
}

function install_links() {
    dotbot -c "${SCRIPT_DIR}/dotbot.yaml" --verbose
}

progress_msg "Installing required tools..."
install_or_update_dotbot
install_or_update_rust

progress_msg "Installing command line tools..."
install_cargo_tools

progress_msg "Setting up configuration files..."
install_links