# Hero Mission  🏆 — Gamified To-Do App for Children

A Flutter mobile application where children experience tasks as exciting game **missions**, earn **coins**, level up as **heroes**, and redeem **rewards** — all under their parent's watchful control.

> 👥 Team project built by a team of 5 · Flutter · Firebase

---

## 📸 Screenshots

![Hero Mission screens](hero-mission-screens.png)

---

## ✨ Features

### For Children (Game Experience)
- 🎮 **Mission-style tasks** — colorful gradient cards with status badges
- 🪙 **Coin rewards** — animated counter that bounces when you earn coins  
- ⭐ **XP & Levels** — 10 levels from Newbie to Grand Master
- 🔥 **Daily streaks** — tracked automatically each day
- 🏅 **Badges** — 7 unlockable achievements
- 🎁 **Rewards Shop** — redeem coins for parent-defined rewards
- 🎉 **Celebration screen** — full confetti burst on mission completion
- 🧑‍🎤 **Avatar selector** — 8 built-in cartoon animal avatars

### For Parents (Clean & Professional)
- 👨‍👩‍👧‍👦 **Dashboard** — children overview with XP bars, coins, and streaks
- ⚔️ **Mission creator** — title, description, coin reward (slider), deadline, child assignment
- ✅ **Approval system** — approve or reject completed missions
- 📊 **Progress viewer** — detailed stats and badge overview per child

---

## 🚀 Firebase Setup (Required)

