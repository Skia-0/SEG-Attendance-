# SendGrid Domain Authentication Setup

## Purpose
Prevent SEG Attendance emails from going to spam.

## When To Do This
When you have access to SEG's DNS settings (IT admin needed).

## Steps

1. Log into SendGrid (sendgrid.com)
2. Settings → Sender Authentication → Authenticate Your Domain
3. Enter domain: `seghana.net` (or actual SEG domain)
4. SendGrid gives you 3 CNAME records like:
em1234.seghana.net → u1234.wl.sendgrid.net
s1._domainkey.seghana.net → s1.domainkey.u1234.wl.sendgrid.net
s2._domainkey.seghana.net → s2.domainkey.u1234.wl.sendgrid.net





5. Add these CNAME records to seghana.net DNS
6. Wait 15-60 minutes for DNS propagation
7. Click "Verify" in SendGrid
8. Once verified, update these env vars:
- SENDGRID_FROM_EMAIL=attendance@seghana.net
- ALLOWED_EMAIL_DOMAIN=seghana.net

## Result
- Emails come FROM @seghana.net (professional)
- DKIM + SPF aligned (passes spam filters)
- Delivery rate: ~99%

## Cost
Free (included in SendGrid plan)