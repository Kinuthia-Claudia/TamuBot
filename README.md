### TAMUBOT: SMART KITCHEN ASSISTANT
A smart voice-enabled kitchen assistant app that helps users discover, prepare, and track Kenyan recipes through intuitive voice interactions and smart recipe management.

<img width="307" height="302" alt="image" src="https://github.com/user-attachments/assets/abdda1b8-1c03-4159-9d01-220ea445eacb" />


---

## Features

###  **Authentication & Security**
- **Multi-method Authentication**: Email and password with confirmation, One-time Login
- **Social Login**: Google Authentication integration
- **Session Management**: Secure token-based session handling

###  **Recipe Management**

- **Smart Search**: Voice-based search and cooking guidance
- **Recipe Organization**: Bookmark, categorize, and save favorite recipes
- **Ingredient Substitution**: Smart suggestions for ingredient alternatives
- **Nutrition Tracking**: Calorie and nutrition information per serving
- **Meal Plan Curation**: Arrange bookmarked recipes into customizable mealplans
  
  
###  **Voice Assistant**
- **Voice Commands**: Natural language processing for recipe queries
- **Audio Waveform Visualization**: Real-time voice recording visualization
- **Text-to-Speech**: Step-by-step cooking instructions read aloud

###  **User Experience**
- **Manage Dietary Preferences**: Customize preferences
- **Progress Tracking**: Track cooking progress and completion
- **Cooking Timer**: Built-in timer for recipe steps
  
###  **Admin Web-App**
- **User Management**: Track users in the system
- **Data and Analytics**: Access important app analytics

---



##  Tech Stack

### **App Frontend**
- **Framework**: Flutter 
- **State Management**: Riverpod 
- **Animations**: Flutter Animations, Rive
### **Backend & Services**
- **Backend & Auth**: Supabase (PostgreSQL, Auth, Storage buckets for audio)
- **Deep Links**: App Links
- **Kaggle**
- **Ngrok**
- **HuggingFace Spaces**
- **Whisper and Microsoft Phi 2 finetuned models**

---
## AI Model Performance


### **Speech Recognition (Whisper Model)**
The Whisper model was fine-tuned for bilingual speech recognition (English & Kiswahili) achieving:
- **Word Accuracy**: ~65% (WER: 0.348)
- **Character Accuracy**: ~75% (CER: 0.254)
- **Training**: 500 steps with data streaming & mixed-precision (40% faster)

### **Recipe Generation (Phi Model)**
The Phi model specializes in culinary text generation with:
- **Semantic Accuracy**: 78.4% (BERTScore)
- **Practical Recipes**: 66.7% execution-ready
- **Ingredient Coverage**: 72.3% completeness
- **Hallucination Rate**: 15.6% (low false ingredients)

### **Technical Highlights**
- **Efficient Training**: Mixed precision (FP16) for 40% speed improvement
- **Bilingual Support**: English & Kiswahili speech recognition
- **Practical Utility**: Generates cookable recipes with proper ingredients
- **Balanced Performance**: Strong semantic understanding with room for sequencing improvement

---

##  System Architecture
<img width="742" height="414" alt="image" src="https://github.com/user-attachments/assets/dd88ae7f-48d9-4dcb-8a60-33cbdb25458b" />
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

---
##  Acknowledgments

### **Data Sources**

- **Kenyan Recipes Dataset** by **Lewis Mutonyi**  
  A comprehensive collection of Kenyan dishes with nutritional information and regional data.  
  [Kaggle Link](https://www.kaggle.com/datasets/lewismutonyi/kenyan-recipes-dataset)

- **Kenyan Recipes** by **GNARLY404**  
  Additional Kenyan culinary data used to enhance our recipe database.  
  [Kaggle Link](https://www.kaggle.com/datasets/gnarly404/kenyan-recipes)

### **Platforms & Tools**
- **Supabase** for the amazing backend platform
- **Flutter** for the cross-platform framework
- **Kaggle** for hosting valuable open datasets

## Contribution
Contributions, issues, and feature requests are welcome.

## License
This project is licensed under the MIT License



