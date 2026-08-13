# SEG Attendance — v1.2 Roadmap

## Deferred from v1.1 (Agreed to implement later)

### Security
- [ ] Refresh token revocation (token blocklist table)
- [ ] CSRF protection on admin portal session-based login
- [ ] Standardize all error messages (prevent info leakage)

### Features
- [ ] Privacy policy screen in mobile app
- [ ] Printed learner consent form template
- [ ] Coordinator quick-start guide (PDF)
- [ ] Photo capture during learner registration
- [ ] Soft delete for cohorts (flag instead of hard delete)

### Infrastructure
- [ ] Render keep-alive (cron-job.org ping every 10 min)
      OR upgrade to $7/month paid tier
- [ ] Custom domain (seg-attendance.org)
- [ ] SendGrid domain authentication (fix spam)

### Nice To Have
- [ ] Search bar in admin portal
- [ ] Keyboard shortcuts
- [ ] Data refresh button on each admin page
- [ ] Coordinator detail view in admin portal
- [ ] Admin can create new coordinators
- [ ] Admin can deactivate coordinators
- [ ] Admin can transfer coordinators between hubs
- [ ] Multi-language support (Twi, Ga, Ewe)
- [ ] iOS version of mobile app
- [ ] Facial recognition module
- [ ] External USB fingerprint scanner support
- [ ] Offline sync mode
- [ ] SMS OTP as alternative to email

## v2.0 Vision
- Admin approval workflow for reports
- Report versioning
- Analytics dashboards with charts
- Learner self-service portal
- Bulk learner import (CSV upload)
- Automated backup exports
- Multi-tenant SaaS architecture