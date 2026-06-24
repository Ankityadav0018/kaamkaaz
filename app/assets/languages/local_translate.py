import json
import os

TRANSLATIONS = {
    "hi": {
        "exploreModeSub": "कहीं भी 50 किमी से अधिक दूरी पर काम देखें",
        "filter_plumber": "प्लंबर",
        "filter_electrician": "इलेक्ट्रीशियन",
        "filter_carpenter": "बढ़ई",
        "filter_painter": "पेंटर",
        "filter_cleaner": "सफाई कर्मचारी",
        "filter_driver": "ड्राइवर",
        "filter_helper": "हेल्पर / लोडर",
        "filter_security": "सुरक्षा गार्ड",
        "filter_cook": "रसोइया",
        "filter_mason": "राजमिस्त्री",
        "filter_welder": "वेल्डर",
        "filter_other": "अन्य"
    },
    "bgc": {
        "exploreModeSub": "कहीं भी 50 किमी से अधिक दूरी पर काम देखें",
        "filter_plumber": "प्लंबर",
        "filter_electrician": "इलेक्ट्रीशियन",
        "filter_carpenter": "बढ़ई",
        "filter_painter": "पेंटर",
        "filter_cleaner": "सफाई कर्मचारी",
        "filter_driver": "ड्राइवर",
        "filter_helper": "हेल्पर / लोडर",
        "filter_security": "सुरक्षा गार्ड",
        "filter_cook": "रसोइया",
        "filter_mason": "राजमिस्त्री",
        "filter_welder": "वेल्डर",
        "filter_other": "अन्य"
    },
    "raj": {
        "exploreModeSub": "कहीं भी 50 किमी से अधिक दूरी पर काम देखें",
        "filter_plumber": "प्लंबर",
        "filter_electrician": "इलेक्ट्रीशियन",
        "filter_carpenter": "बढ़ई",
        "filter_painter": "पेंटर",
        "filter_cleaner": "सफाई कर्मचारी",
        "filter_driver": "ड्राइवर",
        "filter_helper": "हेल्पर / लोडर",
        "filter_security": "सुरक्षा गार्ड",
        "filter_cook": "रसोइया",
        "filter_mason": "राजमिस्त्री",
        "filter_welder": "वेल्डर",
        "filter_other": "अन्य"
    },
    "pa": {
        "exploreModeSub": "ਕਿਤੇ ਵੀ 50 ਕਿਲੋਮੀਟਰ ਤੋਂ ਵੱਧ ਦੂਰੀ 'ਤੇ ਕੰਮ ਦੇਖੋ",
        "filter_plumber": "ਪਲੰਬਰ",
        "filter_electrician": "ਬਿਜਲੀ ਵਾਲਾ",
        "filter_carpenter": "ਤਰਖਾਣ",
        "filter_painter": "ਪੇਂਟਰ",
        "filter_cleaner": "ਸਫਾਈ ਕਰਮਚਾਰੀ",
        "filter_driver": "ਡਰਾਈਵਰ",
        "filter_helper": "ਮਦਦਗਾਰ / ਲੋਡਰ",
        "filter_security": "ਸੁਰੱਖਿਆ ਗਾਰਡ",
        "filter_cook": "ਰਸੋਈਆ",
        "filter_mason": "ਰਾਜ ਮਿਸਤਰੀ",
        "filter_welder": "ਵੈਲਡਰ",
        "filter_other": "ਹੋਰ"
    },
    "mr": {
        "exploreModeSub": "कुठेही ५० किमीपेक्षा जास्त अंतरावरील कामे पहा",
        "filter_plumber": "प्लंबर",
        "filter_electrician": "इलेक्ट्रीशियन",
        "filter_carpenter": "सुतार",
        "filter_painter": "पेंटर",
        "filter_cleaner": "सफाई कामगार",
        "filter_driver": "ड्रायव्हर",
        "filter_helper": "हेल्पर / लोडर",
        "filter_security": "सुरक्षा रक्षक",
        "filter_cook": "आचारी",
        "filter_mason": "गवंडी / मिस्त्री",
        "filter_welder": "वेल्डर",
        "filter_other": "इतर"
    },
    "gu": {
        "exploreModeSub": "ગમે ત્યાં 50 કિમીથી વધુ દૂર કામ જુઓ",
        "filter_plumber": "પ્લમ્બર",
        "filter_electrician": "ઇલેક્ટ્રિશિયન",
        "filter_carpenter": "સુથાર",
        "filter_painter": "પેઇન્ટર",
        "filter_cleaner": "સફાઈ કામદાર",
        "filter_driver": "ડ્રાઇવર",
        "filter_helper": "હેલ્પર / લોડર",
        "filter_security": "સુરક્ષા ગાર્ડ",
        "filter_cook": "રસોઈયો",
        "filter_mason": "કડીયો / મિસ્ત્રી",
        "filter_welder": "વેલ્ડર",
        "filter_other": "અન્ય"
    },
    "bn": {
        "exploreModeSub": "যেকোনো জায়গায় ৫০ কিমির বেশি দূরত্বের কাজ দেখুন",
        "filter_plumber": "প্লাম্বার",
        "filter_electrician": "ইলেকট্রিশিয়ান",
        "filter_carpenter": "ছুতোর",
        "filter_painter": "রঙমিস্ত্রী",
        "filter_cleaner": "পরিচ্ছন্নতাকর্মী",
        "filter_driver": "চালক",
        "filter_helper": "হেল্পার / লোডার",
        "filter_security": "নিরাপত্তা রক্ষী",
        "filter_cook": "বাবুর্চি",
        "filter_mason": "রাজমিস্ত্রী",
        "filter_welder": "ওয়েল্ডার",
        "filter_other": "অন্যান্য"
    },
    "ta": {
        "exploreModeSub": "எங்கும் 50 கி.மீ-க்கு அப்பால் உள்ள வேலைகளைக் காண்க",
        "filter_plumber": "பிளம்பர்",
        "filter_electrician": "மின்சார பணியாளர்",
        "filter_carpenter": "தச்சர்",
        "filter_painter": "பெயிண்டர்",
        "filter_cleaner": "தூய்மைப் பணியாளர்",
        "filter_driver": "ஓட்டுநர்",
        "filter_helper": "உதவியாளர் / லோடர்",
        "filter_security": "பாதுகாப்புக் காவலர்",
        "filter_cook": "சமையல்காரர்",
        "filter_mason": "கொத்தனார் / மேஸ்திரி",
        "filter_welder": "வெல்டர்",
        "filter_other": "மற்றவை"
    },
    "te": {
        "exploreModeSub": "ఎక్కడైనా 50 కి.మీ మించి ఉన్న పనులను చూడండి",
        "filter_plumber": "ప్లంబర్",
        "filter_electrician": "ఎలక్ట్రీషియన్",
        "filter_carpenter": "వడ్రంగి",
        "filter_painter": "పెయింటర్",
        "filter_cleaner": "శుభ్రపరిచే వ్యక్తి",
        "filter_driver": "డ్రైవర్",
        "filter_helper": "సహాయకుడు / లోడర్",
        "filter_security": "సెక్యూరిటీ గార్డ్",
        "filter_cook": "వంటమనిషి",
        "filter_mason": "మేస్త్రీ",
        "filter_welder": "వెల్డర్",
        "filter_other": "ఇతర"
    },
    "kn": {
        "exploreModeSub": "ಎಲ್ಲಾದರೂ 50 ಕಿ.ಮೀ ಮೀರಿದ ಕೆಲಸಗಳನ್ನು ನೋಡಿ",
        "filter_plumber": "ಪ್ಲಂಬರ್",
        "filter_electrician": "ಎಲೆಕ್ಟ್ರೀಷಿಯನ್",
        "filter_carpenter": "ಬಡಗಿ",
        "filter_painter": "ಪೇಂಟರ್",
        "filter_cleaner": "ಸ್ವಚ್ಛತಾ ಸಿಬ್ಬಂದಿ",
        "filter_driver": "ಚಾಲಕ",
        "filter_helper": "ಸಹಾಯಕ / ಲೋಡರ್",
        "filter_security": "ಭದ್ರತಾ ಸಿಬ್ಬಂದി",
        "filter_cook": "ಅಡುಗೆಯವ",
        "filter_mason": "ಮೇಸ್ತ್ರಿ",
        "filter_welder": "ವೆಲ್ಡರ್",
        "filter_other": "ಇತರೆ"
    },
    "ml": {
        "exploreModeSub": "എവിടെയും 50 കിലോമീറ്ററിന് മുകളിലുള്ള ജോലികൾ കാണുക",
        "filter_plumber": "പ്ലംബർ",
        "filter_electrician": "ഇലക്ട്രീഷ്യൻ",
        "filter_carpenter": "ആശാരി",
        "filter_painter": "പെയിന്റർ",
        "filter_cleaner": "ക്ലീനർ",
        "filter_driver": "ഡ്രൈവർ",
        "filter_helper": "സഹായി / ലോഡർ",
        "filter_security": "സെക്യൂരിറ്റി ഗാർഡ്",
        "filter_cook": "പാചകക്കാരൻ",
        "filter_mason": "മേസ്തിരി",
        "filter_welder": "വെൽഡർ",
        "filter_other": "മറ്റുള്ളവ"
    },
    "or": {
        "exploreModeSub": "ଯେକୌଣସି ସ୍ଥାନରେ ୫୦ କିମିରୁ ଅଧିକ ଦୂରତାରେ କାମ ଦେଖନ୍ତୁ",
        "filter_plumber": "ପ୍ଲମ୍ବର",
        "filter_electrician": "ଇଲେକ୍ଟ୍ରିସିଆନ୍",
        "filter_carpenter": "ବଢ଼େଇ",
        "filter_painter": "ପେଣ୍ଟର",
        "filter_cleaner": "ସଫେଇ କର୍ମଚାରୀ",
        "filter_driver": "ଡ୍ରାଇଭର",
        "filter_helper": "ହେଲ୍ପର / ଲୋଡର",
        "filter_security": "ସୁରକ୍ଷା ଗାର୍ଡ",
        "filter_cook": "ରୋଷେଇୟା",
        "filter_mason": "ରାଜମିସ୍ତ୍ରୀ",
        "filter_welder": "ୱେଲ୍ଡର",
        "filter_other": "ଅନ୍ୟାନ୍ୟ"
    },
    "ur": {
        "exploreModeSub": "کہیں بھی 50 کلومیٹر سے زیادہ دوری پر کام دیکھیں",
        "filter_plumber": "پلمبر",
        "filter_electrician": "الیکٹریشن",
        "filter_carpenter": "بڑھئی",
        "filter_painter": "پینٹر",
        "filter_cleaner": "صفائی کرنے والا",
        "filter_driver": "ڈرائیور",
        "filter_helper": "مددگار / لوڈر",
        "filter_security": "سیکیورٹی گارڈ",
        "filter_cook": "باورچی",
        "filter_mason": "راج مستری / مستری",
        "filter_welder": "ویلڈر",
        "filter_other": "دیگر"
    }
}

