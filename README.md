# 🍲 Recipe App

A production-ready, feature-rich **Recipe Application** built with **Flutter**, **Firebase Cloud Firestore**, and **Provider** for state management. The app features real-time database synchronization, live search & category filtering, persistent favorites, interactive serving counters with proportional ingredient scaling, and step-by-step cooking instructions.

---

## 📱 App Preview & Key Features

- ⚡ **Real-Time Cloud Firestore Sync**: Instant updates for categories, recipes, and user favorites using Firestore reactive streams (`collectionGroup('recipes')`).
- 🔍 **Instant Search & Filtering**: Live search by recipe title or ingredient keywords combined with horizontal category chips (*Breakfast, Dessert, Dinner, Lunch, Vegetables*).
- ⚖️ **Dynamic Serving & Ingredient Scaler**: Increment or decrement serving sizes to automatically recalculate and scale ingredient quantities (supporting whole numbers, fractions like `1/2`, and decimals).
- ❤️ **Persistent Favorites**: Bookmark recipes with optimistic UI updates and live synchronization to Firestore.
- 📖 **Comprehensive Detail View**: Immersive Hero animations, nutrition/time stat badges, visual ingredient cards, and numbered cooking instructions.
- 🗄️ **Idempotent Database Seeder**: Built-in CLI tool to seed and verify initial Firestore collections and subcollections without duplicate data.

---

## 🛠️ Tech Stack & Dependencies

- **Framework**: [Flutter](https://flutter.dev/) (Channel Stable, Material 3)
- **Language**: [Dart](https://dart.dev/)
- **Backend & Database**: [Firebase Cloud Firestore](https://firebase.google.com/docs/firestore) (`cloud_firestore: ^6.9.0`, `firebase_core: ^4.14.0`)
- **State Management**: [Provider](https://pub.dev/packages/provider) (`provider: ^6.1.5+1`)
- **Icons**: [Iconsax](https://pub.dev/packages/iconsax) (`iconsax: ^0.0.8`)

---

## 📂 Project Structure

```text
lib/
├── category_model.dart              # Category data model (id, name, image)
├── firebase_options.dart            # FlutterFire auto-generated configuration
├── main.dart                        # App entry point with MultiProvider & Theme
├── models/
│   └── recipe_model.dart            # Recipe data model with safe parsers & instructions
├── providers/
│   └── recipe_provider.dart         # ChangeNotifier managing state, streams, & filters
├── services/
│   └── firestore_service.dart       # Firestore stream subscriptions & favorite toggling
├── utils/
│   ├── app_colors.dart              # Shared design system palette & constants
│   └── ingredient_scaler.dart       # Proportional scaling algorithm for fractions & decimals
└── views/
    ├── detail/
    │   └── recipe_detail_screen.dart # SliverAppBar, servings counter, scaled ingredients, steps
    ├── favorites/
    │   └── favorites_screen.dart    # Favorites grid with empty state illustration
    ├── home/
    │   ├── home_screen.dart         # Search bar, category chips, recipe grid
    │   └── recipe_card.dart         # Reusable card with Hero image, rating & calorie tags
    └── main_shell.dart              # Root navigation shell (NavigationBar + IndexedStack)

tool/
├── file_reader.dart                 # Platform-agnostic file reader (Web/IO conditional exports)
├── file_reader_io.dart              # Native filesystem reader for desktop/mobile
├── file_reader_web.dart             # Web stub
└── seed_firestore.dart              # Idempotent batch database seeder tool
```

---

## 🗄️ Firestore Database Schema

The database follows a hierarchical collection/subcollection architecture:

```text
categories/ (Collection)
  └── {categoryId}/ (Document: e.g., "breakfast", "dinner", "lunch")
        ├── name: String ("Breakfast")
        ├── image: String (URL)
        └── recipes/ (Subcollection)
              └── {recipeId}/ (Document: e.g., "butter_paneer", "chicken_curry")
                    ├── name: String
                    ├── calorie: String
                    ├── category: String
                    ├── image: String
                    ├── ingredientAmount: List<String>
                    ├── ingredientImage: List<String>
                    ├── ingredientName: List<String>
                    ├── instructions: List<String>
                    ├── isFavorite: Boolean
                    ├── rating: Number (double)
                    ├── review: Number (int)
                    └── time: Number (int)
```

---

## 🚀 Getting Started

### 1. Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.47.0` recommended)
- [Firebase CLI](https://firebase.google.com/docs/cli) & Google Account

### 2. Clone and Install Dependencies
```bash
git clone https://github.com/<your-username>/recipe.git
cd recipe
flutter pub get
```

### 3. Firebase Configuration
Ensure your project is registered in your Firebase console. The existing configuration in [`lib/firebase_options.dart`](lib/firebase_options.dart) is pre-configured for project `recipeapp-f533f`.

To reconfigure or connect to your own Firebase project:
```bash
flutterfire configure
```

Ensure your **Firestore Security Rules** allow read/write access during development:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

---

## 🌾 Database Seeding

To populate Firestore with the 5 categories and 25 recipes from [`recipe_firestore_seed_5x5.json`](recipe_firestore_seed_5x5.json), run the seeder tool:

```bash
# Run on Chrome
flutter run -t tool/seed_firestore.dart -d chrome

# Or run on connected Android device/emulator
flutter run -t tool/seed_firestore.dart -d android
```

The script executes idempotent batch writes:
```text
Starting Firestore seed...

Category: Breakfast
Uploading 5 recipes...

Category: Dessert
Uploading 5 recipes...

Category: Dinner
Uploading 5 recipes...

Category: Lunch
Uploading 5 recipes...

Category: Vegetables
Uploading 5 recipes...

--------------------------------
Firestore seed completed.
Categories uploaded: 5
Recipes uploaded: 25
--------------------------------
```

---

## 🏃 Running the Application

### Debug Mode (Web / Chrome)
```bash
flutter run -d chrome
```

### Debug Mode (Android)
```bash
flutter run -d android
```

### Run Static Analysis
```bash
flutter analyze
```

---

## 📦 Building for Production

### Android APK (Release)
```bash
flutter build apk --release
```
*The output APK will be located at `build/app/outputs/flutter-apk/app-release.apk`.*

### Web Application (Release)
```bash
flutter build web --no-tree-shake-icons
```
*The output bundle will be located at `build/web`.*

---

## 📄 License
This project is licensed under the MIT License.
