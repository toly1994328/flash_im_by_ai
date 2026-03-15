use axum::{
    Router,
    extract::ws::{Message, WebSocket, WebSocketUpgrade},
    extract::State,
    http::{HeaderMap, StatusCode},
    response::IntoResponse,
    routing::{get, post},
    Json,
};
use chrono::Utc;
use futures::{SinkExt, StreamExt};
use jsonwebtoken::{DecodingKey, EncodingKey, Header, Validation, decode, encode};
use rand::Rng;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::net::UdpSocket;
use std::sync::Arc;
use tokio::sync::{broadcast, Mutex};
use tower_http::services::ServeDir;

const JWT_SECRET: &str = "flash-im-playground-secret";

// ========== 共享状态 ==========

/// 内存用户存储
struct AppState {
    users: Mutex<HashMap<String, User>>,       // phone -> User
    sms_codes: Mutex<HashMap<String, String>>, // phone -> code
    next_id: Mutex<i64>,
    chat_tx: broadcast::Sender<String>,        // 聊天室广播
}

/// 用户信息
#[derive(Clone, Serialize)]
struct User {
    user_id: i64,
    phone: String,
    nickname: String,
    avatar: String,
}

// ========== JWT ==========

#[derive(Serialize, Deserialize)]
struct Claims {
    sub: String,   // 用户 ID
    exp: i64,      // 过期时间
    iat: i64,      // 签发时间
}

fn generate_token(user_id: i64) -> String {
    let now = Utc::now().timestamp();
    let claims = Claims {
        sub: user_id.to_string(),
        exp: now + 7 * 24 * 3600, // 7 天
        iat: now,
    };
    encode(&Header::default(), &claims, &EncodingKey::from_secret(JWT_SECRET.as_bytes())).unwrap()
}

fn verify_token(token: &str) -> Result<i64, &'static str> {
    let data = decode::<Claims>(
        token,
        &DecodingKey::from_secret(JWT_SECRET.as_bytes()),
        &Validation::default(),
    )
    .map_err(|_| "Token 无效")?;
    data.claims.sub.parse().map_err(|_| "用户 ID 解析失败")
}

// ========== 认证接口 ==========

#[derive(Deserialize)]
struct SmsRequest {
    phone: String,
}

#[derive(Serialize)]
struct SmsResponse {
    code: String,
    message: String,
}

/// POST /auth/sms — 发送验证码（模拟）
async fn send_sms(State(state): State<Arc<AppState>>, Json(req): Json<SmsRequest>) -> Result<Json<SmsResponse>, StatusCode> {
    if req.phone.len() != 11 || !req.phone.starts_with('1') {
        return Err(StatusCode::BAD_REQUEST);
    }
    let code: String = format!("{:06}", rand::rng().random_range(0..1000000));
    println!("📱 验证码 [{}] -> {}", req.phone, code);
    state.sms_codes.lock().await.insert(req.phone, code.clone());
    Ok(Json(SmsResponse { code, message: "验证码已发送".into() }))
}

#[derive(Deserialize)]
struct LoginRequest {
    phone: String,
    code: String,
}

#[derive(Serialize)]
struct LoginResponse {
    token: String,
    user_id: i64,
}

/// POST /auth/login — 验证码登录（登录即注册）
async fn login(State(state): State<Arc<AppState>>, Json(req): Json<LoginRequest>) -> Result<Json<LoginResponse>, StatusCode> {
    if req.phone.len() != 11 || !req.phone.starts_with('1') {
        return Err(StatusCode::BAD_REQUEST);
    }
    // 校验验证码
    let codes = state.sms_codes.lock().await;
    match codes.get(&req.phone) {
        Some(c) if c == &req.code => {}
        _ => return Err(StatusCode::UNAUTHORIZED),
    }
    drop(codes);

    // 查找或创建用户
    let mut users = state.users.lock().await;
    let user = if let Some(u) = users.get(&req.phone) {
        u.clone()
    } else {
        let mut next_id = state.next_id.lock().await;
        *next_id += 1;
        let user = User {
            user_id: *next_id,
            phone: req.phone.clone(),
            nickname: req.phone.clone(),
            avatar: format!("https://picsum.photos/seed/{}/100/100", *next_id),
        };
        users.insert(req.phone.clone(), user.clone());
        println!("🆕 新用户注册: {} (ID: {})", req.phone, user.user_id);
        user
    };

    // 清除已使用的验证码
    state.sms_codes.lock().await.remove(&req.phone);

    let token = generate_token(user.user_id);
    println!("🔑 用户登录: {} (ID: {})", req.phone, user.user_id);
    Ok(Json(LoginResponse { token, user_id: user.user_id }))
}

