# group_manage v0.0.3 - API test link

Base URL: `http://127.0.0.1:9600`

| # | Interface | Status | Result | Doc |
|---|-----------|--------|--------|-----|
| 1 | `POST /groups/33a71c87-efc8-414d-af0e-696879167e33/members` | `200` | PASS | [01_invite_members.md](01_invite_members.md) |
| 2 | `POST /groups/33a71c87-efc8-414d-af0e-696879167e33/members` | `403` | PASS | [02_invite_non_member.md](02_invite_non_member.md) |
| 3 | `GET /groups/33a71c87-efc8-414d-af0e-696879167e33/detail` | `200` | PASS | [03_verify_invite.md](03_verify_invite.md) |
| 4 | `DELETE /groups/33a71c87-efc8-414d-af0e-696879167e33/members/5` | `200` | PASS | [04_kick_member.md](04_kick_member.md) |
| 5 | `DELETE /groups/33a71c87-efc8-414d-af0e-696879167e33/members/5` | `403` | PASS | [05_kick_non_owner.md](05_kick_non_owner.md) |
| 6 | `DELETE /groups/33a71c87-efc8-414d-af0e-696879167e33/members/1` | `400` | PASS | [06_kick_self.md](06_kick_self.md) |
| 7 | `POST /groups/33a71c87-efc8-414d-af0e-696879167e33/leave` | `200` | PASS | [07_leave_group.md](07_leave_group.md) |
| 8 | `POST /groups/33a71c87-efc8-414d-af0e-696879167e33/leave` | `400` | PASS | [08_leave_owner.md](08_leave_owner.md) |
| 9 | `PUT /groups/33a71c87-efc8-414d-af0e-696879167e33/transfer` | `200` | PASS | [09_transfer_owner.md](09_transfer_owner.md) |
| 10 | `PUT /groups/33a71c87-efc8-414d-af0e-696879167e33/transfer` | `403` | PASS | [10_transfer_non_owner.md](10_transfer_non_owner.md) |
| 11 | `GET /groups/33a71c87-efc8-414d-af0e-696879167e33/detail` | `200` | PASS | [11_verify_transfer.md](11_verify_transfer.md) |
| 12 | `PUT /groups/33a71c87-efc8-414d-af0e-696879167e33/transfer` | `200` | PASS | [12_transfer_back.md](12_transfer_back.md) |
| 13 | `PUT /groups/33a71c87-efc8-414d-af0e-696879167e33/announcement` | `200` | PASS | [13_announcement.md](13_announcement.md) |
| 14 | `PUT /groups/33a71c87-efc8-414d-af0e-696879167e33/announcement` | `403` | PASS | [14_announcement_non_owner.md](14_announcement_non_owner.md) |
| 15 | `GET /groups/33a71c87-efc8-414d-af0e-696879167e33/detail` | `200` | PASS | [15_verify_announcement.md](15_verify_announcement.md) |
| 16 | `PUT /groups/33a71c87-efc8-414d-af0e-696879167e33` | `200` | PASS | [16_update_name.md](16_update_name.md) |
| 17 | `PUT /groups/33a71c87-efc8-414d-af0e-696879167e33` | `400` | PASS | [17_update_empty_name.md](17_update_empty_name.md) |
| 18 | `PUT /groups/33a71c87-efc8-414d-af0e-696879167e33` | `403` | PASS | [18_update_non_owner.md](18_update_non_owner.md) |
| 19 | `POST /groups` | `200` | PASS | [19_create_disband_group.md](19_create_disband_group.md) |
| 20 | `POST /groups/9a8114f7-8766-4bf2-86ab-623a219257c7/disband` | `403` | PASS | [20_disband_non_owner.md](20_disband_non_owner.md) |
| 21 | `POST /groups/9a8114f7-8766-4bf2-86ab-623a219257c7/disband` | `200` | PASS | [21_disband.md](21_disband.md) |
| 22 | `GET /groups/9a8114f7-8766-4bf2-86ab-623a219257c7/detail` | `200` | PASS | [22_verify_disband.md](22_verify_disband.md) |