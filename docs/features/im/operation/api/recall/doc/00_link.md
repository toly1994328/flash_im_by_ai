# recall - API test link

Base URL: `http://127.0.0.1:9600`

| # | Interface | Status | Result | Doc |
|---|-----------|--------|--------|-----|
| 1 | `POST /conversations/bad76d18-338e-4d86-bd68-3cea87aad5bf/messages` | `200` | PASS | [01_send_message.md](01_send_message.md) |
| 2 | `POST /conversations/bad76d18-338e-4d86-bd68-3cea87aad5bf/messages/b83d0207-9765-4a7d-8b5a-5483e68b9f8d/recall` | `200` | PASS | [02_recall_success.md](02_recall_success.md) |
| 3 | `GET /conversations/bad76d18-338e-4d86-bd68-3cea87aad5bf/messages?limit=5` | `200` | PASS | [03_verify_recalled.md](03_verify_recalled.md) |
| 4 | `POST /conversations/bad76d18-338e-4d86-bd68-3cea87aad5bf/messages/b83d0207-9765-4a7d-8b5a-5483e68b9f8d/recall` | `400` | PASS | [04_recall_duplicate.md](04_recall_duplicate.md) |
| 5 | `POST /conversations/bad76d18-338e-4d86-bd68-3cea87aad5bf/messages/355bf3e8-5c0a-404a-9c75-63e3938a92a6/recall` | `403` | PASS | [05_recall_not_owner.md](05_recall_not_owner.md) |
| 6 | `POST /conversations/bad76d18-338e-4d86-bd68-3cea87aad5bf/messages/50fdb7d9-ac36-4e4d-ada5-0d3a07e7f236/recall` | `403` | PASS | [06_recall_timeout.md](06_recall_timeout.md) |