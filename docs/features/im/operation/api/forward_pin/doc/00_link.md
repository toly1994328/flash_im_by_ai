# forward_pin - API test link

Base URL: `http://127.0.0.1:9600`

| # | Interface | Status | Result | Doc |
|---|-----------|--------|--------|-----|
| 1 | `POST /conversations/{conv_id}/messages/forward` | `200` | PASS | [01_forward_single.md](01_forward_single.md) |
| 2 | `POST /conversations/{conv_id}/messages/forward` | `200` | PASS | [02_forward_merge.md](02_forward_merge.md) |
| 3 | `POST /conversations/{conv_id}/messages/forward` | `400` | PASS | [03_forward_empty.md](03_forward_empty.md) |
| 4 | `POST /conversations/{conv_id}/messages/pin` | `200` | PASS | [04_pin_message.md](04_pin_message.md) |
| 5 | `GET /conversations/{conv_id}/messages/pinned` | `200` | PASS | [05_get_pinned.md](05_get_pinned.md) |
| 6 | `POST /conversations/{conv_id}/messages/pin` | `400` | PASS | [06_pin_duplicate.md](06_pin_duplicate.md) |
| 8 | `DELETE /conversations/{conv_id}/messages/pin/{pin_id}` | `200` | PASS | [08_unpin.md](08_unpin.md) |
| 9 | `GET /conversations/{conv_id}/messages/pinned` | `200` | PASS | [09_verify_unpinned.md](09_verify_unpinned.md) |