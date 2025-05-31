#!/bin/bash

# Script to download NYC TLC Trip Record Data (Yellow, Green, FHV)
# Usage: ./download_taxi_data.sh <year> <taxi_color> [month1 month2 ...]
# Example: ./download_taxi_data.sh 2024 yellow 01 02 03
# Example: ./download_taxi_data.sh 2023 green 11 12
# Example: ./download_taxi_data.sh 2022 fhv 07
# Example: ./download_taxi_data.sh 2021 all 01 02 # Downloads all colors for Jan/Feb 2021
# Example: ./download_taxi_data.sh 2024 yellow all_months # Downloads all months for Yellow 2024

# Base URL for the data files
BASE_URL="https://d37ci6vzurychx.cloudfront.net/trip-data"

# Check if year and color are provided
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: $0 <year> <taxi_color> [month1 month2 ...]"
    echo "  <year>: Four-digit year (e.g., 2023)"
    echo "  <taxi_color>: yellow, green, fhv, fhv_bases, high_volume_fhv, or 'all'"
    echo "  [month1 month2 ...]: One or more two-digit months (e.g., 01 02 12)"
    echo "                       or 'all_months' to download all 12 months."
    exit 1
fi

YEAR="$1"
TAXI_COLOR_ARG="$2"
shift 2 # Shift arguments so months are $1, $2, etc.

# Validate year format
if ! [[ "$YEAR" =~ ^[0-9]{4}$ ]]; then
    echo "Error: Year must be a four-digit number."
    exit 1
fi

# Function to download a single file
download_file() {
    local year=$1
    local color=$2
    local month=$3
    local filename="${color}_tripdata_${year}-${month}.parquet"
    local full_url="${BASE_URL}/${filename}"
    local output_dir="${year}/${color}"
    local output_path="${output_dir}/${filename}"

    echo "Attempting to download: $full_url"

    # Create output directory if it doesn't exist
    mkdir -p "$output_dir"

    # Use wget with options:
    # -nc: Don't clobber (don't overwrite existing files)
    # --show-progress: Show download progress
    # --spider: Don't download, just check if the file exists (for initial check)
    # -q: Quiet mode for spider check
    # -O: Output file name
    if wget --spider -q "$full_url"; then
        echo "  File found. Downloading..."
        if wget -nc --show-progress -O "$output_path" "$full_url"; then
            echo "  Successfully downloaded: $output_path"
        else
            echo "  Failed to download: $full_url"
        fi
    else
        echo "  File not found or URL is invalid: $full_url"
    fi
    echo "" # Newline for spacing
}

# Define available taxi colors
declare -a ALL_TAXI_COLORS=("yellow" "green" "fhv" "fhv_bases" "high_volume_fhv")

# Determine which colors to process
TARGET_COLORS=()
if [ "$TAXI_COLOR_ARG" == "all" ]; then
    TARGET_COLORS=("${ALL_TAXI_COLORS[@]}")
else
    # Validate the single color provided
    found=false
    for c in "${ALL_TAXI_COLORS[@]}"; do
        if [ "$c" == "$TAXI_COLOR_ARG" ]; then
            TARGET_COLORS+=("$TAXI_COLOR_ARG")
            found=true
            break
        fi
    done
    if ! $found; then
        echo "Error: Invalid taxi color '$TAXI_COLOR_ARG'."
        echo "Valid colors are: ${ALL_TAXI_COLORS[@]} or 'all'."
        exit 1
    fi
fi

# Determine which months to process
MONTHS=()
if [ -z "$1" ] || [ "$1" == "all_months" ]; then
    for i in $(seq -w 1 12); do # -w pads with zeros (01, 02, ...)
        MONTHS+=("$i")
    done
else
    # Validate provided months
    for month_arg in "$@"; do
        if ! [[ "$month_arg" =~ ^(0[1-9]|1[0-2])$ ]]; then
            echo "Error: Invalid month format '$month_arg'. Months must be two digits (e.g., 01, 12)."
            exit 1
        fi
        MONTHS+=("$month_arg")
    done
fi

# Loop through colors and months to download
for color in "${TARGET_COLORS[@]}"; do
    echo "--- Processing ${color} taxi data for year ${YEAR} ---"
    for month in "${MONTHS[@]}"; do
        download_file "$YEAR" "$color" "$month"
    done
done
