# GET /api/friends

删除好友后查询列表，已删除的好友不再出现。

## Response `200`

```json
{"data":[{"avatar":"identicon:孔雀蓝:4994c4","bio":null,"created_at":"2026-04-12T09:34:08.712406Z","friend_id":"39","nickname":"孔雀蓝"},{"avatar":"identicon:宝石蓝:2486b9","bio":null,"created_at":"2026-04-12T09:34:08.996191Z","friend_id":"38","nickname":"宝石蓝"},{"avatar":"identicon:星蓝:93b5cf","bio":null,"created_at":"2026-04-12T09:34:09.240400Z","friend_id":"37","nickname":"星蓝"},{"avatar":"identicon:杏黄:f28e16","bio":null,"created_at":"2026-04-12T09:33:20.751528Z","friend_id":"15","nickname":"杏黄"},{"avatar":"identicon:枫叶红:c21f30","bio":null,"created_at":"2026-04-12T09:33:21.239706Z","friend_id":"13","nickname":"枫叶红"},{"avatar":"identicon:柿红:f2481b","bio":null,"created_at":"2026-04-12T09:33:19.449360Z","friend_id":"20","nickname":"柿红"},{"avatar":"identicon:棕榈绿:5b4913","bio":null,"created_at":"2026-04-12T09:34:10.630097Z","friend_id":"32","nickname":"棕榈绿"},{"avatar":"identicon:海军蓝:346c9c","bio":null,"created_at":"2026-04-12T09:34:08.469614Z","friend_id":"40","nickname":"海军蓝"},{"avatar":"identicon:海棠红:f03752","bio":null,"created_at":"2026-04-12T09:33:21.488740Z","friend_id":"12","nickname":"海棠红"},{"avatar":"identicon:海螺橙:f0945d","bio":null,"created_at":"2026-04-12T09:33:19.708841Z","friend_id":"19","nickname":"海螺橙"},{"avatar":"identicon:湖水蓝:b0d5df","bio":null,"created_at":"2026-04-12T09:34:09.485474Z","friend_id":"36","nickname":"湖水蓝"},{"avatar":"identicon:潭水绿:645822","bio":null,"created_at":"2026-04-12T09:34:10.306353Z","friend_id":"33","nickname":"潭水绿"},{"avatar":"identicon:琥珀黄:feba07","bio":null,"created_at":"2026-04-12T09:33:20.508510Z","friend_id":"16","nickname":"琥珀黄"},{"avatar":"identicon:粽叶绿:876818","bio":null,"created_at":"2026-04-12T09:34:10.055605Z","friend_id":"34","nickname":"粽叶绿"},{"avatar":"identicon:美人焦橙:fa7e23","bio":null,"created_at":"2026-04-12T09:33:20.059144Z","friend_id":"18","nickname":"美人焦橙"},{"avatar":"identicon:草莓红:ef6f48","bio":null,"created_at":"2026-04-12T09:33:21.023226Z","friend_id":"14","nickname":"草莓红"},{"avatar":"identicon:蔚蓝:29b7cb","bio":null,"created_at":"2026-04-12T09:34:09.819310Z","friend_id":"35","nickname":"蔚蓝"},{"avatar":"identicon:金莲花橙:f86b1d","bio":null,"created_at":"2026-04-12T09:33:20.255568Z","friend_id":"17","nickname":"金莲花橙"}]}
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/api/friends"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc2NTkzOTcxLCJpYXQiOjE3NzU5ODkxNzF9.zS0yoOjS3x0n-SO_8A6zqWxQ3MVfFKqmBR3Gzav0T5Q"
```