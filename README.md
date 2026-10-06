PennyPal

Smart budgeting made for students.

Let us face it, most finance apps are way too complicated. PennyPal is different. Built using Flutter, it is designed specifically for students who want to know where their money actually goes without needing a degree in finance.

With PennyPal, you can log your cash flow, set a realistic monthly budget, keep an eye on your remaining balance, and save up for things you actually care about, like a new laptop or a weekend trip.

We also included an AI advisor that does not just give generic advice. It uses your actual transaction history to answer your financial questions. Plus, there is a full Admin Panel where administrators can manage users, publish helpful financial lessons, and handle support tickets.

Under the hood, it is built with Flutter for Android, iOS, and Web, with Firebase handling the backend.

git hub "https://github.com/hashir-build/pennypal.git"
user credential 
(email : sooraj@gmail.com  password: 123456789)
Table of contents

* The Core Idea
* Feature Breakdown
* For Students
* For Administrators


* The Tech Stack
* How the Code is Organized
* Data Model
* Keeping Data Safe
* Setting it Up Locally
* Environment Config
* How to Run It
* Testing
* Behind the Scenes: Technical Decisions
* Stuff We Know is Broken
* Meet the Team


The Core Idea

We noticed that most budgeting tools assume you already know what you are doing. PennyPal targets students, so we kept the interface simple. You get a clear screen showing your balance, a simple button to add a transaction, and warnings that pop up before you overspend, not after the damage is done.

We intentionally made the main user flow short. A student opens the app, instantly sees what is left to spend this month, taps Add Transaction, quickly fills in the details, and they are done. Everything else in the app, like the visual budget ring, category charts, and goal tracking, updates automatically based on that single entry.

Also, to make sure new users do not get lost, the first launch includes a quick walkthrough that explains exactly what each part of the dashboard does.


Feature Breakdown

For students

The Dashboard
This is your financial hub. It shows your available cash, a quick look at this month's spending versus income, progress on your savings goals, a pie chart of where your money is going, a visual budget ring, and your last five transactions. The top bar holds your notifications, platform stats, and a button to access your profile.

Managing Transactions
A complete list of every entry you have made, grouped neatly by date. We built in filters so you can view just expenses, just income, or sort by time periods like this week, this month, or a custom range. There is also a search bar that looks at titles and categories. As you filter, a results bar shows you the count and the net total of what is on screen. Need to change something? Tap to edit. Made a mistake? Swipe left to delete.

Receipt Photos
Don't want to lose track of paper receipts? You can attach a photo of the receipt to any expense, either straight from the camera or your gallery. To save on database costs, the app automatically resizes the image to 1000px and compresses it into base64 JPEG format, storing it directly inside the transaction document. Tapping the thumbnail opens a full-screen viewer with pinch-to-zoom support.

Budgeting and Limits
You can set a hard monthly spending limit, and optionally, caps on specific categories. The app warns you when you hit 80% of your limit and again at 100%. Once you hit a category cap, the app actually blocks you from adding more expenses to that category until you raise the limit. We enforce this check in the logic controller, not just visual sugar in the UI. New accounts start with no budget, so we don't annoy you with over budget warnings until you have actually set your numbers.

Savings Goals
Dreaming of a trip? Create a goal for it. Give it a title, a target amount, an emoji, and an optional deadline. If you set a monthly contribution, the app estimates when you will hit your target. You can add milestones to break down big goals, check them off, or rearrange them. If you finish a goal or decide you don't want it anymore, you can archive it so you don't lose that savings history.

Your AI Advisor
Type or use your voice to ask financial questions. The cool thing is that the advisor understands your specific situation. It looks at your spending, income, budget, and goal progress to give tailored answers. But it is smart; if you just say hello, it responds locally without pinging the API. It won't give you a lecture unless your question implies you need one. Replies stream in real-time, render with nice markdown tables and lists, and we even hide the model's complex reasoning process in a collapsible block so it doesn't clutter the chat. The whole conversation is saved, so it is there when you come back.

Notifications
The notification bell in the app bar keeps a history of alerts, with unread counts and standard mark all read or swipe-to-delete functionality. These are stored in Firestore, so they sync across all your devices.

For immediate alerts like breaking your budget, we send real system notifications to your phone using flutter_local_notifications. We set up three separate channels for budget, goals, and general so you can silence goal updates but keep budget warnings active. Simple confirmations, like expense added, just stay inside the app as fleeting snackbars without blowing up your lock screen.

