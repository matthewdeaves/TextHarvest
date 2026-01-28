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
  echo "Provides a menu to select all or specific PDFs for processing."
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


# --- Script Initialization ---
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

# --- File Discovery and Selection Menu ---
shopt -s nullglob # Globs that match nothing expand to nothing
all_pdf_files_in_dir=("$PDF_DIR"/*.pdf)
shopt -u nullglob # Turn off nullglob after use

if [ ${#all_pdf_files_in_dir[@]} -eq 0 ]; then
    echo "No PDF files found in the '$PDF_DIR' directory."
    exit 0
fi

declare -a files_to_process # This will hold the final list of files to process

while true; do # Main menu loop
  echo ""
  echo "PDF Processing Menu:"
  echo "1) Process ALL ${#all_pdf_files_in_dir[@]} PDF(s) found in '$PDF_DIR'"
  echo "2) Select specific PDF(s) to process"
  echo "Q) Quit"
  read -r -p "Enter your choice (1, 2, Q): " main_choice
  main_choice=$(echo "$main_choice" | tr '[:upper:]' '[:lower:]') # Normalize to lowercase

  case "$main_choice" in
    "1")
      files_to_process=("${all_pdf_files_in_dir[@]}")
      echo "Selected to process all ${#files_to_process[@]} files."
      break # Exit main menu loop, proceed to processing
      ;;
    "2")
      echo ""
      echo "Available PDF files in '$PDF_DIR':"
      for i in "${!all_pdf_files_in_dir[@]}"; do
        printf "  %2d) %s\n" "$((i + 1))" "$(basename "${all_pdf_files_in_dir[$i]}")"
      done
      
      # File selection sub-menu loop
      while true; do
        current_selection_this_attempt=() # Reset for this specific attempt
        unique_indices_chosen=""    # Reset for this specific attempt to track unique indices (space-separated string for bash 3.2 compatibility)

        echo ""
        read -r -p "Enter file numbers (comma-separated, e.g., 1,3,5), 'a' for all listed, or 'b' for back: " selection_input
        selection_input_normalized=$(echo "$selection_input" | tr '[:upper:]' '[:lower:]')

        if [[ "$selection_input_normalized" == "b" ]]; then
          break # Exit file selection loop, go back to main menu
        elif [[ "$selection_input_normalized" == "a" ]]; then
          files_to_process=("${all_pdf_files_in_dir[@]}")
          echo "All ${#files_to_process[@]} files selected for processing."
          break # Exit file selection loop, selection is final
        fi

        # Attempt to parse comma-separated numbers
        IFS=',' read -r -a raw_indices <<< "$selection_input"
        parse_error=false
        for index_str in "${raw_indices[@]}"; do
          index_str_trimmed=$(echo "$index_str" | awk '{$1=$1};1') # Trim whitespace
          if [[ -z "$index_str_trimmed" ]]; then continue; fi # Skip empty elements like in "1,,2"

          if ! [[ "$index_str_trimmed" =~ ^[1-9][0-9]*$ ]]; then
            echo "Error: Invalid input '$index_str_trimmed'. Not a positive number."
            parse_error=true
            break # Exit this for-loop (parsing indices)
          fi
          
          actual_index=$((index_str_trimmed - 1)) # Convert to 0-based index

          if (( actual_index < 0 || actual_index >= ${#all_pdf_files_in_dir[@]} )); then
            echo "Error: File number '$index_str_trimmed' is out of range (1 to ${#all_pdf_files_in_dir[@]})."
            parse_error=true
            break # Exit this for-loop
          fi

          if [[ ! " $unique_indices_chosen " =~ " $actual_index " ]]; then # Check if index already picked in *this* input string (bash 3.2 compatible)
            current_selection_this_attempt+=("${all_pdf_files_in_dir[$actual_index]}")
            unique_indices_chosen="$unique_indices_chosen $actual_index"
          else
            echo "Note: File number $index_str_trimmed ('$(basename "${all_pdf_files_in_dir[$actual_index]}")') was already included in this specific entry. Processing once."
          fi
        done # End for index_str

        if $parse_error; then
          echo "Please re-enter your selection, or choose 'a' for all, 'b' for back."
          continue # Go to next iteration of file selection sub-menu loop (re-prompt)
        fi

        if [ ${#current_selection_this_attempt[@]} -eq 0 ]; then
            if [[ -n "$selection_input" ]]; then # Input was given, but resulted in no files
                 echo "No valid file numbers were specified in '$selection_input'. Please try again, 'a', or 'b'."
            else # Truly empty line entered by user
                 echo "No input. Please enter file numbers, 'a' for all, or 'b' for back."
            fi
            continue # Re-prompt in file selection sub-menu
        fi

        # If we reach here, current_selection_this_attempt has some files. Confirm with user.
        echo ""
        echo "You have selected the following file(s) for processing:"
        for f_path in "${current_selection_this_attempt[@]}"; do
          echo "  - $(basename "$f_path")"
        done
        
        read -r -p "Proceed with these ${#current_selection_this_attempt[@]} file(s)? (Y/n/r - reselect): " confirm_choice
        confirm_choice_normalized=$(echo "$confirm_choice" | tr '[:upper:]' '[:lower:]')

        if [[ "$confirm_choice_normalized" == "y" || -z "$confirm_choice_normalized" ]]; then # Default to Yes
          files_to_process=("${current_selection_this_attempt[@]}")
          break # Exit file selection loop, selection is made and confirmed.
        elif [[ "$confirm_choice_normalized" == "r" ]]; then
          echo "Reselecting files..."
          continue # Re-prompt in file selection sub-menu
        else # "n" or anything else considered as No
          echo "Selection discarded. Please enter new selection, 'a' for all, or 'b' for back."
          continue # Re-prompt in file selection sub-menu
        fi
      done # End file selection sub-menu while-loop

      # This point is reached after breaking from the file selection sub-menu loop
      # If 'b' was chosen in sub-menu, selection_input_normalized will be "b".
      # files_to_process would be populated if 'a' or a confirmed selection was made.
      if [[ "$selection_input_normalized" == "b" ]]; then
        files_to_process=() # Ensure it's empty if user went back so main menu re-prompts
        continue # Go back to the main menu prompt
      fi
      
      # If files_to_process is populated, it means selection is final (either 'a' or confirmed numbers)
      if [ ${#files_to_process[@]} -gt 0 ]; then
        echo "Proceeding to process ${#files_to_process[@]} selected file(s)."
        break # Exit main menu loop, proceed to actual processing
      else
        echo "No files were finalized for processing. Returning to main menu."
        continue # Back to main menu
      fi
      ;; # End of case "2"
    "q")
      echo "Quitting."
      exit 0
      ;;
    *)
      echo "Invalid choice. Please enter 1, 2, or Q."
      ;;
  esac # End main menu case
done # End main menu while-loop

# --- Sanity check after menu ---
if [ ${#files_to_process[@]} -eq 0 ]; then
  echo "No files were selected for processing. Exiting."
  exit 0
fi

echo "---"
echo "Beginning processing of ${#files_to_process[@]} file(s)..."
echo "---"

# --- Main Processing Loop ---
total_files_to_process=${#files_to_process[@]}
current_file_num=0
skipped_ocr_count=0
failed_ocr_count=0
failed_text_count=0

for pdf_file_path in "${files_to_process[@]}"; do
  current_file_num=$((current_file_num + 1))
  echo "Processing file $current_file_num of $total_files_to_process: '$pdf_file_path'"

  base_name=$(basename "$pdf_file_path" .pdf)
  ocr_pdf_file="$OCR_DIR/${base_name}_ocr.pdf"
  txt_file="$TXT_DIR/${base_name}.txt"

  # --- Step 1: Run OCRmyPDF ---
  echo "  Running OCRmyPDF with flags: -l \"$OCR_LANG\" $OCRMYPDF_ARGS"
  ocr_output="" # Clear for each file
  
  # Capture all output (stdout+stderr) to ocr_output AND display it to tty for live feedback
  ocr_output=$(ocrmypdf -l "$OCR_LANG" $OCRMYPDF_ARGS "$pdf_file_path" "$ocr_pdf_file" 2>&1 | tee /dev/tty)
  ocr_exit_code=${PIPESTATUS[0]} # Get exit code of ocrmypdf (left side of pipe), not tee

  if [ $ocr_exit_code -ne 0 ]; then
    echo "  Error: OCRmyPDF failed for '$pdf_file_path' with exit code $ocr_exit_code. Check output above."
    # The output should have already been displayed by tee, but if it was extensive, printing it here again might be too much.
    # A small portion or just a note that it failed is often enough if tee showed the details.
    # If ocr_output is very long, this could flood the terminal:
    # echo "  OCRmyPDF Full Output Log (if captured): "
    # echo "$ocr_output" | sed 's/^/    /' # Indent output for clarity
    failed_ocr_count=$((failed_ocr_count + 1))
    echo "---------------------"
    continue
  fi

  # --- Check for skipped pages if in --skip-text mode ---
  if [[ "$OCR_MODE" == "skip-text" ]]; then
    # Check 1: Specific message that increments the counter (original behavior)
    if echo "$ocr_output" | grep -q "skipping all processing on this page"; then
      echo "  Note: OCRmyPDF reported skipping ALL processing on at least one page (due to existing text in --skip-text mode)."
      skipped_ocr_count=$((skipped_ocr_count + 1))
    # Check 2: Other general skip messages (informational, does not increment original counter)
    elif echo "$ocr_output" | grep -qi "page already has text"; then # ocrmypdf often says "page X already has text, not rasterizing"
      echo "  Note: OCRmyPDF reported one or more pages already had text. OCR may have been selectively skipped on those pages."
    fi
  fi

  echo "  OCRmyPDF completed: '$ocr_pdf_file'"

  # --- Step 2: Extract text using pdftotext ---
  echo "  Extracting text..."
  if pdftotext "$ocr_pdf_file" "$txt_file"; then
    echo "  Text extracted successfully: '$txt_file'"
  else
    echo "  Error: pdftotext failed for '$ocr_pdf_file'."
    failed_text_count=$((failed_text_count + 1))
  fi
  echo "---------------------"
done

echo ""
echo "Batch processing complete."
echo "---------------------"
echo "Summary:"
echo "  Total PDF file(s) selected for processing: $total_files_to_process"
echo "  OCR'd PDFs created in:                   '$OCR_DIR'"
echo "  Extracted text files saved in:           '$TXT_DIR'"
if [[ "$OCR_MODE" == "skip-text" ]]; then
  # This counter is based on the original script's specific grep phrase
  echo "  Files where OCR was fully skipped on some pages (due to --skip-text): $skipped_ocr_count"
fi
echo "  Files where OCRmyPDF failed:               $failed_ocr_count"
echo "  Files where pdftotext failed:              $failed_text_count"
echo "---------------------"

exit 0