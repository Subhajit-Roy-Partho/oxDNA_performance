#!/bin/bash

# -----------------------------------------------------------------------------
# Script Name: run_oxdna.sh
# Description: Navigates into N* directories, unzips zip files, modifies the
#              input file by appending necessary lines, and runs the oxDNA
#              command using a user-provided path.
# Usage: ./run_oxdna.sh /full/path/to/oxDNA [steps_value]
# -----------------------------------------------------------------------------

# Function to display usage information
usage() {
    echo "Usage: $0 /full/path/to/oxDNA_executable [steps_value]"
    echo "  /full/path/to/oxDNA_executable : Required. Full path to the oxDNA executable."
    echo "  steps_value                     : Optional. Value to set 'steps' in the input file."
    exit 1
}

# Check if at least the oxDNA path is provided
if [ $# -lt 1 ]; then
    echo "Error: Path to oxDNA executable not provided."
    usage
fi

OXDNA_PATH="$1"

# Verify that the provided oxDNA path is executable
if [ ! -x "$OXDNA_PATH" ]; then
    echo "Error: '$OXDNA_PATH' is not an executable or does not exist."
    exit 1
fi

# Extract the directory containing oxDNA for later use
OXDNA_DIR=$(dirname "$OXDNA_PATH")

# Check if a second argument is provided
if [ $# -ge 2 ]; then
    STEPS_VALUE="$2"
    echo "Steps value provided: $STEPS_VALUE"
else
    STEPS_VALUE=""
    echo "No steps value provided."
fi

# Iterate over all directories starting with 'N' in the current directory
for dir in N*/; do
    # Check if the pattern matches a directory
    if [ -d "$dir" ]; then
        echo "Processing directory: $dir"

        # Navigate into the directory
        cd "$dir" || { echo "Failed to enter directory $dir"; continue; }

        # Unzip all zip files if any exist
        zip_files=(*.zip)
        if [ -e "${zip_files[0]}" ]; then
            echo "Found zip files. Unzipping..."
            for zip in *.zip; do
                unzip -o "$zip"
                if [ $? -eq 0 ]; then
                    echo "Successfully unzipped '$zip'."
                else
                    echo "Failed to unzip '$zip'. Continuing with next file."
                fi
            done
        else
            echo "No zip files found in $dir."
        fi

        # Define the input file name
        INPUT_FILE="input"

        # Check if the input file exists
        if [ -f "$INPUT_FILE" ]; then
            # Backup the original input file
            cp "$INPUT_FILE" "${INPUT_FILE}.bak"
            echo "Backup of the input file created as '${INPUT_FILE}.bak'."

            # Check and append the seq_dep_file line if not already present
            if ! grep -q "^seq_dep_file" "$INPUT_FILE"; then
                echo "seq_dep_file = $OXDNA_DIR/oxDNA2_sequence_dependent_parameters.txt" >> "$INPUT_FILE"
                echo "Appended seq_dep_file to '$INPUT_FILE'."
            else
                echo "seq_dep_file already exists in '$INPUT_FILE'. Skipping append."
            fi

            # If steps_value is provided, append the steps line if not already present
            if [ -n "$STEPS_VALUE" ]; then
                if ! grep -q "^steps=" "$INPUT_FILE"; then
                    echo "steps=$STEPS_VALUE" >> "$INPUT_FILE"
                    echo "Appended steps=$STEPS_VALUE to '$INPUT_FILE'."
                else
                    echo "steps already exists in '$INPUT_FILE'. Skipping append."
                fi
            fi
        else
            echo "Warning: Input file '$INPUT_FILE' not found in $dir."
            # Optionally, you can choose to skip running oxDNA if input file is missing
            # cd ..
            # continue
        fi

        # Execute the oxDNA command with the input file
        echo "Running oxDNA with input file '$INPUT_FILE'..."
        "$OXDNA_PATH" "$INPUT_FILE"

        # Optionally, check if oxDNA ran successfully
        if [ $? -eq 0 ]; then
            echo "oxDNA executed successfully in $dir."
        else
            echo "oxDNA encountered an error in $dir."
        fi

        # Return to the parent directory
        cd ..

        echo "Finished processing directory: $dir"
        echo "----------------------------------------"
    fi
done

echo "All N* directories have been processed."

