# GitHub OAuth 登录 — 接入指南

> 基于 [GitHub OAuth 官方文档](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps)，整理闪讯接入所需的关键信息。

## 一、我们使用的流程：Web Application Flow

GitHub OAuth 有两种授权方式：

| 方式 | 适用场景 | 我们用不用 |
|------|---------|-----------|
| **Web Application Flow** | 有浏览器的应用（网页、移动端 WebView） | ✅ 用这个 |
| Device Flow | 没有浏览器的设备（CLI、智能电视） | ❌ 不用 |

Web Application Flow 三步走：

```
1. 客户端打开 GitHub 授权页（用户看到"Authorize"按钮）
2. 用户点击授权 → GitHub 重定向到 callback URL，带上 code
3. 后端用 code 换 access_token → 用 token 调 GitHub API 获取用户信息
```

---

## 二、注册 OAuth App

前往：[GitHub Settings > Developer settings > OAuth Apps > New](https://github.com/settings/applications/new)

| 字段 | 填什么 | 说明 |
|------|--------|------|
| Application name | 闪讯 IM | 用户在授权页看到的名字 |
| Homepage URL | `http://82.157.176.209:9600` | 展示用，不影响功能 |
| Authorization callback URL | `http://localhost/callback` | 授权后浏览器跳转的地址。我们用 WebView 拦截，不需要真的能访问 |

注册后获得：
- **Client ID**（公开的，可以写在客户端代码里）
- **Client Secret**（保密的，只能放在后端）

---

## 三、流程详解

### 步骤 1：请求用户授权

客户端在 WebView 中打开这个 URL：

```
GET https://github.com/login/oauth/authorize?client_id={CLIENT_ID}&redirect_uri=http://localhost/callback&scope=read:user
```

参数说明：

| 参数 | 必填 | 说明 |
|------|------|------|
| client_id | ✅ | 你的 OAuth App 的 Client ID |
| redirect_uri | 推荐 | 授权后跳转地址，必须和注册时填的 callback URL 匹配（或是其子路径） |
| scope | 可选 | 请求的权限范围。我们只需要 `read:user`（读取用户基本信息） |
| state | 推荐 | 随机字符串，防 CSRF 攻击。客户端生成，回调时验证 |

用户看到 GitHub 的授权页面，点击"Authorize"。

### 步骤 2：拿到 code

用户授权后，GitHub 把浏览器重定向到：

```
http://localhost/callback?code=abc123def456&state=xxx
```

客户端（WebView）监听 URL 变化，看到 `?code=` 就拦截，提取 code 值，关闭 WebView。

> code 有效期 10 分钟，只能用一次。

### 步骤 3：后端用 code 换 access_token

客户端把 code 发给我们的后端：

```
POST /auth/github
{
  "code": "abc123def456",
  "device_info": { ... }
}
```

后端收到后，请求 GitHub：

```
POST https://github.com/login/oauth/access_token
Content-Type: application/json
Accept: application/json

{
  "client_id": "你的CLIENT_ID",
  "client_secret": "你的CLIENT_SECRET",
  "code": "abc123def456"
}
```

GitHub 返回：

```json
{
  "access_token": "gho_16C7e42F292c6912E7710c838347Ae178B4a",
  "scope": "read:user",
  "token_type": "bearer"
}
```

### 步骤 4：后端用 token 获取用户信息

```
GET https://api.github.com/user
Authorization: Bearer gho_16C7e42F292c6912E7710c838347Ae178B4a
```

GitHub 返回用户信息（我们需要的字段）：

```json
{
  "id": 12345678,
  "login": "octocat",
  "avatar_url": "https://avatars.githubusercontent.com/u/12345678",
  "name": "The Octocat"
}
```

| 字段 | 用途 |
|------|------|
| id | 唯一标识，存入 auth_credentials.identifier |
| login | GitHub 用户名，可作为默认昵称 |
| avatar_url | 头像 URL |
| name | 显示名（可能为 null，fallback 到 login） |

---

## 四、我们的实现方案

### 后端

```
POST /auth/github
请求：{ code, device_info? }
处理：
  1. 用 code + client_secret 换 access_token
  2. 用 token 获取 GitHub 用户信息
  3. 查 auth_credentials WHERE auth_type='github' AND identifier=github_id
  4. 存在 → 直接登录
  5. 不存在 → 创建 account + user_profile + auth_credential
  6. 记录 login_log
  7. 签发 JWT
响应：{ token, user_id, has_password }
```

### 客户端

```
1. 构造授权 URL（带 client_id + redirect_uri + state）
2. 打开 WebView 加载授权 URL
3. 监听 URL 变化，拦截 redirect_uri?code=xxx
4. 验证 state 一致
5. 关闭 WebView
6. POST /auth/github { code, device_info }
7. 拿到 token，进入主页
```

### .env 配置

```env
GITHUB_CLIENT_ID=Ov23li...
GITHUB_CLIENT_SECRET=abc123...
```

---

## 五、注意事项

| 事项 | 说明 |
|------|------|
| Client Secret 保密 | 只放后端 .env，不能写在客户端代码里 |
| code 一次性 | 用过就失效，不能重复使用 |
| scope 最小化 | 只请求 `read:user`，不要请求 repo 等敏感权限 |
| state 防 CSRF | 客户端生成随机字符串，回调时验证一致性 |
| 网络超时 | 后端请求 GitHub API 要设超时（建议 10 秒），GitHub 偶尔慢 |
| 中国网络 | 服务器在国内时访问 github.com 可能不稳定，考虑重试机制 |
