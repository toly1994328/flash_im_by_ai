# storage - API test link

Base URL: `http://127.0.0.1:9600`

| # | Interface | Status | Result | Doc |
|---|-----------|--------|--------|-----|
| 1 | `POST /api/upload/image` | `200` | PASS | [01_upload_image.md](01_upload_image.md) |
| 2 | `POST /api/upload/image` | `200` | PASS | [02_upload_image_dedup.md](02_upload_image_dedup.md) |
| 3 | `POST /api/upload/file` | `200` | PASS | [03_upload_file.md](03_upload_file.md) |
| 4 | `GET /api/storage/quota` | `200` | PASS | [04_get_quota.md](04_get_quota.md) |
| 5 | `POST /api/upload/image` | `400` | PASS | [05_upload_no_hash.md](05_upload_no_hash.md) |
| 6 | `POST /api/upload/image` | `401` | PASS | [06_upload_unauthorized.md](06_upload_unauthorized.md) |
| 7 | `POST /api/upload/image` | `400` | PASS | [07_upload_unsupported_type.md](07_upload_unsupported_type.md) |
| 8 | `POST /conversations/5cf31a40-473d-4aa9-8208-320e29f98b5b/messages` | `200` | PASS | [08_send_image_msg.md](08_send_image_msg.md) |
| 9 | `POST /conversations/5cf31a40-473d-4aa9-8208-320e29f98b5b/messages` | `200` | PASS | [09_send_video_msg.md](09_send_video_msg.md) |
| 10 | `POST /conversations/5cf31a40-473d-4aa9-8208-320e29f98b5b/messages` | `200` | PASS | [10_send_file_msg.md](10_send_file_msg.md) |
| 11 | `POST /conversations/5cf31a40-473d-4aa9-8208-320e29f98b5b/messages` | `200` | PASS | [11_send_audio_msg.md](11_send_audio_msg.md) |
| 12 | `GET /conversations/5cf31a40-473d-4aa9-8208-320e29f98b5b/messages` | `200` | PASS | [12_verify_history.md](12_verify_history.md) |
| 13 | `GET /api/storage/quota` | `200` | PASS | [13_quota_after_sends.md](13_quota_after_sends.md) |