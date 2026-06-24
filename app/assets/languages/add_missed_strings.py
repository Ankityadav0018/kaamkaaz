import json
import os
from googletrans import Translator

# Initialize translator
translator = Translator()

LANGUAGES = {
    'hi': 'hi',
    'pa': 'pa',
    'bgc': 'hi', # Haryanvi -> fallback to Hindi
    'raj': 'hi', # Rajasthani -> fallback to Hindi
    'mr': 'mr',
    'gu': 'gu',
    'bn': 'bn',
    'ta': 'ta',
    'te': 'te',
    'kn': 'kn',
    'ml': 'ml',
    'or': 'or',
    'ur': 'ur',
}

NEW_KEYS = {
    "saved": "Saved",
    "noSavedJobs": "No Saved Jobs",
    "allSavedJobsUnavailable": "All saved jobs are no longer available.",
    "offlineModeSavedJobs": "Offline Mode: Showing cached saved jobs",
    "reportJob": "Report Job",
    "reportFakeJob": "Fake job",
    "reportWrongInfo": "Wrong information",
    "reportSpam": "Spam",
    "reportInappropriate": "Inappropriate content",
    "jobReportedSuccess": "Job reported successfully for: {}. Admin will review this job.",
    "checkInSuccess": "Checked-in at Job Site",
    "workSummary": "Work Summary",
    "checkOutSuccessMsg": "You checked out successfully!\nTotal Duration: {} hours.",
    "close": "Close"
}

def translate_and_update():
    base_dir = os.path.dirname(os.path.abspath(__file__))
    
    # Update English first
    en_path = os.path.join(base_dir, 'en.json')
    with open(en_path, 'r', encoding='utf-8') as f:
        en_data = json.load(f)
    
    for k, v in NEW_KEYS.items():
        if k not in en_data:
            en_data[k] = v
            
    with open(en_path, 'w', encoding='utf-8') as f:
        json.dump(en_data, f, ensure_ascii=False, indent=2)
    print("Updating en.json...")

    for lang_code, trans_code in LANGUAGES.items():
        print(f"Updating {lang_code}.json...")
        file_path = os.path.join(base_dir, f"{lang_code}.json")
        
        if not os.path.exists(file_path):
            continue
            
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
            
        updated = False
        for k, v in NEW_KEYS.items():
            if k not in data:
                try:
                    translation = translator.translate(v, dest=trans_code).text
                    data[k] = translation
                    updated = True
                    print(f"  Translated: {v} -> {translation}")
                except Exception as e:
                    print(f"  Error translating {v} to {lang_code}: {e}")
                    data[k] = v # Fallback to English
                    updated = True
                    
        if updated:
            with open(file_path, 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False, indent=2)

if __name__ == '__main__':
    translate_and_update()
    print("Done part 5 & 6!")
