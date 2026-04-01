use std::path::PathBuf;

fn main() {
    // 确保 prost-build 能找到 protoc
    let protoc_path = "C:\\toly\\SDK\\protoc\\bin\\protoc.exe";
    if std::path::Path::new(protoc_path).exists() {
        unsafe { std::env::set_var("PROTOC", protoc_path); }
    }

    let manifest_dir = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
    let proto_dir = manifest_dir.join("../../../proto");
    let out_dir = manifest_dir.join("src/generated");

    std::fs::create_dir_all(&out_dir).expect("Failed to create generated dir");

    prost_build::Config::new()
        .out_dir(&out_dir)
        .compile_protos(
            &[
                proto_dir.join("ws.proto"),
                proto_dir.join("message.proto"),
            ],
            &[&proto_dir],
        )
        .expect("Failed to compile proto files");
}
