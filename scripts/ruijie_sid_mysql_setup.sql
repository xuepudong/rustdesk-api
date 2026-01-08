-- ============================================
-- RustDesk API - 锐捷 SID OAuth 数据库对接方案
--
-- 说明:
-- 1. 此脚本包含完整的数据库表结构
-- 2. 包含锐捷 SID OAuth 配置示例
-- 3. 包含测试数据和维护脚本
--
-- 使用方法:
-- mysql -u your_username -p your_database < ruijie_sid_mysql_setup.sql
--
-- 版本: 2.0
-- 日期: 2026-01-08
-- ============================================

-- ============================================
-- 第一部分: 数据库和字符集设置
-- ============================================

-- 设置字符集（如果需要）
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ============================================
-- 第二部分: 检查和创建必要的表
-- ============================================

-- ---------------------------------------------
-- 1. users 表 - 用户主表
-- ---------------------------------------------
CREATE TABLE IF NOT EXISTS `users` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '用户ID',
  `username` varchar(255) NOT NULL DEFAULT '' COMMENT '用户名',
  `email` varchar(255) NOT NULL DEFAULT '' COMMENT '邮箱',
  `password` varchar(255) NOT NULL DEFAULT '' COMMENT '密码（加密）',
  `nickname` varchar(255) NOT NULL DEFAULT '' COMMENT '昵称',
  `avatar` varchar(255) NOT NULL DEFAULT '' COMMENT '头像URL',
  `group_id` bigint unsigned NOT NULL DEFAULT '0' COMMENT '用户组ID',
  `is_admin` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否管理员',
  `status` int NOT NULL DEFAULT '1' COMMENT '状态: 1=启用, 2=禁用',
  `remark` varchar(500) NOT NULL DEFAULT '' COMMENT '备注',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_users_username` (`username`),
  KEY `idx_users_email` (`email`),
  KEY `idx_users_group_id` (`group_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户表';

-- ---------------------------------------------
-- 2. oauths 表 - OAuth 配置表
-- ---------------------------------------------
CREATE TABLE IF NOT EXISTS `oauths` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT 'OAuth配置ID',
  `op` varchar(100) NOT NULL DEFAULT '' COMMENT 'OAuth提供商标识符',
  `oauth_type` varchar(50) NOT NULL DEFAULT '' COMMENT 'OAuth类型: github, google, oidc, linuxdo, ruijie_sid',
  `client_id` varchar(255) NOT NULL DEFAULT '' COMMENT '应用客户端ID',
  `client_secret` varchar(500) NOT NULL DEFAULT '' COMMENT '应用客户端密钥',
  `auto_register` tinyint(1) DEFAULT '1' COMMENT '是否允许自动注册: 1=是, 0=否',
  `scopes` text COMMENT '权限范围，逗号分隔',
  `issuer` varchar(500) NOT NULL DEFAULT '' COMMENT 'OIDC Issuer URL 或服务器基础地址',
  `pkce_enable` tinyint(1) DEFAULT '0' COMMENT '是否启用PKCE: 1=是, 0=否',
  `pkce_method` varchar(20) NOT NULL DEFAULT 'S256' COMMENT 'PKCE方法: S256, plain',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_oauths_op` (`op`),
  KEY `idx_oauths_oauth_type` (`oauth_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='OAuth配置表';

-- ---------------------------------------------
-- 3. user_thirds 表 - 第三方账号绑定表
-- ---------------------------------------------
CREATE TABLE IF NOT EXISTS `user_thirds` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '绑定记录ID',
  `user_id` bigint unsigned NOT NULL COMMENT '关联的用户ID',
  `open_id` varchar(255) NOT NULL DEFAULT '' COMMENT '第三方平台的OpenID',
  `name` varchar(255) NOT NULL DEFAULT '' COMMENT '第三方平台的用户名称',
  `username` varchar(255) NOT NULL DEFAULT '' COMMENT '第三方平台的用户名',
  `email` varchar(255) NOT NULL DEFAULT '' COMMENT '第三方平台的邮箱',
  `verified_email` tinyint(1) DEFAULT '0' COMMENT '邮箱是否已验证',
  `picture` varchar(500) NOT NULL DEFAULT '' COMMENT '第三方平台的头像URL',
  `union_id` varchar(255) NOT NULL DEFAULT '' COMMENT '联合ID（某些平台支持）',
  `third_type` varchar(50) NOT NULL DEFAULT '' COMMENT '第三方类型（已废弃，使用oauth_type）',
  `oauth_type` varchar(50) NOT NULL DEFAULT '' COMMENT 'OAuth类型',
  `op` varchar(100) NOT NULL DEFAULT '' COMMENT 'OAuth提供商标识符',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_thirds_user_id` (`user_id`),
  KEY `idx_user_thirds_open_id` (`open_id`),
  KEY `idx_user_thirds_op` (`op`),
  KEY `idx_user_thirds_oauth_type` (`oauth_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='第三方账号绑定表';

