# TextHarvest: Document and Code Processing Utilities

## Overview

This project consists of a set of Bash shell scripts designed to automate common processing tasks for source code files and PDF documents on a Linux system. It allows you to:

1.  Generate combined source code listings from project directories.
2.  Extract text directly from text-based PDF files.
3.  Perform Optical Character Recognition (OCR) on image-based or scanned PDF files and then extract the recognized text.

## How it Works

The project uses separate scripts for different tasks, relying on standard Linux command-line tools.

**Directory Structure:**

The scripts expect a specific directory structure for input files:

*   `source_code/`: Place individual project folders inside this directory. The `process_code.sh` script will look for source files within each subfolder here.
*   `source_pdf/`: Place all PDF files you want to process (either for direct text extraction or OCR) in this directory.

Output files are generated in separate directories created by the scripts:

*   `code_listings/`: Contains text files, one for each project found in `source_code/`, listing the concatenated content of its source files.
*   `text_output/`: Contains text files extracted directly from PDFs using `process_pdf_text.sh`.
*   `ocr_pdf_output/`: Contains intermediate PDF files that have had an OCR text layer added by `process_pdf_ocr.sh`.
*   `ocr_text_output/`: Contains the final text files extracted from the OCR'd PDFs by `process_pdf_ocr.sh`.

**Scripts:**

1.  **`setup.sh`**:
    *   **Purpose:** Installs the necessary software dependencies required by the other scripts.
    *   **Method:** Uses the `apt` package manager (common on Debian/Ubuntu) to install `poppler-utils` (for `pdftotext`), `ocrmypdf`, `tesseract-ocr`, and the English language pack for Tesseract (`tesseract-ocr-eng`).

2.  **`process_code.sh`**:
    *   **Purpose:** Creates a single text file for each project directory found within `source_code/`. This text file contains the concatenated content of all recognized source code files within that project.
    *   **Method:** It recursively searches each project directory for files matching a predefined list of extensions (e.g., `.c`, `.py`, `.java`, `.sh`). It then concatenates the content of these files, adding headers indicating the filename, into an output file named `[project_name]_listing.txt` within the `code_listings/` directory.

3.  **`process_pdf_text.sh`**:
    *   **Purpose:** Extracts text content directly from PDF files that already contain selectable text (i.e., not image-only PDFs).
    *   **Method:** It iterates through all `.pdf` files in the `source_pdf/` directory and uses the `pdftotext` command to extract the text into corresponding `.txt` files in the `text_output/` directory.

4.  **`process_pdf_ocr.sh`**:
    *   **Purpose:** Processes PDF files, performs OCR to recognize text (useful for scanned documents or image-based PDFs), and then extracts this recognized text into text files.
    *   **Method:**
        *   It iterates through all `.pdf` files in `source_pdf/`.
        *   For each PDF, it runs `ocrmypdf`, which uses the Tesseract OCR engine to create a new PDF with a text layer in the `ocr_pdf_output/` directory.
        *   It then runs `pdftotext` on this *new* OCR'd PDF to extract the recognized text into a `.txt` file in the `ocr_text_output/` directory.

## How to Use

**1. Setup (Install Dependencies):**

*   Make sure you are on a Debian-based Linux distribution like Ubuntu.
*   Open your terminal.
*   Navigate to the directory containing these scripts.
*   Make the setup script executable: `chmod +x setup.sh`
*   Run the setup script with root privileges: `sudo ./setup.sh`
*   This will update your package list and install `poppler-utils`, `ocrmypdf`, `tesseract-ocr`, and `tesseract-ocr-eng`.
*   If you need to process PDFs in languages other than English, you'll need to install the corresponding Tesseract language packs (e.g., `sudo apt install tesseract-ocr-fra` for French). You may also need to update the `OCR_LANG` variable in `process_pdf_ocr.sh`.

**2. Prepare Input Files:**

*   Create the input directories if they don't exist:
    *   `mkdir source_code`
    *   `mkdir source_pdf`
*   Place your project folders (containing source code) inside the `source_code/` directory.
*   Place the PDF files you want to process inside the `source_pdf/` directory.

**3. Run Processing Scripts:**

*   Make the processing scripts executable:
    *   `chmod +x process_code.sh`
    *   `chmod +x process_pdf_text.sh`
    *   `chmod +x process_pdf_ocr.sh`
*   Run the desired script from the terminal in the directory where the scripts are located:
    *   To generate source code listings: `./process_code.sh`
    *   To extract text from text-based PDFs: `./process_pdf_text.sh`
    *   To OCR and extract text from PDFs: `./process_pdf_ocr.sh`

**4. Check Output:**

*   After running a script, check the corresponding output directory (`code_listings/`, `text_output/`, or `ocr_text_output/`) for the generated files.

## Configuration

The scripts (`process_code.sh`, `process_pdf_ocr.sh`) have configuration variables defined near the top (e.g., `CODE_DIR`, `OUTPUT_DIR`, `CODE_EXTENSIONS`, `OCR_LANG`, `OCRMYPDF_ARGS`). You can modify these variables directly in the scripts if you need to change input/output locations, recognized file types, or OCR settings.

## Compatibility

**Important:** These scripts have only been tested on **Ubuntu Linux**. They rely on the `apt` package manager for setup and common Linux command-line tools. They may require modification to run on other operating systems (like macOS or Windows/WSL) or other Linux distributions.