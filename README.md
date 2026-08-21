# 🏠 Smart Hostel Finder & Booking System

A full-featured Flutter mobile application for students to find, book, and review hostels near their universities. Built with **Firebase Firestore**, **Firebase Auth**, **GetX** state management, and **Google Maps**.

---

## 📁 Project Structure

```
lib/
├── main.dart                        ← App entry, routes, GetMaterialApp
├── bindings/
│   └── app_binding.dart             ← Registers all services & controllers
├── controllers/
│   ├── auth_controller.dart         ← Login, register, logout, role routing
│   ├── hostel_controller.dart       ← CRUD hostels, filters, image uploads
│   └── controllers.dart            ← Booking, Review, Complaint, Notification
├── models/
│   ├── user_model.dart              ← UserModel (student/owner/admin)
│   ├── hostel_model.dart            ← HostelModel with all listing details
│   └── models.dart                 ← Booking, Review, Complaint, Notification
├── routes/
│   └── app_routes.dart              ← All named route constants
├── services/
│   ├── auth_service.dart            ← Firebase Auth + Firestore user ops
│   ├── hostel_service.dart          ← Firestore hostel CRUD
│   ├── storage_service.dart         ← Firebase Storage image uploads
│   └── services.dart               ← Booking, Review, Complaint, Notification
├── utils/
│   └── app_constants.dart           ← Colors, theme, constants
└── views/
    ├── auth/
    │   ├── login_screen.dart
    │   └── register_screen.dart
    ├── student/
    │   ├── student_home_screen.dart  ← Browse + city filter + map chips
    │   ├── hostel_detail_screen.dart ← Photos, map, facilities, reviews
    │   ├── booking_screens.dart      ← Book hostel + my bookings history
    │   └── review_complaint_screens.dart ← Write review + complaints
    ├── owner/
    │   ├── owner_home_screen.dart    ← Dashboard with listing stats
    │   ├── add_hostel_screen.dart    ← Create/Edit listing with map + images
    │   └── owner_management_screens.dart ← Manage bookings + complaints
    ├── admin/
    │   └── admin_home_screen.dart    ← Approve hostels, users, reviews
    └── shared/
        ├── shared.dart              ← CustomButton, TextField, StatusChip, HostelCard
        └── profile_notifications.dart ← Profile edit + notifications list
```

---

## 🔧 Key Technologies

| Technology | Purpose |
|---|---|
| **Flutter 3.x** | Cross-platform mobile UI |
| **Firebase Auth** | Email/password authentication |
| **Cloud Firestore** | Real-time NoSQL database |
| **Firebase Storage** | Image uploads (hostel photos, avatars) |
| **GetX** | State management, routing, DI |
| **Google Maps Flutter** | Hostel location display + navigation |
| **Geolocator** | Device GPS for location picker |
| **Image Picker** | Select photos from gallery/camera |
| **Flutter Rating Bar** | Star rating widget |
| **Intl** | Date formatting |

---

## ✅ Functional Requirements Coverage

