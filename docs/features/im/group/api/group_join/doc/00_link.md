# group_join v0.0.2 - API test link

Base URL: `http://127.0.0.1:9600`

| # | Interface | Status | Result | Doc |
|---|-----------|--------|--------|-----|
| 1 | `GET /groups/search?keyword=开放` | `200` | PASS | [01_search_by_name.md](01_search_by_name.md) |
| 2 | `GET /groups/search?keyword=10011` | `200` | PASS | [02_search_by_group_no.md](02_search_by_group_no.md) |
| 3 | `GET /groups/search?keyword=开` | `200` | PASS | [03_search_single_char.md](03_search_single_char.md) |
| 4 | `GET /groups/search?keyword=开放` | `200` | PASS | [04_search_is_member.md](04_search_is_member.md) |
| 5 | `POST /groups/5aaebb83-19e1-45e7-891c-3a2b2775a9ea/join` | `200` | PASS | [05_join_no_verify.md](05_join_no_verify.md) |
| 6 | `POST /groups/5aaebb83-19e1-45e7-891c-3a2b2775a9ea/join` | `400` | PASS | [06_join_already_member.md](06_join_already_member.md) |
| 7 | `POST /groups/1e011830-5353-48f7-ab89-a05c69faaaf5/join` | `200` | PASS | [07_join_with_verify.md](07_join_with_verify.md) |
| 8 | `POST /groups/1e011830-5353-48f7-ab89-a05c69faaaf5/join` | `400` | PASS | [08_join_duplicate_request.md](08_join_duplicate_request.md) |
| 9 | `GET /groups/search?keyword=验证` | `200` | PASS | [09_search_pending.md](09_search_pending.md) |
| 10 | `GET /groups/join-requests` | `200` | PASS | [10_list_join_requests.md](10_list_join_requests.md) |
| 11 | `POST /groups/1e011830-5353-48f7-ab89-a05c69faaaf5/join-requests/39f4f4a5-f6d6-40a8-998d-003a55094e0f/handle` | `403` | PASS | [11_handle_non_owner.md](11_handle_non_owner.md) |
| 12 | `POST /groups/1e011830-5353-48f7-ab89-a05c69faaaf5/join-requests/39f4f4a5-f6d6-40a8-998d-003a55094e0f/handle` | `200` | PASS | [12_handle_approve.md](12_handle_approve.md) |
| 13 | `POST /groups/1e011830-5353-48f7-ab89-a05c69faaaf5/join-requests/39f4f4a5-f6d6-40a8-998d-003a55094e0f/handle` | `400` | PASS | [13_handle_already_done.md](13_handle_already_done.md) |
| 14 | `GET /groups/search?keyword=验证` | `200` | PASS | [14_verify_approved_member.md](14_verify_approved_member.md) |
| 15 | `POST /groups/1e011830-5353-48f7-ab89-a05c69faaaf5/join-requests/0c5353ef-f40c-49ba-a5fc-e63dd29e6a66/handle` | `200` | PASS | [15_handle_reject.md](15_handle_reject.md) |
| 16 | `POST /groups/1e011830-5353-48f7-ab89-a05c69faaaf5/join` | `200` | PASS | [16_reapply_after_reject.md](16_reapply_after_reject.md) |
| 17 | `GET /groups/5aaebb83-19e1-45e7-891c-3a2b2775a9ea/detail` | `200` | PASS | [17_group_detail.md](17_group_detail.md) |
| 18 | `GET /groups/1e011830-5353-48f7-ab89-a05c69faaaf5/detail` | `403` | PASS | [18_detail_non_member.md](18_detail_non_member.md) |
| 19 | `PUT /groups/5aaebb83-19e1-45e7-891c-3a2b2775a9ea/settings` | `200` | PASS | [19_settings_enable_verify.md](19_settings_enable_verify.md) |
| 20 | `GET /groups/search?keyword=开放` | `200` | PASS | [20_verify_setting_changed.md](20_verify_setting_changed.md) |
| 21 | `PUT /groups/5aaebb83-19e1-45e7-891c-3a2b2775a9ea/settings` | `200` | PASS | [21_settings_disable_verify.md](21_settings_disable_verify.md) |
| 22 | `PUT /groups/5aaebb83-19e1-45e7-891c-3a2b2775a9ea/settings` | `403` | PASS | [22_settings_non_owner.md](22_settings_non_owner.md) |