Profile and Settings
Here you can update your name, phone number, currency preference, UI theme, and notification settings. The phone field locks in the country code you used at signup and only accepts digits.

Feedback and Support
We want to hear from users. You can submit star-rated feedback or use the support form to message admins about account issues, bugs, or feature requests. When an admin replies, you see their message right there in the support thread inline.

Privacy Policy
We don't hide this on a website. A full privacy policy is built right into the app, accessible from the About screen, login, and registration. It clearly states what data we collect and what we don't, who sees it, where it is stored, exactly what data is sent to Groq for the AI, and how to request account deletion.

Themes
Whether you like it bright or prefer a true-black dark mode for late-night budgeting, we have got you covered. Both themes use the same clean layout and our signature piggy bank branding.

The First-Run Experience
We don't just dump you into the app. First, there's a splash screen, followed by a six-slide walkthrough explaining what lives where. After you sign up, there's a one-time in-app guided tour that actually highlights the buttons on the dashboard. The app remembers you have seen these, so returning users aren't bothered again.

For administrators

Admins have their own special section, accessed via a shield icon in the top bar.

Real-time Analytics
A dashboard showing 14 key platform metrics: total users, admin count, new signups in the last week or month, transaction counts, total cash flow, budgets set, receipts uploaded, and more. You also get visual charts showing top spending categories, a 14-day daily bar chart, and a 30-day income versus expense line graph, alongside a recent activity feed. These stats are calculated by scanning the entire Firestore Transactions collection group to get accurate numbers for the whole platform.

User Management
Search through the user base, open any profile, change user roles like making another user an admin, or suspend and restore accounts. We also let admins change anything about a role or a suspension, but not roles of their own account.

Who Can Delete an Account
An admin cannot delete a student, and that is a deliberate decision rather than a missing feature. Firebase gives client apps no way to remove somebody else's sign-in. The SDKs expose no such API on purpose, because otherwise any signed-in user could delete any other account.

So an admin delete button could only ever clear Firestore. The transactions and goals would be gone, the email would still be registered, and the student would come back to an address that says it already exists. That is a worse experience than not offering the button at all, so we took it out.

A student can delete their own account, and that is the version that works properly. The profile screen has a Delete my account option that re-checks their password, removes the Firebase sign-in so the email is genuinely released, and then clears their data. The sign-in goes first on purpose, so a failure halfway leaves the data intact rather than orphaning it. After a delete the app returns to the sign-in screen rather than leaving an empty shell behind.

Account Suspension
We handle security early. If an account is suspended, the user is blocked before the app even checks their role, so a suspended admin cannot get in either. The blocked student sees a full-screen lock message showing the reason the admin provided, with a button to contact the admin to appeal, which lands right back in the admin's feedback inbox.

An admin cannot suspend, delete, or change the role of their own account. We blocked this in the UI and the service backend because locking yourself out of the admin panel is impossible to recover from inside the app.

Managing Learning Content
Admins can create, edit, and rearrange financial literacy lessons that students see in the Learning tab. If an admin deletes all articles, the app falls back to three built-in default lessons so the screen is never blank.


The Tech Stack

Here is what we used to build PennyPal:

Framework: Flutter 3.x (Dart SDK ^3.13.3)
Authentication: Firebase Auth (Email/Password)
Database: Cloud Firestore
AI Integration: Groq API running openai/gpt-oss-120b, streaming via SSE
Charting: fl_chart
Markdown Rendering: flutter_markdown_plus
Image Handling: image_picker and image (for resizing and compressing)
Data Export: excel, share_plus, path_provider
Voice Input: speech_to_text
Local Notifications: flutter_local_notifications
Local Storage: shared_preferences
Link Handling: url_launcher
Code Quality: flutter_lints 6.0

Currently, we are targeting Android, iOS, and Web. While the project can technically build for Windows and Linux desktops, the UI is really meant for mobile phones and web browsers.


How the Code is Organized

lib/
main.dart - App entry point, theme handling, notification setup
firebase_options.dart - Generated Firebase config

controllers/
finance_controller.dart - The brain: handles all money data, streams, budget checks, and goal math

models/
transaction_model.dart - Transaction data structure
saving_goal.dart - Goals and milestones structure
user_profile.dart - Basic user data
app_user.dart - How admins view other users
learning_article.dart - Structure for published lessons

