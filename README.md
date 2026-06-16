# معلم القرآن — Quran Teacher Tracker

تطبيق أندرويد للمعلم لمتابعة حفظ طلابه وتسجيل الجلسات والحضور ومشاركة التقارير مع أولياء الأمور.

---

## ⚙️ الإعداد الأولي (مرة واحدة فقط)

### 1. إنشاء مشروع Firebase

1. افتح [https://console.firebase.google.com](https://console.firebase.google.com)
2. أنشئ مشروعاً جديداً
3. فعّل **Authentication** → Sign-in method → **Email/Password**
4. أنشئ حساب المعلم يدوياً من: Authentication → Users → Add user
5. فعّل **Firestore Database** (ابدأ في وضع test ثم انشر القواعد لاحقاً)

### 2. ربط Firebase بالتطبيق

```bash
# تثبيت FlutterFire CLI
dart pub global activate flutterfire_cli

# تسجيل الدخول لـ Firebase
firebase login

# توليد firebase_options.dart (اختر مشروعك واختر android فقط)
flutterfire configure --platforms=android
```

> هذا سيُحدّث `lib/firebase_options.dart` تلقائياً بالقيم الحقيقية.

### 3. نشر قواعد Firestore

```bash
# تثبيت Firebase CLI إذا لم يكن موجوداً
npm install -g firebase-tools

firebase login
firebase init firestore   # اختر مشروعك الحالي

# انسخ firestore.rules و firestore.indexes.json من المشروع
firebase deploy --only firestore:rules,firestore:indexes
```

---

## 🚀 البناء عبر GitHub Actions (الطريقة الموصى بها)

1. ارفع كامل محتوى المشروع إلى مستودع GitHub جديد (انسخ الملفات وارفعها من الواجهة أو git push)
2. تأكد أن `.github/workflows/build_apk.yml` موجود
3. اذهب إلى **Actions** → **Build APK** → **Run workflow**
4. بعد انتهاء البناء: **Artifacts** → حمّل `app-release.apk`

> **ملاحظة:** يستخدم البناء debug signing key لأغراض التطوير. لا تحتاج إلى keystore خاص.

---

## 💻 البناء المحلي

```bash
flutter pub get
flutter run                        # تشغيل في المحاكي
flutter build apk --release        # بناء APK
```

---

## 🏗️ هيكل المشروع

```
lib/
├── main.dart
├── firebase_options.dart          ← يُولَّد بـ flutterfire configure
├── core/
│   ├── constants/                 ← AppConstants, QuranData (114 سورة)
│   ├── router/app_router.dart     ← GoRouter + shell navigation
│   ├── theme/app_theme.dart       ← Material 3 أخضر إسلامي
│   └── utils/                     ← Formatters, AnalyticsUtils
├── domain/
│   ├── entities/                  ← Student, Session, Note, ...
│   └── repositories/              ← Abstract interfaces
├── data/
│   ├── models/                    ← Firestore mappers
│   └── repositories/              ← Firebase implementations
└── presentation/
    ├── providers/app_providers.dart   ← كل Riverpod providers
    ├── screens/
    │   ├── auth/login_screen.dart
    │   ├── dashboard/
    │   ├── students/              ← list, detail, form
    │   ├── sessions/add_session_screen.dart
    │   ├── attendance/
    │   ├── reports/
    │   ├── share/                 ← QR + link management
    │   └── public/                ← صفحة ولي الأمر (بدون تسجيل دخول)
    └── widgets/                   ← StatCard, SectionCard, ...
```

---

## 🗄️ هيكل Firestore

```
teachers/{uid}/
  students/{studentId}
    sessions/{sessionId}
    attendance/{dateKey}           ← yyyy-MM-dd
    notes/{noteId}

shared_tokens/{token}              ← فهرس للرمز → studentId
public_reports/{token}             ← لقطة يقرأها ولي الأمر (public read)
```

---

## 🔗 روابط المشاركة

- كل طالب يمكن إنشاء رابط مشاركة آمن
- الرابط: `https://quran-tracker.web.app/report/{token}`
- غيّر `AppConstants.reportBaseUrl` في `lib/core/constants/app_constants.dart` لاستخدام نطاقك

---

## 📦 الحزم الرئيسية

| الحزمة | الاستخدام |
|--------|-----------|
| `flutter_riverpod` | إدارة الحالة |
| `go_router` | التنقل + deep links |
| `firebase_auth` | تسجيل دخول المعلم |
| `cloud_firestore` | قاعدة البيانات |
| `fl_chart` | مخططات الحفظ الأسبوعي |
| `qr_flutter` | QR code المشاركة |
| `share_plus` | مشاركة الرابط |
| `intl` | التنسيق العربي |
