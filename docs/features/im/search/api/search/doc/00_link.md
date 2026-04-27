# search - API test link

Base URL: `http://127.0.0.1:9600`

| # | Interface | Status | Result | Doc |
|---|-----------|--------|--------|-----|
| 1 | `GET /api/friends/search?keyword=橘` | `200` | PASS | [01_search_friends.md](01_search_friends.md) |
| 2 | `GET /api/friends/search?keyword=不存在的名字xyz` | `200` | PASS | [02_search_friends_empty.md](02_search_friends_empty.md) |
| 3 | `GET /api/conversations/search-joined-groups?keyword=七彩` | `200` | PASS | [03_search_joined_groups.md](03_search_joined_groups.md) |
| 4 | `GET /api/conversations/search-joined-groups?keyword=` | `200` | PASS | [04_search_joined_groups_all.md](04_search_joined_groups_all.md) |
| 5 | `GET /api/messages/search?keyword=签到` | `200` | PASS | [05_search_messages.md](05_search_messages.md) |
| 6 | `GET /api/messages/search?keyword=完全不存在的内容xyz` | `200` | PASS | [06_search_messages_empty.md](06_search_messages_empty.md) |
| 7 | `GET /conversations/5692e36a-77a4-4054-85b0-a953097a92d5/messages/search?keyword=签到` | `200` | PASS | [07_search_conversation_messages.md](07_search_conversation_messages.md) |
| 8 | `GET /api/friends/search?keyword=%25` | `200` | PASS | [08_wildcard_escape.md](08_wildcard_escape.md) |