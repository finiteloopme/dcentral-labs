# Show welcome message on first login
# Uses a marker file to track if welcome has been shown this session

_WELCOME_MARKER="/tmp/.welcome_shown_$$"

# Only show welcome on first interactive login
if [[ $- == *i* ]] && [[ ! -f "$_WELCOME_MARKER" ]]; then
    if command -v welcome &> /dev/null; then
        welcome
        touch "$_WELCOME_MARKER"
    fi
fi

unset _WELCOME_MARKER
