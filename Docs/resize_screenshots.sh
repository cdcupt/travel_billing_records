#!/bin/bash

# Configuration
INPUT_DIR="Docs/screenshots/original"
OUTPUT_DIR="Docs/screenshots/resized"
TARGET_WIDTH=1284
TARGET_HEIGHT=2778

# Ensure directories exist
mkdir -p "$OUTPUT_DIR"

# Check if input directory has images
shopt -s nullglob
files=("$INPUT_DIR"/*.{png,jpg,jpeg,PNG,JPG,JPEG})

if [ ${#files[@]} -eq 0 ]; then
    echo "No images found in $INPUT_DIR."
    echo "Please place your original screenshots in $INPUT_DIR first."
    exit 1
fi

echo "Found ${#files[@]} images. Resizing to ${TARGET_WIDTH}x${TARGET_HEIGHT}..."

for file in "${files[@]}"; do
    filename=$(basename "$file")
    extension="${filename##*.}"
    filename="${filename%.*}"
    
    output_file="$OUTPUT_DIR/${filename}_resized.${extension}"
    
    # Resize using sips (height width)
    sips -z $TARGET_HEIGHT $TARGET_WIDTH "$file" --out "$output_file" > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo "✅ Resized: $filename"
    else
        echo "❌ Failed to resize: $filename"
    fi
done

echo "Done! Resized images are in $OUTPUT_DIR"
