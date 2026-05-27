# email_auth - API test link

Base URL: `http://127.0.0.1:9600`

| # | Interface | Status | Result | Doc |
|---|-----------|--------|--------|-----|
| 1 | `POST /auth/email/code` | `200` | PASS | [01_send_email_code.md](01_send_email_code.md) |
| 2 | `POST /auth/email/code` | `429` | PASS | [02_rate_limit.md](02_rate_limit.md) |
| 3 | `POST /auth/email/code` | `400` | PASS | [03_invalid_email.md](03_invalid_email.md) |
| 4 | `POST /auth/login` | `200` | PASS | [04_email_login.md](04_email_login.md) |
| 5 | `POST /auth/login` | `401` | PASS | [05_wrong_credential.md](05_wrong_credential.md) |