# scan - API test link

Base URL: `http://127.0.0.1:9600`

| # | Interface | Status | Result | Doc |
|---|-----------|--------|--------|-----|
| 1 | `POST /auth/scan/create` | `200` | PASS | [01_scan_create.md](01_scan_create.md) |
| 2 | `GET /auth/scan/status?token=1a7d3f1e-2e4c-4ed6-b208-7977098d87e3` | `200` | PASS | [02_scan_status_pending.md](02_scan_status_pending.md) |
| 3 | `POST /auth/scan/confirm` | `200` | PASS | [03_scan_confirm_scan.md](03_scan_confirm_scan.md) |
| 4 | `GET /auth/scan/status?token=1a7d3f1e-2e4c-4ed6-b208-7977098d87e3` | `200` | PASS | [04_scan_status_scanned.md](04_scan_status_scanned.md) |
| 5 | `POST /auth/scan/confirm` | `200` | PASS | [05_scan_confirm_confirm.md](05_scan_confirm_confirm.md) |
| 6 | `GET /auth/scan/status?token=1a7d3f1e-2e4c-4ed6-b208-7977098d87e3` | `200` | PASS | [06_scan_status_confirmed.md](06_scan_status_confirmed.md) |
| 7 | `GET /auth/scan/status?token=invalid-token-xxx` | `404` | PASS | [07_scan_status_not_found.md](07_scan_status_not_found.md) |
| 8 | `POST /auth/scan/confirm` | `401` | PASS | [08_scan_confirm_unauthorized.md](08_scan_confirm_unauthorized.md) |
| 9 | `POST /auth/scan/cancel` | `200` | PASS | [09_scan_cancel.md](09_scan_cancel.md) |
| 10 | `GET /auth/scan/status?token=f753365e-1a82-44a5-a01c-e7537a512093` | `200` | PASS | [10_scan_status_cancelled.md](10_scan_status_cancelled.md) |