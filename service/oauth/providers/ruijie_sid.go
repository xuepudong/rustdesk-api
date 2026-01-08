package providers

import (
	"context"
	"errors"
	"fmt"

	"github.com/lejianwen/rustdesk-api/v2/model"
	"github.com/lejianwen/rustdesk-api/v2/service/oauth"
	"golang.org/x/oauth2"
)

// RuijieSIDProvider 锐捷 SourceID OAuth Provider
// 支持锐捷统一身份认证平台 (https://sourceid.ruishan.cc/)
type RuijieSIDProvider struct {
	*oauth.BaseProvider
	baseURL string // 锐捷 SID 服务器地址，默认 https://sourceid.ruishan.cc
}

// RuijieSIDUserResponse 锐捷 SID 用户信息响应格式
// 参考文档: OAuth2.0认证demo示例
type RuijieSIDUserResponse struct {
	ID         string                 `json:"id"`         // 用户名/学号
	Attributes map[string]interface{} `json:"attributes"` // 用户属性列表
}

// NewRuijieSIDProvider 创建锐捷 SID Provider
// baseURL: 锐捷 SID 服务器地址，如 https://sourceid.ruishan.cc 或 https://sid.rghall.com.cn
// config: OAuth 配置（ClientID, ClientSecret, RedirectURL, Scopes）
func NewRuijieSIDProvider(baseURL string, config *oauth.ProviderConfig) (*RuijieSIDProvider, error) {
	if baseURL == "" {
		baseURL = "https://sourceid.ruishan.cc"
	}

	// 设置锐捷 SID 的 OAuth 端点
	config.Name = "ruijie_sid"
	config.Type = "ruijie_sid"
	config.Endpoints = oauth2.Endpoint{
		AuthURL:   baseURL + "/oauth2.0/authorize",
		TokenURL:  baseURL + "/oauth2.0/accessToken",
		AuthStyle: oauth2.AuthStyleInParams, // 锐捷 SID 使用 URL 参数方式
	}

	// 锐捷 SID 不支持 PKCE
	config.PKCEEnabled = false

	// 如果没有配置 Scopes，使用默认值
	if len(config.Scopes) == 0 {
		// 锐捷 SID 的 scope 是可选的，默认为空表示使用服务端配置
		config.Scopes = []string{}
	}

	baseProvider := oauth.NewBaseProvider(config)

	return &RuijieSIDProvider{
		BaseProvider: baseProvider,
		baseURL:      baseURL,
	}, nil
}

// GetUserInfo 获取锐捷 SID 用户信息
// 端点: /oauth2.0/profile
// 方法: GET 或 POST
// 参数: access_token
func (p *RuijieSIDProvider) GetUserInfo(ctx context.Context, token *oauth2.Token) (*model.OauthUser, error) {
	if token == nil || token.AccessToken == "" {
		return nil, errors.New("invalid token")
	}

	// 构造用户信息端点 URL
	profileURL := p.baseURL + "/oauth2.0/profile"

	// 调用基类的通用方法获取用户信息
	var sidUser RuijieSIDUserResponse
	if err := p.FetchUserInfo(ctx, profileURL, token, &sidUser); err != nil {
		return nil, fmt.Errorf("failed to fetch Ruijie SID user info: %w", err)
	}

	// 转换为标准 OauthUser 结构
	return p.convertToOAuthUser(&sidUser), nil
}

