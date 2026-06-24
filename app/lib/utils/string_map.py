import os, re

# Complete string → (key, translation_hi, translation_raj, translation_hry) mapping
STRINGS = {
    # Navigation
    'Home': ('home', 'होम', 'घर', 'घर'),
    'Search': ('search', 'खोजें', 'खोजो', 'खोज'),
    'Applied': ('applied', 'आवेदित', 'अरजी दी', 'अर्जी दी'),
    'Profile': ('profile', 'प्रोफाइल', 'प्रोफाइल', 'प्रोफाइल'),
    'Post Job': ('postJob', 'काम पोस्ट करें', 'काम पोस्ट करो', 'काम पोस्ट करो'),
    'My Jobs': ('myJobs', 'मेरी नौकरियां', 'मारा काम', 'मेरे काम'),
    'Logout': ('logout', 'लॉगआउट', 'लॉगआउट', 'लॉगआउट'),

    # Auth
    'Login': ('login', 'लॉगिन', 'लॉगिन', 'लॉगिन'),
    'Register': ('register', 'रजिस्टर', 'रजिस्टर', 'रजिस्टर'),
    'Password': ('password', 'पासवर्ड', 'पासवर्ड', 'पासवर्ड'),
    'OTP Login': ('otpLogin', 'OTP लॉगिन', 'OTP लॉगिन', 'OTP लॉगिन'),
    'Language': ('language', 'भाषा', 'भाषा', 'भाषा'),
    'Send OTP': ('sendOtp', 'OTP भेजें', 'OTP भेजो', 'OTP भेजो'),
    'Verify OTP': ('verifyOtp', 'OTP सत्यापित करें', 'OTP सत्यापित करो', 'OTP सत्यापित करो'),
    'Resend OTP': ('resendOtp', 'OTP फिर भेजें', 'OTP फिर भेजो', 'OTP फिर भेजो'),
    'Demo Accounts': ('demoAccounts', 'डेमो खाते', 'डेमो खाते', 'डेमो खाते'),

    # Jobs
    'Apply': ('apply', 'आवेदन करें', 'अरजी करो', 'अर्जी करो'),
    'Accept': ('accept', 'स्वीकार करें', 'मंजूर करो', 'मंजूर करो'),
    'Reject': ('reject', 'अस्वीकार करें', 'नामंजूर करो', 'नामंजूर करो'),
    'Applicants': ('applicants', 'आवेदक', 'अरजीदार', 'अर्जीदार'),
    'No jobs found nearby': ('noJobsNearby', 'पास में कोई काम नहीं', 'पास में कोई काम नी', 'पास में कोई काम नहीं'),
    'No jobs posted yet': ('noJobsPosted', 'अभी कोई काम पोस्ट नहीं', 'अभी कोई काम पोस्ट नी', 'अभी कोई काम पोस्ट नहीं'),
    'No applications yet': ('noApplications', 'अभी कोई आवेदन नहीं', 'अभी कोई अरजी नी', 'अभी कोई अर्जी नहीं'),
    'Try expanding search radius': ('expandRadius', 'खोज दायरा बढ़ाएं', 'खोज दायरा बढ़ाओ', 'खोज का दायरा बढ़ाओ'),
    'Workers will apply soon!': ('workersSoon', 'जल्द ही मजदूर आवेदन करेंगे!', 'जल्दी मजदूर अरजी देसी!', 'जल्दी मजदूर आएंगे!'),
    'Tap + to post your first job': ('tapToPost', '+ दबाएं और काम पोस्ट करें', '+ दबाओ और काम पोस्ट करो', '+ दबाओ और काम पोस्ट करो'),
    'Job Description': ('jobDescription', 'काम की जानकारी', 'काम री जाणकारी', 'काम की जानकारी'),
    'Required Skills / जरूरी काम': ('requiredSkills', 'जरूरी कौशल', 'जरूरी काम', 'जरूरी काम'),
    'Site Photos': ('sitePhotos', 'साइट की फोटो', 'साइट री फोटो', 'साइट की फोटो'),
    'Skills / कौशल': ('skills', 'कौशल', 'काम', 'काम'),
    'Mark as Urgent': ('markUrgent', 'जरूरी बनाएं', 'जरूरी बणाओ', 'जरूरी बनाओ'),

    # Status
    'My Applications': ('myApplications', 'मेरी आवेदन', 'मारी अरजियां', 'मेरी अर्जियां'),
    'Mark as Completed': ('markCompleted', 'काम पूरा हुआ', 'काम पूरो थयो', 'काम पूरा हो ग्या'),
    'Rate Worker': ('rateWorker', 'मजदूर को रेट करें', 'मजदूर ने रेटिंग दो', 'मजदूर ने रेटिंग दो'),
    'Rate Recruiter': ('rateRecruiter', 'मालिक को रेट करें', 'मालिक ने रेटिंग दो', 'मालिक ने रेटिंग दो'),
    'Withdraw Application': ('withdraw', 'आवेदन वापस लें', 'अरजी वापस लो', 'अर्जी वापस लो'),
    'Apply for jobs to see them here': ('applyToSee', 'देखने के लिए आवेदन करें', 'देखण नै अरजी दो', 'देखने के लिए अर्जी दो'),
    'Application Submitted ✅': ('appSubmitted', 'आवेदन जमा हुआ ✅', 'अरजी जमा थई ✅', 'अर्जी जमा हो गई ✅'),
    'Contact Details Revealed': ('contactRevealed', 'संपर्क जानकारी मिली', 'संपर्क जाणकारी मिली', 'संपर्क जानकारी मिली'),

    # Profile
    'My Profile': ('myProfile', 'मेरी प्रोफाइल', 'मारी प्रोफाइल', 'मेरी प्रोफाइल'),
    'Edit Profile': ('editProfile', 'प्रोफाइल बदलें', 'प्रोफाइल बदलो', 'प्रोफाइल बदलो'),
    'Member Since': ('memberSince', 'सदस्य बने', 'सदस्य बण्या', 'मेंबर बने'),
    'jobs done': ('jobsDone', 'काम किए', 'काम करया', 'काम किए'),
    'Save Changes': ('saveChanges', 'बदलाव सहेजें', 'बदलाव सेव करो', 'बदलाव सेव करो'),

    # Notifications
    'Notifications': ('notifications', 'सूचनाएं', 'सूचनावां', 'सूचनाएं'),
    'No notifications yet': ('noNotifications', 'अभी कोई सूचना नहीं', 'अभी कोई सूचना नी', 'अभी कोई सूचना नहीं'),
    'Mark all read': ('markAllRead', 'सभी पढ़ा', 'सब पढ़्यो', 'सब पढ़ लो'),
    'Updates will appear here': ('updatesHere', 'अपडेट यहाँ दिखेंगे', 'अपडेट इयां दिखसी', 'अपडेट यहाँ दिखेंगे'),

    # Common
    'Showing nearby jobs': ('showingNearby', 'पास के काम दिखाए जा रहे हैं', 'पास रा काम दिखाए जावे सै', 'पास के काम दिखाए जा रहे हैं'),
    'Call Now': ('callNow', 'अभी कॉल करें', 'अभी कॉल करो', 'अभी कॉल करो'),
    'WhatsApp': ('whatsapp', 'व्हाट्सएप', 'व्हाट्सएप', 'व्हाट्सएप'),
    'KYC Pending': ('kycPending', 'KYC लंबित', 'KYC बाकी', 'KYC बाकी'),
    'Verified': ('verified', 'सत्यापित', 'सत्यापित', 'सत्यापित'),
    'Admin Panel': ('adminPanel', 'एडमिन पैनल', 'एडमिन पैनल', 'एडमिन पैनल'),
    'Choose Language': ('chooseLanguage', 'भाषा चुनें', 'भाषा चुणो', 'भाषा चुनो'),
    'Select your language': ('selectLanguage', 'अपनी भाषा चुनें', 'आपणी भाषा चुणो', 'अपनी भाषा चुनो'),
    'Navigate': ('navigate', 'नेविगेट करें', 'नेविगेट करो', 'नेविगेट करो'),
}

print(f'Loaded {len(STRINGS)} string mappings')
print('Ready for replacement.')
