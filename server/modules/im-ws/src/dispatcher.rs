//! 帧分发器
//!
//! 根据 WsFrameType 分发到对应的处理逻辑。

use prost::Message as ProstMessage;

use crate::proto::{WsFrame, WsFrameType};

/// 处理收到的帧，返回需要回复的帧字节（如果有）
pub fn handle_frame(frame: WsFrame) -> Option<Vec<u8>> {
    let frame_type = WsFrameType::try_from(frame.r#type).ok();

    match frame_type {
        Some(WsFrameType::Ping) => {
            let pong = WsFrame {
                r#type: WsFrameType::Pong as i32,
                payload: vec![],
            };
            Some(pong.encode_to_vec())
        }
        Some(other) => {
            println!("⚠️ [im-ws] 未处理的帧类型: {:?}", other);
            None
        }
        None => {
            println!("⚠️ [im-ws] 未知的帧类型编号: {}", frame.r#type);
            None
        }
    }
}
