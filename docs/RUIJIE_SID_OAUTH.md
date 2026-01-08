# 锐捷 SourceID OAuth 2.0 对接指南

## 概述

锐捷 SourceID（SID）是锐捷网络提供的统一身份认证平台，支持标准的 OAuth 2.0 协议。本文档介绍如何在 RustDesk API 中配置和使用锐捷 SID 进行 OAuth 认证。

## 功能特性

- ✅ 支持 OAuth 2.0 授权码模式（Authorization Code）
- ✅ 支持访问令牌（Access Token）和刷新令牌（Refresh Token）
- ✅ 自动提取用户信息（姓名、学号、邮箱、手机号等）
- ✅ 支持公有云和私有部署实例
- ✅ 支持自动注册和用户绑定

## 前提条件

1. **获取应用凭证**
   - 联系锐捷 SID 管理员注册应用
   - 获取 `client_id`（应用账号）和 `client_secret`（应用密钥）
   - 配置回调地址：`https://your-domain.com/api/oidc/callback`

2. **确定 SID 服务器地址**
   - 公有云：`https://sourceid.ruishan.cc` 或 `https://sid.rghall.com.cn`
   - 私有部署：根据实际部署地址配置

## 配置步骤

### 1. 通过管理后台配置

登录 RustDesk API 管理后台，进入 **OAuth 管理** 页面：

1. 点击"新增 OAuth 配置"
2. 填写以下信息：
   - **名称/Op**: 自定义标识符（如 `ruijie_sid`）
   - **OAuth 类型**: 选择 `ruijie_sid`
   - **Client ID**: 锐捷 SID 分配的应用账号
   - **Client Secret**: 锐捷 SID 分配的应用密钥
   - **Issuer**: 锐捷 SID 服务器地址（如 `https://sourceid.ruishan.cc`）
   - **Scopes**: 留空（锐捷 SID 的 scope 是可选的）
   - **自动注册**: 是否允许新用户自动注册
   - **PKCE**: 不支持，保持关闭

3. 点击"保存"

### 2. 通��数据库配置

如果需要通过数据库直接配置，插入以下记录到 `oauths` 表：

```sql
INSERT INTO `oauths` (
    `op`,
    `oauth_type`,
    `client_id`,
    `client_secret`,
    `issuer`,
    `scopes`,
    `auto_register`,
    `pkce_enable`,
    `pkce_method`,
    `created_at`,
    `updated_at`
) VALUES (
    'ruijie_sid',                    -- Op 标识符
    'ruijie_sid',                    -- OAuth 类型
    'your_client_id',                -- 应用账号
    'your_client_secret',            -- 应用密钥
    'https://sourceid.ruishan.cc',   -- SID 服务器地址
    '',                              -- Scopes（留空）
    1,                               -- 自动注册：1=是，0=否
    0,                               -- PKCE：0=关闭
    'S256',                          -- PKCE 方法（不使用）
    NOW(),
    NOW()
);
```

## OAuth 端点

锐捷 SID OAuth 2.0 端点：

| 端点 | URL | 说明 |
|------|-----|------|
| 授权端点 | `/oauth2.0/authorize` | 获取授权码 |
| 令牌端点 | `/oauth2.0/accessToken` | 交换访问令牌 |
| 用户信息端点 | `/oauth2.0/profile` | 获取用户信息 |
| 令牌验证端点 | `/oauth2.0/introspect` | 验证令牌有效性（可选） |

完整 URL 示例（公有云）：
- 授权：`https://sourceid.ruishan.cc/oauth2.0/authorize`
- 令牌：`https://sourceid.ruishan.cc/oauth2.0/accessToken`
- 用户信息：`https://sourceid.ruishan.cc/oauth2.0/profile`

## 用户信息映射

锐捷 SID 返回的用户信息结构：

```json
{
    "id": "test003",
    "attributes": {
        "objectId": "5cf7849a3350660001256e28",
        "SFLBDM": "02",
        "TEL": "18819470607",
        "XB": "男性",
        "XH": "test003",
        "XM": "傅光晨",
        "Email": "test003@example.com",
        "DZYX": "test003@example.com"
    }
}
```

字段映射到 RustDesk 用户：

| 锐捷 SID 字段 | RustDesk 字段 | 说明 |
|--------------|---------------|------|
| `id` | `uuid`, `username` | 用户唯一标识 |
| `attributes.XM` | `nickname` | 姓名 |
| `attributes.Email` / `attributes.DZYX` | `email` | 邮箱地址 |
| `attributes.TEL` | `email` (备用) | 手机号，当无邮箱时使用 `{tel}@ruijie.sid` |
| `attributes.XH` | - | 学号（存储在 attributes 中） |
| `attributes.XB` | - | 性别 |

