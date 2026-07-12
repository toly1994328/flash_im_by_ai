# conversation - API test link (v0.0.5)

Base URL: `http://127.0.0.1:9600`

| # | Interface | Status | Result | Doc |
|---|-----------|--------|--------|-----|
| 1 | `GET /conversations` | `200` | PASS | [01_list_conversations.md](01_list_conversations.md) |
| 2 | `POST /conversations/eb8cf7ec-44d8-4c38-a190-72bf3c878d81/pin` | `200` | PASS | [02_toggle_pin_on.md](02_toggle_pin_on.md) |
| 3 | `POST /conversations/eb8cf7ec-44d8-4c38-a190-72bf3c878d81/pin` | `200` | PASS | [03_toggle_pin_off.md](03_toggle_pin_off.md) |
| 4 | `POST /conversations/eb8cf7ec-44d8-4c38-a190-72bf3c878d81/mute` | `200` | PASS | [04_toggle_mute_on.md](04_toggle_mute_on.md) |
| 5 | `POST /conversations/eb8cf7ec-44d8-4c38-a190-72bf3c878d81/mute` | `200` | PASS | [05_toggle_mute_off.md](05_toggle_mute_off.md) |
| 6 | `POST /conversations/eb8cf7ec-44d8-4c38-a190-72bf3c878d81/unread` | `200` | PASS | [06_mark_unread.md](06_mark_unread.md) |
| 7 | `POST /conversations/eb8cf7ec-44d8-4c38-a190-72bf3c878d81/read` | `200` | PASS | [07_mark_read.md](07_mark_read.md) |
| 8 | `POST /conversations/not-a-uuid/pin` | `400` | PASS | [08_invalid_uuid.md](08_invalid_uuid.md) |
| 9 | `POST /conversations/eb8cf7ec-44d8-4c38-a190-72bf3c878d81/pin` | `403` | PASS | [09_non_member.md](09_non_member.md) |
| 10 | `POST /conversations/d2fbe818-d19b-4069-9b12-9e2410d5f35d/pin` | `404` | PASS | [10_not_found.md](10_not_found.md) |
| 11 | `POST /conversations/eb8cf7ec-44d8-4c38-a190-72bf3c878d81/pin` | `401` | PASS | [11_unauthorized.md](11_unauthorized.md) |