| FR | Description | Status |
|---|---|---|
| FR-1.1 | Student registration via email/password | ✅ |
| FR-1.2 | Hostel owner registration | ✅ |
| FR-1.3 | Secure login for all roles | ✅ |
| FR-1.4 | Password reset via email | ✅ |
| FR-1.5 | Role-based access (Student/Owner/Admin) | ✅ |
| FR-2.1 | View & update profile | ✅ |
| FR-2.2 | Owner updates hostel details | ✅ |
| FR-2.3 | Secure data storage | ✅ |
| FR-3.1 | Owner adds hostel listing | ✅ |
| FR-3.2 | Owner uploads hostel images | ✅ |
| FR-3.3 | Rent, room type, gender, facilities, availability | ✅ |
| FR-3.4 | Edit or delete listings | ✅ |
| FR-3.5 | Admin approval before public visibility | ✅ |
| FR-4.1 | Search by city | ✅ |
| FR-4.2 | Filter by price, gender, facilities | ✅ |
| FR-4.3 | Hostel details with images, ratings, availability | ✅ |
| FR-4.4 | Google Maps integration | ✅ |
| FR-5.1 | Student submits booking request | ✅ |
| FR-5.2 | Owner accepts/rejects booking | ✅ |
| FR-5.3 | Room availability updated after booking | ✅ |
| FR-5.4 | Student cancels booking | ✅ |
| FR-5.5 | Booking history for both roles | ✅ |
| FR-6.1 | Student submits rating + review | ✅ |
| FR-6.2 | Average rating displayed on hostel | ✅ |
| FR-6.3 | AI-based fake review detection (heuristic) | ✅ |
| FR-6.4 | Admin removes flagged reviews | ✅ |
| FR-7.1 | Student submits complaint | ✅ |
| FR-7.2 | Owner responds to complaint | ✅ |
| FR-7.3 | Complaint status tracking | ✅ |
| FR-7.4 | Complaint history logged | ✅ |
| FR-8.1 | Admin verifies hostel listings | ✅ |
| FR-8.2 | Admin suspends/activates accounts | ✅ |
| FR-8.3 | Admin monitors system activity | ✅ |
| FR-8.4 | Admin manages flagged reviews & complaints | ✅ |
| FR-9.1 | Notify student of booking decision | ✅ |
| FR-9.2 | Notify owner of new booking request | ✅ |
| FR-9.3 | Notify users of complaint updates | ✅ |
| FR-10.1 | Secure centralized Firestore database | ✅ |
| FR-10.2 | Firestore transactions for booking integrity | ✅ |
| FR-10.3 | Firestore timestamps on all critical actions | ✅ |

---

## 🏗️ Firestore Data Structure

```
/users/{uid}
  name, email, role, phone, profileImage, university, isActive, createdAt

/hostels/{hostelId}
  ownerId, ownerName, name, description, city, address, lat, lng,
  rentPerMonth, roomType, genderPreference, facilities[], images[],
  isAvailable, status, averageRating, totalReviews, totalRooms,
  availableRooms, createdAt, updatedAt

/bookings/{bookingId}
  studentId, studentName, hostelId, hostelName, ownerId,
  checkInDate, checkOutDate, totalAmount, status, ownerNote, createdAt

/reviews/{reviewId}
  hostelId, studentId, studentName, rating, comment,
  isFlagged, flagReason, createdAt

/complaints/{complaintId}
  studentId, hostelId, ownerId, title, description,
  status, ownerResponse, createdAt, updatedAt

/notifications/{notifId}
  userId, title, body, type, relatedId, isRead, createdAt
```

---

## 🚀 Getting Started

```bash
# 1. Clone / download project
cd smart_hostel_finder

# 2. Install dependencies
flutter pub get

# 3. Configure Firebase (see FIREBASE_SETUP.dart for detailed steps)
#    - Add google-services.json to android/app/
#    - Add GoogleService-Info.plist to ios/Runner/

# 4. Add your Google Maps API key to AndroidManifest.xml

# 5. Run the app
flutter run

# Build for release
flutter build apk --release
```

---

## 👤 Test Accounts (create manually in Firebase Auth + Firestore)

To quickly test all roles, create these accounts:
- **Admin**: admin@hostel.com / password123 → role: "admin"
- **Owner**: owner@hostel.com / password123 → role: "owner"
- **Student**: student@hostel.com / password123 → role: "student"

---

## 📝 Developer Notes

- All controllers are **GetX reactive** – use `Obx()` to rebuild UI on state changes
- Services are **permanent singletons** – they live for the entire app session
- Controllers use **lazyPut** – created only when their screen is first accessed
- Firestore queries use **real-time streams** – no manual refresh needed
- The fake review detector in `ReviewController._detectFakeReview()` uses simple heuristics.  Replace with a **TensorFlow Lite** or **Scikit-learn** model via a REST API for production.

