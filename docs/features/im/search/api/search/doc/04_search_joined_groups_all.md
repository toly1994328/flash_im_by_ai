# GET /api/conversations/search-joined-groups?keyword=

空关键词返回所有已加入的群聊。

## Response `200`

```json
{"data":[{"avatar":"grid:identicon:朱红:ed5126,identicon:橘橙:f97d1c,identicon:藤黄:ffd111,identicon:碧螺春绿:867018,identicon:天蓝:1677b3,identicon:景泰蓝:2775b6,identicon:葡萄紫:4c1f24","conversation_id":"4da5fa4d-5309-4c16-812a-7035e9990a03","member_count":7,"name":"七彩虹"},{"avatar":"grid:identicon:朱红:ed5126,identicon:藤黄:ffd111,identicon:天蓝:1677b3,identicon:葡萄紫:4c1f24,identicon:枫叶红:c21f30,identicon:姜黄:d6c560,identicon:橄榄绿:5e5314,identicon:宝石蓝:2486b9,identicon:花青:1a2847","conversation_id":"5692e36a-77a4-4054-85b0-a953097a92d5","member_count":10,"name":"传统色研究会"},{"avatar":"grid:identicon:朱红:ed5126,identicon:橘橙:f97d1c,identicon:藤黄:ffd111,identicon:银红:e7cad3,identicon:胭脂红:f03f24,identicon:杏黄:f28e16,identicon:柠檬黄:fcd337","conversation_id":"b79228b7-2585-46e6-8e51-19af4901d46a","member_count":7,"name":"暖色系联盟"},{"avatar":"grid:identicon:朱红:ed5126,identicon:橘橙:f97d1c,identicon:胭脂红:f03f24,identicon:樱桃红:ed3321,identicon:草莓红:ef6f48,identicon:杏黄:f28e16,identicon:金莲花橙:f86b1d,identicon:美人焦橙:fa7e23,identicon:海螺橙:f0945d","conversation_id":"957ec795-b4b5-497a-a46f-0481403a3f32","member_count":10,"name":"橙红色调"},{"avatar":"grid:identicon:朱红:ed5126,identicon:银红:e7cad3,identicon:胭脂红:f03f24,identicon:樱桃红:ed3321,identicon:珊瑚红:f04a3a,identicon:海棠红:f03752,identicon:枫叶红:c21f30,identicon:草莓红:ef6f48","conversation_id":"faf1076d-193f-41ce-9baa-2385428ac867","member_count":8,"name":"红色系家族"}]}
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/api/conversations/search-joined-groups?keyword="
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc4MzcwNDk3LCJpYXQiOjE3Nzc3NjU2OTd9.3woan6cwSZSYb0105mBe1_EocZxGU8-yquq11g8W7ak"
```