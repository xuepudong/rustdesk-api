package oauth

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"

	"github.com/lejianwen/rustdesk-api/v2/model"
	"golang.org/x/oauth2"
)

// BaseProvider 基础 OAuth Provider 实现
// 提供通用的实现，具体的 Provider 可以组合使用
type BaseProvider struct {
	config       *ProviderConfig
	oauth2Config *oauth2.Config
	httpClient   *http.Client
}

// NewBaseProvider 创建基础 Provider
func NewBaseProvider(config *ProviderConfig) *BaseProvider {
	oauth2Config := &oauth2.Config{
		ClientID:     config.ClientID,
		ClientSecret: config.ClientSecret,
		Scopes:       config.Scopes,
		RedirectURL:  config.RedirectURL,
		Endpoint:     config.Endpoints,
	}

	return &BaseProvider{
		config:       config,
		oauth2Config: oauth2Config,
		httpClient:   http.DefaultClient,
	}
}

// GetName 获取提供商名称
func (p *BaseProvider) GetName() string {
	return p.config.Name
}

// GetType 获取 OAuth 类型
func (p *BaseProvider) GetType() string {
	return p.config.Type
}

// GetAuthURL 生成授权 URL
func (p *BaseProvider) GetAuthURL(state, verifier, nonce string) string {
	opts := []oauth2.AuthCodeOption{oauth2.AccessTypeOffline}

	// PKCE 支持
	if p.config.PKCEEnabled && verifier != "" {
		if p.config.PKCEMethod == "S256" {
			opts = append(opts, oauth2.S256ChallengeOption(verifier))
		} else {
			opts = append(opts, oauth2.VerifierOption(verifier))
		}
	}

	// Nonce 支持（OIDC）
	if nonce != "" {
		opts = append(opts, oauth2.SetAuthURLParam("nonce", nonce))
	}

	return p.oauth2Config.AuthCodeURL(state, opts...)
}

// GetConfig 获取 OAuth2 配置
func (p *BaseProvider) GetConfig() *oauth2.Config {
	return p.oauth2Config
}

// GetUserInfo 获取用户信息（基础实现，子类可以覆盖）
// 这是一个通用实现，假设 UserInfo 端点返回标准的 JSON 格式
func (p *BaseProvider) GetUserInfo(ctx context.Context, token *oauth2.Token) (*model.OauthUser, error) {
	return nil, errors.New("GetUserInfo not implemented for this provider")
}

// SupportsFeature 检查是否支持特定功能
func (p *BaseProvider) SupportsFeature(feature string) bool {
	switch feature {
	case FeaturePKCE:
		return p.config.PKCEEnabled
	case FeatureRefreshToken:
		return true // 大部分 OAuth 提供商都支持
	default:
		return false
	}
}

// Validate 验证配置
func (p *BaseProvider) Validate() error {
	if p.config.ClientID == "" {
		return errors.New("client_id is required")
	}
	if p.config.ClientSecret == "" {
		return errors.New("client_secret is required")
	}
	if p.config.RedirectURL == "" {
		return errors.New("redirect_url is required")
	}
	if len(p.config.Scopes) == 0 {
		return errors.New("at least one scope is required")
	}
	return nil
}

// GetIssuer 获取 Issuer URL（默认返回空字符串）
func (p *BaseProvider) GetIssuer() string {
	return p.config.Issuer
}

// GetScopes 获取 Scopes
func (p *BaseProvider) GetScopes() []string {
	return p.config.Scopes
}

// SupportsPKCE 是否支持 PKCE
func (p *BaseProvider) SupportsPKCE() bool {
	return p.config.PKCEEnabled
}

// GetPKCEMethod 获取 PKCE 方法
func (p *BaseProvider) GetPKCEMethod() string {
	if p.config.PKCEMethod == "" {
		return "S256" // 默认使用 S256
	}
	return p.config.PKCEMethod
}

// SetHTTPClient 设置自定义 HTTP 客户端（用于代理等）
func (p *BaseProvider) SetHTTPClient(client *http.Client) {
	p.httpClient = client
	p.oauth2Config.Client = client
}

// FetchUserInfo 通用的获取用户信息方法
// endpoint: UserInfo API 端点
// token: OAuth2 访问令牌
// result: 用于接收 JSON 响应的结构体指针
func (p *BaseProvider) FetchUserInfo(ctx context.Context, endpoint string, token *oauth2.Token, result interface{}) error {
	req, err := http.NewRequestWithContext(ctx, "GET", endpoint, nil)
	if err != nil {
		return fmt.Errorf("failed to create request: %w", err)
	}

	// 设置 Authorization Header
	req.Header.Set("Authorization", "Bearer "+token.AccessToken)
	req.Header.Set("Accept", "application/json")

	// 发送请求
	resp, err := p.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("failed to fetch user info: %w", err)
	}
	defer resp.Body.Close()

	// 检查状态码
	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("failed to fetch user info: status=%d, body=%s", resp.StatusCode, string(body))
	}

	// 解析 JSON 响应
	if err := json.NewDecoder(resp.Body).Decode(result); err != nil {
		return fmt.Errorf("failed to decode user info: %w", err)
	}

	return nil
}

// ExchangeToken 交换授权码为访问令牌
func (p *BaseProvider) ExchangeToken(ctx context.Context, code string, verifier string) (*oauth2.Token, error) {
	opts := []oauth2.AuthCodeOption{}

	// PKCE 支持
	if p.config.PKCEEnabled && verifier != "" {
		opts = append(opts, oauth2.VerifierOption(verifier))
	}

	token, err := p.oauth2Config.Exchange(ctx, code, opts...)
	if err != nil {
		return nil, fmt.Errorf("failed to exchange token: %w", err)
	}

	return token, nil
}

// GetProviderConfig 获取配置
func (p *BaseProvider) GetProviderConfig() *ProviderConfig {
	return p.config
}

// UpdateConfig 更新配置
func (p *BaseProvider) UpdateConfig(config *ProviderConfig) {
	p.config = config
	p.oauth2Config.ClientID = config.ClientID
	p.oauth2Config.ClientSecret = config.ClientSecret
	p.oauth2Config.Scopes = config.Scopes
	p.oauth2Config.RedirectURL = config.RedirectURL
	p.oauth2Config.Endpoint = config.Endpoints
}