// convertToOAuthUser 将锐捷 SID 用户信息转换为标准格式
func (p *RuijieSIDProvider) convertToOAuthUser(sidUser *RuijieSIDUserResponse) *model.OauthUser {
	if sidUser == nil {
		return nil
	}

	user := &model.OauthUser{
		Uuid:     sidUser.ID, // 使用 id 作为唯一标识
		Username: sidUser.ID, // 使用 id 作为用户名
		Nickname: sidUser.ID, // 默认使用 id，后续可从 attributes 提取
		Email:    "",         // 需要从 attributes 提取
	}

	// 从 attributes 中提取常见字段
	if sidUser.Attributes != nil {
		// XM: 姓名
		if name, ok := sidUser.Attributes["XM"].(string); ok && name != "" {
			user.Nickname = name
		}

		// Email 或 DZYX (电子邮箱)
		if email, ok := sidUser.Attributes["Email"].(string); ok && email != "" {
			user.Email = email
		} else if email, ok := sidUser.Attributes["DZYX"].(string); ok && email != "" {
			user.Email = email
		}

		// TEL: 手机号
		if tel, ok := sidUser.Attributes["TEL"].(string); ok && tel != "" {
			// 可以存储到扩展字段或作为备用联系方式
			user.Email = tel + "@ruijie.sid" // 如果没有邮箱，使用手机号构造
		}

		// 其他字段可以根据需要提取
		// XH: 学号
		// XB: 性别
		// SFLBDM: 身份类别代码
		// objectId: 对象ID
	}

	return user
}

// Validate 验证配置
func (p *RuijieSIDProvider) Validate() error {
	// 调用基类验证
	if err := p.BaseProvider.Validate(); err != nil {
		return err
	}

	// 验证 baseURL
	if p.baseURL == "" {
		return errors.New("baseURL is required for Ruijie SID provider")
	}

	return nil
}

// GetName 获取提供商名称
func (p *RuijieSIDProvider) GetName() string {
	return "Ruijie SID"
}

// GetType 获取提供商类型
func (p *RuijieSIDProvider) GetType() string {
	return "ruijie_sid"
}

// GetBaseURL 获取锐捷 SID 服务器地址
func (p *RuijieSIDProvider) GetBaseURL() string {
	return p.baseURL
}

// SetBaseURL 设置锐捷 SID 服务器地址
// 用于支持私有部署的锐捷 SID 实例
func (p *RuijieSIDProvider) SetBaseURL(baseURL string) {
	p.baseURL = baseURL
	// 更新端点配置
	config := p.GetProviderConfig()
	config.Endpoints = oauth2.Endpoint{
		AuthURL:   baseURL + "/oauth2.0/authorize",
		TokenURL:  baseURL + "/oauth2.0/accessToken",
		AuthStyle: oauth2.AuthStyleInParams,
	}
	p.UpdateConfig(config)
}

// SupportsFeature 检查是否支持特定功能
func (p *RuijieSIDProvider) SupportsFeature(feature string) bool {
	switch feature {
	case oauth.FeatureRefreshToken:
		return true // 锐捷 SID 支持 refresh_token
	case oauth.FeaturePKCE:
		return false // 锐捷 SID 不支持 PKCE
	case oauth.FeatureTokenIntrospection:
		return true // 锐捷 SID 支持 /oauth2.0/introspect 端点
	default:
		return false
	}
}

// IntrospectToken 验证访问令牌是否有效
// 端点: /oauth2.0/introspect
// 方法: POST
// 认证: Basic Auth (client_id:client_secret)
// 参数: token=<access_token>
func (p *RuijieSIDProvider) IntrospectToken(ctx context.Context, token string) (*TokenIntrospection, error) {
	// 注意：此方法需要使用 Basic Auth
	// 实现细节可以在需要时添加
	return nil, errors.New("token introspection not implemented yet")
}

// TokenIntrospection 令牌验证响应
type TokenIntrospection struct {
	Active               bool   `json:"active"`                // 令牌是否有效
	Sub                  string `json:"sub"`                   // 使用者
	Scope                string `json:"scope"`                 // 令牌授权的 scope
	Iat                  int64  `json:"iat"`                   // 令牌签发时间
	Exp                  int64  `json:"exp"`                   // 令牌过期时间
	UniqueSecurityName   string `json:"uniqueSecurityName"`    // 唯一安全名称
	TokenType            string `json:"tokenType"`             // 令牌类型
	Iss                  string `json:"iss"`                   // 签发者
	ClientID             string `json:"client_id"`             // 客户端 ID
	GrantType            string `json:"grant_type"`            // 授权类型
}
