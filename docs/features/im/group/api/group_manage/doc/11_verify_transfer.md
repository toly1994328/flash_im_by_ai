# GET /groups/33a71c87-efc8-414d-af0e-696879167e33/detail

验证转让后 owner_id 已变更为 uid2。

## Response `200`

```json
{"id":"33a71c87-efc8-414d-af0e-696879167e33","name":"管理测试群","avatar":"grid:identicon:朱红:ed5126,identicon:橘橙:f97d1c,identicon:藤黄:ffd111","owner_id":2,"group_no":10018,"member_count":3,"join_verification":false,"members":[{"user_id":1,"nickname":"朱红","avatar":"identicon:朱红:ed5126"},{"user_id":2,"nickname":"橘橙","avatar":"identicon:橘橙:f97d1c"},{"user_id":3,"nickname":"藤黄","avatar":"identicon:藤黄:ffd111"}],"status":0,"announcement":null,"announcement_updated_at":null}
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/groups/33a71c87-efc8-414d-af0e-696879167e33/detail"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIyIiwiZXhwIjoxNzc3MzMzNTExLCJpYXQiOjE3NzY3Mjg3MTF9.7Z1nZxpxZB41Zqe86nTUYAaYCJi5kWWiSRTNOrFNzvY"
```

> 转让成功后群详情中 owner_id 应为新群主。