import json
import time
import logging
from openai import OpenAI  # or your import for the custom client

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Instantiate your OpenAI-like client (replace with valid credentials/config).
client = OpenAI()

# Adjust these parameters as needed
BATCH_SIZE = 50
TOTAL_ENTRIES = 10000
OUTPUT_FILE = "training_data.json"

# This is your system prompt content. Customize as needed.
system_prompt_content = [
    {
        "type": "text",
        "text": (
            "Create training data for a machine learning text classifier in JSON "
            "format where each entry contains a line of standard output from common "
            "Unix programs paired with a diverse emoji.\n\n"
            "1. **Collect Unix Program Outputs**:\n"
            "   - Gather a list of common Unix commands, such as `ls`, `pwd`, `cat`, "
            "     `echo`, `grep`, etc.\n"
            "   - Execute each command to collect a diverse array of realistic stdout lines.\n"
            "   - Document the output lines ensuring uniqueness and relevance.\n\n"
            "2. **Select Diverse Emojis**:\n"
            "   - Compile a list of a wide range of emojis, including different "
            "     emotions, symbols, and objects. Examples include 😃, 🚀, 🔍, etc.\n"
            "   - Make sure the emojis are varied and cover a broad spectrum of "
            "     meanings and usages.\n\n"
            "3. **Pair Outputs and Emojis**:\n"
            "   - Randomly assign an emoji to each collected command output line.\n"
            "   - Ensure each pairing is unique and well-distributed.\n\n"
            "# Output Format\n"
            "Each entry in the JSON should be formatted as:\n"
            "{\"text\": \"<stdout line>\", \"label\": \"<emoji>\"}\n\n"
            "# Notes\n"
            "- Include edge cases such as empty stdout lines or common errors.\n"
            "- Produce a variety of real looking command outputs.\n"
            "- Provide enough entries to reach the requested dataset size.\n\n"
            "In your next response, create exactly "
            f"{BATCH_SIZE} JSON objects inside the \"data\" array to be appended "
            "to our final dataset."
        )
    }
]

def main():
    """
    Requests the GPT-4-style endpoint in batches, each batch containing
    BATCH_SIZE entries, until we have at least TOTAL_ENTRIES total items.
    Writes progress to OUTPUT_FILE after each batch.
    """
    all_data = []

    # Calculate how many batches we need.
    # We might go slightly over TOTAL_ENTRIES if not divisible by BATCH_SIZE,
    # but typically you'd want EXACTly 1000, so adjust if needed.
    num_batches = (TOTAL_ENTRIES + BATCH_SIZE - 1) // BATCH_SIZE

    logger.info(f"Requesting {num_batches} batches of {BATCH_SIZE} items each.")

    for batch_index in range(1, num_batches + 1):
        try:
            # Create your chat completion request
            response = client.chat.completions.create(
                model="gpt-4o",  # or the GPT-4 model name you're using
                messages=[{
                    "role": "system", 
                    "content": system_prompt_content[0]["text"]
                }],
                response_format={"type": "json_object"},
                temperature=1,
                max_tokens=2048,
                top_p=1,
                frequency_penalty=0,
                presence_penalty=0
            )

            # Unwrap the JSON in "data"
            # Adjust indexing based on your library's return structure 
            content = response.choices[0].message.content
            if content is None:
                raise ValueError("Received null content from API")
            batch_data = json.loads(content)["data"]
            logger.info(f"Received batch {batch_index} with {len(batch_data)} items.")

            # Accumulate
            all_data.extend(batch_data)

            # If we've reached or exceeded the total needed, we can stop early
            if len(all_data) >= TOTAL_ENTRIES:
                all_data = all_data[:TOTAL_ENTRIES]  # truncate if overshoot
                logger.info(f"Reached {TOTAL_ENTRIES} total entries; stopping.")

            # Write partial or final output to file
            with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
                json.dump(all_data, f, indent=2, ensure_ascii=False)

            logger.info(f"Total so far: {len(all_data)} / {TOTAL_ENTRIES}")

            # Stop if we've reached the required number of entries
            if len(all_data) >= TOTAL_ENTRIES:
                break

        except Exception as e:
            logger.error(f"Error fetching batch {batch_index}: {e}")

        # Optional sleep to avoid hitting rate limits, can adjust as needed
        time.sleep(2)

    logger.info(f"Done! Final dataset written to '{OUTPUT_FILE}' with {len(all_data)} entries.")

if __name__ == "__main__":
    main()
