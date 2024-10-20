#!/bin/bash

INPUT_FILE="docker-compose/docker-compose-full.yml.template"
OUTPUT_FILE="docker-compose/docker-compose-full.yml"
ENV_FILE=".env.docker"

TEMP_FILE=$(mktemp)
cp "$INPUT_FILE" "$TEMP_FILE"

while IFS= read -r line
do
    [[ $line =~ ^[[:space:]]*$ || $line =~ ^# ]] && continue
    key=$(echo "$line" | cut -d= -f1)
    value=$(echo "$line" | cut -d= -f2-)
    key=$(echo "$key" | xargs)
    value=$(echo "$value" | xargs)
    value=$(printf '%s\n' "$value" | sed -e 's/[\/&]/\\&/g')
    sed -i.bak "s|\${$key}|$value|g" "$TEMP_FILE"
done < "$ENV_FILE"

mv "$TEMP_FILE" "$OUTPUT_FILE"

echo "Processed $INPUT_FILE and wrote result to $OUTPUT_FILE"