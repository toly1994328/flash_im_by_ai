# GET /groups/33a71c87-efc8-414d-af0e-696879167e33/detail

验证邀请入群后，新成员出现在群详情的成员列表中。

## Response `200`

```json
{"id":"33a71c87-efc8-414d-af0e-696879167e33","name":"管理测试群","avatar":"grid:identicon:朱红:ed5126,identicon:橘橙:f97d1c,identicon:藤黄:ffd111,identicon:碧螺春绿:867018,identicon:天蓝:1677b3","owner_id":1,"group_no":10018,"member_count":5,"join_verification":false,"members":[{"user_id":1,"nickname":"朱红","avatar":"identicon:朱红:ed5126"},{"user_id":2,"nickname":"橘橙","avatar":"identicon:橘橙:f97d1c"},{"user_id":3,"nickname":"藤黄","avatar":"identicon:藤黄:ffd111"},{"user_id":4,"nickname":"碧螺春绿","avatar":"identicon:碧螺春绿:867018"},{"user_id":5,"nickname":"天蓝","avatar":"identicon:天蓝:1677b3"}],"status":0,"announcement":null,"announcement_updated_at":null}
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/groups/33a71c87-efc8-414d-af0e-696879167e33/detail"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc3MzMzNTExLCJpYXQiOjE3NzY3Mjg3MTF9.5NMBPyBR3-3MvkmY1zDZQLvBUGdVhxW2wpm4Agg4pjE"
```

> 邀请成功后 member_count 应增加，成员列表包含新成员。