use axum::{
    Router,
    extract::ws::{Message, WebSocket, WebSocketUpgrade},
    response::IntoResponse,
    routing::get,
};
use futures::StreamExt;
use serde::Serialize;
use std::net::UdpSocket;
use tower_http::services::ServeDir;

/// 系统版本信息
#[derive(Serialize)]
struct VersionInfo {
    name: &'static str,
    version: &'static str,
}

/// 会话信息
#[derive(Serialize)]
struct Conversation {
    title: String,
    avatar: String,
    last_msg: String,
    time: String,
}

/// GET /conversation — 返回模拟会话列表
async fn conversation() -> axum::Json<Vec<Conversation>> {
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

/// GET /v — 返回系统版本号
async fn version() -> axum::Json<VersionInfo> {
    axum::Json(VersionInfo {
        name: env!("CARGO_PKG_NAME"),
        version: env!("CARGO_PKG_VERSION"),
    })
}

/// GET /ws — WebSocket 升级端点
async fn ws_handler(ws: WebSocketUpgrade) -> impl IntoResponse {
    ws.on_upgrade(handle_socket)
}

/// 处理单个 WebSocket 连接
async fn handle_socket(mut socket: WebSocket) {
    println!("🔗 WebSocket 连接已建立");

    let welcome = "欢迎连接 Flash IM WebSocket 服务！";
    let _ = socket.send(Message::Text(welcome.into())).await;

    while let Some(Ok(msg)) = socket.next().await {
        match msg {
            Message::Text(text) => {
                println!("📨 收到文本: {text}");
                let reply = format!("echo: {text}");
                if socket.send(Message::Text(reply.into())).await.is_err() {
                    break;
                }
            }
            Message::Close(_) => break,
            _ => {}
        }
    }

    println!("❌ WebSocket 连接已断开");
}

#[tokio::main]
async fn main() {
    let app = Router::new()
        .route("/v", get(version))
        .route("/conversation", get(conversation))
        .route("/ws", get(ws_handler))
        .nest_service("/static", ServeDir::new("static"));

    let port = 9600;
    let addr = format!("0.0.0.0:{port}");

    let local_ip = get_local_ip();

    println!("🚀 Flash IM server listening on:");
    println!("   Local:   http://127.0.0.1:{port}");
    println!("   Network: http://{local_ip}:{port}");
    println!("   WS:      ws://{local_ip}:{port}/ws");
    println!("   测试台:  http://{local_ip}:{port}/static/ws_test.html");

    let listener = tokio::net::TcpListener::bind(&addr).await.unwrap();
    axum::serve(listener, app).await.unwrap();
}

/// 获取本机局域网 IP，跳过代理虚拟网卡（如 Clash 的 198.18.x.x）
fn get_local_ip() -> String {
    // 尝试多个目标地址，优先局域网常见网关
    let targets = ["192.168.1.1:80", "10.0.0.1:80", "172.16.0.1:80", "8.8.8.8:80"];
    for target in targets {
        if let Ok(ip) = try_get_ip(target) {
            if is_real_lan_ip(&ip) {
                return ip;
            }
        }
    }
    "127.0.0.1".to_string()
}

fn try_get_ip(target: &str) -> Result<String, std::io::Error> {
    let socket = UdpSocket::bind("0.0.0.0:0")?;
    socket.connect(target)?;
    Ok(socket.local_addr()?.ip().to_string())
}

/// 过滤掉代理/虚拟网卡地址
fn is_real_lan_ip(ip: &str) -> bool {
    if ip.starts_with("127.") || ip.starts_with("198.18.") || ip.starts_with("169.254.") {
        return false;
    }
    // 只保留常见局域网段
    ip.starts_with("192.168.") || ip.starts_with("10.") || ip.starts_with("172.")
}
