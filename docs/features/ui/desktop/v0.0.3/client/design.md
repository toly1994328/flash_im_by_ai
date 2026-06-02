# 前端设计 — Web 加载优化

## 变更范围

| 文件 | 改动类型 | 说明 |
|------|----------|------|
| `client/web/index.html` | 重写 | 科技感加载页（纯 HTML/CSS/JS） |
| `client/modules/flash_starter/lib/src/splash_page.dart` | 修改 | Web 端跳过隐私弹窗 |
| `scripts/build_center/build_web.py` | 重写 | 默认 WASM 模式 + tree-shake-icons |

## 加载页设计

### 视觉元素

1. **粒子网络背景**：Canvas 绘制浮动粒子 + 连线，模拟"网络链接"
2. **旋转光环**：外圈蓝紫渐变 conic-gradient，CSS animation 旋转
3. **SVG Logo**：消息气泡 + 闪电符号，描边流动动画
4. **品牌文字**："闪 讯"渐变填充
5. **进度条**：细条来回滑动
6. **状态文字**："正在建立连接..."
7. **底部装饰线**：渐变发光线 + 呼吸脉冲

### 退出机制

监听 `flutter-first-frame` 事件：
```js
window.addEventListener('flutter-first-frame', function() {
  // 停止粒子动画
  cancelAnimationFrame(animId);
  // fade-out + scale 过渡后移除 DOM
  el.classList.add('fade-out');
  setTimeout(() => el.remove(), 600);
});
```

### 性能考虑

- 粒子数量根据屏幕面积自适应（`Math.min(80, width*height/15000)`）
- Canvas 动画在 flutter-first-frame 后立即停止
- 无外部依赖（不加载字体、不加载图片）

## 隐私弹窗跳过

```dart
Future<void> _checkPrivacyConsent() async {
  if (kIsWeb) {
    widget.onComplete(_results!);
    return;
  }
  // 原生平台保持不变...
}
```

Web 端不需要 App 级别的隐私确认（浏览器环境），直接进入主流程。

## 构建脚本

```bash
flutter build web --wasm --release --tree-shake-icons --base-href /im/ --dart-define-from-file=.env.production
```

默认 WASM 模式，产物部署到服务器 `static/im/` 目录。
