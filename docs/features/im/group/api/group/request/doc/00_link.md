# group - API test link

Base URL: `http://127.0.0.1:9600`

| # | Interface | Status | Result | Doc |
|---|-----------|--------|--------|-----|
| 1 | `POST /conversations` | `200` | PASS | [01_create_group.md](01_create_group.md) |
| 2 | `POST /conversations` | `400` | PASS | [02_create_group_empty_name.md](02_create_group_empty_name.md) |
| 3 | `POST /conversations` | `400` | PASS | [03_create_group_too_few.md](03_create_group_too_few.md) |
| 4 | `POST /conversations` | `200` | PASS | [04_create_private.md](04_create_private.md) |
| 5 | `POST /conversations` | `200` | PASS | [05_create_legacy.md](05_create_legacy.md) |
| 6 | `GET /conversations` | `200` | PASS | [06_list_with_group.md](06_list_with_group.md) |
| 7 | `GET /conversations/search` | `200` | PASS | [07_search_groups.md](07_search_groups.md) |
| 8 | `GET /conversations/search` | `200` | PASS | [08_search_non_member.md](08_search_non_member.md) |
| 9 | `GET /conversations/search` | `200` | PASS | [09_search_empty.md](09_search_empty.md) |
| 10 | `POST /conversations/890056e8-8d10-4e40-82a8-a8810ff7374d/join` | `200` | PASS | [10_join_auto.md](10_join_auto.md) |
| 11 | `POST /conversations/890056e8-8d10-4e40-82a8-a8810ff7374d/join` | `400` | PASS | [11_join_already_member.md](11_join_already_member.md) |
| 12 | `POST /conversations/890056e8-8d10-4e40-82a8-a8810ff7374d/join` | `200` | PASS | [12_join_verification.md](12_join_verification.md) |
| 13 | `POST /conversations/890056e8-8d10-4e40-82a8-a8810ff7374d/join` | `400` | PASS | [13_join_duplicate.md](13_join_duplicate.md) |
| 14 | `GET /conversations/my-join-requests` | `200` | PASS | [14_my_join_requests.md](14_my_join_requests.md) |
| 15 | `GET /conversations/my-join-requests` | `200` | PASS | [15_my_join_requests_empty.md](15_my_join_requests_empty.md) |
| 16 | `POST /conversations/890056e8-8d10-4e40-82a8-a8810ff7374d/join-requests/0b9354bf-cab2-49cd-83eb-796dfec8a791/handle` | `403` | PASS | [16_handle_forbidden.md](16_handle_forbidden.md) |
| 17 | `POST /conversations/890056e8-8d10-4e40-82a8-a8810ff7374d/join-requests/0b9354bf-cab2-49cd-83eb-796dfec8a791/handle` | `200` | PASS | [17_handle_approve.md](17_handle_approve.md) |
| 18 | `GET /conversations/search` | `200` | PASS | [18_verify_joined.md](18_verify_joined.md) |