-- ---------------------------------------------
-- 4. user_tokens 表 - 用户令牌表
-- ---------------------------------------------
CREATE TABLE IF NOT EXISTS `user_tokens` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '令牌ID',
  `user_id` bigint unsigned NOT NULL COMMENT '关联的用户ID',
  `uuid` varchar(100) NOT NULL DEFAULT '' COMMENT '设备UUID',
  `token` varchar(255) NOT NULL DEFAULT '' COMMENT '访问令牌',
  `device_info` text COMMENT '设备信息（JSON格式）',
  `expired_at` timestamp NULL DEFAULT NULL COMMENT '过期时间',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_user_tokens_token` (`token`),
  KEY `idx_user_tokens_user_id` (`user_id`),
  KEY `idx_user_tokens_uuid` (`uuid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户令牌表';

-- ---------------------------------------------
-- 5. groups 表 - 用户组表
-- ---------------------------------------------
CREATE TABLE IF NOT EXISTS `groups` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '组ID',
  `name` varchar(255) NOT NULL DEFAULT '' COMMENT '组名称',
  `note` varchar(500) NOT NULL DEFAULT '' COMMENT '组描述',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_groups_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户组表';

-- ---------------------------------------------
-- 6. login_logs 表 - 登录日志表
-- ---------------------------------------------
CREATE TABLE IF NOT EXISTS `login_logs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '日志ID',
  `user_id` bigint unsigned NOT NULL COMMENT '用户ID',
  `username` varchar(255) NOT NULL DEFAULT '' COMMENT '用户名',
  `client_id` varchar(100) NOT NULL DEFAULT '' COMMENT '客户端ID',
  `uuid` varchar(100) NOT NULL DEFAULT '' COMMENT '设备UUID',
  `ip` varchar(50) NOT NULL DEFAULT '' COMMENT '登录IP',
  `type` int NOT NULL DEFAULT '0' COMMENT '登录类型: 0=密码, 1=OAuth',
  `oauth_type` varchar(50) NOT NULL DEFAULT '' COMMENT 'OAuth类型（如果是OAuth登录）',
  `platform` varchar(50) NOT NULL DEFAULT '' COMMENT '登录平台',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '登录时间',
  PRIMARY KEY (`id`),
  KEY `idx_login_logs_user_id` (`user_id`),
  KEY `idx_login_logs_username` (`username`),
  KEY `idx_login_logs_created_at` (`created_at`),
  KEY `idx_login_logs_oauth_type` (`oauth_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='登录日志表';

-- ============================================
-- 第三部分: 插入锐捷 SID OAuth 配置
-- ============================================

-- 说明: 请根据实际情况修改以下配置信息

-- 检查是否已存在锐捷 SID 配置
DELETE FROM `oauths` WHERE `op` = 'ruijie_sid';

-- 插入锐捷 SID OAuth 配置
-- 配置项说明:
-- - op: OAuth提供商标识符，用于API调用时指定（如: /api/oidc/login?op=ruijie_sid）
-- - oauth_type: 必须为 'ruijie_sid'
-- - client_id: 从锐捷 SID 管理平台获取的应用账号
-- - client_secret: 从锐捷 SID 管理平台获取的应用密钥
-- - issuer: 锐捷 SID 服务器地址
--   公有云: https://sourceid.ruishan.cc 或 https://sid.rghall.com.cn
--   私有部署: 填写实际部署地址，如 https://sid.your-company.com
-- - scopes: 留空（锐捷 SID 的 scope 是可选的，留空使用服务端默认配置）
-- - auto_register: 1=允许自动注册新用户, 0=仅允许已存在用户绑定
-- - pkce_enable: 锐捷 SID 不支持 PKCE，必须设置为 0

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
    'ruijie_sid',                                           -- OAuth提供商标识符
    'ruijie_sid',                                           -- OAuth类型
    'ruijiedesk',                                           -- 应用客户端ID
    'WMWljn4HdWyhek1FRPlZ-QYG45A7H0RpEiE1b0MEg_FEGJNCcX_skpDyxtLIWiSu', -- 应用客户端密钥
    'https://sid.ruijie.com.cn',                            -- SID服务器地址
    '',                                                     -- Scopes（留空）
    1,                                                      -- 允许自动注册
    0,                                                      -- 不启用PKCE
    'S256',                                                 -- PKCE方法（不使用）
    NOW(),
    NOW()
);

-- ============================================
-- 第四部分: 测试数据（可选）
-- ============================================

