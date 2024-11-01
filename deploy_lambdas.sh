#!/bin/bash

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