/// GET /user/profile — 获取用户信息（需要 Token）
async fn profile(State(state): State<Arc<AppState>>, headers: HeaderMap) -> Result<Json<User>, StatusCode> {
    let token = headers
        .get("Authorization")
        .and_then(|v| v.to_str().ok())
        .and_then(|v| v.strip_prefix("Bearer "))
        .ok_or(StatusCode::UNAUTHORIZED)?;

    let user_id = verify_token(token).map_err(|_| StatusCode::UNAUTHORIZED)?;

    let users = state.users.lock().await;
    users
        .values()
        .find(|u| u.user_id == user_id)
        .cloned()
        .ok_or(StatusCode::NOT_FOUND)
        .map(Json)
}

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
/// GET /ws/auth — 需要认证的 WebSocket 端点
async fn ws_auth_handler(
    ws: WebSocketUpgrade,
    State(state): State<Arc<AppState>>,
) -> impl IntoResponse {
    ws.on_upgrade(move |socket| handle_auth_socket(socket, state))
}

/// 处理带认证的 WebSocket 连接
async fn handle_auth_socket(mut socket: WebSocket, state: Arc<AppState>) {
    println!("🔗 [ws/auth] 连接已建立，等待认证...");

    // 10 秒内必须完成认证
    let auth_result = tokio::time::timeout(
        std::time::Duration::from_secs(10),
        wait_for_auth(&mut socket, &state),
    )
    .await;

    let user = match auth_result {
        Ok(Some(u)) => u,
        Ok(None) => {
            let _ = socket.send(Message::Text(r#"{"type":"auth_fail","message":"Token 无效"}"#.into())).await;
            let _ = socket.send(Message::Close(None)).await;
            println!("❌ [ws/auth] 认证失败");
            return;
        }
        Err(_) => {
            let _ = socket.send(Message::Text(r#"{"type":"auth_timeout","message":"认证超时"}"#.into())).await;
            let _ = socket.send(Message::Close(None)).await;
            println!("⏰ [ws/auth] 认证超时（10s）");
            return;
        }
    };

    // 认证成功
    let welcome = format!(
        r#"{{"type":"auth_ok","user_id":{},"nickname":"{}"}}"#,
        user.user_id, user.nickname
    );
    let _ = socket.send(Message::Text(welcome.into())).await;
    println!("✅ [ws/auth] 用户 {} (ID:{}) 认证成功", user.nickname, user.user_id);

    // 进入正常消息循环
    while let Some(Ok(msg)) = socket.next().await {
        match msg {
            Message::Text(text) => {
                println!("📨 [ws/auth] 用户{}说: {text}", user.user_id);
                let reply = format!(
                    r#"{{"type":"message","from":{},"text":"echo: {text}"}}"#,
                    user.user_id
                );
                if socket.send(Message::Text(reply.into())).await.is_err() {
                    break;
                }
            }
            Message::Close(_) => break,
            _ => {}
        }
    }

    println!("❌ [ws/auth] 用户 {} 断开连接", user.user_id);
}

/// 等待客户端发送 Token 进行认证
async fn wait_for_auth(socket: &mut WebSocket, state: &Arc<AppState>) -> Option<User> {
    while let Some(Ok(msg)) = socket.next().await {
        if let Message::Text(text) = msg {
            // 尝试解析 JSON: {"token": "xxx"}
            if let Ok(parsed) = serde_json::from_str::<serde_json::Value>(&text) {
                if let Some(token) = parsed.get("token").and_then(|t| t.as_str()) {
                    if let Ok(user_id) = verify_token(token) {
                        let users = state.users.lock().await;
                        return users.values().find(|u| u.user_id == user_id).cloned();
                    }
                }
            }
            return None; // 第一条消息格式不对，直接失败
        }
    }
    None
}
/// GET /ws/chat_room — 聊天室 WebSocket 端点（需认证）
async fn ws_chat_room_handler(
    ws: WebSocketUpgrade,
    State(state): State<Arc<AppState>>,
) -> impl IntoResponse {
    ws.on_upgrade(move |socket| handle_chat_room(socket, state))
}

/// 处理聊天室连接：认证 → 广播消息
async fn handle_chat_room(mut socket: WebSocket, state: Arc<AppState>) {
    println!("🔗 [chat_room] 连接已建立，等待认证...");

    // 10 秒认证超时
    let auth_result = tokio::time::timeout(
        std::time::Duration::from_secs(10),
        wait_for_auth(&mut socket, &state),
    )
    .await;

    let user = match auth_result {
        Ok(Some(u)) => u,
        Ok(None) => {
            let _ = socket.send(Message::Text(r#"{"type":"auth_fail","message":"Token 无效"}"#.into())).await;
            let _ = socket.send(Message::Close(None)).await;
            return;
        }
        Err(_) => {
            let _ = socket.send(Message::Text(r#"{"type":"auth_timeout","message":"认证超时"}"#.into())).await;
            let _ = socket.send(Message::Close(None)).await;
            return;
        }
    };

    // 认证成功
    let welcome = format!(
        r#"{{"type":"auth_ok","user_id":{},"nickname":"{}","avatar":"{}"}}"#,
        user.user_id, user.nickname, user.avatar
    );
    let _ = socket.send(Message::Text(welcome.into())).await;
    println!("✅ [chat_room] {} (ID:{}) 进入聊天室", user.nickname, user.user_id);

    // 广播「加入」
    let join_msg = format!(
        r#"{{"type":"join","user_id":{},"nickname":"{}","avatar":"{}"}}"#,
        user.user_id, user.nickname, user.avatar
    );
    let _ = state.chat_tx.send(join_msg);

    // 订阅广播
    let mut rx = state.chat_tx.subscribe();
    let tx = state.chat_tx.clone();
    let uid = user.user_id;
    let nick = user.nickname.clone();
    let avatar = user.avatar.clone();

    let (mut ws_sink, mut ws_stream) = socket.split();

    // 任务1：广播 → 客户端
    let send_task = tokio::spawn(async move {
        while let Ok(msg) = rx.recv().await {
            if ws_sink.send(Message::Text(msg.into())).await.is_err() {
                break;
            }
        }
    });

    // 任务2：客户端 → 广播
    while let Some(Ok(msg)) = ws_stream.next().await {
        match msg {
            Message::Text(text) => {
                let broadcast_msg = format!(
                    r#"{{"type":"message","user_id":{},"nickname":"{}","avatar":"{}","text":{}}}"#,
                    uid, nick, avatar, serde_json::to_string(&text.to_string()).unwrap_or_default()
                );
                let _ = tx.send(broadcast_msg);
            }
            Message::Close(_) => break,
            _ => {}
        }
    }

    // 广播「离开」
    let leave_msg = format!(
        r#"{{"type":"leave","user_id":{},"nickname":"{}","avatar":"{}"}}"#,
        uid, nick, avatar
    );
    let _ = tx.send(leave_msg);
    send_task.abort();
    println!("❌ [chat_room] {} 离开聊天室", nick);
}

#[tokio::main]
async fn main() {
    let (chat_tx, _) = broadcast::channel::<String>(256);

    let state = Arc::new(AppState {
        users: Mutex::new(HashMap::new()),
        sms_codes: Mutex::new(HashMap::new()),
        next_id: Mutex::new(0),
        chat_tx,
    });

    let app = Router::new()
        .route("/v", get(version))
        .route("/conversation", get(conversation))
        .route("/ws", get(ws_handler))
        .route("/ws/auth", get(ws_auth_handler))
        .route("/ws/chat_room", get(ws_chat_room_handler))
        .route("/auth/sms", post(send_sms))
        .route("/auth/login", post(login))
        .route("/user/profile", get(profile))
        .nest_service("/static", ServeDir::new("static"))
        .with_state(state);

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
