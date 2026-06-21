//! OSS 后端集成测试
//!
//! 前置条件：server/.env 中配置好 OSS_* 环境变量
//! 运行：cd server && cargo test -p app-storage --test oss_test -- --nocapture

use app_storage::backend::{OssBackend, OssConfig, StorageBackend};

fn load_env() {
    let env_path = std::path::PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .join("../../.env");
    dotenvy::from_path(env_path).ok();
}

fn create_backend() -> Option<OssBackend> {
    load_env();
    let config = OssConfig::from_env()?;
    Some(OssBackend::new(config))
}

#[tokio::test]
async fn test_oss_put_get_delete() {
    let Some(backend) = create_backend() else {
        println!("⚠️  OSS 未配置，跳过测试");
        return;
    };

    let test_path = "test/integration_test_file.txt";
    let test_data = b"Hello from flash_im OSS test!";

    // 1. 上传
    println!("📤 上传文件: {}", test_path);
    backend.put(test_path, test_data).await
        .expect("put 失败");
    println!("✅ 上传成功");

    // 2. 检查存在
    println!("🔍 检查文件是否存在...");
    let exists = backend.exists(test_path).await
        .expect("exists 失败");
    assert!(exists, "文件应该存在");
    println!("✅ 文件存在");

    // 3. 下载
    println!("📥 下载文件...");
    let downloaded = backend.get(test_path).await
        .expect("get 失败");
    assert_eq!(downloaded, test_data);
    println!("✅ 内容匹配");

    // 4. 删除
    println!("🗑️  删除文件...");
    backend.delete(test_path).await
        .expect("delete 失败");
    println!("✅ 删除成功");

    // 5. 确认不存在
    let exists_after = backend.exists(test_path).await
        .expect("exists 失败");
    assert!(!exists_after, "文件应该已被删除");
    println!("✅ 确认已删除");

    println!("\n🎉 OSS 全链路测试通过！");
    println!("   公网 URL: {}/{}", backend.url_prefix, test_path);
}
