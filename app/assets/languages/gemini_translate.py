import json
import os
import time
import google.generativeai as genai

# Load Gemini API Key from environment or hardcode it (extracted from backend/.env)
API_KEY = "AQ.Ab8RN6KbNt8QpZdPl5vKpOzfnqbZ1UYL6sDQHWfVdCaTYII5ag"
genai.configure(api_key=API_KEY)
model = genai.GenerativeModel("gemini-2.5-flash")

base_dir = os.path.dirname(os.path.abspath(__file__))
hi_path = os.path.join(base_dir, 'hi.json')

with open(hi_path, 'r', encoding='utf-8') as f:
    hi_data = json.load(f)

# The target files we want to translate
targets = [
    {'file': 'raj.json', 'lang': 'Rajasthani (Marwari dialect)'},
    {'file': 'bgc.json', 'lang': 'Haryanvi (Bagri dialect)'}
]

def translate_batch(target_lang, keys, values):
    prompt = f"""
You are an expert translator specializing in Indian regional dialects.
I will give you a list of words/phrases in standard Hindi. You must translate them into authentic {target_lang}.
Output the translations strictly as a JSON object where the keys are exactly the same as the input keys, and the values are the translated strings. Do not include Markdown blocks like ```json.
Ensure the translation matches the tone of a professional but simple daily wage job app.

Input (JSON):
{json.dumps(dict(zip(keys, values)), ensure_ascii=False)}
"""
    retries = 3
    while retries > 0:
        try:
            response = model.generate_content(prompt)
            text = response.text.strip()
            if text.startswith("```json"):
                text = text[7:]
            if text.endswith("```"):
                text = text[:-3]
            
            result = json.loads(text.strip())
            return result
        except Exception as e:
            print(f"Error in batch translation: {e}")
            retries -= 1
            print("Rate limit hit. Waiting 60 seconds...")
            time.sleep(60)
    
    return {}

BATCH_SIZE = 150

for target in targets:
    file_path = os.path.join(base_dir, target['file'])
    print(f"\nProcessing {target['file']} for {target['lang']}...")
    
    if not os.path.exists(file_path):
        lang_data = {}
    else:
        with open(file_path, 'r', encoding='utf-8') as f:
            lang_data = json.load(f)

    keys_to_translate = []
    
    # Identify which keys to translate (if they are exactly the same as Hindi, they were probably auto-filled incorrectly)
    for key, hi_val in hi_data.items():
        if key not in lang_data or lang_data[key].strip() == hi_val.strip():
            # Skip placeholders and very short non-translatable text
            if len(hi_val.strip()) > 1 and not hi_val.isascii():
                keys_to_translate.append(key)

    print(f"Found {len(keys_to_translate)} phrases to translate for {target['lang']}.")
    
    # Process in batches
    for i in range(0, len(keys_to_translate), BATCH_SIZE):
        batch_keys = keys_to_translate[i:i + BATCH_SIZE]
        batch_vals = [hi_data[k] for k in batch_keys]
        
        print(f"Translating batch {i // BATCH_SIZE + 1}/{(len(keys_to_translate) + BATCH_SIZE - 1) // BATCH_SIZE}...")
        translated_batch = translate_batch(target['lang'], batch_keys, batch_vals)
        
        for k, v in translated_batch.items():
            if k in batch_keys:
                lang_data[k] = v
                
        # Save incrementally
        with open(file_path, 'w', encoding='utf-8') as f:
            json.dump(lang_data, f, ensure_ascii=False, indent=2)
            
        time.sleep(5) # rate limiting for Free Tier (15 RPM)

print("\nTranslation complete!")
