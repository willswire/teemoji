# Training Data Generator

## Overview

The **Training Data Generator** is a Python script designed to create a robust dataset for machine learning text classifiers. It pairs realistic standard output lines from common Unix commands with a diverse set of emojis, facilitating the training of models that understand and interpret emoji associations.

## Features

- **Unix Command Output Collection**: Gathers realistic and varied stdout lines from commands like `ls`, `pwd`, `cat`, `echo`, `grep`, and more.
- **Diverse Emoji Pairing**: Assigns a wide range of emojis, covering different emotions, symbols, and objects, to each command output.
- **Batch Processing**: Generates data in configurable batches to efficiently reach the desired dataset size.
- **Progress Logging**: Logs progress and handles errors gracefully to ensure smooth execution.
- **JSON Output**: Outputs the dataset in a structured JSON format for easy integration into machine learning workflows.

## Requirements

- Python 3.13 or higher
- [OpenAI Python Library](https://pypi.org/project/openai/) (version 1.60.1 or higher)

## Installation

1. **Clone the Repository**

   ```bash
   git clone https://github.com/willswire/teemoji.git
   cd teemoji/Resources/Training
   ```

2. **Install Dependencies**

   It's recommended to use a virtual environment:

   ```bash
   python3 -m venv venv
   source venv/bin/activate
   ```

   Then install the required packages:

   ```bash
   pip install -r requirements.txt
   ```

   *Alternatively, install directly using pip:*

   ```bash
   pip install openai>=1.60.1
   ```

## Configuration

1. **OpenAI API Setup**

   Ensure you have your OpenAI API credentials set up. You may need to configure authentication within the `main.py` script or set environment variables as per the OpenAI library requirements.

2. **Parameters Adjustment**

   You can adjust the following parameters in `main.py` to suit your needs:

   - `BATCH_SIZE`: Number of entries to request per batch (default: 50)
   - `TOTAL_ENTRIES`: Total number of dataset entries to generate (default: 10,000)
   - `OUTPUT_FILE`: Name of the output JSON file (default: `training_data.json`)

## Usage

Run the script using Python:

```bash
python main.py
```

The script will:

1. Request data from the OpenAI API in batches.
2. Pair Unix command outputs with random emojis.
3. Save the accumulated data to `training_data.json`.
4. Log progress and handle any errors during execution.

## Output

The generated `training_data.json` will have the following structure:

```json
{
  "data": [
    {
      "text": "ls -la",
      "label": "📁"
    },
    {
      "text": "echo 'Hello, World!'",
      "label": "💬"
    },
    ...
  ]
}
```

Each entry contains:

- `text`: A line of standard output from a Unix command.
- `label`: A corresponding emoji representing or associated with the output.

## Notes

- The script includes edge case handling, such as empty stdout lines and common command errors, to ensure a diverse and comprehensive dataset.
- Ensure you have sufficient API usage limits with OpenAI to handle the number of requests based on `BATCH_SIZE` and `TOTAL_ENTRIES`.
- Modify the `system_prompt_content` within `main.py` if you need to customize the data generation process further.
