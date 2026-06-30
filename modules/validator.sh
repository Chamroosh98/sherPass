#!/bin/sh

# shellcheck shell=ash
# Input and Keyboard Layout Strict Validator Module

validate_ascii_input() {
    local user_input=$1
    
    user_input=$(echo "$user_input" | tr -d ' ')
    
    if [ -z "$user_input" ]; then
        echo "empty"
        return 0
    fi

    if echo "$user_input" | grep -q '[^a-zA-Z]'; then
        echo "non-ascii"
        return 0
    fi

    echo "$user_input"
}