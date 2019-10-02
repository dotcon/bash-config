# Copyright (c) 2018 Herbert Shen <ishbguy@hotmail.com> All Rights Reserved.
# Released under the terms of the MIT License.

export BASH_PROMPT_ABS_SRC="$(realpath "${BASH_SOURCE[0]}")"
export BASH_PROMPT_ABS_DIR="$(dirname "$BASH_PROMPT_ABS_SRC")"

# declare -p BASH_PRECMDS &>/dev/null || return 1
# declare -p BASH_ANSI_COLOR &>/dev/null || return 1

declare -ga BASH_PROMPT_PS1_LAYOUT=()
declare -ga BASH_PROMPT_COUNTERS=()
declare -gA BASH_PROMPT_COLOR=()
declare -gA BASH_PROMPT_CHARS=()

bash_prompt_color() {
    local color="${BASH_ANSI_COLOR[default]}"
    if has_map BASH_ANSI_COLOR "$1"; then
        color="${BASH_ANSI_COLOR[$1]}"; shift;
        has_map BASH_ANSI_COLOR "$1" \
            && { color="$color;${BASH_ANSI_COLOR[$1]}"; shift; }
    fi
    color="\\[\\033[${color}m\\]"
    printf '%s%s%s\n' "$color" "$*" '\[\033[00m\]'
}

bash_prompt_last_status() {
    local color="${BASH_PROMPT_COLOR[last_fail]:-red}"
    [[ $LAST_STATUS -eq 0 ]] && color="${BASH_PROMPT_COLOR[last_ok]:-green}"
    bash_prompt_color $color "${BASH_PROMPT_CHARS[last_status]:-&}"
}

bash_prompt_time() {
    bash_prompt_color ${BASH_PROMPT_COLOR[time]:-green} \
        "${BASH_PROMPT_CHARS[time]:-[\A]}"
}

bash_prompt_location() {
    bash_prompt_color ${BASH_PROMPT_COLOR[location]:-blue} \
        "${BASH_PROMPT_CHARS[location]:-[\u@\h:\W]}"
}

BASH_PROMPT_COUNTERS+=('dirs -p | tail -n +2 | wc -l')
BASH_PROMPT_COUNTERS+=('jobs -p | wc -l')
bash_prompt_counter() {
    local -A counters
    local str=''
    for cnt in "${BASH_PROMPT_COUNTERS[@]}"; do
        local nr="$(eval "$cnt")"
        [[ $nr =~ ^[[:digit:]]+$ && $nr != 0 ]] || continue
        cnt="${cnt// /}"
        for ((len = 1; len <= ${#cnt}; len++)); do
            [[ -z ${counters[${cnt:0:$len}]} ]] || continue
            str+="${cnt:0:$len}$nr"
            counters[${cnt:0:$len}]="$nr"
            break
        done
    done
    [[ -n $str ]] && bash_prompt_color ${BASH_PROMPT_COLOR[counter]:-yellow} "[$str]"
}

bash_prompt_dollar() {
    bash_prompt_color ${BASH_PROMPT_COLOR[dollar]:-blue} \
        "${BASH_PROMPT_CHARS[dollar]:-\$ }"
}

BASH_PROMPT_PS1_LAYOUT=(
    bash_prompt_last_status
    bash_prompt_time
    bash_prompt_location
    bash_prompt_counter
)
bash_prompt_PS1() {
    PS1=
    for layout in "${BASH_PROMPT_PS1_LAYOUT[@]}"; do
        definedf "$layout" && PS1+="$($layout)"
    done
    PS1+="$(bash_prompt_dollar)"
    export PS1
}

BASH_PRECMDS+=('bash_prompt_PS1')

export PS4='+ $(basename ${0##+(-)}) line $LINENO: '

# vim:set ft=sh ts=4 sw=4: