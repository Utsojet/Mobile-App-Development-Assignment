# 🍲 Recipe App — Mobile App Development Assignment

A modern, production-grade **Recipe Application** built with **Flutter**, **Firebase Authentication**, **Cloud Firestore**, and **Provider** for reactive state management. Designed and developed by **[Utsojet](https://github.com/Utsojet)** as part of the Mobile App Development coursework.

The application features full user authentication, customized user profiles, light/dark theme switching, a live recipe review and rating engine, interactive serving scaling, custom recipe publishing with real-time ingredient photo resolution, and cross-platform responsiveness across Mobile, Tablet, and Desktop web.

---

## 👨‍💻 Developer Information

- **Developer**: Utsojet
- **GitHub**: [@Utsojet](https://github.com/Utsojet)
- **Repository**: [https://github.com/Utsojet/Mobile-App-Development-Assignment](https://github.com/Utsojet/Mobile-App-Development-Assignment)
- **Platform**: Flutter (Android, iOS, Web, macOS, Linux, Windows)

---

## ✨ Key Features

### 1. 🔐 User Authentication & Security
- **Email & Password Authentication**: Full registration and sign-in powered by Firebase Authentication.
- **Session Persistence**: Automatic login persistence across app launches via `AuthGate`.
- **Password Reset**: Forgot password flow sending secure reset emails via Firebase.
- **Guest / Protected Mode**: Guests can freely browse and search recipes; signing in is required to bookmark favorites, submit reviews, or publish new recipes.

### 2. 👤 User Profile Management
- **Custom Profile**: View and edit user display name, avatar photo URL, and bio description.
- **Change Password**: Secure in-app password update dialog with re-authentication support.
- **My Reviews**: Dedicated dashboard showing all reviews submitted by the logged-in user with quick navigation and delete options.
- **Sign Out**: Instant account sign-out with state cleanup.

### 3. 🌓 Modern Theme Engine
- **Theme Modes**: Full support for **Light Mode**, **Dark Mode**, and **System Default**.
- **Persistence**: Theme selection is saved locally via `shared_preferences` and restored upon launch.
- **Contrast & Accessibility**: Carefully selected color palettes adhering to Material 3 guidelines and high contrast standards.

### 4. 📝 Recipe Reviews & Ratings
- **Interactive Ratings**: 5-star interactive rating bar with text feedback.
- **Real-Time Aggregates**: Automatically recalculates average recipe ratings and review counts upon submission or deletion.
- **Review Deletion**: Users can remove their own reviews directly from the recipe detail screen or the profile review list.

### 5. ➕ Add Recipe Flow
- **Recipe Publishing**: Users can publish new recipes directly to Cloud Firestore.
- **Live Ingredient Previews**: Dynamic ingredient list cards with real-time 48x48 photo previews auto-resolved via TheMealDB CDN or custom image URLs.
- **Rich Metadata**: Specify cooking time, calories, servings, difficulty level (*Easy, Medium, Hard*), category, and numbered instruction steps.

### 6. 🔍 Search, Filter & Favorites
- **Real-Time Search**: Instant querying across recipe titles and ingredient lists.
- **Horizontal Category Bar**: Quick filtering by categories (*Breakfast, Dessert, Dinner, Lunch, Vegetables, Chicken, Seafood*).
- **Personal Favorites**: User-isolated bookmarks stored under `users/{uid}/favorites` with optimistic UI updates.

### 7. ⚖️ Proportional Ingredient Scaler
- **Dynamic Servings**: Adjust serving counts up or down on the detail screen.
- **Smart Arithmetic**: Automatically scales whole numbers, fractions (`1/2`, `3/4`), and decimals proportionally.

### 8. 📱 Responsive Layout
- Adaptive UI constrained with max-width boundaries and fluid grids for optimal presentation on smartphones, tablets, and desktop browsers.

---

## 🛠️ Tech Stack & Architecture

- **Framework**: [Flutter](https://flutter.dev/) (Channel Stable, Material 3)
- **Language**: [Dart](https://dart.dev/)
- **State Management**: [Provider](https://pub.dev/packages/provider) (`ChangeNotifierProvider`, `MultiProvider`)
- **Backend & Database**:
  - [Firebase Core](https://pub.dev/packages/firebase_core)
  - [Firebase Authentication](https://pub.dev/packages/firebase_auth)
  - [Cloud Firestore](https://pub.dev/packages/cloud_firestore)
- **Local Storage**: [shared_preferences](https://pub.dev/packages/shared_preferences)
- **Icons**: [Iconsax](https://pub.dev/packages/iconsax)
- **Image Assets**: [TheMealDB CDN](https://www.themealdb.com/) & [Unsplash](https://unsplash.com/)

---

## 📂 Project Architecture

```text
lib/
├── category_model.dart              # Category data model (id, name, image)
├── firebase_options.dart            # FlutterFire initialization config
├── main.dart                        # Entry point with MultiProvider & ThemeController
├── models/
│   ├── recipe_model.dart            # Recipe model, multi-format parsers & smart fallbacks
│   ├── review_model.dart            # Review data model
│   └── user_model.dart              # User profile data model
├── providers/
│   ├── auth_provider.dart           # Authentication & user profile state manager
│   └── recipe_provider.dart         # Recipe data streams, search, and user favorites
├── services/
│   ├── auth_service.dart            # Firebase Auth operations & credential handling
│   ├── firestore_service.dart       # Firestore CRUD, recipe streams, & favorites
│   ├── review_service.dart          # Review creation, deletion, & aggregate calculation
│   └── user_service.dart            # User profile reads & updates in Firestore
├── theme/
│   ├── app_theme.dart               # Light & Dark ThemeData definitions
│   └── theme_controller.dart        # ThemeMode state notifier with SharedPreferences
├── utils/
│   ├── app_colors.dart              # Color palette constants
│   └── ingredient_scaler.dart       # Proportional scaling algorithm
└── views/
    ├── auth/
    │   ├── auth_gate.dart           # Auth state router
    │   ├── login_screen.dart        # Email/password sign-in & password reset
    │   └── register_screen.dart     # New account registration
    ├── detail/
    │   └── recipe_detail_screen.dart# Detail view, servings scaler, reviews section
    ├── favorites/
    │   └── favorites_screen.dart    # User's bookmarked recipes grid
    ├── home/
    │   ├── home_screen.dart         # Search bar, category chips, recipe grid
    │   └── recipe_card.dart         # Recipe card with Hero image, rating & stats
    ├── profile/
    │   ├── change_password_dialog.dart # In-app password change modal
    │   ├── edit_profile_screen.dart # Edit display name, photo, & bio
    │   ├── my_reviews_screen.dart   # List and delete user's reviews
    │   ├── profile_screen.dart      # Main user profile screen
    │   ├── profile_sheet.dart       # Quick profile bottom sheet
    │   └── theme_settings_screen.dart # Theme selection screen (System/Light/Dark)
    ├── recipe/
    │   └── add_recipe_screen.dart   # Interactive recipe creation with ingredient preview
    └── main_shell.dart              # Bottom navigation bar root shell
```

---

## 🗄️ Cloud Firestore Schema

### 1. `categories/{categoryId}`
```json
{
  "name": "Breakfast",
  "image": "https://images.unsplash.com/..."
}
```

### 2. `categories/{categoryId}/recipes/{recipeId}`
```json
{
  "id": "chicken_curry_1713225718",
  "categoryId": "chicken",
  "name": "Bengali Chicken Curry with Potatoes",
  "category": "Chicken",
  "image": "https://images.unsplash.com/...",
  "calorie": "420",
  "time": 35,
  "servings": 4,
  "difficulty": "Medium",
  "rating": 4.8,
  "review": 15,
  "ingredientName": ["Chicken Breast", "Potatoes", "Curry Powder", "Onion", "Garlic"],
  "ingredientAmount": ["450 gm", "2 medium", "2 tbsp", "1 large", "3 cloves"],
  "ingredientImage": ["https://www.themealdb.com/images/ingredients/Chicken%20Breast-Small.png", "..."],
  "instructions": [
    "Heat oil in a heavy pot and sauté onions until translucent.",
    "Add curry powder and garlic, cooking for 1 minute.",
    "Add chicken and potatoes, simmer for 25 minutes until cooked through."
  ],
  "createdBy": "user_uid_here",
  "createdAt": "Timestamp"
}
```

### 3. `users/{uid}`
```json
{
  "uid": "user_uid_here",
  "email": "user@example.com",
  "displayName": "Utsojet",
  "photoUrl": "https://images.unsplash.com/...",
  "bio": "Passionate home cook exploring world recipes.",
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```

### 4. `users/{uid}/favorites/{recipeId}`
```json
{
  "favoritedAt": "Timestamp"
}
```

### 5. `reviews/{reviewId}`
```json
{
  "id": "reviewId",
  "recipeId": "recipeId",
  "recipeName": "Bengali Chicken Curry with Potatoes",
  "recipeImage": "https://images.unsplash.com/...",
  "userId": "user_uid_here",
  "userName": "Utsojet",
  "userPhotoUrl": "https://...",
  "rating": 5.0,
  "comment": "Incredible flavor! Family loved it.",
  "createdAt": "Timestamp"
}
```

---

## 🚀 Getting Started

### 1. Clone the Repository
```bash
git clone https://github.com/Utsojet/Mobile-App-Development-Assignment.git
cd Mobile-App-Development-Assignment
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Run the App
- **Web (Chrome)**:
  ```bash
  flutter run -d chrome
  ```
- **Android**:
  ```bash
  flutter run -d android
  ```
- **iOS** (macOS only):
  ```bash
  flutter run -d ios
  ```

### 4. Run Automated Tests
```bash
flutter test
```

### 5. Static Code Analysis
```bash
flutter analyze
```

---

## 📦 Building for Production

### Android Release APK
```bash
flutter build apk --release
```
*Generated output: `build/app/outputs/flutter-apk/app-release.apk`*

### Web Release
```bash
flutter build web --no-tree-shake-icons
```
*Generated output: `build/web/`*

---

## 📜 License

Created by **[Utsojet](https://github.com/Utsojet)** for the Mobile App Development Assignment. All rights reserved.
