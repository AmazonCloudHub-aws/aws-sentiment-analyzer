#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
LAMBDA_DIR="${ROOT_DIR}/terraform/lambda"

if [ ! -d "${LAMBDA_DIR}" ]; then
  echo "No ${LAMBDA_DIR} directory found"
  exit 1
fi

echo "Packaging lambdas under ${LAMBDA_DIR} ..."

# Remove previous zips so packaging starts clean
find "${LAMBDA_DIR}" -maxdepth 1 -type f -name "*.zip" -print0 | xargs -0 -r rm -f

# Zip each subdirectory into terraform/lambda/<name>.zip, excluding caches and packaging metadata
for dir in "${LAMBDA_DIR}"/*; do
  [ -d "$dir" ] || continue
  name="$(basename "$dir")"
  zipfile="${LAMBDA_DIR}/${name}.zip"
  echo "Packaging ${name} -> ${zipfile}"
  # create a clean zip: exclude __pycache__ and packaging metadata
  (cd "$dir" && zip -r -q "${zipfile}" . -x "__pycache__/*" "*.dist-info/*" "*.egg-info/*" "*.pytest_cache/*")
done

echo "Lambda packaging complete. Zips are in ${LAMBDA_DIR}"
# ...existing code...
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
LAMBDA_DIR="${ROOT_DIR}/terraform/lambda"

if [ ! -d "${LAMBDA_DIR}" ]; then
  echo "No ${LAMBDA_DIR} directory found"
  exit 1
fi

echo "Packaging lambdas under ${LAMBDA_DIR} ..."

# Remove previous zips
find "${LAMBDA_DIR}" -maxdepth 1 -type f -name "*.zip" -print0 | xargs -0 -r rm -f

for dir in "${LAMBDA_DIR}"/*; do
  [ -d "$dir" ] || continue
  name="$(basename "$dir")"
  zipfile="${LAMBDA_DIR}/${name}.zip"
  echo "Packaging ${name} -> ${zipfile}"
  # create a clean zip: exclude __pycache__ and .dist-info directories if present
  (cd "$dir" && zip -r -q "${zipfile}" . -x "__pycache__/*" "*.dist-info/*" "*.egg-info/*" "*.pytest_cache/*")
done

echo "Lambda packaging complete. Zips are in ${LAMBDA_DIR}"#!/bin/bash

# List of Lambda function names
FUNCTIONS=("reddit_collector" "amazon_reviews_processor" "sentiment_analyzer")

# Ensure we're in the correct directory
if [[ ! -d "lambda" ]]; then
    echo "Error: 'lambda' directory not found. Please run this script from the project root."
    exit 1
fi

# Loop through each function
for func in "${FUNCTIONS[@]}"; do
    echo "Creating zip file for $func..."
    
    # Change to the function's directory
    cd "lambda/$func" || { echo "Error: Directory lambda/$func not found"; continue; }
    
    # Create the zip file in the lambda directory
    zip -r "../$func.zip" . || { echo "Error: Failed to create zip for $func"; cd ../..; continue; }
    
    # Return to the project root directory
    cd ../..
    
    echo "Zip file created: lambda/$func.zip"
    echo "------------------------"
done

echo "All zip files created successfully."