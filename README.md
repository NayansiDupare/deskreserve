# 📚 DeskReserve – Study Seat Booking System
### Book. Study. Focus.

DeskReserve is a full-stack Study Seat Booking system built using Flutter (Frontend) and Node.js + Express (Backend).  
It is designed to manage study seat subscriptions, membership freeze logic, seat changes, and admin-level analytics.

---

## 🏗 Project Structure

deskreserve/
│
├── deskreserve-app/        → Flutter Mobile Application
├── deskreserve-backend/    → Node.js Backend API
└── README.md               → Project Documentation

---

## 📱 Frontend – Flutter App

Location:
deskreserve-app/

### Features

- Subscription flow (Quote → Lock → Create)
- Seat change with usage limits
- Membership freeze with tracking
- Admin dashboard
- Search & filter support
- Pull-to-refresh
- Analytics overview
- Clean UI structure

### Tech Stack

- Flutter
- Dart
- REST API Integration
- Material Design

### Run Flutter App

Clone repository:

git clone https://github.com/your-username/deskreserve.git

Go inside app folder:

cd deskreserve-app

Install dependencies:

flutter pub get

Run app:

flutter run

Build release APK:

flutter build apk --release

---

## ⚙️ Backend – Node.js API

Location:
deskreserve-backend/

### Features

- Subscription management
- Seat change validation
- Membership freeze logic
- Status tracking (Active / Frozen / Expired)
- Google Sheets API integration
- MVC architecture

### Tech Stack

- Node.js
- Express.js
- Google Sheets API
- REST APIs

### Run Backend

Go inside backend folder:

cd deskreserve-backend

Install dependencies:

npm install

Start server:

node server.js

---

## 🔐 Environment Variables (Backend)

Create a `.env` file inside `deskreserve-backend`:

PORT=10000  
GOOGLE_SHEET_ID=your_google_sheet_id  
GOOGLE_CLIENT_EMAIL=your_service_account_email  
GOOGLE_PRIVATE_KEY=your_private_key  

⚠️ Never upload `.env` or credentials.json to GitHub.

---

## 🌍 Deployment

Backend can be deployed on:
- Render
- Railway
- VPS

Frontend APK can be generated using:

flutter build apk --release

---

## 👩‍💻 Author

Nayansi Dupare

---

## 📄 License

This project is for educational and portfolio purposes.
