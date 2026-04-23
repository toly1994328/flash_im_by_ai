# GET /groups/0756c679-62de-4f8f-a274-43d29187d18b/detail

验证转让后 owner_id 已变更为 uid2。

## Response `200`

```json
{"id":"0756c679-62de-4f8f-a274-43d29187d18b","name":"管理测试群","avatar":"grid:identicon:朱红:ed5126,identicon:橘橙:f97d1c,identicon:藤黄:ffd111","owner_id":2,"group_no":10012,"member_count":3,"join_verification":false,"members":[{"user_id":2,"nickname":"橘橙","avatar":"identicon:橘橙:f97d1c"},{"user_id":1,"nickname":"朱红","avatar":"identicon:朱红:ed5126"},{"user_id":3,"nickname":"藤黄","avatar":"identicon:藤黄:ffd111"}],"status":0,"announcement":null,"announcement_updated_at":null}
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/groups/0756c679-62de-4f8f-a274-43d29187d18b/detail"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIyIiwiZXhwIjoxNzc3NTA2ODU1LCJpYXQiOjE3NzY5MDIwNTV9.aSX1haVYCWshpi-kSMQipO4ftHQnprzE1Y6FSs6YpGE"
```

> 转让成功后群详情中 owner_id 应为新群主。