# user_profile - API test link

Base URL: `http://127.0.0.1:9600`

| # | Interface | Status | Result | Doc |
|---|-----------|--------|--------|-----|
| 1 | `GET /user/profile` | `200` | PASS | [01_get_profile.md](01_get_profile.md) |
| 2 | `PUT /user/profile` | `200` | PASS | [02_update_profile.md](02_update_profile.md) |
| 3 | `PUT /user/profile` | `200` | PASS | [03_change_avatar.md](03_change_avatar.md) |
| 4 | `POST /user/password` | `200` | PASS | [04_set_password.md](04_set_password.md) |
| 5 | `POST /user/password` | `409` | PASS | [05_set_password_conflict.md](05_set_password_conflict.md) |
| 6 | `PUT /user/password` | `200` | PASS | [06_change_password.md](06_change_password.md) |
| 7 | `PUT /user/password` | `401` | PASS | [07_change_password_wrong.md](07_change_password_wrong.md) |
| 8 | `POST /auth/login` | `200` | PASS | [08_login_password.md](08_login_password.md) |