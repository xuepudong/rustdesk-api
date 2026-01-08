# OAuth 2.0 认证流程说明

## 目录
- [概述](#概述)
- [OAuth 2.0 基础](#oauth-20-基础)
- [rustdesk-api OAuth 实现](#rustdesk-api-oauth-实现)
- [支持的 OAuth 提供商](#支持的-oauth-提供商)
- [认证流程](#认证流程)
- [配置指南](#配置指南)
- [API 接口说明](#api-接口说明)
- [常见问题](#常见问题)

---

## 概述

rustdesk-api 支持 OAuth 2.0 / OIDC 第三方登录，允许用户使用 GitHub、Google 等第三方账号登录系统。本文档详细说明了 OAuth 认证的实现和使用方法。

### 特性

- ✅ 支持多种 OAuth 提供商（GitHub, Google, OIDC, Linux.do, Gitee 等）
- ✅ 支持 PKCE (Proof Key for Code Exchange) 增强安全性
- ✅ 支持 OIDC ID Token 验证
- ✅ 支持账号绑定/解绑
- ✅ 支持自动注册
- ✅ 支持代理配置

---

## OAuth 2.0 基础

### 什么是 OAuth 2.0？

OAuth 2.0 是一个授权框架，允许第三方应用在资源所有者授权的情况下，访问资源服务器上的受保护资源。

### 核心概念

- **Resource Owner（资源所有者）**: 用户
- **Client（客户端）**: rustdesk-api
- **Authorization Server（授权服务器）**: OAuth 提供商（如 GitHub, Google）
- **Resource Server（资源服务器）**: 存储用户资源的服务器
- **Access Token（访问令牌）**: 用于访问受保护资源的凭证

### 授权流程类型

rustdesk-api 使用 **Authorization Code Flow（授权码流程）**：

1. 客户端将用户重定向到授权服务器
2. 用户在授权服务器上登录并授权
3. 授权服务器将用户重定向回客户端，附带授权码
4. 客户端使用授权码交换访问令牌
5. 客户端使用访问令牌访问用户资源

---

## rustdesk-api OAuth 实现

### 架构设计

```
┌─────────────┐
│   Client    │ (RustDesk 客户端/Web)
└─────┬───────┘
      │ 1. 发起认证
      ↓
┌─────────────────────┐
│  rustdesk-api       │
│  /api/oidc/auth     │ ← 2. 生成授权 URL
└─────┬───────────────┘
      │ 3. 重定向
      ↓
┌─────────────────────┐
│  OAuth Provider     │
│  (GitHub/Google等)  │ ← 4. 用户授权
└─────┬───────────────┘
      │ 5. 回调 (带 code)
      ↓
┌─────────────────────┐
│  rustdesk-api       │
│  /api/oidc/callback │ ← 6. 交换 token, 获取用户信息
└─────┬───────────────┘
      │ 7. 返回结果
      ↓
┌─────────────┐
│   Client    │ ← 8. 登录成功/绑定成功
└─────────────┘
```

### 核心组件

#### 1. OAuth 服务 (`service/oauth.go`)

核心业务逻辑：
- `BeginAuth()` - 发起 OAuth 认证
- `Callback()` - 处理 OAuth 回调
- `GetOauthConfig()` - 获取 OAuth 配置

#### 2. OAuth 控制器

**客户端 API** (`http/controller/api/ouath.go`):
- `POST /api/oidc/auth` - 发起认证
- `GET /api/oidc/auth-query` - 查询认证状态
- `GET /api/oidc/callback` - OAuth 回调

**管理后台** (`http/controller/admin/oauth.go`):
- OAuth 提供商管理 (CRUD)
- OAuth 账号绑定/解绑

#### 3. 数据模型 (`model/oauth.go`)

```go
type Oauth struct {
    Op           string  // 提供商标识
    OauthType    string  // oauth 类型：github/google/oidc/gitee
    ClientId     string  // OAuth Client ID
    ClientSecret string  // OAuth Client Secret
    AutoRegister *bool   // 是否自动注册
    Scopes       string  // OAuth scopes
    Issuer       string  // OIDC issuer URL
    PkceEnable   *bool   // 是否启用 PKCE
    PkceMethod   string  // PKCE 方法：S256/plain
}

type OauthUser struct {
    Op      string // 提供商标识
    Openid  string // OAuth 用户唯一标识
    Name    string // 用户名
    Email   string // 邮箱
    Avatar  string // 头像
}
```

---

## 支持的 OAuth 提供商

### 1. GitHub

**适用场景**: 开发者、技术团队

**配置示例**:
```yaml
oauth:
  github:
    enabled: true
    client-id: "your-github-client-id"
    client-secret: "your-github-client-secret"
    scopes: "read:user user:email"
    auto-register: true
```

**申请流程**:
1. 访问 [GitHub Developer Settings](https://github.com/settings/developers)
2. 创建 OAuth App
3. 设置回调 URL: `http://your-domain/api/oauth/callback`
4. 获取 Client ID 和 Client Secret

### 2. Google

**适用场景**: 企业、个人用户

**配置示例**:
```yaml
oauth:
  google:
    enabled: true
    client-id: "your-google-client-id.apps.googleusercontent.com"
    client-secret: "your-google-client-secret"
    scopes: "openid profile email"
    auto-register: true
```

**申请流程**:
1. 访问 [Google Cloud Console](https://console.cloud.google.com/)
2. 创建项目并启用 Google+ API
3. 创建 OAuth 2.0 凭据
4. 设置授权重定向 URI: `http://your-domain/api/oauth/callback`

### 3. OIDC (通用 OpenID Connect)

**适用场景**: 企业自建认证系统、第三方 OIDC 提供商

**配置示例**:
```yaml
oauth:
  custom-oidc:
    enabled: true
    oauth-type: "oidc"
    issuer: "https://accounts.example.com"
    client-id: "your-client-id"
    client-secret: "your-client-secret"
    scopes: "openid profile email"
    pkce-enable: true
    pkce-method: "S256"
    auto-register: true
```

**OIDC 发现**:
rustdesk-api 自动从 `{issuer}/.well-known/openid-configuration` 获取配置。

### 4. Linux.do

**适用场景**: Linux 中文社区用户

**配置示例**:
```yaml
oauth:
  linuxdo:
    enabled: true
    client-id: "your-linuxdo-client-id"
    client-secret: "your-linuxdo-client-secret"
    auto-register: true
```

### 5. Gitee

**适用场景**: 中国开发者

**配置示例**:
```yaml
oauth:
  gitee:
    enabled: true
    client-id: "your-gitee-client-id"
    client-secret: "your-gitee-client-secret"
    scopes: "user_info emails"
    auto-register: true
```

**申请流程**:
1. 访问 [Gitee 第三方应用](https://gitee.com/oauth/applications)
2. 创建应用
3. 设置回调地址: `http://your-domain/api/oauth/callback`

---

## 认证流程

### 流程图

```
┌─────────┐
│  开始   │
└────┬────┘
     │
     ↓
┌─────────────────────────────────┐
│ 1. 客户端调用 /api/oidc/auth   │
│    发送: {op: "github"}         │
└────┬────────────────────────────┘
     │
     ↓
┌─────────────────────────────────┐
│ 2. rustdesk-api 生成:           │
│    - state (防 CSRF)            │
│    - verifier (PKCE)            │
│    - nonce (防重放)             │
│    - 授权 URL                   │
└────┬────────────────────────────┘
     │
     ↓
┌─────────────────────────────────┐
│ 3. 返回给客户端:                │
│    {                             │
│      "code": "abc123",           │
│      "url": "https://github..." │
│    }                             │
└────┬────────────────────────────┘
     │
     ↓
┌─────────────────────────────────┐
│ 4. 客户端保存 code 并轮询:      │
│    GET /api/oidc/auth-query?    │
│        code=abc123               │
└────┬────────────────────────────┘
     │
     ↓
┌─────────────────────────────────┐
│ 5. 用户在浏览器中打开授权 URL   │
│    完成 GitHub 授权              │
└────┬────────────────────────────┘
     │
     ↓
┌─────────────────────────────────┐
│ 6. GitHub 回调:                 │
│    /api/oidc/callback?          │
│      code=xxx&state=xxx          │
└────┬────────────────────────────┘
     │
     ↓
┌─────────────────────────────────┐
│ 7. rustdesk-api:                │
│    - 验证 state                  │
│    - 使用 code 交换 token       │
│    - 获取用户信息                │
│    - 查询/创建本地用户           │
└────┬────────────────────────────┘
     │
     ↓
┌─────────────────────────────────┐
│ 8. 客户端轮询到结果:            │
│    - 成功: 返回 access_token    │
│    - 失败: 返回错误信息         │
└────┬────────────────────────────┘
     │
     ↓
┌─────────┐
│  结束   │
└─────────┘
```

### 详细步骤

#### 步骤 1: 发起认证

客户端调用接口：
```http
POST /api/oidc/auth
Content-Type: application/json

{
  "op": "github",
  "action": "login",
  "device_id": "device-123",
  "device_os": "Windows"
}
```

响应：
```json
{
  "code": "abc123def456",
  "url": "https://github.com/login/oauth/authorize?client_id=xxx&state=yyy&..."
}
```

#### 步骤 2: 轮询认证状态

客户端保存 `code` 并开始轮询：
```http
GET /api/oidc/auth-query?code=abc123def456
```

未完成时返回：
```json
{
  "status": "pending"
}
```

#### 步骤 3: 用户授权

用户在浏览器中打开 `url`，在 GitHub 上登录并授权。

#### 步骤 4: OAuth 回调

GitHub 将用户重定向到：
```
http://your-domain/api/oidc/callback?code=xxx&state=yyy
```

rustdesk-api 处理回调：
1. 验证 `state` 参数
2. 使用 `code` 交换 `access_token`
3. 使用 `access_token` 获取用户信息
4. 根据 `openid` 查询或创建本地用户
5. 更新缓存状态

#### 步骤 5: 获取结果

客户端轮询获取结果：
```http
GET /api/oidc/auth-query?code=abc123def456
```

成功时返回：
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "type": "access_token",
  "user": {
    "name": "username",
    "email": "user@example.com",
    ...
  }
}
```

---

## 配置指南

### 配置文件方式

编辑 `conf/config.yaml`:

```yaml
oauth:
  github:
    enabled: true
    client-id: "your-github-client-id"
    client-secret: "your-github-client-secret"
    scopes: "read:user user:email"
    auto-register: true

  google:
    enabled: true
    client-id: "your-google-client-id"
    client-secret: "your-google-client-secret"
    scopes: "openid profile email"
    auto-register: true
```

### 数据库配置方式

通过管理后台界面配置 OAuth 提供商：

1. 登录管理后台
2. 进入 "OAuth 管理"
3. 点击 "添加 OAuth 提供商"
4. 填写配置信息
5. 保存

**数据库配置优先级高于配置文件**。

### 配置参数说明

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `enabled` | bool | 否 | 是否启用，默认 false |
| `oauth-type` | string | 是 | OAuth 类型：github/google/oidc/gitee 等 |
| `client-id` | string | 是 | OAuth Client ID |
| `client-secret` | string | 是 | OAuth Client Secret |
| `scopes` | string | 否 | OAuth scopes，多个用空格分隔 |
| `issuer` | string | OIDC必填 | OIDC Issuer URL |
| `auto-register` | bool | 否 | 是否自动注册，默认 false |
| `pkce-enable` | bool | 否 | 是否启用 PKCE，默认 false |
| `pkce-method` | string | 否 | PKCE 方法：S256/plain，默认 S256 |

### 安全建议

1. **使用 HTTPS**: 生产环境必须使用 HTTPS
2. **启用 PKCE**: 增强安全性，防止授权码拦截攻击
3. **验证回调 URL**: 在 OAuth 提供商配置中设置正确的回调 URL
4. **限制 Scopes**: 只请求必要的权限
5. **保密 Client Secret**: 不要将 Client Secret 提交到代码仓库

---

## API 接口说明

### 1. 发起 OAuth 认证

```http
POST /api/oidc/auth
```

**请求体**:
```json
{
  "op": "github",
  "action": "login",
  "device_id": "device-123",
  "device_os": "Windows"
}
```

**响应**:
```json
{
  "code": "abc123",
  "url": "https://github.com/login/oauth/authorize?..."
}
```

### 2. 查询认证状态

```http
GET /api/oidc/auth-query?code=abc123
```

**响应（未完成）**:
```json
{
  "status": "pending"
}
```

**响应（成功）**:
```json
{
  "access_token": "eyJhbGc...",
  "type": "access_token",
  "user": {...}
}
```

**响应（失败）**:
```json
{
  "error": "认证失败: 用户拒绝授权"
}
```

### 3. OAuth 回调

```http
GET /api/oidc/callback?code=xxx&state=yyy
```

浏览器会自动重定向到成功/失败页面。

---

## 常见问题

### Q1: OAuth 认证一直显示 "pending"？

**可能原因**:
1. 用户未完成授权
2. 回调 URL 配置错误
3. 网络问题

**解决方法**:
1. 检查用户是否打开了授权 URL
2. 检查 OAuth 提供商的回调 URL 配置
3. 查看服务器日志

### Q2: 提示 "invalid_client"？

**原因**: Client ID 或 Client Secret 错误

**解决方法**: 检查配置，确保 Client ID 和 Secret 正确

### Q3: 提示 "redirect_uri_mismatch"？

**原因**: 回调 URL 不匹配

**解决方法**:
1. 检查 OAuth 提供商配置的回调 URL
2. 确保回调 URL 与实际访问的 URL 一致（包括协议、域名、端口）

### Q4: 用户授权后无法自动登录？

**可能原因**:
1. `auto_register` 未启用
2. 用户邮箱与现有用户冲突

**解决方法**:
1. 启用 `auto_register`
2. 手动绑定 OAuth 账号到现有用户

### Q5: 如何测试 OAuth 配置？

1. 使用管理后台的 OAuth 管理界面
2. 点击 "测试" 按钮
3. 在浏览器中完成授权流程
4. 查看测试结果

### Q6: 支持多个相同类型的 OAuth 提供商吗？

**支持**。使用不同的 `op` 标识即可：

```yaml
oauth:
  github-org1:
    oauth-type: "github"
    client-id: "..."

  github-org2:
    oauth-type: "github"
    client-id: "..."
```

### Q7: 如何禁用某个 OAuth 提供商？

**方法 1**: 配置文件中设置 `enabled: false`
**方法 2**: 数据库中删除或禁用该提供商

### Q8: OAuth 认证是否支持代理？

**支持**。在 `config.yaml` 中配置：

```yaml
proxy:
  enable: true
  host: "http://127.0.0.1:1080"
```

### Q9: PKCE 是什么？是否必须启用？

**PKCE** (Proof Key for Code Exchange) 是 OAuth 2.0 的安全扩展，防止授权码拦截攻击。

- **移动应用**: 强烈建议启用
- **Web应用**: 推荐启用
- **服务端应用**: 可选

---

## 故障排查

### 查看日志

OAuth 相关日志会记录在应用日志中，搜索关键词：
- `OAuth: Begin auth`
- `OAuth: Callback`
- `OAuth: Token exchange failed`

### 调试模式

设置环境变量启用调试：
```bash
export LOG_LEVEL=debug
```

### 常见错误码

| 错误码 | 说明 | 解决方法 |
|--------|------|----------|
| `invalid_request` | 请求参数错误 | 检查请求参数 |
| `invalid_client` | Client ID/Secret 错误 | 检查配置 |
| `invalid_grant` | 授权码无效或已过期 | 重新发起认证 |
| `unauthorized_client` | 客户端未授权 | 检查 OAuth 提供商配置 |
| `access_denied` | 用户拒绝授权 | 用户操作，无需处理 |

---

## 参考资源

- [OAuth 2.0 RFC 6749](https://tools.ietf.org/html/rfc6749)
- [OpenID Connect Core](https://openid.net/specs/openid-connect-core-1_0.html)
- [PKCE RFC 7636](https://tools.ietf.org/html/rfc7636)
- [GitHub OAuth 文档](https://docs.github.com/en/developers/apps/building-oauth-apps)
- [Google OAuth 文档](https://developers.google.com/identity/protocols/oauth2)

---

**更新日期**: 2026-01-08
**维护者**: RustDesk API Team
