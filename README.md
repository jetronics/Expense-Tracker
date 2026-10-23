# Budget Tracker

A simple, classic-style income and expense tracker for Android (Flutter).

## Features
- Add, edit and swipe-to-delete income and expense transactions (with undo)
- Default categories plus your own custom categories (name, color, icon)
- Month-by-month navigation with income / expenses / balance summary
- Monthly budget per category with progress bars and an overall "left" figure
- Stats tab with a donut chart and percentage breakdown for expenses or income
- Configurable currency symbol
- All data stored locally on the device

## Get the APK (no local setup)
1. Create a new GitHub repository and push this folder to it (branch `main`).
2. Open the **Actions** tab, choose **Build APK**, and click **Run workflow**
   (it also runs on every push).
3. When it finishes, open the run and download the **budget-tracker-apk**
   artifact. Unzip it and install `app-release.apk` on your phone.

## Build locally
Requires Flutter and the Android SDK.

    flutter create . --project-name budget_tracker --org com.jet --platforms=android
    git checkout -- lib pubspec.yaml   # keep our files if create touched them
    flutter pub get
    flutter build apk --release

The APK is written to `build/app/outputs/flutter-apk/app-release.apk`.
