# cloud - API test link

Base URL: `http://127.0.0.1:9600`

| # | Interface | Status | Result | Doc |
|---|-----------|--------|--------|-----|
| 1 | `GET /api/storage/files` | `200` | PASS | [01_list_all.md](01_list_all.md) |
| 2 | `GET /api/storage/files?category=image` | `200` | PASS | [02_list_by_category.md](02_list_by_category.md) |
| 3 | `GET /api/storage/files/13` | `200` | PASS | [03_file_detail.md](03_file_detail.md) |
| 4 | `GET /api/storage/files/99999` | `404` | PASS | [04_detail_not_found.md](04_detail_not_found.md) |
| 5 | `DELETE /api/storage/files/14` | `200` | PASS | [05_delete_file.md](05_delete_file.md) |
| 6 | `GET /api/storage/files?category=file` | `200` | PASS | [06_verify_deleted.md](06_verify_deleted.md) |
| 7 | `DELETE /api/storage/files/99999` | `404` | PASS | [07_delete_not_found.md](07_delete_not_found.md) |