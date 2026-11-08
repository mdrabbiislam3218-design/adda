# আড্ডা — ফেসবুকের মতো সোশ্যাল অ্যাপ (Android)

Flutter দিয়ে তৈরি অ্যাপ, আর ডাটাবেজ/লগইন/মেসেজের সার্ভার হিসেবে Firebase।

## অ্যাপে যা আছে

- ইমেইল ও পাসওয়ার্ড দিয়ে অ্যাকাউন্ট খোলা ও লগইন (পাসওয়ার্ড ভুলে গেলে রিসেট লিংক)
- প্রত্যেকের নিজের আইডি: নাম, প্রোফাইল ছবি, সংক্ষিপ্ত পরিচিতি (এডিট করা যায়)
- সবার পোস্ট দেখার ফিড: লেখা ও ছবি পোস্ট, লাইক, মন্তব্য, নিজের পোস্ট ও মন্তব্য মোছা
- "মানুষ" ট্যাব: নাম দিয়ে সবাইকে খোঁজা ও অন্যের প্রোফাইল দেখা
- মেসেঞ্জার: যে কোনো দুজনের মধ্যে সরাসরি রিয়েল-টাইম মেসেজ, আর মেসেজের তালিকা

## যা নেই (পরে যোগ করা যাবে)

- নতুন মেসেজ বা লাইকের পুশ নোটিফিকেশন
- ফ্রেন্ড রিকোয়েস্ট (এখন লগইন করা সবাই সবাইকে দেখতে ও মেসেজ দিতে পারে)
- মেসেজে ছবি পাঠানো, ভিডিও, অনলাইন স্ট্যাটাস
- রিপোর্ট ও ব্লক (Play Store-এ দিতে চাইলে এগুলো লাগবে)

ছবিগুলো ছোট করে Firestore-এ জমা হয়, কারণ নতুন প্রজেক্টে Firebase Storage চালাতে সাধারণত বিলিং (Blaze) অ্যাকাউন্ট লাগে। ছোট দল বা পরীক্ষার জন্য এটা ঠিক আছে। ব্যবহারকারী অনেক বাড়লে ছবি Storage-এ সরাতে হবে।

---

## চালু করার ধাপ

### ধাপ ১: Flutter ও Android Studio ইনস্টল

1. https://docs.flutter.dev/get-started/install থেকে নিজের কম্পিউটারের জন্য Flutter ইনস্টল করুন (Android Studio সহ)।
2. টার্মিনালে `flutter doctor` চালান। Android অংশে টিক চিহ্ন আসতে হবে। লাইসেন্স নিয়ে অভিযোগ এলে `flutter doctor --android-licenses` চালিয়ে সব `y` দিন।

### ধাপ ২: প্রজেক্ট তৈরি

1. zip ফাইলটি এক্সট্র্যাক্ট করুন, ভেতরে `adda` ফোল্ডার পাবেন।
2. টার্মিনালে ওই ফোল্ডারে ঢুকে চালান (শেষের ডট `.` ভুলবেন না):

```
cd adda
flutter create --org com.adda --project-name adda .
```

এতে `android` ফোল্ডার তৈরি হবে। যদি কখনো `lib/main.dart` বদলে যায়, zip থেকে আবার কপি করে দিন।

### ধাপ ৩: Firebase প্রজেক্ট খোলা

1. https://console.firebase.google.com এ নিজের Google অ্যাকাউন্টে ঢুকে **Add project** চাপুন। নাম দিন, Google Analytics বন্ধ রাখলেও চলবে।
2. বাঁ মেনু থেকে **Build → Authentication → Get started → Sign-in method → Email/Password** চালু (Enable) করে Save করুন।
3. **Build → Firestore Database → Create database** চাপুন। লোকেশন নিন `asia-south1` (মুম্বাই, বাংলাদেশের কাছের) এবং **Production mode** বেছে নিন।
4. Firestore-এর **Rules** ট্যাবে যান, আগের লেখা মুছে এই প্রজেক্টের `firestore.rules` ফাইলের পুরো লেখা পেস্ট করে **Publish** চাপুন। এটা না করলে অ্যাপে `permission-denied` ত্রুটি আসবে।

### ধাপ ৪: অ্যাপকে Firebase-এর সাথে জোড়া

1. Node.js ইনস্টল করুন (https://nodejs.org)।
2. টার্মিনালে একে একে চালান:

```
npm install -g firebase-tools
firebase login
dart pub global activate flutterfire_cli
flutterfire configure
```

3. `flutterfire configure` প্রশ্ন করলে নিজের Firebase প্রজেক্টটি বেছে নিন এবং প্ল্যাটফর্ম হিসেবে শুধু **android** রাখুন।
4. কমান্ডটি `lib/firebase_options.dart` ফাইল তৈরি করবে এবং Android-এ Firebase যোগ করে দেবে।

`flutterfire` কমান্ড না পেলে এভাবে চালান: `dart pub global run flutterfire_cli:flutterfire configure`

### ধাপ ৫: ফোনে চালানো

1. ফোনে **Settings → Developer options → USB debugging** চালু করে USB দিয়ে কম্পিউটারে লাগান (অথবা Android Studio-র Emulator চালু করুন)।
2. চালান:

```
flutter pub get
flutter run
```

### ধাপ ৬: APK বানিয়ে বন্ধুদের দেওয়া

```
flutter build apk --release
```

ফাইলটি পাবেন `build/app/outputs/flutter-apk/app-release.apk` এ। ফোনে পাঠিয়ে ইনস্টল করলেই হবে। এটা Play Store-এ আপলোডের জন্য নয়, সেজন্য আলাদা সাইনিং কি লাগে।

---

## সমস্যা হলে

| সমস্যা | সমাধান |
|---|---|
| `firebase_options.dart` পাওয়া যাচ্ছে না | ধাপ ৪-এর `flutterfire configure` চালানো হয়নি |
| `permission-denied` | ধাপ ৩-এর চার নম্বরে Rules Publish করা হয়নি |
| লগইনে "Email/Password সাইন-ইন চালু করা হয়নি" | ধাপ ৩-এর দুই নম্বর করা হয়নি |
| বিল্ডে `minSdkVersion` নিয়ে ত্রুটি | `android/app/build.gradle` (বা `build.gradle.kts`) ফাইলে `minSdk = flutter.minSdkVersion` লাইনটি `minSdk = 23` করে দিন |
| ছবি দিলে "ছবিটি অনেক বড়" | তুলনামূলক ছোট বা কম রেজোলিউশনের ছবি বেছে নিন |
| ফোনে ইন্টারনেট কাজ করছে না (শুধু release APK-তে) | `android/app/src/main/AndroidManifest.xml` এ `<manifest>` এর ঠিক নিচে `<uses-permission android:name="android.permission.INTERNET"/>` যোগ করুন |

## নিরাপত্তার কথা

আপনার Firebase বা Google অ্যাকাউন্টের পাসওয়ার্ড বা অ্যাক্সেস কারও সাথে শেয়ার করবেন না। এই অ্যাপ চালাতে আপনার নিজের কম্পিউটারে উপরের ধাপগুলোই যথেষ্ট।
