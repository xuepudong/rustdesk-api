package oauth

import (
	"context"

	"github.com/lejianwen/rustdesk-api/v2/model"
	"golang.org/x/oauth2"
)

// OAuthProvider 统一的 OAuth 提供商接口
// 所有 OAuth 提供商（GitHub, Google, OIDC, Gitee 等）都需要实现此接口
type OAuthProvider interface {
	// GetName 获取提供商标识名称（如 "github", "google", "gitee"）
	GetName() string

	// GetType 获取 OAuth 类型（如 "github", "google", "oidc", "gitee"）
	GetType() string

	// GetAuthURL 生成授权 URL
	// state: CSRF 防护令牌
	// verifier: PKCE code verifier (可选)
	// nonce: 防重放令牌 (OIDC 使用)
	// 返回完整的授权 URL
	GetAuthURL(state, verifier, nonce string) string

	// GetConfig 获取 OAuth2 配置
	// 返回 golang.org/x/oauth2 库使用的 Config 对象
	GetConfig() *oauth2.Config

	// GetUserInfo 获取用户信息
	// ctx: 上下文
	// token: OAuth2 访问令牌
	// 返回标准化的 OauthUser 对象
	GetUserInfo(ctx context.Context, token *oauth2.Token) (*model.OauthUser, error)

	// SupportsFeature 检查是否支持特定功能
	// feature: 功能名称（如 "pkce", "id_token", "refresh_token"）
	// 返回 true 表示支持，false 表示不支持
	SupportsFeature(feature string) bool

	// Validate 验证提供商配置是否有效
	// 返回 nil 表示配置有效，否则返回错误信息
	Validate() error

	// GetIssuer 获取 OIDC Issuer URL（仅 OIDC 提供商需要）
	// 对于非 OIDC 提供商，返回空字符串
	GetIssuer() string

	// GetScopes 获取 OAuth Scopes
	// 返回 scope 列表
	GetScopes() []string

	// SupportsPKCE 是否支持 PKCE
	SupportsPKCE() bool

	// GetPKCEMethod 获取 PKCE 方法（S256 或 plain）
	GetPKCEMethod() string
}

// ProviderConfig 统一的提供商配置结构
type ProviderConfig struct {
	Name         string   // 提供商标识名称
	Type         string   // OAuth 类型
	ClientID     string   // OAuth Client ID
	ClientSecret string   // OAuth Client Secret
	Scopes       []string // OAuth Scopes
	RedirectURL  string   // 回调 URL
	Issuer       string   // OIDC Issuer URL（仅 OIDC 需要）
	PKCEEnabled  bool     // 是否启用 PKCE
	PKCEMethod   string   // PKCE 方法（S256 或 plain）
	AutoRegister bool     // 是否自动注册
	Endpoints    oauth2.Endpoint // OAuth 端点配置
}

// Feature 支持的功能常量
const (
	FeaturePKCE         = "pkce"          // PKCE 支持
	FeatureIDToken      = "id_token"      // ID Token (OIDC)
	FeatureRefreshToken = "refresh_token" // Refresh Token
	FeatureNonce        = "nonce"         // Nonce 验证
	FeatureUserInfo     = "userinfo"      // UserInfo 端点
)
