# GET /api/messages/search?keyword=签到

跨会话搜索消息内容，按会话分组返回。只搜文本消息（msg_type=0）。

## Parameters

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| keyword | string | 是 | 搜索关键词（消息内容模糊匹配） |
| limit | int | 否 | 返回的会话分组数量，默认 10，最大 20 |

## Response `200`

```json
{"data":[{"conv_type":1,"conversation_avatar":"grid:identicon:朱红:ed5126,identicon:藤黄:ffd111,identicon:天蓝:1677b3,identicon:葡萄紫:4c1f24,identicon:枫叶红:c21f30,identicon:姜黄:d6c560,identicon:橄榄绿:5e5314,identicon:宝石蓝:2486b9,identicon:花青:1a2847","conversation_id":"5692e36a-77a4-4054-85b0-a953097a92d5","conversation_name":"传统色研究会","match_count":2,"messages":[{"content":"枫叶红签到 🍁","created_at":"2026-04-26T14:33:52.810223+00:00","message_id":"1a1d556b-875d-4e87-b956-3ef7a2d34cde","sender_avatar":"identicon:枫叶红:c21f30","sender_name":"枫叶红"},{"content":"姜黄签到，中药色系代表","created_at":"2026-04-26T14:33:52.616167+00:00","message_id":"0e89136a-31d0-4406-a96c-660f065c07a8","sender_avatar":"identicon:姜黄:d6c560","sender_name":"姜黄"}]},{"conv_type":1,"conversation_avatar":"grid:identicon:朱红:ed5126,identicon:橘橙:f97d1c,identicon:胭脂红:f03f24,identicon:樱桃红:ed3321,identicon:草莓红:ef6f48,identicon:杏黄:f28e16,identicon:金莲花橙:f86b1d,identicon:美人焦橙:fa7e23,identicon:海螺橙:f0945d","conversation_id":"957ec795-b4b5-497a-a46f-0481403a3f32","conversation_name":"橙红色调","match_count":1,"messages":[{"content":"金莲花橙签到","created_at":"2026-04-26T14:33:52.193659+00:00","message_id":"3ce1ac49-5369-46e9-9e95-79c343aa1b0a","sender_avatar":"identicon:金莲花橙:f86b1d","sender_name":"金莲花橙"}]},{"conv_type":1,"conversation_avatar":"grid:identicon:朱红:ed5126,identicon:银红:e7cad3,identicon:胭脂红:f03f24,identicon:樱桃红:ed3321,identicon:珊瑚红:f04a3a,identicon:海棠红:f03752,identicon:枫叶红:c21f30,identicon:草莓红:ef6f48","conversation_id":"faf1076d-193f-41ce-9baa-2385428ac867","conversation_name":"红色系家族","match_count":1,"messages":[{"content":"胭脂红签到","created_at":"2026-04-26T14:33:50.263467+00:00","message_id":"fa0879ae-f042-4e7d-8987-d4c0b377682c","sender_avatar":"identicon:胭脂红:f03f24","sender_name":"胭脂红"}]},{"conv_type":1,"conversation_avatar":"grid:identicon:朱红:ed5126,identicon:橘橙:f97d1c,identicon:藤黄:ffd111,identicon:碧螺春绿:867018,identicon:天蓝:1677b3,identicon:景泰蓝:2775b6,identicon:葡萄紫:4c1f24","conversation_id":"4da5fa4d-5309-4c16-812a-7035e9990a03","conversation_name":"七彩虹","match_count":1,"messages":[{"content":"蓝色签到 💙","created_at":"2026-04-26T14:33:49.655180+00:00","message_id":"bd99b9f3-15d2-4903-a6c8-fc508768ec76","sender_avatar":"identicon:天蓝:1677b3","sender_name":"天蓝"}]}]}
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/api/messages/search?keyword=签到"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc4MzcwNDk3LCJpYXQiOjE3Nzc3NjU2OTd9.3woan6cwSZSYb0105mBe1_EocZxGU8-yquq11g8W7ak"
```

> 每个会话分组包含 conversation_name/avatar/conv_type/match_count + 最近 3 条匹配消息。