base_dir = os.path.dirname(os.path.abspath(__file__))

# Update English en.json with new keys
en_path = os.path.join(base_dir, 'en.json')
if os.path.exists(en_path):
    with open(en_path, 'r', encoding='utf-8') as f:
        en_data = json.load(f)
else:
    en_data = {}

# Make sure all new and category keys exist in en_data
en_data["exploreModeSub"] = "See jobs beyond 50km anywhere"
en_data["filter_plumber"] = "Plumber"
en_data["filter_electrician"] = "Electrician"
en_data["filter_carpenter"] = "Carpenter"
en_data["filter_painter"] = "Painter"
en_data["filter_cleaner"] = "Cleaner"
en_data["filter_driver"] = "Driver"
en_data["filter_helper"] = "Helper / Loader"
en_data["filter_security"] = "Security Guard"
en_data["filter_cook"] = "Cook"
en_data["filter_mason"] = "Mason / Mistri"
en_data["filter_welder"] = "Welder"
en_data["filter_other"] = "Other"

with open(en_path, 'w', encoding='utf-8') as f:
    json.dump(en_data, f, ensure_ascii=False, indent=2)
print("Updated en.json.")

# Iterate and update each language JSON file
for lang, kvs in TRANSLATIONS.items():
    file_path = os.path.join(base_dir, f"{lang}.json")
    if not os.path.exists(file_path):
        print(f"Skipping {lang}.json (not found)")
        continue
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    for k, v in kvs.items():
        data[k] = v
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print(f"Updated {lang}.json.")

print("All translations updated successfully!")
