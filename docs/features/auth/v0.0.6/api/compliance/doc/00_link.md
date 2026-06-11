# compliance - API test link

Base URL: `http://127.0.0.1:9600`

| # | Interface | Status | Result | Doc |
|---|-----------|--------|--------|-----|
| 1 | `POST /api/reports` | `201` | PASS | [01_report_message.md](01_report_message.md) |
| 2 | `POST /api/reports` | `201` | PASS | [02_report_user.md](02_report_user.md) |
| 3 | `POST /api/reports` | `400` | PASS | [03_report_invalid.md](03_report_invalid.md) |
| 4 | `POST /api/blocks` | `201` | PASS | [04_block_user.md](04_block_user.md) |
| 5 | `POST /api/blocks` | `400` | PASS | [05_block_self.md](05_block_self.md) |
| 6 | `GET /api/blocks/check?user_id=3` | `200` | PASS | [06_check_block.md](06_check_block.md) |
| 7 | `GET /api/blocks` | `200` | PASS | [07_block_list.md](07_block_list.md) |
| 8 | `DELETE /api/blocks/3` | `200` | PASS | [08_unblock.md](08_unblock.md) |
| 9 | `GET /api/blocks/check?user_id=3` | `200` | PASS | [09_verify_unblocked.md](09_verify_unblocked.md) |
| 10 | `POST /user/password` | `200` | PASS | [10_set_password.md](10_set_password.md) |
| 11 | `POST /api/account/delete` | `401` | PASS | [11_delete_wrong_pwd.md](11_delete_wrong_pwd.md) |
| 12 | `POST /api/account/delete` | `200` | PASS | [12_delete_account.md](12_delete_account.md) |
| 13 | `GET /user/profile` | `404` | PASS | [13_login_after_delete.md](13_login_after_delete.md) |