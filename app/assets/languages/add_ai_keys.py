import json

with open('en.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

data.update({
    "aiAssistantTitle": "Kaamkaaz Sahayak",
    "aiHowCanIHelp": "How can I help you?",
    "aiThinking": "Thinking...",
    "aiTypeMessage": "Type your message or speak...",
    "aiReadAloud": "Read Aloud",
    "aiStopReading": "Stop Reading",
    "aiError": "Sorry, I could not process your request.",
    "aiClose": "Close"
})

with open('en.json', 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

