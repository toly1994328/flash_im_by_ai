# subscription - API test link

Base URL: `http://127.0.0.1:9600`

| # | Interface | Status | Result | Doc |
|---|-----------|--------|--------|-----|
| 1 | `GET /api/subscriptions/status` | `200` | PASS | [01_status_no_sub.md](01_status_no_sub.md) |
| 2 | `POST /api/storage/upload-token` | `403` | PASS | [02_upload_token_no_sub.md](02_upload_token_no_sub.md) |
| 3 | `POST /api/subscriptions/redeem` | `400` | PASS | [03_redeem_invalid.md](03_redeem_invalid.md) |
| 4 | `POST /api/subscriptions/redeem` | `200` | PASS | [04_redeem_success.md](04_redeem_success.md) |
| 5 | `GET /api/subscriptions/status` | `200` | PASS | [05_status_with_sub.md](05_status_with_sub.md) |
| 6 | `POST /api/storage/upload-token` | `200` | PASS | [06_upload_token_success.md](06_upload_token_success.md) |