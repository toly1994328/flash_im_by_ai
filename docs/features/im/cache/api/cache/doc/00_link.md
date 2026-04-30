# cache - API test link

Base URL: `http://127.0.0.1:9600`

| # | Interface | Status | Result | Doc |
|---|-----------|--------|--------|-----|
| 1 | `GET /conversations/294588ba-f96e-4ced-9d7c-b73bd6f66117/messages?limit=5` | `200` | PASS | [01_messages_latest.md](01_messages_latest.md) |
| 2 | `GET /conversations/294588ba-f96e-4ced-9d7c-b73bd6f66117/messages?before_seq=1&limit=3` | `200` | PASS | [02_messages_before_seq.md](02_messages_before_seq.md) |
| 3 | `GET /conversations/294588ba-f96e-4ced-9d7c-b73bd6f66117/messages?after_seq=0&limit=5` | `200` | PASS | [03_messages_after_seq.md](03_messages_after_seq.md) |
| 4 | `GET /conversations/294588ba-f96e-4ced-9d7c-b73bd6f66117/messages?after_seq=1&limit=5` | `200` | PASS | [04_messages_after_seq_mid.md](04_messages_after_seq_mid.md) |
| 5 | `GET /conversations/294588ba-f96e-4ced-9d7c-b73bd6f66117/messages?after_seq=0&before_seq=999&limit=5` | `200` | PASS | [05_after_seq_priority.md](05_after_seq_priority.md) |