screens/
splash_screen.dart - Branding screen on launch
onboarding_screen.dart - Walkthrough slides
auth_gate.dart - Routes users: handles login vs dashboard vs suspension
dashboard_screen.dart - Main app shell with navigation
ai_chatbot_screen.dart - The streaming chat interface
admin/ - All admin-specific screens

services/
auth_service.dart
receipt_service.dart - Handles the camera, resizing, and encoding logic
groq_service.dart - The Groq API client with SSE parsing
local_notice_service.dart - Triggers Android system notifications
voice_service.dart - Handles voice-to-text with conditional stubs for web
app_tour.dart - Logic for the in-app guided tour

theme/
app_theme.dart - Definition of colors, dark mode, and spacing

utils/
chat_prompt.dart - System prompts for the AI and small-talk detection
env_config.dart - Reads secrets like the Groq key at runtime

widgets/
ui_kit.dart - Reusable generic UI components
guided_tour.dart - The overlay for the dashboard tour


Data Model (Firestore)

Here is how our Firestore documents look structure-wise:

Users/{uid}
FullName, Email, Phone, Role, IsSuspended, Currency, Theme, MonthlyBudget, CategoryLimits

Users/{uid}/Transactions/{id}
    Title, Amount, Category, Date, IsExpense, ReceiptData

Users/{uid}/SavingGoals/{id}
    Title, TargetAmount, SavedAmount, Emoji, Milestones, Archived

Users/{uid}/Profile/me
    NotificationPreference, ProfileImage

Users/{uid}/Notifications/{id}
    Title, Body, Kind, Read, CreatedAt

Users/{uid}/Chats/{chatId}/Messages/{id}


LearningArticles/{id} - Read-only for students, writable by admins
Feedbacks/{id} - Users create these, admins read and reply to them


Keeping Data Safe (Security Rules)

We use firestore.rules to make sure nobody accesses data they should not.

A regular logged-in user can only read and write documents inside their own user path. They cannot see other students' money data.
An Admin has overarching permissions and can read and write data for any user.
LearningArticles are public-read for any logged-in user, but only admins can modify them.
Feedbacks: Users can create support tickets as long as they stamp their own UserId. They can read their own messages, but admins can see all tickets and are the only ones allowed to post a reply.

Note: If you are deploying this, you must push these rules to Firebase for admin replies to work using the command firebase deploy --only firestore:rules.


Setting it Up Locally

Prerequisites

Flutter 3.x and Dart ^3.13.3 installed and configured.
A Firebase project created with Authentication (Email/Password) and Firestore turned on.
FlutterFire CLI installed if you haven't set up Firebase in Flutter before.

Step 1: Install dependencies

Run this in your terminal:
flutter pub get

Step 2: Configure Firebase

You need to link the app to your own Firebase project:
dart pub global activate flutterfire_cli
flutterfire configure

This will generate lib/firebase_options.dart. For Android, make sure to download your google-services.json and place it in android/app/.


Environment Config

The AI advisor won't work without a Groq API key. Get one from [console.groq.com/keys](https://www.google.com/search?q=https%3A%2F%2Fconsole.groq.com%2Fkeys).

1. Copy the example file:
copy .env.example .env
2. Open .env and paste your key:
GROQ_API_KEY=gsk_your_real_key_here
GROQ_MODEL=openai/gpt-oss-120b
3. Run this helper script once:
.\sync-env.ps1

Why the script? It takes your .env key and writes it into assets/env.txt and web/env.js. The app reads the key from these files at runtime. This means you don't need extra dart-define arguments when running flutter run or building an APK. If you change the key in .env, run the script again and fully restart the app.

Note: .env, assets/env.txt, and web/env.js are in .gitignore. Never commit real API keys to GitHub.


How to Run It

We made a PowerShell helper script run.ps1 that handles the sync logic automatically:

.\run.ps1             Runs on your currently connected device or emulator
.\run.ps1 chrome      Runs specifically in Chrome
.\run.ps1 web         Builds the project for web deployment
.\run.ps1 apk         Builds a release APK
.\run.ps1 test        Runs the full test suite

Alternatively, you can use standard Flutter commands:

flutter run
flutter build apk --release

A release APK will be generated at build/app/outputs/flutter-apk/app-release.apk (around 69 MB).

Note: The current release build configuration is signed with the debug keystore. You can sideload it onto a phone to test, but you cannot upload it to the Play Store until you configure a real release keystore in android/app/build.gradle.kts.


Testing

Run the tests using:
flutter test

