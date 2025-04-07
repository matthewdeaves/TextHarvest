#!/bin/bash

# --- Default Configuration ---
PDF_DIR="source_pdf"
OCR_DIR="ocr_pdf_output"
TXT_DIR="ocr_text_output"
OCR_LANG="eng"
# Default OCR mode: force OCR on all pages. Use -s or --skip-text flag to change.
OCR_MODE="force-ocr"
# Other potential ocrmypdf args can be added here if needed, e.g. "--deskew --clean"
OTHER_OCRMYPDF_ARGS=""

# --- Usage Function ---
usage() {
  echo "Usage: $0 [-s | --skip-text] [-l LANG] [-i INPUT_DIR] [-o OCR_DIR] [-t TEXT_DIR] [-h | --help]"
  echo ""
  echo "Processes PDF files in an input directory using OCRmyPDF and extracts text using pdftotext."
  echo ""
  echo "Options:"
  echo "  -s, --skip-text   Skip OCR on pages that already contain text (default is --force-ocr)."
  echo "  -l LANG           Specify OCR language(s) for Tesseract (default: 'eng')."
  echo "                    Example: 'eng+fra' for English and French."
  echo "  -i INPUT_DIR      Specify the input directory containing source PDFs (default: '$PDF_DIR')."
  echo "  -o OCR_DIR        Specify the intermediate directory for OCR'd PDFs (default: '$OCR_DIR')."
  echo "  -t TEXT_DIR       Specify the final directory for extracted text files (default: '$TXT_DIR')."
  echo "  -h, --help        Display this help message and exit."
  echo ""
  echo "Example:"
  echo "  $0 -l eng+deu -i my_scans -t extracted_texts"
  echo "  $0 --skip-text -i documents" # Use skip-text mode
  exit 1
}

# --- Argument Parsing ---
while [[ "$#" -gt 0 ]]; do
  case $1 in
    -s|--skip-text) OCR_MODE="skip-text"; shift ;;
    -l) OCR_LANG="$2"; shift; shift ;;
    -i) PDF_DIR="$2"; shift; shift ;;
    -o) OCR_DIR="$2"; shift; shift ;;
    -t) TXT_DIR="$2"; shift; shift ;;
    -h|--help) usage ;;
    *) echo "Unknown parameter passed: $1"; usage ;;
  esac
done

# Combine OCR mode flag with other potential arguments
OCRMYPDF_ARGS="--${OCR_MODE} ${OTHER_OCRMYPDF_ARGS}"
# Trim leading/trailing whitespace that might result if OTHER_OCRMYPDF_ARGS is empty
OCRMYPDF_ARGS=$(echo "$OCRMYPDF_ARGS" | awk '{$1=$1};1')


# --- Script Logic ---

echo "Starting OCR and Text Extraction Process..."

# Check if input directory exists
if [ ! -d "$PDF_DIR" ]; then
  echo "Error: Input directory '$PDF_DIR' not found."
  echo "Please create it and place your PDF files inside, or specify a different directory with -i."
  exit 1
fi

# Check if required commands exist
if ! command -v ocrmypdf &> /dev/null; then
    echo "Error: 'ocrmypdf' command not found."
    echo "Please install it (e.g., sudo apt update && sudo apt install ocrmypdf or pip install ocrmypdf)"
    exit 1
fi

if ! command -v pdftotext &> /dev/null; then
    echo "Error: 'pdftotext' command not found."
    echo "Please install poppler-utils (e.g., sudo apt update && sudo apt install poppler-utils)"
    exit 1
fi

# Create output directories if they don't exist
mkdir -p "$OCR_DIR"
mkdir -p "$TXT_DIR"

echo "Input PDF directory:          '$PDF_DIR'"
echo "Intermediate OCR PDF directory: '$OCR_DIR'"
echo "Final Text Output directory:    '$TXT_DIR'"
echo "OCR Language(s):              '$OCR_LANG'"
echo "OCR Mode (ocrmypdf flag):     '--${OCR_MODE}'"
echo "Additional ocrmypdf args:     '$OTHER_OCRMYPDF_ARGS'"
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
skipped_ocr_count=0
failed_ocr_count=0
failed_text_count=0

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
  echo "  Running OCRmyPDF with flags: -l \"$OCR_LANG\" $OCRMYPDF_ARGS"
  # Run ocrmypdf and capture its output to check for skipping messages
  # Use process substitution and tee to both capture output and display it
  ocr_output=$(ocrmypdf -l "$OCR_LANG" $OCRMYPDF_ARGS "$pdf_file" "$ocr_pdf_file" 2>&1 | tee /dev/tty)
  ocr_exit_code=$? # Capture exit code of ocrmypdf (left side of pipe)

  # Check if OCRmyPDF was successful
  if [ $ocr_exit_code -ne 0 ]; then
    # Check for specific exit code 6 which means "Input file is not a valid PDF" or similar non-OCR issues
    # Exit code 7 often means "Child process error" (like Tesseract failing)
    # Exit code 1 often means general error
    echo "  Error: OCRmyPDF failed for '$pdf_file' with exit code $ocr_exit_code. Skipping text extraction for this file."
    # You could add more specific error handling based on exit codes if needed
    # See ocrmypdf documentation for exit codes
    failed_ocr_count=$((failed_ocr_count + 1))
    echo "---------------------"
    continue # Skip to the next file in the loop
  fi

  # Check if ocrmypdf reported skipping pages (only relevant if using --skip-text)
  if [[ "$OCR_MODE" == "skip-text" ]] && echo "$ocr_output" | grep -q "skipping all processing on this page"; then
     echo "  Note: OCRmyPDF skipped processing on one or more pages due to existing text (--skip-text mode)."
     skipped_ocr_count=$((skipped_ocr_count + 1))
     # Continue processing even if pages were skipped
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
    failed_text_count=$((failed_text_count + 1))
  fi
  echo "---------------------"

done

echo "Batch processing complete."
echo "---------------------"
echo "Summary:"
echo "  Total PDF file(s) processed: $total_files"
echo "  OCR'd PDFs created in:       '$OCR_DIR'"
echo "  Extracted text files saved in: '$TXT_DIR'"
if [[ "$OCR_MODE" == "skip-text" ]]; then
  echo "  Files where OCR was skipped on some pages (due to --skip-text): $skipped_ocr_count"
fi
echo "  Files where OCRmyPDF failed:   $failed_ocr_count"
echo "  Files where pdftotext failed:  $failed_text_count"
echo "---------------------"


exit 0