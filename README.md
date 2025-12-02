### TAMUBOT: SMART KITCHEN ASSISTANT

---

##  Features

**Authentication**
  - Email + password with confirmation  
  - Google sign-in integration  
  - Phone authentication with MessageBird provider  
  - Two-Factor Authentication (2FA) via OTP  

**Recipe Management**
  - Browse curated Kenyan recipes  
  - Voice-based search and cooking guidance 
  - Bookmark and categorize recipes  

---

## Tech Stack

- **Frontend**: Flutter  
- **State Management**: Riverpod  
- **Backend & Auth**: Supabase  
- **2FA (OTP)**: MessageBird SMS API  
- **Deep Links**: App Links  
 

---

## Getting Started

### 1. Clone the repository
```bash
git clone https://github.com/Kinuthia-Claudia/TamuBot.git
cd TamuBot
```

### 2. Install dependencies
```bash
flutter pub get
```

### 3. Configure environment variables
Create a `.env` file in the TamuBot folder:
```bash
touch .env
```
Add the following inside:
```env
SUPABASE_URL=your-supabase-url
SUPABASE_ANON_KEY=your-supabase-anon-key
```

### 4. Set up deep links with your domain

Android
Edit `android/app/src/main/AndroidManifest.xml`:
```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="https" android:host="your-domain.com" />
</intent-filter>
```
iOS
Add the following in `ios/Runner/Info.plist`:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>your-domain</string>
        </array>
    </dict>
</array>
```

### 5. Run the app
```bash
flutter run
```

### 6. Build release versions

Android (APK / AAB)
```bash
flutter build apk --release
flutter build appbundle --release
```

 iOS
```bash
flutter build ios --release
```

## Contribution
Contributions, issues, and feature requests are welcome.

## License
This project is licensed under the MIT License



