# SEG Attendance — API Documentation

**Base URL:** `https://seg-attendance-backend.onrender.com/api`

## Authentication

All endpoints (except login/register) require JWT Bearer token.


### POST /auth/login
Login with email + password. Returns access + refresh tokens.

### POST /auth/register
Register new coordinator. Requires email verification.

### POST /auth/verify-email
Verify email with 6-digit OTP code.

### POST /auth/forgot-password
Request password reset OTP.

### POST /auth/reset-password
Reset password with OTP code.

### POST /auth/refresh
Exchange refresh token for new access token.

### POST /auth/logout
Revoke current access token.

### GET /auth/me
Get current coordinator profile.

### PATCH /auth/me
Update coordinator profile (name, phone).

### POST /auth/change-password
Change password (requires old password).

---

## Hubs
### POST /hubs — Create hub
### GET /hubs/<id> — Get hub details

## Cohorts
### POST /cohorts — Create cohort
### GET /cohorts — List coordinator's cohorts
### GET /cohorts/<id> — Get cohort details
### GET /cohorts/<id>/summary — Certification report
### GET /cohorts/<id>/at-risk — At-risk learners
### DELETE /cohorts/<id> — Soft-delete cohort

## Learners
### POST /learners — Register learner
### GET /learners?cohort_id=X — List learners
### GET /learners/<id> — Get learner
### PATCH /learners/<id> — Update learner
### DELETE /learners/<id> — Delete learner
### GET /learners/nfc/<uid> — Lookup by NFC
### PATCH /learners/<id>/fingerprint — Update fingerprint status

## NFC Cards
### POST /nfc-cards/assign — Assign card to learner
### POST /nfc-cards/clear/<cohort_id> — Clear cohort cards

## Sessions
### POST /sessions — Start session
### GET /sessions?cohort_id=X — List sessions
### GET /sessions/<id> — Get session
### PATCH /sessions/<id>/checkin — Open/close check-in
### PATCH /sessions/<id>/checkout — Open/close check-out
### PATCH /sessions/<id>/end — End session

## Attendance
### POST /attendance/checkin — Check in learner
### POST /attendance/checkout — Check out learner
### GET /attendance/<session_id> — Get attendance records

## Reports
### POST /reports/session/<id> — Submit session report
### POST /reports/cohort/<id>/final — Submit cohort final report
### GET /reports — List coordinator's reports
### GET /reports/<id> — Get report detail

## Admin API (requires admin JWT)
### POST /admin/login — Admin login
### GET /admin/overview — Dashboard stats
### GET /admin/hubs — List all hubs
### GET /admin/hubs/<id> — Hub detail
### GET /admin/coordinators — List coordinators
### GET /admin/coordinators/<id> — Coordinator detail
### POST /admin/coordinators — Create coordinator
### POST /admin/coordinators/<id>/unlock — Unlock account
### POST /admin/coordinators/<id>/reset-password — Send reset
### POST /admin/coordinators/<id>/deactivate — Deactivate
### POST /admin/coordinators/<id>/transfer — Transfer hub
### POST /admin/coordinators/<id>/role — Change role
### GET /admin/reports — All reports
### GET /admin/reports/<id> — Report detail
### GET /admin/reports/<id>/pdf — Download PDF
### GET /admin/reports/<id>/csv — Download CSV
### GET /admin/reports/<id>/json — Download JSON
### DELETE /admin/reports/<id>/delete — Delete/unlock report
### GET /admin/notifications — Get notifications
### POST /admin/notifications/<id>/read — Mark read
### POST /admin/notifications/read-all — Mark all read
### GET /admin/audit-log — System audit log
### GET /admin/search?q=X — Global search