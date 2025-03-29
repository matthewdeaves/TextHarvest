#!/bin/bash

# Define the input directory containing PDF files
PDF_DIR="source_pdf"

# Define the output directory for the text files
TXT_DIR="text_output"

# Check if the input directory exists
if [ ! -d "$PDF_DIR" ]; then
  echo "Error: Input directory '$PDF_DIR' not found."
  exit 1
fi

# Create the output directory if it doesn't exist
mkdir -p "$TXT_DIR"

# Check if poppler-utils (which contains pdftotext) is installed
if ! command -v pdftotext &> /dev/null; then
    echo "Error: 'pdftotext' command not found."
    echo "Please install poppler-utils: sudo apt update && sudo apt install poppler-utils"
    exit 1
fi

echo "Starting PDF to text conversion..."

# Loop through all PDF files in the input directory
# Using nullglob to avoid errors if no PDFs are found
shopt -s nullglob
pdf_files=("$PDF_DIR"/*.pdf)
shopt -u nullglob # Turn off nullglob after use

if [ ${#pdf_files[@]} -eq 0 ]; then
    echo "No PDF files found in the '$PDF_DIR' directory."
    exit 0
fi


for pdf_file in "${pdf_files[@]}"; do
  # Get the base name of the PDF file (e.g., "mybook" from "pdf/mybook.pdf")
  base_name=$(basename "$pdf_file" .pdf)

  # Define the output text file path
  txt_file="$TXT_DIR/${base_name}.txt"

  echo "Processing '$pdf_file' -> '$txt_file'"

  # Run pdftotext
  # Add any desired pdftotext options here (e.g., -layout, -raw)
  pdftotext "$pdf_file" "$txt_file"

  # Optional: Check if the command was successful
  if [ $? -eq 0 ]; then
    echo "Successfully converted '$base_name.pdf'"
  else
    echo "Error converting '$base_name.pdf'"
  fi
  echo "---------------------"
done

echo "Batch conversion complete. Text files are in '$TXT_DIR'."

exit 0