-- 插入默认管理员用户（如果不存在）
-- 注意: 密码为 'admin123' 的 bcrypt 哈希值
-- 生产环境请务必修改密码！
INSERT INTO `users` (
    `username`,
    `email`,
    `password`,
    `nickname`,
    `avatar`,
    `group_id`,
    `is_admin`,
    `status`,
    `remark`,
    `created_at`,
    `updated_at`
)
SELECT
    'admin',
    'admin@rd.jiecloud.com.cn',
    '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy',  -- 密码: admin123
    '系统管理员',
    '',
    0,
    1,
    1,
    '默认管理员账户',
    NOW(),
    NOW()
FROM DUAL
WHERE NOT EXISTS (
    SELECT 1 FROM `users` WHERE `username` = 'admin'
);

-- 插入默认用户组（如果不存在）
INSERT INTO `groups` (`name`, `note`, `created_at`, `updated_at`)
SELECT '默认组', '系统默认用户组', NOW(), NOW()
FROM DUAL
WHERE NOT EXISTS (
    SELECT 1 FROM `groups` WHERE `name` = '默认组'
);

-- ============================================
-- 第五部分: 数据库索引优化（可选）
-- ============================================

-- 为高频查询字段添加索引
-- 这些索引可能已经在表创建时添加，此处为确保存在

-- user_thirds 表的复合索引
CREATE INDEX IF NOT EXISTS `idx_user_thirds_user_oauth` ON `user_thirds` (`user_id`, `oauth_type`);
CREATE INDEX IF NOT EXISTS `idx_user_thirds_open_oauth` ON `user_thirds` (`open_id`, `op`);

-- login_logs 表的复合索引
CREATE INDEX IF NOT EXISTS `idx_login_logs_user_time` ON `login_logs` (`user_id`, `created_at`);

-- ============================================
-- 第六部分: 数据验证查询
-- ============================================

-- 查询当前所有 OAuth 配置
SELECT
    id,
    op AS '提供商标识',
    oauth_type AS 'OAuth类型',
    client_id AS '客户端ID',
    CASE
        WHEN LENGTH(client_secret) > 0 THEN CONCAT(LEFT(client_secret, 10), '...')
        ELSE '未配置'
    END AS '客户端密钥',
    issuer AS '服务器地址',
    CASE auto_register WHEN 1 THEN '是' ELSE '否' END AS '自动注册',
    CASE pkce_enable WHEN 1 THEN '是' ELSE '否' END AS '启用PKCE',
    created_at AS '创建时间'
FROM `oauths`
ORDER BY id DESC;

-- 统计用户和第三方账号绑定情况
SELECT
    '总用户数' AS '统计项',
    COUNT(*) AS '数量'
FROM `users`
UNION ALL
SELECT
    '第三方账号绑定数' AS '统计项',
    COUNT(*) AS '数量'
FROM `user_thirds`
UNION ALL
SELECT
    CONCAT(oauth_type, ' 绑定数') AS '统计项',
    COUNT(*) AS '数量'
FROM `user_thirds`
GROUP BY oauth_type;

-- ============================================
-- 第七部分: 常用维护脚本
-- ============================================

-- 1. 查看特定用户的第三方账号绑定情况
-- SELECT
--     ut.id,
--     u.username AS '用户名',
--     ut.oauth_type AS 'OAuth类型',
--     ut.op AS '提供商',
--     ut.open_id AS 'OpenID',
--     ut.name AS '第三方名称',
--     ut.email AS '第三方邮箱',
--     ut.created_at AS '绑定时间'
-- FROM `user_thirds` ut
-- JOIN `users` u ON ut.user_id = u.id
-- WHERE u.username = 'YOUR_USERNAME';

-- 2. 查看锐捷 SID 登录日志
-- SELECT
--     ll.id,
--     ll.username AS '用户名',
--     ll.oauth_type AS 'OAuth类型',
--     ll.ip AS '登录IP',
--     ll.platform AS '平台',
--     ll.created_at AS '登录时间'
-- FROM `login_logs` ll
-- WHERE ll.oauth_type = 'ruijie_sid'
-- ORDER BY ll.created_at DESC
-- LIMIT 50;

-- 3. 解除用户的锐捷 SID 绑定
-- DELETE FROM `user_thirds`
-- WHERE user_id = YOUR_USER_ID
--   AND oauth_type = 'ruijie_sid';

-- 4. 更新锐捷 SID OAuth 配置
-- UPDATE `oauths`
-- SET
--     client_id = 'NEW_CLIENT_ID',
--     client_secret = 'NEW_CLIENT_SECRET',
--     issuer = 'https://sid.your-domain.com',
--     updated_at = NOW()
-- WHERE op = 'ruijie_sid';

-- 5. 禁用/启用锐捷 SID OAuth
-- 禁用: 删除配置记录
-- DELETE FROM `oauths` WHERE op = 'ruijie_sid';
-- 启用: 重新插入配置（参考第三部分）