### Step 1 — Create Firebase Project
1. Go to [console.firebase.google.com](https://console.firebase.google.com)
2. Click **Add Project** → follow the wizard
3. Enable **Google Analytics** (optional)

### Step 2 — Enable Services
1. **Authentication** → Sign-in method → Enable **Google**
2. **Cloud Firestore** → Create database → Start in **test mode** (update rules before production)

### Step 3 — Add Android App
1. In Firebase Console → Project Settings → Add App → Android
2. Package name: `com.kidquest.todoGame`
3. Download **`google-services.json`**
4. Place it at: `android/app/google-services.json`

### Step 4 — Add iOS App (if needed)
1. Add App → iOS
2. Bundle ID: `com.kidquest.todoGame`
3. Download **`GoogleService-Info.plist`**
4. Place it at: `ios/Runner/GoogleService-Info.plist`

### Step 5 — Configure FlutterFire
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure (auto-generates lib/firebase_options.dart)
flutterfire configure
```

> **Note**: If using `flutterfire configure`, it will overwrite `lib/firebase_options.dart` with your real values. Otherwise, manually replace the placeholder values in that file.

---

## 🗄️ Firestore Data Structure

```
users/{userId}
  ├── name: string
  ├── email: string
  ├── role: "parent" | "child"
  ├── parentId: string (child only)
  ├── avatarIndex: int (0-7)
  ├── pin: string (child only, 4 digits)
  └── createdAt: timestamp

tasks/{taskId}
  ├── title: string
  ├── description: string
  ├── points: int
  ├── deadline: timestamp (optional)
  ├── status: "pending" | "completed" | "approved" | "rejected"
  ├── childId: string
  ├── parentId: string
  ├── createdAt: timestamp
  └── completedAt: timestamp (optional)

rewards/{rewardId}
  ├── title: string
  ├── description: string
  ├── cost: int
  ├── iconName: string (emoji)
  ├── childId: string
  ├── parentId: string
  ├── isRedeemed: bool
  ├── createdAt: timestamp
  └── redeemedAt: timestamp (optional)

progress/{childId}
  ├── points: int (spendable coins)
  ├── xp: int (cumulative, never decreases)
  ├── level: int
  ├── streak: int
  ├── lastActivityDate: timestamp
  ├── badges: string[]
  └── updatedAt: timestamp
```

### Firestore Indexes Required
Add these composite indexes in Firebase Console:

| Collection | Fields | Order |
|---|---|---|
| `tasks` | `parentId` ASC, `status` ASC, `completedAt` DESC | — |
| `tasks` | `childId` ASC, `createdAt` DESC | — |
| `rewards` | `childId` ASC, `createdAt` ASC | — |

---

## 🏗️ Project Structure

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_colors.dart      # Child + parent color palettes
│   │   └── app_strings.dart     # All text constants
│   ├── theme/
│   │   └── app_theme.dart       # childTheme + parentTheme
│   ├── utils/
│   │   └── level_utils.dart     # XP/level calculations
│   └── router.dart              # Named routes
├── models/
│   ├── user_model.dart
│   ├── task_model.dart
│   ├── reward_model.dart
│   ├── progress_model.dart
│   └── badge_model.dart
├── services/
│   ├── auth_service.dart        # Google Sign-In, PIN login
│   └── firestore_service.dart   # Firestore CRUD + approval logic
├── providers/
│   ├── auth_provider.dart
│   ├── task_provider.dart
│   ├── reward_provider.dart
│   ├── progress_provider.dart
│   └── child_provider.dart
├── screens/
│   ├── splash/splash_screen.dart
│   ├── auth/
│   │   ├── login_screen.dart
│   │   ├── role_selection_screen.dart
│   │   └── child_login_screen.dart
│   ├── parent/
│   │   ├── parent_dashboard_screen.dart
│   │   ├── add_task_screen.dart
│   │   ├── task_approval_screen.dart
│   │   └── child_progress_screen.dart
│   └── child/
│       ├── child_home_screen.dart
│       ├── missions_screen.dart
│       ├── rewards_screen.dart
│       ├── profile_screen.dart
│       └── celebration_screen.dart
├── widgets/
│   ├── avatar_widget.dart
│   ├── badge_chip.dart
│   ├── child_summary_card.dart
│   ├── coin_counter.dart
│   ├── confetti_overlay.dart
│   ├── gradient_button.dart
│   ├── level_bar.dart
│   ├── mission_card.dart
│   ├── reward_card.dart
│   ├── streak_badge.dart
│   └── task_approval_card.dart
├── firebase_options.dart        # ← REPLACE with your config
└── main.dart
```

---

## ▶️ Running the App

```bash
# Install dependencies
flutter pub get

# Run on connected device/emulator
flutter run

# Build debug APK
flutter build apk --debug
```

---

## 🎮 Gamification System

| Mechanic | Details |
|---|---|
| **Coins** | Awarded when parent approves a task. Spendable in rewards shop. |
| **XP** | Cumulative (never decreases). Coins and XP are the same value added. |
| **Levels** | 0→50→150→300→500→750→1050→1400→1800→2250 XP |
| **Streak** | Counts consecutive days with at least 1 approved task. Resets if gap > 1 day. |
| **Badges** | 7 milestones: First Mission, 5-day streak, 10-day streak, Level 5, Level 10, 100 XP, 10 missions |

---

## 🎨 Design System

### Child Theme (Dark Game Mode)
- Font: **Nunito** (rounded, playful)
- Primary: `#6C63FF` (Purple)
- Gold: `#FFD700` (Coins)
- Accent: `#00B4FF` (Sky Blue)
- Background: `#1A1A2E` (Deep Dark)

### Parent Theme (Light Professional)
- Font: **Poppins** (clean, modern)
- Primary: `#5C6BC0` (Indigo)
- Background: `#F8F9FA` (Light Grey)
- Clean cards with subtle borders

---

## 🔐 Security Notes

Before going to production, update Firestore Security Rules:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    match /tasks/{taskId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    match /rewards/{rewardId} {
      allow read, write: if request.auth != null;
    }
    match /progress/{childId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

---

## 👩‍💻 My Role

This is a team project built by a team of 5. I worked on every part of the app:
- **UI & screens:** child game-mode screens and parent dashboard in Flutter
- **Gamification logic:** missions, coins, XP levels, streaks, badges, and rewards
- **Firebase:** authentication, Firestore data structure, and security rules

## 👥 Team
- Amani Rabeea — [@Amani20f](https://github.com/Amani20f)
- Noor Abdullah — [@noorbam](https://github.com/noorbam)
- Nora Omar
- Hanan Omar
- Raghad Akram

> Original repository: [noorbam/Hero_Mission](https://github.com/noorbam/Hero_Mission)

---

*Built with Flutter · Firebase · Provider · flutter_animate · confetti*
