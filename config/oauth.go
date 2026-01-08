package config

type GithubOauth struct {
	ClientId     string `mapstructure:"client-id"`
	ClientSecret string `mapstructure:"client-secret"`
}

type GoogleOauth struct {
	ClientId     string `mapstructure:"client-id"`
	ClientSecret string `mapstructure:"client-secret"`
}

type OidcOauth struct {
	Issuer       string `mapstructure:"issuer"`
	ClientId     string `mapstructure:"client-id"`
	ClientSecret string `mapstructure:"client-secret"`
}

type LinuxdoOauth struct {
	ClientId     string `mapstructure:"client-id"`
	ClientSecret string `mapstructure:"client-secret"`
}

type RuijieSIDOauth struct {
	BaseUrl      string `mapstructure:"base-url"`      // 锐捷 SID 服务器地址，如 https://sourceid.ruishan.cc 或 https://sid.rghall.com.cn
	ClientId     string `mapstructure:"client-id"`     // 应用账号
	ClientSecret string `mapstructure:"client-secret"` // 应用密钥
}