-- ============================================
-- 第八部分: 故障排查查询
-- ============================================

-- 1. 检查 OAuth 配置是否正确
SELECT
    CASE
        WHEN COUNT(*) = 0 THEN '❌ 未找到锐捷 SID OAuth 配置'
        WHEN COUNT(*) > 1 THEN '⚠️  存在多个锐捷 SID OAuth 配置'
        ELSE '✓ OAuth 配置正常'
    END AS '配置状态',
    COUNT(*) AS '配置数量'
FROM `oauths`
WHERE op = 'ruijie_sid';

-- 2. 检查配置字段是否完整
SELECT
    CASE
        WHEN client_id = '' OR client_id IS NULL THEN '❌ client_id 未配置'
        ELSE '✓ client_id 已配置'
    END AS 'Client ID 状态',
    CASE
        WHEN client_secret = '' OR client_secret IS NULL THEN '❌ client_secret 未配置'
        ELSE '✓ client_secret 已配置'
    END AS 'Client Secret 状态',
    CASE
        WHEN issuer = '' OR issuer IS NULL THEN '❌ issuer 未配置'
        ELSE CONCAT('✓ issuer: ', issuer)
    END AS 'Issuer 状态',
    CASE
        WHEN oauth_type != 'ruijie_sid' THEN '❌ oauth_type 错误'
        ELSE '✓ oauth_type 正确'
    END AS 'OAuth Type 状态'
FROM `oauths`
WHERE op = 'ruijie_sid';

-- 3. 查看最近的锐捷 SID 登录失败（需要配合应用日志）
SELECT
    ll.username AS '用户名',
    ll.ip AS 'IP地址',
    ll.created_at AS '尝试时间',
    '查看应用日志获取详细错误' AS '备注'
FROM `login_logs` ll
WHERE ll.oauth_type = 'ruijie_sid'
ORDER BY ll.created_at DESC
LIMIT 10;

-- 4. 查看锐捷 SID 绑定用户列表
SELECT
    u.id AS '用户ID',
    u.username AS '用户名',
    u.nickname AS '昵称',
    u.email AS '邮箱',
    ut.open_id AS 'SID OpenID',
    ut.name AS 'SID 名称',
    ut.email AS 'SID 邮箱',
    ut.created_at AS '绑定时间',
    CASE u.status
        WHEN 1 THEN '启用'
        WHEN 2 THEN '禁用'
        ELSE '未知'
    END AS '用户状态'
FROM `user_thirds` ut
JOIN `users` u ON ut.user_id = u.id
WHERE ut.oauth_type = 'ruijie_sid'
ORDER BY ut.created_at DESC;

-- ============================================
-- 第九部分: 清理脚本（谨慎使用！）
-- ============================================

-- ⚠️  警告: 以下脚本会删除数据，请谨慎使用！

-- 清理锐捷 SID 相关的所有数据（包括配置、绑定、日志）
-- 使用前请先备份数据库！

-- 1. 删除锐捷 SID OAuth 配置
-- DELETE FROM `oauths` WHERE oauth_type = 'ruijie_sid';

-- 2. 删除所有锐捷 SID 账号绑定
-- DELETE FROM `user_thirds` WHERE oauth_type = 'ruijie_sid';

-- 3. 删除锐捷 SID 登录日志
-- DELETE FROM `login_logs` WHERE oauth_type = 'ruijie_sid';

-- ============================================
-- 完成
-- ============================================

SET FOREIGN_KEY_CHECKS = 1;

-- 显示完成消息
SELECT '✓ 数据库对接脚本执行完成！' AS '状态', NOW() AS '完成时间';
SELECT '请检查上方的查询结果，确认配置是否正确。' AS '提示';
SELECT '⚠️  重要: 请将 client_id 和 client_secret 替换为实际的值！' AS '注意事项';

-- ============================================
-- 说明文档
-- ============================================
--
-- 1. 回调地址配置
--    在锐捷 SID 管理平台配置回调地址:
--    https://your-domain.com/api/oidc/callback
--
-- 2. 客户端登录流程
--    GET /api/oidc/login?op=ruijie_sid&action=login&id={device_id}&uuid={device_uuid}
--
-- 3. 用户绑定流程
--    GET /api/oidc/login?op=ruijie_sid&action=bind&id={device_id}&uuid={device_uuid}
--
-- 4. 查询登录状态
--    GET /api/oidc/query?id={device_id}
--
-- 5. 技术支持
--    - RustDesk API: https://github.com/lejianwen/rustdesk-api/issues
--    - 锐捷 SID: https://sourceid.ruishan.cc/
--
-- 6. 详细文档
--    请查看: docs/RUIJIE_SID_OAUTH.md
--
-- ============================================
