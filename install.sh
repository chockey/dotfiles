#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
COLOR_OFF='\033[0m'

declare -a REQUIRED_CMDS
REQUIRED_CMDS=(
    pipx
    curl
)

declare -a CARGO_TOOLS
CARGO_TOOLS=(
    bat
    ripgrep
    fd-find
)

GO_VERSION=1.26.2
declare -a GO_TOOLS
GO_TOOLS=(
    github.com/junegunn/fzf@latest
    github.com/jesseduffield/lazydocker@latest
    github.com/wagoodman/dive@latest
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

function ensure_dirs() {
    mkdir -p ${LOCAL_PREFIX}/bin
    mkdir -p ${LOCAL_PREFIX}/lib
    mkdir -p ${LOCAL_PREFIX}/share
}

function ensure_cmds() {
    for cmd in "${REQUIRED_CMDS[@]}"; do
        if ! cmd_exists "${cmd}"; then
            error_msg "Required command '${cmd}' not on path. Please install it first!"
            exit 1
        fi
    done
}

function make_bin_links() {
    dir=$1

    (
        cd ${LOCAL_PREFIX}/bin
        for l in ${dir}/*; do
            if [ -x "${l}" ]; then
                ln -sf "${l}"
            fi
        done
    )
}

function install_or_update_dotbot() {
    if cmd_exists dotbot; then
        pipx upgrade dotbot
    else
        pipx install dotbot
    fi

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

function install_go() {
    mkdir -p ${SCRIPT_DIR}/.tmp
    curl -L -o ${SCRIPT_DIR}/.tmp/go.tar.gz "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"

    INSTALL_DIR=$(dirname ${GOROOT})

    mkdir -p ${INSTALL_DIR}
    rm -rf ${GOROOT}
    tar -C ${INSTALL_DIR} -xf ${SCRIPT_DIR}/.tmp/go.tar.gz

    make_bin_links ${GOROOT}/bin
}

function install_go_tools() {
    mkdir -p ${GOPATH}
    for tool in "${GO_TOOLS[@]}"; do
        go install "${tool}"
    done

    make_bin_links ${GOPATH}/bin
}

function install_cargo_tools() {
    for tool in "${CARGO_TOOLS[@]}"; do
        "$HOME/.cargo/bin/cargo" install "${tool}"
    done
}

function install_links() {
    dotbot -c "${SCRIPT_DIR}/dotbot.yaml" --verbose
}

# Make sure the new install dirs are set
export LOCAL_PREFIX=$HOME/.local
export PATH=${LOCAL_PREFIX}/bin:$PATH
export GOROOT=${LOCAL_PREFIX}/share/go
export GOPATH=${LOCAL_PREFIX}/share/gopath

progress_msg "Ensuring we're ready for setup..."
ensure_dirs
ensure_cmds

progress_msg "Installing required tools..."
install_or_update_dotbot
install_or_update_rust
install_go

progress_msg "Installing command line tools..."
install_cargo_tools
install_go_tools

progress_msg "Setting up configuration files..."
install_links
