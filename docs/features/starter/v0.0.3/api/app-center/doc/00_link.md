# app-center - API test link

Base URL: `http://127.0.0.1:9600`

| # | Interface | Status | Result | Doc |
|---|-----------|--------|--------|-----|
| 1 | `GET /api/app/list` | `200` | PASS | [01_list_apps.md](01_list_apps.md) |
| 2 | `POST /api/app` | `201` | PASS | [02_create_app.md](02_create_app.md) |
| 3 | `POST /api/app` | `400` | PASS | [03_create_app_duplicate.md](03_create_app_duplicate.md) |
| 4 | `GET /api/app/list` | `200` | PASS | [04_list_apps_after_create.md](04_list_apps_after_create.md) |
| 5 | `POST /api/app/version` | `201` | PASS | [05_create_version.md](05_create_version.md) |
| 6 | `GET /api/app/versions?app_id=test_app` | `200` | PASS | [06_list_versions.md](06_list_versions.md) |
| 7 | `GET /api/app/version?app_id=test_app&platform=windows` | `200` | PASS | [07_get_version.md](07_get_version.md) |
| 8 | `GET /api/app/version?app_id=test_app&platform=ios` | `404` | PASS | [08_get_version_not_found.md](08_get_version_not_found.md) |
| 9 | `PUT /api/app/version?app_id=test_app&platform=windows&version=0.1.0` | `200` | PASS | [09_update_version.md](09_update_version.md) |
| 10 | `GET /api/app/version?app_id=test_app&platform=windows` | `200` | PASS | [10_verify_update.md](10_verify_update.md) |