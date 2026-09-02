#!/usr/bin/env bash

# Copyright (C) 2026 Neo Ctopher
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published
# under the terms of the GNU Affero General Public License,
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# See the GNU Affero General Public License in the LICENSE file
# distributed with this repository.
#
# This software uses the Swiss Ephemeris.
# Swiss Ephemeris is Copyright Astrodienst AG.
# See: https://www.astro.com/swisseph/


set -euo pipefail

# Usage:
#   ./moon-ingress.sh [start-date] [days] [timezone]
#
# Examples:
#   ./moon-ingress.sh
#   ./moon-ingress.sh 2026-07-25 14 America/Denver
#   ./moon-ingress.sh 2026-08-01 31 UTC
#
# The start date is interpreted at midnight in the chosen timezone.

START_DATE="${1:-$(date +%F)}"
DAYS="${2:-14}"
OUTPUT_TZ="${3:-America/Denver}"

# Change this when swetest is not in your PATH.
SWETEST="${SWETEST:-swetest}"

# Optional Swiss Ephemeris data directory.
# Example:
#   export SE_EPHE_PATH=/usr/share/libswe/ephe
EPHE_PATH="${SE_EPHE_PATH:-}"

SIGNS=(
    Aries Taurus Gemini Cancer Leo Virgo
    Libra Scorpio Sagittarius Capricorn Aquarius Pisces
)

# We scan in three-hour increments.
# The Moon normally spends roughly 2–3 days in a sign, so this gives
# a comfortable detection window before refining the exact time.
SCAN_STEP=$((3 * 60 * 60))

swetest_args=(
    -p1
    -fl
    -head
    -eswe
)

if [[ -n "$EPHE_PATH" ]]; then
    swetest_args+=("-edir${EPHE_PATH}")
fi

check_dependencies() {
    if ! command -v "$SWETEST" >/dev/null 2>&1; then
        echo "Error: swetest was not found." >&2
        echo "Set SWETEST to its full path, for example:" >&2
        echo "  export SWETEST=/usr/local/bin/swetest" >&2
        exit 1
    fi

    if ! command -v bc >/dev/null 2>&1; then
        echo "Error: bc is required." >&2
        echo "Install it with:" >&2
        echo "  sudo apt install bc" >&2
        exit 1
    fi
}

# Return the Moon's tropical geocentric longitude for a Unix timestamp.
moon_longitude() {
    local timestamp="$1"
    local date_arg
    local time_arg
    local output
    local longitude

    date_arg=$(date -u -d "@${timestamp}" '+%-d.%-m.%Y')
    time_arg=$(date -u -d "@${timestamp}" '+%H:%M:%S')

    output=$(
        "$SWETEST" \
            "-b${date_arg}" \
            "-ut${time_arg}" \
            "${swetest_args[@]}" 2>/dev/null
    )

    # Select the first line whose first field is numeric.
    longitude=$(
        awk '
            $1 ~ /^[-+]?[0-9]+([.][0-9]+)?$/ {
                print $1
                exit
            }
        ' <<< "$output"
    )

    if [[ -z "$longitude" ]]; then
        echo "Could not parse swetest output for ${date_arg} ${time_arg} UTC" >&2
        echo "$output" >&2
        return 1
    fi

    printf '%s\n' "$longitude"
}

sign_number() {
    local longitude="$1"

    awk -v lon="$longitude" '
        BEGIN {
            sign = int(lon / 30)

            if (sign < 0) {
                sign = 0
            }

            if (sign > 11) {
                sign = 11
            }

            print sign
        }
    '
}

# Locate the boundary between two timestamps known to be in different signs.
find_ingress() {
    local low="$1"
    local high="$2"
    local old_sign="$3"

    local middle
    local longitude
    local middle_sign

    while (( high - low > 1 )); do
        middle=$(( (low + high) / 2 ))
        longitude=$(moon_longitude "$middle")
        middle_sign=$(sign_number "$longitude")

        if (( middle_sign == old_sign )); then
            low="$middle"
        else
            high="$middle"
        fi
    done

    printf '%s\n' "$high"
}

print_ingress() {
    local timestamp="$1"
    local new_sign="$2"
    local longitude

    longitude=$(moon_longitude "$timestamp")

    printf '%-12s  %s  |  %s UTC  |  longitude %.6f°\n' \
        "${SIGNS[$new_sign]}" \
        "$(TZ="$OUTPUT_TZ" date -d "@${timestamp}" '+%Y-%m-%d %H:%M:%S %Z')" \
        "$(date -u -d "@${timestamp}" '+%Y-%m-%d %H:%M:%S')" \
        "$longitude"
}

main() {
    check_dependencies

    local start_timestamp
    local end_timestamp
    local current_timestamp
    local next_timestamp

    local previous_longitude
    local current_longitude
    local previous_sign
    local current_sign
    local ingress_timestamp

    start_timestamp=$(
        TZ="$OUTPUT_TZ" date -d "${START_DATE} 00:00:00" '+%s'
    )

    end_timestamp=$((start_timestamp + DAYS * 86400))

    previous_longitude=$(moon_longitude "$start_timestamp")
    previous_sign=$(sign_number "$previous_longitude")

    echo
    echo "Moon sign ingresses"
    echo "Start:    ${START_DATE}"
    echo "Period:   ${DAYS} days"
    echo "Timezone: ${OUTPUT_TZ}"
    echo "Zodiac:   Tropical"
    echo
    echo "Starting sign: ${SIGNS[$previous_sign]}"
    echo

    current_timestamp="$start_timestamp"

    while (( current_timestamp < end_timestamp )); do
        next_timestamp=$((current_timestamp + SCAN_STEP))

        if (( next_timestamp > end_timestamp )); then
            next_timestamp="$end_timestamp"
        fi

        current_longitude=$(moon_longitude "$next_timestamp")
        current_sign=$(sign_number "$current_longitude")

        if (( current_sign != previous_sign )); then
            ingress_timestamp=$(
                find_ingress \
                    "$current_timestamp" \
                    "$next_timestamp" \
                    "$previous_sign"
            )

            current_sign=$(
                sign_number "$(moon_longitude "$ingress_timestamp")"
            )

            print_ingress "$ingress_timestamp" "$current_sign"

            previous_sign="$current_sign"
        fi

        current_timestamp="$next_timestamp"
    done
}

main


