use std::net::UdpSocket;

/// 获取本机局域网 IP，跳过代理虚拟网卡（如 Clash 的 198.18.x.x）
pub fn get_local_ip() -> String {
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

fn is_real_lan_ip(ip: &str) -> bool {
    if ip.starts_with("127.") || ip.starts_with("198.18.") || ip.starts_with("169.254.") {
        return false;
    }
    ip.starts_with("192.168.") || ip.starts_with("10.") || ip.starts_with("172.")
}
