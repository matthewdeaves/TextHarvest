#!/bin/bash

# --- Configuration ---
# Input directory containing original PDF files
PDF_DIR="source_pdf"
# Intermediate directory to store PDFs after OCR processing
OCR_DIR="ocr_pdf_output"
# Final output directory for the extracted text files
TXT_DIR="ocr_text_output"
# Optional: Specify language(s) for Tesseract OCR, e.g., "eng+fra" for English and French
OCR_LANG="eng"
# Optional: Add extra arguments for ocrmypdf (e.g., "--deskew --clean")
OCRMYPDF_ARGS="--skip-text" # --skip-text is good practice for potentially mixed PDFs

# --- Script Logic ---

echo "Starting OCR and Text Extraction Process..."

# Check if input directory exists
if [ ! -d "$PDF_DIR" ]; then
  echo "Error: Input directory '$PDF_DIR' not found."
  echo "Please create it and place your PDF files inside."
  exit 1
fi

# Check if required commands exist
if ! command -v ocrmypdf &> /dev/null; then
    echo "Error: 'ocrmypdf' command not found."
    echo "Please install it: sudo apt update && sudo apt install ocrmypdf"
    exit 1
fi

if ! command -v pdftotext &> /dev/null; then
    echo "Error: 'pdftotext' command not found."
    echo "Please install poppler-utils: sudo apt update && sudo apt install poppler-utils"
    exit 1
fi

# Create output directories if they don't exist
mkdir -p "$OCR_DIR"
mkdir -p "$TXT_DIR"

echo "Input PDF directory:  '$PDF_DIR'"
echo "Intermediate OCR PDF directory: '$OCR_DIR'"
echo "Final Text Output directory: '$TXT_DIR'"
echo "OCR Language(s): '$OCR_LANG'"
echo "Additional ocrmypdf args: '$OCRMYPDF_ARGS'"
echo "---"


# Find PDF files - using nullglob to handle cases with no PDFs gracefully
shopt -s nullglob
pdf_files=("$PDF_DIR"/*.pdf)
shopt -u nullglob # Turn off nullglob after use

# Check if any PDF files were found
if [ ${#pdf_files[@]} -eq 0 ]; then
    echo "No PDF files found in the '$PDF_DIR' directory."
    exit 0
fi

# Loop through all PDF files in the input directory
total_files=${#pdf_files[@]}
current_file=0

for pdf_file in "${pdf_files[@]}"; do
  current_file=$((current_file + 1))
  echo "Processing file $current_file of $total_files: '$pdf_file'"

  # Get the base name of the PDF file (e.g., "mybook" from "pdf/mybook.pdf")
  base_name=$(basename "$pdf_file" .pdf)

  # Define the intermediate OCR'd PDF file path
  ocr_pdf_file="$OCR_DIR/${base_name}_ocr.pdf"
  # Define the final output text file path
  txt_file="$TXT_DIR/${base_name}.txt"

  # --- Step 1: Run OCRmyPDF ---
  echo "  Running OCRmyPDF..."
  # shellcheck disable=SC2086 # We want word splitting for OCRMYPDF_ARGS
  ocrmypdf -l "$OCR_LANG" $OCRMYPDF_ARGS "$pdf_file" "$ocr_pdf_file"

  # Check if OCRmyPDF was successful
  if [ $? -ne 0 ]; then
    echo "  Error: OCRmyPDF failed for '$pdf_file'. Skipping text extraction for this file."
    echo "---------------------"
    continue # Skip to the next file in the loop
  fi
  echo "  OCRmyPDF completed: '$ocr_pdf_file'"

  # --- Step 2: Extract text using pdftotext ---
  echo "  Extracting text..."
  pdftotext "$ocr_pdf_file" "$txt_file"

  # Check if pdftotext was successful
  if [ $? -eq 0 ]; then
    echo "  Text extracted successfully: '$txt_file'"
  else
    echo "  Error: pdftotext failed for '$ocr_pdf_file'."
  fi
  echo "---------------------"

done

echo "Batch processing complete."
echo "Processed $total_files PDF file(s)."
echo "OCR'd PDFs are in '$OCR_DIR'."
echo "Extracted text files are in '$TXT_DIR'."

exit 0