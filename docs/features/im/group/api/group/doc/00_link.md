# group v0.0.1 - API test link

Base URL: `http://127.0.0.1:9600`

| # | Interface | Status | Result | Doc |
|---|-----------|--------|--------|-----|
| 1 | `POST /groups` | `200` | PASS | [01_create_group.md](01_create_group.md) |
| 2 | `POST /groups` | `400` | PASS | [02_create_group_empty_name.md](02_create_group_empty_name.md) |
| 3 | `POST /groups` | `400` | PASS | [03_create_group_too_few.md](03_create_group_too_few.md) |
| 4 | `POST /conversations` | `200` | PASS | [04_create_private.md](04_create_private.md) |
| 5 | `GET /conversations` | `200` | PASS | [05_list_with_group.md](05_list_with_group.md) |
| 6 | `GET /conversations?type=1` | `200` | PASS | [06_list_type_filter.md](06_list_type_filter.md) |
| 7 | `GET /conversations?type=1` | `200` | PASS | [07_member_sees_group.md](07_member_sees_group.md) |