#!/bin/bash

# --- Configuration ---
# Define the base directory containing project folders
CODE_DIR="source_code"
# Define the suffix for output files
OUTPUT_SUFFIX="_listing.txt"
# Define the directory where output files will be saved
OUTPUT_DIR="code_listings" # Changed from "."
# Define the code file extensions to include (add or remove as needed)
# Ensure each extension starts with a dot '.'
CODE_EXTENSIONS=(
    ".c" ".h" ".cpp" ".hpp" ".java" ".py" ".js" ".ts" ".html" ".css"
    ".sh" ".rb" ".go" ".rs" ".php" ".swift" ".kt" ".kts" ".scala"
    # Add more extensions here
)

# --- Script Logic ---

# Check if the code directory exists
if [ ! -d "$CODE_DIR" ]; then
  echo "Error: Input directory '$CODE_DIR' not found in the current path."
  exit 1
fi

# Create the output directory if it doesn't exist
# The -p flag prevents errors if it already exists and creates parent dirs if needed
mkdir -p "$OUTPUT_DIR"
if [ ! -d "$OUTPUT_DIR" ]; then
  echo "Error: Could not create output directory '$OUTPUT_DIR'."
  exit 1
fi


echo "Generating project source listings (recursively)..."
echo "Input directory: '$CODE_DIR'"
echo "Output directory: '$OUTPUT_DIR'"

# Change into the code directory to make find paths relative
# Use pushd/popd for safer directory navigation
pushd "$CODE_DIR" > /dev/null || exit 1 # Enter code dir, exit if fails

# Loop through each item in the code directory (potential project folders)
for project_dir in *; do
  # Check if it's actually a directory
  if [ -d "$project_dir" ]; then
    echo "Processing project: $project_dir"

    # Define the output file name for this specific project
    # Place it inside the OUTPUT_DIR relative to the original script location
    PROJECT_OUTPUT_FILE="../${OUTPUT_DIR}/${project_dir}${OUTPUT_SUFFIX}" # Updated path

    # Create or clear the output file for this project
    > "$PROJECT_OUTPUT_FILE"

    # Add a header indicating the project name inside the file
    echo "=======================================" >> "$PROJECT_OUTPUT_FILE"
    echo "=== Project Listing: $project_dir ===" >> "$PROJECT_OUTPUT_FILE"
    echo "=======================================" >> "$PROJECT_OUTPUT_FILE"
    echo "" >> "$PROJECT_OUTPUT_FILE"

    # --- Build the find command arguments for extensions ---
    find_args=()
    first_ext=true
    for ext in "${CODE_EXTENSIONS[@]}"; do
      if [ "$first_ext" = true ]; then
        find_args+=(-name "*$ext")
        first_ext=false
      else
        # Add '-o' (OR) before subsequent -name arguments
        find_args+=(-o -name "*$ext")
      fi
    done

    # Check if any extensions were defined
    if [ ${#find_args[@]} -eq 0 ]; then
        echo "Warning: No code extensions defined in CODE_EXTENSIONS array for project '$project_dir'. Skipping file search."
    else
        # --- Find and process all matching code files recursively ---
        # Use find -print0 and read -d '' for safe handling of filenames with spaces/special chars
        # Sort -z sorts null-terminated strings (paths) alphabetically
        # The find command searches within the specific $project_dir
        find "$project_dir" -type f \( "${find_args[@]}" \) -print0 | sort -z | while IFS= read -r -d $'\0' code_file; do
          # $code_file will contain the relative path like 'project_dir/subdir/file.c'
          echo "--- File: $code_file ---" >> "$PROJECT_OUTPUT_FILE"
          cat "$code_file" >> "$PROJECT_OUTPUT_FILE"
          # Add blank lines for readability between files
          echo "" >> "$PROJECT_OUTPUT_FILE"
          echo "" >> "$PROJECT_OUTPUT_FILE"
        done
    fi # End check for defined extensions

    echo " -> Created $PROJECT_OUTPUT_FILE"

  fi # End check if item is a directory
done # End loop through items in CODE_DIR

# Go back to the original directory
popd > /dev/null

echo "Source listing generation complete. Output files are in '$OUTPUT_DIR'."

exit 0