## 使用流程

### 1. 客户端发起登录

客户端调用 RustDesk API 的 OAuth 登录接口：

```bash
GET /api/oidc/login?op=ruijie_sid&action=login&id={device_id}&uuid={device_uuid}&name={device_name}
```

参数说明：
- `op`: OAuth 提供商标识（配置时填写的 op 值）
- `action`: 操作类型（`login` 或 `bind`）
- `id`: 设备 ID
- `uuid`: 设备 UUID
- `name`: 设备名称

### 2. 用户授权

API 返回锐捷 SID 授权页面 URL，用户点击链接进入授权页面：

```
https://sourceid.ruishan.cc/oauth2.0/authorize?
    response_type=code
    &client_id={client_id}
    &redirect_uri=https://your-domain.com/api/oidc/callback
    &state={state}
```

### 3. 授权回调

用户完成授权后，锐捷 SID 重定向回 RustDesk API：

```
https://your-domain.com/api/oidc/callback?code={authorization_code}&state={state}
```

API 自动：
1. 使用 code 交换 access_token
2. 使用 access_token 获取用户信息
3. 创建或绑定 RustDesk 用户
4. 返回登录成功页面

### 4. 登录成功

用户完成登录，客户端可以查询登录状态：

```bash
GET /api/oidc/query?id={device_id}
```

返回示例：
```json
{
    "access_token": "xxx",
    "user": {
        "name": "傅光晨",
        "email": "test003@example.com"
    }
}
```

## 高级配置

### 私有部署配置

如果使用私有部署的锐捷 SID，在 **Issuer** 字段填写实际部署地址：

```
https://sid.your-company.com
```

API 会自动拼接 OAuth 端点：
- 授权：`https://sid.your-company.com/oauth2.0/authorize`
- 令牌：`https://sid.your-company.com/oauth2.0/accessToken`
- 用户信息：`https://sid.your-company.com/oauth2.0/profile`

### Scopes 配置

锐捷 SID 的 `scopes` 参数是可选的：
- **留空**：使用服务端默认配置（推荐）
- **自定义**：填写特定权限（如 `profile,email`）

## 故障排查

### 1. "ConfigNotFound" 错误

**原因**：找不到 OAuth 配置

**解决方法**：
- 检查数据库中是否存在 op 为 `ruijie_sid` 的记录
- 确认 `client_id` 和 `client_secret` 不为空

### 2. "Token exchange failed" 错误

**原因**：无法交换访问令牌

**解决方法**：
- 检查 `client_id` 和 `client_secret` 是否正确
- 确认回调地址与锐捷 SID 中注册的一致
- 检查网络连接和 Issuer 地址是否正确

### 3. "DecodeOauthUserInfoError" 错误

**原因**：无法解析用户信息

**解决方法**：
- 检查锐捷 SID 返回的用户信息格式是否正确
- 确认 access_token 有效

### 4. 用户邮箱为空

**原因**：锐捷 SID 未返回 Email 字段

**解决方法**：
- API 会自动使用手机号构造邮箱：`{tel}@ruijie.sid`
- 如果手机号也为空，使用用户名：`{username}@ruijie.sid`

## 安全建议

1. **使用 HTTPS**
   - 生产环境必须使用 HTTPS 部署
   - 确保回调地址使用 HTTPS

2. **保护密钥**
   - `client_secret` 必须保密
   - 不要在客户端代码中硬编码密钥
   - 定期更新密钥

3. **验证回调**
   - API 会自动验证 `state` 参数防止 CSRF 攻击
   - 确保回调地址在锐捷 SID 中正确注册

4. **令牌管理**
   - 访问令牌有效期默认 28800 秒（8 小时）
   - 使用 refresh_token 自动刷新令牌
   - 令牌应安全存储，不要泄露

## 参考资料

- [锐捷 SID OAuth 2.0 开发文档](OAuth2.0.html)
- [OAuth 2.0 RFC 6749](https://datatracker.ietf.org/doc/html/rfc6749)
- [RustDesk API OAuth 流程说明](OAUTH_FLOW.md)

## 技术支持

如有问题，请联系：
- RustDesk API：https://github.com/lejianwen/rustdesk-api/issues
- 锐捷 SID：https://sourceid.ruishan.cc/

---

最后更新：2026-01-08
