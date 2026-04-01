# conversation_message - API test link

Base URL: `http://127.0.0.1:9600`

| # | Interface | Status | Result | Doc |
|---|-----------|--------|--------|-----|
| 1 | `GET /conversations/9e7ec25e-bd37-4f5f-8bac-eb54bed10dd8/messages` | `200` | PASS | [01_get_latest.md](01_get_latest.md) |
| 2 | `GET /conversations/9e7ec25e-bd37-4f5f-8bac-eb54bed10dd8/messages?before_seq=10` | `200` | PASS | [02_get_before_seq.md](02_get_before_seq.md) |
| 3 | `GET /conversations/9e7ec25e-bd37-4f5f-8bac-eb54bed10dd8/messages?before_seq=1` | `200` | PASS | [03_get_empty.md](03_get_empty.md) |