We have 307 tests covering 31 files. They are all passing. Running flutter analyze also shows no issues.

These are not just basic smoke tests. We wrote them to prevent bugs we actually encountered during development:

We test responsiveness to ensure the text inside the budget ring fits inside the circle on small screens even when system fonts are scaled up.
We ensure UI elements don't drift or float awkwardly.
We make sure the guided tour works on tiny screens at 2x text scaling without causing overflows.
We test the phone number validation logic to ensure it accepts standard 11-digit numbers and short local numbers, blocking anything else.
We have a test that fails the build if your generated key file is empty, preventing you from shipping a broken build with a stale .env.


Technical Decisions

Here is the logic behind why we built things the way we did:

Why base64 images in Firestore?
Ideally, images go in Firebase Cloud Storage. However, Storage requires Firebase's paid Blaze plan. We are on the Free Spark plan. Our workaround was to compress images heavily and store them as base64 strings directly in the Firestore document, keeping them under the 1 MiB document limit.

No FCM for Push Notifications
Similar to Storage, Cloud Messaging works best on the Blaze plan. Instead, we generate notifications locally within the app logic, store them in a Firestore subcollection so they appear in the inbox, and trigger phone system tray alerts using flutter_local_notifications. We left the commented-out FCM code in push_service.dart as a reference.

Why there is no admin delete button
This one cost us a build to learn. We first tried a Cloud Function that would delete the Auth record for an admin, but the deploy failed: cloudbuild.googleapis.com cannot be enabled without Blaze, so the function is not available to us on the free plan. Our fallback was a button that cleared the data and then explained the leftover step.

We removed it in the end. A control that silently leaves a student with an unusable email is a worse problem than a missing one, so the button is gone and self-service deletion is the answer. If you later move to Blaze, the function approach works and the button would be worth restoring, but until then we would rather the app not pretend.

How the AI key works at runtime
Instead of compiling the key directly into the code, EnvConfig looks in multiple places at runtime: first a dart-define flag, then local assets. This is what lets flutter run work out of the box after syncing.

Single Source of Truth for Phone Rules
To prevent bugs where the UI allows a phone number but the backend rejects it, we defined the 7 to 15 digit phone rule in one file called PhoneRule. Both the signup form and AuthService read from this single file.

Dialog Overflows
We built a custom ConfirmDialog because standard AlertDialog components place content in a non-scrolling column. If a user has a very large system font enabled, the text can push buttons off screen. Our custom dialog ensures the body is scrollable while buttons stay pinned.

Conditional Imports
Plugins like speech_to_text don't have web implementations. To prevent compile errors, we use conditional imports to load a stub service on the web and the real recognizer on native mobile. We use this same pattern for the Excel export logic.


Stuff We Know is Broken

Offline Mode: You need an internet connection to save data. Firestore has built-in caching, but we haven't implemented a robust queue strategy for handling conflicts when a user goes offline and makes changes.
iOS Testing: While the code is platform-neutral and configured for iOS, we have only verified it on Android and Web. It has not been tested on a physical iPhone yet.
Security Rules Deployment: Until you actually run firebase deploy --only firestore:rules, the Admin panel cannot reply to support tickets.
API Key Security: The API key is in the app assets. While unavoidable for a pure client app, it means someone could extract the key from the APK. In a real production environment, the AI requests should go through a backend proxy to hide the key.

Meet the Team

PennyPal was developed by students at APTECH GARDEN, based on a strict Software Requirements Specification to ensure all intended features were met.

Muhammad Hashir Edhi - GitHub: [https://github.com/hashir-build](https://github.com/hashir-build?utm_source=gemini) | LinkedIn: [https://www.linkedin.com/in/muhammad-hashir-247850348/](https://www.linkedin.com/in/muhammad-hashir-247850348/?utm_source=gemini)
Abdul Kabeer - GitHub: [https://github.com/kabeerfaisal](https://github.com/kabeerfaisal?utm_source=gemini) | LinkedIn: [https://www.linkedin.com/in/kabeersaudagar/](https://www.linkedin.com/in/kabeersaudagar/?utm_source=gemini)
Muhammad Saad - GitHub: [https://github.com/MSaad2408b](https://github.com/MSaad2408b?utm_source=gemini) | LinkedIn: [https://www.linkedin.com/in/muhammad-saad-8a8249340/](https://www.linkedin.com/in/muhammad-saad-8a8249340/?utm_source=gemini)

---

Made with Flutter and Firebase.