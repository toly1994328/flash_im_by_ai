# GET /groups/0756c679-62de-4f8f-a274-43d29187d18b/detail

验证群公告已更新到群详情中。

## Response `200`

```json
{"id":"0756c679-62de-4f8f-a274-43d29187d18b","name":"管理测试群","avatar":"grid:identicon:朱红:ed5126,identicon:橘橙:f97d1c,identicon:藤黄:ffd111","owner_id":1,"group_no":10012,"member_count":3,"join_verification":false,"members":[{"user_id":1,"nickname":"朱红","avatar":"identicon:朱红:ed5126"},{"user_id":2,"nickname":"橘橙","avatar":"identicon:橘橙:f97d1c"},{"user_id":3,"nickname":"藤黄","avatar":"identicon:藤黄:ffd111"}],"status":0,"announcement":"本周六下午两点线下聚会","announcement_updated_at":"2026-04-22T23:54:15.768274Z"}
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/groups/0756c679-62de-4f8f-a274-43d29187d18b/detail"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc3NTA2ODU0LCJpYXQiOjE3NzY5MDIwNTR9.OvMfZ0nEOPIxrXAWzv7wrfR8YEUsQFQljufpASuRvOU"
```

> 群详情返回 announcement、announcement_updated_at、announcement_updated_by 字段。