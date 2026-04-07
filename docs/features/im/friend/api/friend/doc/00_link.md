# friend - API test link

Base URL: `http://127.0.0.1:9600`

| # | Interface | Status | Result | Doc |
|---|-----------|--------|--------|-----|
| 1 | `GET /api/users/search?keyword=橘` | `200` | PASS | [01_search_users.md](01_search_users.md) |
| 2 | `POST /api/friends/requests` | `200` | PASS | [02_send_request.md](02_send_request.md) |
| 3 | `POST /api/friends/requests` | `400` | PASS | [03_duplicate_request.md](03_duplicate_request.md) |
| 4 | `POST /api/friends/requests` | `400` | PASS | [04_add_self.md](04_add_self.md) |
| 5 | `POST /api/friends/requests` | `404` | PASS | [05_user_not_found.md](05_user_not_found.md) |
| 6 | `GET /api/friends/requests/received` | `200` | PASS | [06_received_requests.md](06_received_requests.md) |
| 7 | `GET /api/friends/requests/sent` | `200` | PASS | [07_sent_requests.md](07_sent_requests.md) |
| 8 | `POST /api/friends/requests/47932555-560d-45d0-9c83-06681781cde6/accept` | `200` | PASS | [08_accept_request.md](08_accept_request.md) |
| 9 | `POST /api/friends/requests/47932555-560d-45d0-9c83-06681781cde6/accept` | `403` | PASS | [09_accept_again.md](09_accept_again.md) |
| 10 | `GET /api/friends` | `200` | PASS | [10_friends_list_a.md](10_friends_list_a.md) |
| 11 | `GET /api/friends` | `200` | PASS | [11_friends_list_b.md](11_friends_list_b.md) |
| 12 | `GET /conversations` | `200` | PASS | [12_auto_conversation.md](12_auto_conversation.md) |
| 13 | `DELETE /api/friends/2` | `200` | PASS | [13_delete_friend.md](13_delete_friend.md) |
| 14 | `GET /api/friends` | `200` | PASS | [14_friends_after_delete.md](14_friends_after_delete.md) |
| 15 | `POST /api/friends/requests` | `200` | PASS | [15_resend_after_delete.md](15_resend_after_delete.md) |
| 16 | `POST /api/friends/requests/47932555-560d-45d0-9c83-06681781cde6/reject` | `200` | PASS | [16_reject_request.md](16_reject_request.md) |
| 17 | `GET /api/friends/requests/received` | `200` | PASS | [17_no_pending_after_reject.md](17_no_pending_after_reject.md) |