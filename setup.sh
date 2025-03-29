#!/bin/bash

echo "--- OCR and PDF Tools Setup Script ---"
echo "This script will install poppler-utils (for pdftotext), ocrmypdf, tesseract-ocr,"
echo "and the Tesseract English language pack using apt."
echo "Root privileges are required for installation."
echo

# Check if running as root, although apt commands will use sudo anyway
# if [[ $EUID -ne 0 ]]; then
#    echo "This script requires root privileges for installation. Please run with sudo."
#    exit 1
# fi

# --- List of packages to install ---
# poppler-utils: Contains pdftotext and other PDF utilities
# ocrmypdf: The main OCR processing tool for PDFs
# tesseract-ocr: The OCR engine used by ocrmypdf
# tesseract-ocr-eng: The English language data for Tesseract (essential)
# Add other language packs here if needed, e.g., tesseract-ocr-fra for French
PACKAGES="poppler-utils ocrmypdf tesseract-ocr tesseract-ocr-eng"

# --- Update package list ---
echo "Step 1: Updating package list (sudo apt update)..."
if sudo apt update; then
  echo "Package list updated successfully."
else
  echo "Error: Failed to update package list. Please check your internet connection and repository configuration."
  exit 1
fi

echo
# --- Install packages ---
echo "Step 2: Installing required packages ($PACKAGES)..."
# The -y flag automatically confirms the installation prompts
if sudo apt install -y $PACKAGES; then
  echo "All required packages installed successfully!"
else
  echo "Error: Failed to install one or more packages."
  echo "Please check the output above for specific errors."
  echo "You may need to resolve dependencies or configuration issues manually."
  exit 1
fi

echo
echo "--- Setup Complete ---"
echo "You should now have pdftotext, ocrmypdf, and tesseract (with English support) installed."
echo "If you need to process PDFs in other languages, install the corresponding"
echo "tesseract language packs, e.g., 'sudo apt install tesseract-ocr-fra' for French."
echo

exit 0