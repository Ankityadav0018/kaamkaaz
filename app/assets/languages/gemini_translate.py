import json
import os
import time
import google.generativeai as genai
import sys
import re

# Load Gemini API Key
API_KEY = "AQ.Ab8RN6KbNt8QpZdPl5vKpOzfnqbZ1UYL6sDQHWfVdCaTYII5ag"
genai.configure(api_key=API_KEY)
model = genai.GenerativeModel("gemini-2.5-flash", generation_config={"temperature": 0.2})

base_dir = os.path.dirname(os.path.abspath(__file__))
hi_path = os.path.join(base_dir, 'hi.json')

with open(hi_path, 'r', encoding='utf-8') as f:
    hi_data = json.load(f)

targets = [
    {'file': 'raj.json', 'lang': 'Rajasthani (Marwari dialect)'},
    {'file': 'bgc.json', 'lang': 'Haryanvi (Bagri dialect)'}
]

def translate_batch(target_lang, keys, values):
    prompt = f"""
Translate the following Hindi phrases to authentic {target_lang}.
Provide only a raw JSON object as output. No markdown, no formatting. The keys must remain exactly the same.

Input:
{json.dumps(dict(zip(keys, values)), ensure_ascii=False)}
"""
    retries = 10 # very high retry count
    while retries > 0:
        try:
            response = model.generate_content(prompt)
            text = response.text.strip()
            # Clean up potential markdown formatting from the response
            if text.startswith("```json"):
                text = text[7:]
            elif text.startswith("```"):
                text = text[3:]
            if text.endswith("```"):
                text = text[:-3]
            
            result = json.loads(text.strip())
            return result
        except Exception as e:
            error_str = str(e)
            print(f"Error in batch translation: {error_str}")
            
            # If it's a rate limit error (429), parse the wait time or wait 65 seconds
            wait_time = 65
            match = re.search(r'retry in (\d+)\.', error_str)
            if match:
                wait_time = int(match.group(1)) + 5
                
            print(f"Waiting {wait_time} seconds before retrying...")
            time.sleep(wait_time)
            retries -= 1
    
    return {}

BATCH_SIZE = 20

for target in targets:
    file_path = os.path.join(base_dir, target['file'])
    print(f"\nProcessing {target['file']} for {target['lang']}...")
    
    if not os.path.exists(file_path):
        lang_data = {}
    else:
        with open(file_path, 'r', encoding='utf-8') as f:
            lang_data = json.load(f)

    keys_to_translate = []
    
    for key, hi_val in hi_data.items():
        if key not in lang_data or lang_data[key].strip() == hi_val.strip():
            if len(hi_val.strip()) > 1 and not hi_val.isascii():
                keys_to_translate.append(key)

    print(f"Found {len(keys_to_translate)} phrases to translate for {target['lang']}.")
    
    for i in range(0, len(keys_to_translate), BATCH_SIZE):
        batch_keys = keys_to_translate[i:i + BATCH_SIZE]
        batch_vals = [hi_data[k] for k in batch_keys]
        
        print(f"Translating batch {i // BATCH_SIZE + 1}/{(len(keys_to_translate) + BATCH_SIZE - 1) // BATCH_SIZE}...")
        
        # Don't translate if the batch is empty
        if not batch_keys:
            continue
            
        translated_batch = translate_batch(target['lang'], batch_keys, batch_vals)
        
        if translated_batch:
            for k, v in translated_batch.items():
                if k in batch_keys:
                    lang_data[k] = v
                    
            with open(file_path, 'w', encoding='utf-8') as f:
                json.dump(lang_data, f, ensure_ascii=False, indent=2)
                
        # Base sleep to avoid hitting limit immediately
        time.sleep(3)

print("\nTranslation complete!")
