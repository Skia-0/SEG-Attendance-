# SEG Hub Attendance Verification System — v2.0

An enterprise-grade, dual-credential biometric and NFC attendance tracking and verification system designed for **Social Enterprise Ghana (SEG)**. This system enables coordinators to seamlessly track learner attendance across multiple hubs and cohorts using secure Android devices, while offering management a real-time web dashboard.

---

## 📱 System Architecture

```text
                                 ┌─────────────────────────────────┐
                                 │       Web Admin Dashboard       │
                                 │     (Flask + Jinja2 + HTML)     │
                                 └────────────────┬────────────────┘
                                                  │ (Reads Live Status)
                                                  ▼
┌───────────────────────┐        ┌─────────────────────────────────┐
│                       │  Post  │                                 │
│   Flutter Mobile App  ├───────►│       Python Flask Backend      │
│ (NFC & Fingerprints)  │  JWT   │   (SQLAlchemy + Flask-Migrate)  │
│                       │        │                                 │
└───────────────────────┘        └────────────────┬────────────────┘
                                                  │
                                                  ▼
                                 ┌─────────────────────────────────┐
                                 │    Serverless PostgreSQL (Neon)  │
                                 └─────────────────────────────────┘
```

---

## 🛠️ Tech Stack
- **Backend**: Python 3.11, Flask 3.0.3, PostgreSQL (Neon serverless), SQLAlchemy, Flask-Migrate, JWT-Extended, PBKDF2.
- **Mobile Application**: Flutter (Dart), `nfc_manager` (NFC UID scanning), `local_auth` (on-device fingerprint validation), `dio` (networking), `provider` (state management).
- **Web Dashboard**: Plain HTML/CSS/JS (Tailwind CDN) served directly from Flask.

---

## 🔑 Environment Variables Reference

### Backend (`.env` local, Render environment variables in production)
```env
DATABASE_URL=postgresql://<username>:<password>@<host>/<dbname>
SECRET_KEY=a_highly_secure_random_string_for_sessions
JWT_SECRET_KEY=a_highly_secure_random_string_for_jwts
```

### Mobile App (`lib/config/api_config.dart`)
```dart
class ApiConfig {
  static const String baseUrl = "https://your-render-app.onrender.com/api";
}
```

---

## 🚀 Backend Setup Instructions

### 1. Local Setup
1. Clone the repository and navigate to the backend directory:
   ```bash
   cd seg-attendance-api
   ```
2. Create and activate a Python virtual environment:
   ```bash
   python -m venv .venv
   source .venv/bin/activate  # On Windows: .venv\Scripts\activate
   ```
3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
4. Configure your `.env` file based on `.env.example`:
   ```bash
   cp .env.example .env
   ```
5. Apply database migrations:
   ```bash
   flask db init
   flask db migrate -m "Initial migration"
   flask db upgrade
   ```
6. Run the local development server:
   ```bash
   python run.py
   ```

### 2. Seeding Testing Data
To insert the default Hub, Cohort, and Coordinator into the database, run:
```bash
python seed.py
```
This will output the newly created UUIDs and credentials to the console for testing.

### 3. Deploying to Render
This repository includes a `render.yaml` specification for zero-configuration deployments on **Render**:
1. Connect your GitHub repository to Render.
2. Render will automatically detect `render.yaml` and create a **Web Service**.
3. Add the following environment variables in the Render dashboard:
   - `DATABASE_URL` (your Neon connection string)
   - `SECRET_KEY`
   - `JWT_SECRET_KEY`
4. Deploy! Render will run `flask db upgrade` as the build step and start the service with Gunicorn.

---

## 📱 Flutter Mobile App Setup

### 1. Prerequisites
- Flutter SDK `^3.0.0`
- Android Studio / VS Code with Dart & Flutter extensions
- A physical Android device with NFC capabilities (emulators do not support NFC or physical biometrics)

### 2. Building the App
1. Navigate to the mobile directory:
   ```bash
   cd seg-attendance-mobile
   ```
2. Fetch dependencies:
   ```bash
   flutter pub get
   ```
3. Update `lib/config/api_config.dart` with your production backend URL.
4. Connect your Android device and run:
   ```bash
   flutter run --release
   ```

### 3. Permissions Configured
The Android app includes permissions in `AndroidManifest.xml` for NFC and biometrics:
```xml
<uses-permission android:name="android.permission.NFC" />
<uses-permission android:name="android.permission.USE_FINGERPRINT" />
<uses-permission android:name="android.permission.USE_BIOMETRIC" />
```

---

## 📇 NFC Card Lifecycle & Setup
1. **Unassigned State**: New tags or tags with `is_active=False` exist in the pool.
2. **Assignment**: In the app, click **Register Learner**, fill in details, scan the card on the physical device. The app reads the card's hardware UID, posts it to `POST /api/nfc-cards/assign`, which saves the card, binds it to the learner's record, and activates it.
3. **Take Attendance**: When check-in/out is active, learners tap their card on the coordinator's device. The device fetches the learner matching the UID via `GET /api/learners/nfc/<uid>` and records the timestamp.
4. **Cohort Completion**: At the end of a training cohort, calling `POST /api/nfc-cards/clear/<cohort_id>` deactivates all cards in the cohort and unbinds them from learners, returning the cards to the pool for reuse.

---

## 🔒 Known Limitations (Biometrics)
- **On-Device Biometrics (Secure Enclave)**: The fingerprint scanner uses the device's native hardware security enclave (via Android BiometricPrompt). Because fingerprint data never leaves the device's hardware, **enrolling a fingerprint binds that learner's verification capability to that specific device**.
- **Alternative Verification**: In multi-device setups or if a learner moves devices, coordinators can re-enroll biometrics on the new device, or use their assigned **NFC card** as a portable credential.

---

## 🔌 API Endpoint Reference

### Auth
- `POST /api/auth/login` - Authenticate coordinator with phone/password.

### Hubs
- `GET /api/hubs/<hub_id>` - Fetch hub details.

### Cohorts
- `GET /api/cohorts/<cohort_id>` - Fetch cohort information.
- `GET /api/cohorts/<cohort_id>/summary` - Cohort summary ledger with certification status.

### Learners
- `POST /api/learners` - Register a new learner. Automatically generates a unique, sequential `seg_id` (e.g. `SEG-POU-0001`).
- `GET /api/learners?cohort_id=<id>` - Get learners inside a cohort.
- `GET /api/learners/nfc/<uid>` - Lookup a learner by NFC card UID.
- `PATCH /api/learners/<learner_id>/fingerprint` - Update fingerprint enrollment status.

### NFC Cards
- `POST /api/nfc-cards/assign` - Create/update NFC card and link to learner.
- `POST /api/nfc-cards/clear/<cohort_id>` - Deactivate and unbind all cards in a cohort.

### Sessions
- `POST /api/sessions` - Start a new attendance session.
- `GET /api/sessions/<session_id>` - Fetch session details.
- `PATCH /api/sessions/<session_id>/checkin` - Open/Close Check-in state.
- `PATCH /api/sessions/<session_id>/checkout` - Open/Close Check-out state.
- `PATCH /api/sessions/<session_id>/end` - Close session permanently.

### Attendance
- `POST /api/attendance/checkin` - Record check-in timestamp.
- `POST /api/attendance/checkout` - Record check-out timestamp (sets `is_complete = True`).
- `GET /api/attendance/<session_id>` - Fetch live attendance list for a session.
