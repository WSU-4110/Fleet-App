# React + Vite

This template provides a minimal setup to get React working in Vite with HMR and some ESLint rules.

Currently, two official plugins are available:

- [@vitejs/plugin-react](https://github.com/vitejs/vite-plugin-react/blob/main/packages/plugin-react) uses [Babel](https://babeljs.io/) (or [oxc](https://oxc.rs) when used in [rolldown-vite](https://vite.dev/guide/rolldown)) for Fast Refresh
- [@vitejs/plugin-react-swc](https://github.com/vitejs/vite-plugin-react/blob/main/packages/plugin-react-swc) uses [SWC](https://swc.rs/) for Fast Refresh

## React Compiler

The React Compiler is not enabled on this template because of its impact on dev & build performances. To add it, see [this documentation](https://react.dev/learn/react-compiler/installation).

## Expanding the ESLint configuration

If you are developing a production application, we recommend using TypeScript with type-aware lint rules enabled. Check out the [TS template](https://github.com/vitejs/vite/tree/main/packages/create-vite/template-react-ts) for information on how to integrate TypeScript and [`typescript-eslint`](https://typescript-eslint.io) in your project.


##############################
FOR IOS
## Requirements

- Xcode 15 or later
- iOS 16.0+
- CocoaPods
- A Firebase project
- A Google Maps API key

---

## Setup

### 1. Clone the repo

```bash
git clone https://github.com/WSU-4110/Fleet-App.git
cd Fleet-App/iOS
```

### 2. Install dependencies

```bash
cd Fleet-Tracker
pod install
```

Open the project using the `.xcworkspace` file — **not** `.xcodeproj`:

```bash
open Fleet-Tracker.xcworkspace
```

### 3. Add GoogleService-Info.plist

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project → iOS app
3. Download `GoogleService-Info.plist`
4. Drag it into the `Fleet-Tracker` folder in Xcode (make sure "Copy items if needed" is checked)

### 4. Add your Google Maps API key

In `AppDelegate.swift` or wherever `GMSServices.provideAPIKey` is called, replace with your key:

```swift
GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY")
```

You can get a key from [Google Cloud Console](https://console.cloud.google.com) — enable the **Maps SDK for iOS** and **Roads API**.

### 5. Configure Info.plist

Make sure these keys are present in `Info.plist`:

```
NSLocationWhenInUseUsageDescription
NSLocationAlwaysAndWhenInUseUsageDescription
NSLocationAlwaysUsageDescription
NSCameraUsageDescription
NSPhotoLibraryUsageDescription
NSPhotoLibraryAddUsageDescription
```

### 6. Enable capabilities in Xcode

- Target → Signing & Capabilities
- Add **Background Modes** → check **Location updates**
- Add **Push Notifications** (if using notifications)

---

## Firebase Setup

### Firestore Rules

Copy the rules from `firestore.rules` in the repo into your Firebase Console → Firestore → Rules tab.

### Required Firestore Collections

These are created automatically when users sign up and use the app:

```
users/
employeeUsers/
employeeIndex/
usernameIndex/
businesses/
  └── employees/
  └── vehicles/
  └── timesheets/
  └── expenses/
  └── notifications/
  └── speedAlerts/
```
### Firestore Index

Add a composite index for speed alerts:

- Collection: `speedAlerts`
- Fields: `read` (Ascending), `timestamp` (Descending)

---

## Running the App

1. Connect a real iPhone (push notifications and GPS do not work on the simulator)
2. Select your device in Xcode's device picker
3. Press **Cmd + R** to build and run
4. Sign up as an **Admin** first to create a business
5. Share the access code with drivers so they can sign up as employees

---

## Features

- **Admin view** — live map of all clocked-in drivers with GPS pins, speed, and mileage
- **Employee view** — clock in/out, mileage tracking, break management, expense submission
- **Fleet management** — add and manage vehicles with photos
- **Speed monitoring** — automatic alerts when drivers exceed speed limits
- **Notifications** — clock-in/out events logged and visible to admin
- **Expense reports** — employees can submit receipts with photos
- **Subscription management** — Pro/Enterprise tier plans

---

## Tech Stack
- Swift / SwiftUI
- Firebase Auth, Firestore, Storage
- Google Maps SDK for iOS
- Google Roads API (speed limits)
- CoreLocation

---

## Troubleshooting

**Drivers not showing on admin map** — make sure the employee has location permission set to "Always" in iOS Settings → Fleet Tracker → Location.

**App crashes when adding a vehicle** — confirm `NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription` are in `Info.plist`.

**Mileage not updating** — GPS must be active. Test on a real device while moving.

**Push notifications not working** — requires APNs key uploaded to Firebase Console → Project Settings → Cloud Messaging.
