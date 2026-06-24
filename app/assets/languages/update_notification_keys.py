import json

new_strings = {
    "reminderJobTomorrow": "Reminder: Job Tomorrow",
    "jobTomorrowBody": "You have a job tomorrow: {jobTitle} at {location}",
    "jobToday": "Job Today!",
    "jobTodayBody": "Your job starts today: {jobTitle}",
    "checkInReminder": "Check-in Reminder",
    "checkInBody": "Please check-in to your job: {jobTitle} if you have arrived."
}

with open('/Users/ankityadav/lpu/rozgar/app/assets/languages/en.json', 'r') as f:
    data = json.load(f)

for k, v in new_strings.items():
    data[k] = v

with open('/Users/ankityadav/lpu/rozgar/app/assets/languages/en.json', 'w') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print("Updated en.json with notification keys")
