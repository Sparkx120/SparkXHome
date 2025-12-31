cargo-activate() {
    if [ -f $HOME/.cargo/env ]; then
        . "$HOME/.cargo/env"
    fi
}
if $SPARKX_HOME_ALWAYS_ACTIVATE_CARGO; then
    cargo-activate
fi

