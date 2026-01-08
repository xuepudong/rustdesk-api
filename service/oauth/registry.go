package oauth

import (
	"errors"
	"fmt"
	"sync"
)

// ProviderRegistry Provider 注册表
// 用于管理所有已注册的 OAuth 提供商
type ProviderRegistry struct {
	providers map[string]OAuthProvider // key: provider name (如 "github", "google")
	mu        sync.RWMutex             // 读写锁，保证并发安全
}

// NewProviderRegistry 创建新的注册表
func NewProviderRegistry() *ProviderRegistry {
	return &ProviderRegistry{
		providers: make(map[string]OAuthProvider),
	}
}

// Register 注册 OAuth 提供商
// name: 提供商标识名称（如 "github", "google", "gitee"）
// provider: OAuthProvider 接口实现
// 如果 name 已存在，会返回错误
func (r *ProviderRegistry) Register(name string, provider OAuthProvider) error {
	if name == "" {
		return errors.New("provider name cannot be empty")
	}

	if provider == nil {
		return errors.New("provider cannot be nil")
	}

	// 验证 Provider 配置
	if err := provider.Validate(); err != nil {
		return fmt.Errorf("invalid provider config: %w", err)
	}

	r.mu.Lock()
	defer r.mu.Unlock()

	// 检查是否已注册
	if _, exists := r.providers[name]; exists {
		return fmt.Errorf("provider '%s' is already registered", name)
	}

	r.providers[name] = provider
	return nil
}

// RegisterOrReplace 注册或替换 OAuth 提供商
// 如果 name 已存在，会替换为新的 provider
func (r *ProviderRegistry) RegisterOrReplace(name string, provider OAuthProvider) error {
	if name == "" {
		return errors.New("provider name cannot be empty")
	}

	if provider == nil {
		return errors.New("provider cannot be nil")
	}

	// 验证 Provider 配置
	if err := provider.Validate(); err != nil {
		return fmt.Errorf("invalid provider config: %w", err)
	}

	r.mu.Lock()
	defer r.mu.Unlock()

	r.providers[name] = provider
	return nil
}

// Get 获取指定的 OAuth 提供商
// name: 提供商标识名称
// 如果 name 不存在，返回 nil 和错误
func (r *ProviderRegistry) Get(name string) (OAuthProvider, error) {
	if name == "" {
		return nil, errors.New("provider name cannot be empty")
	}

	r.mu.RLock()
	defer r.mu.RUnlock()

	provider, exists := r.providers[name]
	if !exists {
		return nil, fmt.Errorf("provider '%s' not found", name)
	}

	return provider, nil
}

// Unregister 注销指定的 OAuth 提供商
// name: 提供商标识名称
// 如果 name 不存在，返回错误
func (r *ProviderRegistry) Unregister(name string) error {
	if name == "" {
		return errors.New("provider name cannot be empty")
	}

	r.mu.Lock()
	defer r.mu.Unlock()

	if _, exists := r.providers[name]; !exists {
		return fmt.Errorf("provider '%s' not found", name)
	}

	delete(r.providers, name)
	return nil
}

// List 列出所有已注册的提供商名称
// 返回提供商名称列表
func (r *ProviderRegistry) List() []string {
	r.mu.RLock()
	defer r.mu.RUnlock()

	names := make([]string, 0, len(r.providers))
	for name := range r.providers {
		names = append(names, name)
	}

	return names
}

// Count 获取已注册的提供商数量
func (r *ProviderRegistry) Count() int {
	r.mu.RLock()
	defer r.mu.RUnlock()

	return len(r.providers)
}

// Exists 检查指定的提供商是否已注册
func (r *ProviderRegistry) Exists(name string) bool {
	r.mu.RLock()
	defer r.mu.RUnlock()

	_, exists := r.providers[name]
	return exists
}

// GetAll 获取所有已注册的提供商
// 返回 map[name]provider
func (r *ProviderRegistry) GetAll() map[string]OAuthProvider {
	r.mu.RLock()
	defer r.mu.RUnlock()

	// 复制一份，避免外部修改
	providers := make(map[string]OAuthProvider, len(r.providers))
	for name, provider := range r.providers {
		providers[name] = provider
	}

	return providers
}

// Clear 清空所有已注册的提供商
func (r *ProviderRegistry) Clear() {
	r.mu.Lock()
	defer r.mu.Unlock()

	r.providers = make(map[string]OAuthProvider)
}

// GetByType 根据类型获取所有提供商
// oauthType: OAuth 类型（如 "github", "oidc"）
// 返回符合条件的提供商列表
func (r *ProviderRegistry) GetByType(oauthType string) []OAuthProvider {
	r.mu.RLock()
	defer r.mu.RUnlock()

	providers := make([]OAuthProvider, 0)
	for _, provider := range r.providers {
		if provider.GetType() == oauthType {
			providers = append(providers, provider)
		}
	}

	return providers
}

// ValidateAll 验证所有已注册的提供商配置
// 返回验证失败的提供商列表
func (r *ProviderRegistry) ValidateAll() map[string]error {
	r.mu.RLock()
	defer r.mu.RUnlock()

	errors := make(map[string]error)
	for name, provider := range r.providers {
		if err := provider.Validate(); err != nil {
			errors[name] = err
		}
	}

	return errors
}

// 全局默认注册表
var defaultRegistry = NewProviderRegistry()

// GetDefaultRegistry 获取全局默认注册表
func GetDefaultRegistry() *ProviderRegistry {
	return defaultRegistry
}

// RegisterProvider 向全局注册表注册提供商
func RegisterProvider(name string, provider OAuthProvider) error {
	return defaultRegistry.Register(name, provider)
}

// RegisterOrReplaceProvider 向全局注册表注册或替换提供商
func RegisterOrReplaceProvider(name string, provider OAuthProvider) error {
	return defaultRegistry.RegisterOrReplace(name, provider)
}

// GetProvider 从全局注册表获取提供商
func GetProvider(name string) (OAuthProvider, error) {
	return defaultRegistry.Get(name)
}

// ListProviders 列出全局注册表中的所有提供商
func ListProviders() []string {
	return defaultRegistry.List()
}

// UnregisterProvider 从全局注册表注销提供商
func UnregisterProvider(name string) error {
	return defaultRegistry.Unregister(name)
}
