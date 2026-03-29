# conversation - API test link

Base URL: `http://127.0.0.1:9600`

| # | Interface | Status | Result | Doc |
|---|-----------|--------|--------|-----|
| 1 | `POST /conversations` | `200` | PASS | [01_create_private.md](01_create_private.md) |
| 2 | `POST /conversations` | `200` | PASS | [02_create_idempotent.md](02_create_idempotent.md) |
| 3 | `POST /conversations` | `404` | PASS | [03_create_peer_not_found.md](03_create_peer_not_found.md) |
| 4 | `GET /conversations` | `200` | PASS | [04_list.md](04_list.md) |
| 5 | `GET /conversations?limit=1&offset=0` | `200` | PASS | [05_list_paginated.md](05_list_paginated.md) |
| 6 | `GET /conversations?limit=20&offset=100` | `200` | PASS | [06_list_empty.md](06_list_empty.md) |
| 7 | `DELETE /conversations/d1752cc9-8a9c-428c-b97b-f030655c7afb` | `200` | PASS | [07_delete.md](07_delete.md) |
| 8 | `GET /conversations` | `200` | PASS | [08_list_after_delete.md](08_list_after_delete.md) |
| 9 | `GET /conversations` | `200` | PASS | [09_other_user_sees.md](09_other_user_sees.md) |