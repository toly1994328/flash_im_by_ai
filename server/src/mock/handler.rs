use serde::Serialize;

/// 系统版本信息
#[derive(Serialize)]
pub struct VersionInfo {
    pub name: &'static str,
    pub version: &'static str,
}

/// 会话信息
#[derive(Serialize)]
pub struct Conversation {
    pub title: String,
    pub avatar: String,
    pub last_msg: String,
    pub time: String,
}

/// GET /v — 返回系统版本号
pub async fn version() -> axum::Json<VersionInfo> {
    axum::Json(VersionInfo {
        name: env!("CARGO_PKG_NAME"),
        version: env!("CARGO_PKG_VERSION"),
    })
}

/// GET /conversation — 返回模拟会话列表
pub async fn conversation() -> axum::Json<Vec<Conversation>> {
    let data = vec![
        ("张三", "晚上一起吃饭吗？", "10:30"),
        ("李四", "代码已经提交了", "10:25"),
        ("产品群", "需求文档已更新，请查收", "10:20"),
        ("王五", "收到，我马上处理", "10:15"),
        ("技术讨论组", "Rust 异步性能确实强", "10:10"),
        ("赵六", "明天下午开会别忘了", "09:58"),
        ("设计团队", "新版 UI 稿已上传 Figma", "09:45"),
        ("小红", "周末去爬山吗？", "09:30"),
        ("运维告警", "[OK] 服务器 CPU 恢复正常", "09:20"),
        ("老板", "这个季度目标确认一下", "09:15"),
        ("前端群", "Flutter 3.x 升级踩坑记录", "09:00"),
        ("小明", "那个 bug 修好了", "08:50"),
        ("HR", "本月考勤确认，请及时处理", "08:45"),
        ("后端群", "新接口文档已同步到 wiki", "08:30"),
        ("客户A", "合同已签署，请确认", "昨天"),
        ("测试组", "v0.1.0 回归测试通过", "昨天"),
        ("小华", "生日快乐！🎂", "昨天"),
        ("DevOps", "CI/CD 流水线优化完成", "周一"),
        ("读书会", "本周共读《Rust 编程之道》第三章", "周一"),
        ("系统通知", "您的账号已在新设备登录", "上周"),
    ];

    axum::Json(
        data.into_iter()
            .enumerate()
            .map(|(i, (title, last_msg, time))| Conversation {
                title: title.to_string(),
                avatar: format!("https://picsum.photos/seed/{}/100/100", i + 1),
                last_msg: last_msg.to_string(),
                time: time.to_string(),
            })
            .collect(),
    )
}
