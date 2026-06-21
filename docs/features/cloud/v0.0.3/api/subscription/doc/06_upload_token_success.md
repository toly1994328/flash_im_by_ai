# POST /api/storage/upload-token

有订阅用户获取 STS Token 成功。

## Parameters

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| file_name | string | 是 | 文件名 |
| file_size | int | 是 | 文件大小（bytes） |
| mime_type | string | 是 | MIME 类型 |
| hash | string | 是 | 文件 SHA-1 哈希 |

```json
{"file_name": "photo.jpg", "file_size": 2048000, "mime_type": "image/jpeg", "hash": "def456"}
```

## Response `200`

```json
{"access_key_id":"STS.NZKbMpet5wXbfJXAowpbwpend","access_key_secret":"8x26gJoGyLfKAUvwHbKryWMVagFRfdyfAw5YycNukYC6","security_token":"CAISqwN1q6Ft5B2yfSjIr5n+KffEiKsUwJqJZGzppW8ifO1bn6DFhjz2IHhMdHBvAe4esf83mm5Y7PsZlqRuU5tCTECBcNB99NENqaJO6yNH4J7b16cNrbH4M7T6aXeirgm7AYjQSNfaZY3iCTTtnTNyxr3XbCirW0ffX7SClZ9gaKZwPGy/diEUPMpKAQFgpcQGT2+zU8ygKRn3mGHdIVN1sw5n8wNF5L+439eX52jW7mvzwfRHoJ/qcNr2LZtiOJ5kU5K02altaq3b2SFduQVR+b1ty/YD/i3GsdCbCl0WuU3cba2MrJphJQYlNvdnQ+tOpvSl0KEjtLaWnoivwVMWZe1bDniDHtGqycaCGvumFK5gJOuhayySgoDSZsao7Vx4Wx9BalMWIehGA2RrFBkhRgvdLqKa413Qam+hMfPdiPFvjsIrlwqzpYTUdwLSGK/53yIRIZ95bkY4haWWF5wLpsTsGi07kDMPb979Je0b5yAPoC5BoqP44oxxHNwmXux/FhIngNprTa/VcPwoP4RziupuAc+G5+Bd84ZHo6b5l0WF6F8nuPjMGw/hgNftGoABhoXI5uf4wbrz7QNqBKdl316ruIM3xftWyziZhHssgcE8jXbmv7GvGPgSVKVAlw2OUFAVeh2Ofy6oYmzlXCVivCc8pjxun5g6pEzFgI4RyEhfH1udjqizb9rfH2N7OI+Z9vFBOYCXlsaXTp9T8YgxPlZp3hnhFteTFyAJ2BR05WIgAA==","expiration":"2026-06-21T03:27:25Z","bucket":"flash-im-storage","endpoint":"https://oss-cn-beijing.aliyuncs.com","object_key":"users/2/original/2026/06/faa48750-bbd1-43f2-ad0b-30df54429bae.jpg","thumb_object_key":null,"url":"https://flash-im-storage.oss-cn-beijing.aliyuncs.com/users/2/original/2026/06/faa48750-bbd1-43f2-ad0b-30df54429bae.jpg","thumb_url":null}
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/api/storage/upload-token"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIyIiwiZXhwIjoxNzgyNjE2MzQzLCJpYXQiOjE3ODIwMTE1NDN9.hOIXWaFEm4WW3UP39oexFGwV-OKaNI9OBnVoA04fFdE"
  -H "Content-Type: application/json"
  -d '{"file_name": "photo.jpg", "file_size": 2048000, "mime_type": "image/jpeg", "hash": "def456"}'
```