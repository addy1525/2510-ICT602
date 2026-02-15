# ICT602 Carry Mark System

A Flutter mobile application for managing student carry marks with multi-level authentication.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)

## 📱 Features

### Multi-Level Authentication
- **Administrator** - Access to web management portal
- **Lecturer** - Enter and manage student marks
- **Student** - View carry marks and calculate target scores

### Mark Components
| Component | Weightage |
|-----------|-----------|
| Test | 20% |
| Assignment | 10% |
| Project | 20% |
| **Total Carry Mark** | **50%** |
| Final Exam | 50% |

### Target Grade Calculator
Students can calculate required final exam marks to achieve target grades (A+ to C).

## 🛠️ Tech Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Firebase Firestore
- **Authentication**: Custom email/password via Firestore

## 📁 Project Structure

```
lib/
├── main.dart                    # App entry point
├── theme/
│   └── app_theme.dart          # Centralized theme
├── models/
│   └── user_model.dart         # User data model
├── services/
│   └── database_service.dart   # Firestore operations
└── screens/
    ├── login_page.dart          # Login screen
    ├── admin_dashboard.dart     # Admin dashboard
    ├── lecturer_dashboard.dart  # Lecturer view
    ├── student_dashboard.dart   # Student view
    ├── edit_marks_page.dart     # Mark entry form
    └── target_score_page.dart   # Grade calculator
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (^3.10.1)
- Android Studio / VS Code
- Firebase account

### Installation

1. Clone the repository
```bash
git clone <your-repo-url>
cd ict602_lab_assignment
```

2. Install dependencies
```bash
flutter pub get
```

3. Configure Firebase
- Create project at [Firebase Console](https://console.firebase.google.com)
- Add Android app with package name `com.example.ict602_lab_assignment`
- Download `google-services.json` to `android/app/`
- Enable Firestore Database

4. Run the app
```bash
flutter run
```

## 👥 Demo Accounts

| Role | Email | Password |
|------|-------|----------|
| Admin | admin@ict602.com | admin123 |
| Lecturer | lecturer@ict602.com | lecturer123 |
| Student | student@ict602.com | student123 |

