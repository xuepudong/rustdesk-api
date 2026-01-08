# Swagger API 文档编写规范

## 目录
- [概述](#概述)
- [标准模板](#标准模板)
- [注释规范](#注释规范)
- [示例](#示例)
- [常见问题](#常见问题)

---

## 概述

本文档定义了 rustdesk-api 项目的 Swagger API 文档编写规范，确保所有 API 文档的一致性和完整性。

### 使用工具
- **swaggo/swag**: Swagger 文档生成工具
- **gin-swagger**: Gin 框架的 Swagger 集成

### 文档生成命令
```bash
# 生成 API 文档
swag init --parseDependency --parseInternal --instanceName api -o docs/api

# 生成 Admin 文档
swag init --parseDependency --parseInternal --instanceName admin -o docs/admin
```

---

## 标准模板

### 基础模板

```go
// MethodName API功能简述
// @Tags 模块名称
// @Summary API功能简述
// @Description 详细的功能描述，包括业务场景和注意事项
// @Accept  json
// @Produce  json
// @Param param_name query/path/body type required "参数说明" Enums(val1,val2) example(example_value)
// @Success 200 {object} response.Response{data=model.DataType} "成功响应说明"
// @Failure 400 {object} response.ErrorResponse "参数错误"
// @Failure 401 {object} response.ErrorResponse "未授权"
// @Failure 403 {object} response.ErrorResponse "无权限"
// @Failure 404 {object} response.ErrorResponse "资源不存在"
// @Failure 500 {object} response.ErrorResponse "服务器错误"
// @Router /path [method]
// @Security BearerAuth
```

### 需要认证的 API

```go
// @Router /api/user/info [get]
// @Security BearerAuth
```

### 无需认证的 API

```go
// @Router /api/login [post]
// (不添加 @Security 标记)
```

---

## 注释规范

### 1. Tags (分组)

**规范**: 使用清晰的模块名称，首字母大写

**示例**:
```go
// @Tags 用户管理
// @Tags 设备管理
// @Tags OAuth认证
// @Tags 地址簿
```

**不推荐**:
```go
// @Tags user  // 使用中文
// @Tags users_api  // 使用下划线
```

### 2. Summary (简述)

**规范**:
- 简短描述（10字以内）
- 使用动词开头
- 不使用标点符号

**示例**:
```go
// @Summary 获取用户信息
// @Summary 创建新用户
// @Summary 删除设备
```

**不推荐**:
```go
// @Summary 这个API用来获取用户的详细信息。  // 太长且有标点
// @Summary User Info  // 使用英文
```

### 3. Description (详细描述)

**规范**:
- 详细说明 API 的功能和用途
- 包含业务场景说明
- 说明特殊注意事项
- 可以多行

**示例**:
```go
// @Description 获取当前登录用户的详细信息，包括用户名、邮箱、权限等。
// @Description 此接口需要 Bearer Token 认证。
// @Description 返回的用户信息会根据用户权限有所不同。
```

### 4. Accept & Produce (内容类型)

**规范**: 标准化内容类型

**常用配置**:
```go
// @Accept  json
// @Produce  json
```

**上传文件**:
```go
// @Accept  multipart/form-data
// @Produce  json
```

### 5. Param (参数)

#### 5.1 路径参数 (path)

```go
// @Param id path int true "用户ID" example(1)
// @Param uuid path string true "设备UUID" example("abc-123-def")
```

#### 5.2 查询参数 (query)

```go
// @Param page query int false "页码" default(1) example(1)
// @Param pageSize query int false "每页数量" default(10) example(10)
// @Param keyword query string false "搜索关键词" example("test")
// @Param status query int false "状态" Enums(0, 1) example(1)
```

#### 5.3 请求体参数 (body)

```go
// @Param body body request.LoginForm true "登录表单"
// @Param body body request.UserCreateForm true "用户创建表单"
```

#### 5.4 Header 参数

```go
// @Param Authorization header string true "Bearer Token" example("Bearer eyJhbGc...")
// @Param api-token header string true "API Token" example("abc123def456")
```

**参数格式说明**:
```go
// @Param name位置 类型 是否必填 "说明" 额外选项
//       ↑    ↑    ↑      ↑      ↑        ↑
//      名称  位置  类型  必填    描述   Enums/default/example
```

### 6. Success (成功响应)

**标准格式**:
```go
// @Success 200 {object} response.Response "成功"
// @Success 200 {object} response.Response{data=model.User} "返回用户信息"
// @Success 200 {object} response.Response{data=[]model.Peer} "返回设备列表"
```

**分页响应**:
```go
// @Success 200 {object} response.Response{data=response.PageData{list=[]model.User}} "返回用户分页列表"
```

### 7. Failure (错误响应)

**规范**: 列出所有可能的错误状态码

**标准错误响应**:
```go
// @Failure 400 {object} response.ErrorResponse "参数错误"
// @Failure 401 {object} response.ErrorResponse "未授权，需要登录"
// @Failure 403 {object} response.ErrorResponse "无权限访问"
// @Failure 404 {object} response.ErrorResponse "资源不存在"
// @Failure 500 {object} response.ErrorResponse "服务器内部错误"
```

### 8. Router (路由)

**格式**:
```go
// @Router /api/path [method]
```

**示例**:
```go
// @Router /api/user/info [get]
// @Router /api/user/create [post]
// @Router /api/user/update [put]
// @Router /api/user/delete/{id} [delete]
```

### 9. Security (安全认证)

**规范**: 需要认证的 API 必须添加 Security 标记

**类型**:
```go
// @Security BearerAuth     // Bearer Token 认证
// @Security ApiKeyAuth     // API Key 认证
```

**定义位置**: 在 `main.go` 中定义

```go
// @securityDefinitions.apikey BearerAuth
// @in header
// @name Authorization
// @description Bearer token 认证，格式: Bearer {token}

// @securityDefinitions.apikey ApiKeyAuth
// @in header
// @name api-token
// @description API Token 认证
```

---

## 示例

### 示例 1: 用户登录 API

```go
// Login 用户登录
// @Tags 认证
// @Summary 用户登录
// @Description 使用用户名和密码登录系统，返回 Access Token。
// @Description 支持普通账号密码登录和 LDAP 认证（如果启用）。
// @Description 如果登录失败次数过多，会要求输入验证码。
// @Accept  json
// @Produce  json
// @Param body body api.LoginForm true "登录表单"
// @Success 200 {object} apiResp.LoginRes "登录成功，返回 Access Token"
// @Failure 400 {object} response.ErrorResponse "参数错误"
// @Failure 401 {object} response.ErrorResponse "用户名或密码错误"
// @Failure 403 {object} response.ErrorResponse "用户已被禁用"
// @Failure 500 {object} response.ErrorResponse "服务器内部错误"
// @Router /api/login [post]
func (l *Login) Login(c *gin.Context) {
    // 实现代码...
}
```

### 示例 2: 获取用户信息 API (需要认证)

```go
// Info 获取用户信息
// @Tags 用户
// @Summary 获取当前用户信息
// @Description 获取当前登录用户的详细信息，包括用户名、邮箱、权限等。
// @Description 此接口需要 Bearer Token 认证。
// @Accept  json
// @Produce  json
// @Success 200 {object} response.Response{data=apiResp.UserPayload} "返回用户信息"
// @Failure 401 {object} response.ErrorResponse "未授权，Token 无效或已过期"
// @Failure 500 {object} response.ErrorResponse "服务器内部错误"
// @Router /api/user/info [get]
// @Security BearerAuth
func (u *User) Info(c *gin.Context) {
    // 实现代码...
}
```

### 示例 3: 用户列表 API (分页 + 查询)

```go
// List 获取用户列表
// @Tags 用户管理
// @Summary 获取用户列表
// @Description 分页获取用户列表，支持按用户名、邮箱搜索。
// @Description 仅管理员可访问此接口。
// @Accept  json
// @Produce  json
// @Param page query int false "页码" default(1) example(1)
// @Param pageSize query int false "每页数量" default(10) example(10)
// @Param keyword query string false "搜索关键词（用户名或邮箱）" example("admin")
// @Param status query int false "用户状态" Enums(0, 1) example(1)
// @Success 200 {object} response.Response{data=admin.UserListResponse} "返回用户分页列表"
// @Failure 400 {object} response.ErrorResponse "参数错误"
// @Failure 401 {object} response.ErrorResponse "未授权"
// @Failure 403 {object} response.ErrorResponse "无权限，仅管理员可访问"
// @Failure 500 {object} response.ErrorResponse "服务器内部错误"
// @Router /api/admin/user/list [get]
// @Security ApiKeyAuth
func (u *User) List(c *gin.Context) {
    // 实现代码...
}
```

### 示例 4: 创建用户 API

```go
// Create 创建用户
// @Tags 用户管理
// @Summary 创建新用户
// @Description 创建新用户账号，需要提供用户名、密码、邮箱等信息。
// @Description 用户名和邮箱不能重复。
// @Description 仅管理员可访问此接口。
// @Accept  json
// @Produce  json
// @Param body body admin.UserForm true "用户信息表单"
// @Success 200 {object} response.Response{data=model.User} "创建成功，返回用户信息"
// @Failure 400 {object} response.ErrorResponse "参数错误或用户名已存在"
// @Failure 401 {object} response.ErrorResponse "未授权"
// @Failure 403 {object} response.ErrorResponse "无权限，仅管理员可访问"
// @Failure 500 {object} response.ErrorResponse "服务器内部错误"
// @Router /api/admin/user/create [post]
// @Security ApiKeyAuth
func (u *User) Create(c *gin.Context) {
    // 实现代码...
}
```

### 示例 5: OAuth 认证 API

```go
// OidcAuth 发起 OAuth 认证
// @Tags OAuth认证
// @Summary 发起 OAuth 2.0 认证流程
// @Description 发起 OAuth 2.0 / OIDC 认证流程，返回授权 URL 和状态码。
// @Description 客户端需要保存 state 和 code_verifier (如果启用 PKCE)。
// @Description 用户在浏览器中访问授权 URL 完成认证后，会回调到指定的 callback URL。
// @Accept  json
// @Produce  json
// @Param body body api.OidcAuthForm true "OAuth 认证请求"
// @Success 200 {object} apiResp.OidcAuthResponse "返回授权 URL 和状态信息"
// @Failure 400 {object} response.ErrorResponse "参数错误或 OAuth 提供商不存在"
// @Failure 500 {object} response.ErrorResponse "服务器内部错误"
// @Router /api/oidc/auth [post]
func (o *Oauth) OidcAuth(c *gin.Context) {
    // 实现代码...
}
```

---

## 常见问题

### Q1: 如何处理嵌套对象的响应？

使用 `{...}` 语法：

```go
// @Success 200 {object} response.Response{data=model.User{groups=[]model.Group}} "返回用户及其所属群组"
```

### Q2: 如何标记可选参数？

使用 `false` 标记：

```go
// @Param keyword query string false "搜索关键词"  // 可选
// @Param page query int false "页码" default(1)   // 可选，有默认值
```

### Q3: 如何添加枚举值？

使用 `Enums(...)`：

```go
// @Param status query int false "状态" Enums(0, 1) example(1)
// @Param type query string false "类型" Enums(admin, user, guest) example("user")
```

### Q4: 如何标记数组返回？

使用 `[]` 语法：

```go
// @Success 200 {object} response.Response{data=[]model.User} "返回用户列表"
```

### Q5: 如何处理文件上传？

```go
// @Accept multipart/form-data
// @Param file formData file true "上传的文件"
// @Param name formData string true "文件名称"
```

### Q6: 如何隐藏某些 API（不生成文档）？

不添加 Swagger 注释即可，或者添加：

```go
// @deprecated
```

### Q7: 一个 API 有多个认证方式？

```go
// @Security BearerAuth
// @Security ApiKeyAuth
```

### Q8: 如何测试 Swagger 文档？

1. 启动项目
2. 访问 Swagger UI: `http://localhost:21114/swagger/index.html`
3. 测试各个 API 端点

---

## 文档生成流程

### 1. 编写 Swagger 注释
按照本规范在控制器方法上添加 Swagger 注释。

### 2. 生成文档
```bash
# Windows
scripts\generate-docs.bat

# Linux/Mac
./scripts/generate-docs.sh
```

### 3. 验证文档
启动项目，访问 Swagger UI 检查文档是否正确。

### 4. 提交代码
确保 `docs/api/` 和 `docs/admin/` 目录下的生成文件一起提交。

---

## 最佳实践

1. **保持一致性**: 所有 API 使用相同的注释风格
2. **完整性**: 确保包含所有必要的注释标签
3. **准确性**: Description 要准确描述 API 的功能和注意事项
4. **示例**: 尽可能提供参数示例
5. **错误处理**: 列出所有可能的错误响应
6. **及时更新**: API 修改后同步更新文档注释
7. **测试验证**: 生成文档后在 Swagger UI 中验证

---

## 参考资源

- [Swaggo 官方文档](https://github.com/swaggo/swag)
- [OpenAPI Specification](https://swagger.io/specification/)
- [Gin-Swagger](https://github.com/swaggo/gin-swagger)

---

**更新日期**: 2026-01-08
**维护者**: RustDesk API Team
