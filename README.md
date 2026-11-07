# Campus Fix

Campus Fix is a Flutter app for reporting problems around the ALU campus, such as broken facilities, water shortages, power outages, damaged furniture, sanitation issues and safety concerns. Students submit a report with a description, location and optional photo, then follow it from **Submitted → In Progress → Resolved**. Campus staff review the reports, update their status and leave notes for the student.
For the assignment demonstration, the app may be shown in Chrome using DevTools device mode configured to Pixel 9, as approved by the facilitator. Device mode simulates a mobile viewport in the browser; it is not an Android emulator or physical device.

**Built with:** Flutter · Provider · Firebase Authentication · Cloud Firestore · Cloudinary

**Demo video:** [add link]

## Features

- **ALU-only accounts.** Sign up with an `@alustudent.com`, `@alu.edu` or `@aluedu.com` email. Every account verifies its email before using the app.
- **Two roles.** Students submit and track reports. Staff (`@aluedu.com` accounts, or users promoted by an admin) can update statuses. The Firestore security rules enforce this, not just the interface.
- **Report an incident.** Choose a category, add a title, description and campus location, and optionally attach a photo. Photos are compressed on the device before upload.
- **Browse and filter.** See all reports live, switch to *My reports*, search by keyword, and filter by status or category.
- **Report details.** A status timeline, an activity history with staff notes, a full-screen photo, and the option to withdraw your own report before it is reviewed.
- **Staff tools.** A dashboard of reports awaiting review, and a panel for changing a report's status with a note.

## Project structure

```
lib/
  main.dart        App start-up, providers and the AuthGate
  models/          Incident, StatusChange, AppUser and enums
  providers/       AuthProvider and IncidentProvider (app state)
  services/        Firebase access, Cloudinary upload, photo compression
  screens/         Auth, home, reports, report form, details, profile
  widgets/         Reusable UI components
  utils/           Validators, filters, formatting
test/              Unit and widget tests
test_rules/        Firestore security rules tests
firestore.rules    Server-side access rules
```

## Getting started

You need Flutter 3.27 or newer, Chrome for the approved DevTools Pixel 9 device-mode demonstration, Node.js for the Firebase CLI, and Java for Firestore emulator tests. Android Studio with an emulator or physical Android device is also supported; iOS development requires macOS and Xcode. Chrome device mode is a browser simulation, not an Android emulator or physical device.

1. **Install dependencies**
   ```bash
   flutter pub get
   ```

2. **Set up Firebase**
   - Create a project in the [Firebase console](https://console.firebase.google.com).
   - Enable **Authentication → Email/Password**.
   - Create a **Firestore database** in production mode.
   - Connect the app:
     ```bash
     npm install -g firebase-tools
     firebase login
     dart pub global activate flutterfire_cli
     flutterfire configure
     ```

3. **Set up Cloudinary** (for photos)
   - Create a free account at [cloudinary.com](https://cloudinary.com).
   - Create an **unsigned** upload preset called `campus_fix`.
   - Add your cloud name and preset name to `lib/config/cloudinary_config.dart`.

4. **Deploy the security rules**
   ```bash
   firebase deploy --only firestore:rules
   ```

5. **Run the app**
   ```bash
   flutter devices
   flutter run -d <device-id>
   ```

## Data model

```
users/{uid}
  name, email, role (student | staff), department, createdAt

incidents/{incidentId}
  title, description, category, location,
  status (submitted | inProgress | resolved | rejected),
  reporterId, reporterName, imageUrl, imagePath, thumbnail,
  createdAt, updatedAt,
  history: [ { status, changedBy, changedByName, note, at } ]
```

Photos are stored in Cloudinary at `incident_images/{uid}/{incidentId}`, and their link is saved on the report as `imageUrl`.

## Why Cloudinary instead of Firebase Storage

Firebase Storage requires the paid Blaze plan, which needed a US$30 prepayment for this account. With my facilitator's approval, I used Cloudinary's free tier instead. Uploads use an unsigned preset, so no secret key is stored in the app. Because Cloudinary links are public, avoid uploading photos of people or personal information.

## Running the tests

```bash
flutter analyze
flutter test
```

To test the Firestore rules (requires Java):

```bash
cd test_rules && npm install && cd ..
npx --prefix test_rules firebase emulators:exec --only firestore --project demo-campus "npm --prefix test_rules test"
```

## Author

Andrew Thon Riem Alier, African Leadership University
