/// 图片气泡尺寸计算策略
///
/// 规则：
/// 1. 等比缩放，不超过 maxW×maxH
/// 2. 缩放后不小于 minSize
/// 3. 极端比例（>4:1 或 <1:4）时裁剪显示
/// 4. 未知尺寸返回默认值
class BubbleSize {
  static const double maxW = 250;
  static const double maxH = 200;
  static const double minSize = 80;
  static const double _extremeRatio = 4.0;

  /// 计算气泡显示尺寸
  ///
  /// [originalWidth] / [originalHeight] 为原图像素尺寸，0 或负数视为未知。
  /// 返回 (width, height, needCrop)：
  /// - width/height: 气泡逻辑像素尺寸
  /// - needCrop: 是否需要裁剪（BoxFit.cover），否则 contain
  static ({double width, double height, bool crop}) calc(double originalWidth, double originalHeight) {
    if (originalWidth <= 0 || originalHeight <= 0) {
      return (width: 200, height: 150, crop: false);
    }

    final double ratio = originalWidth / originalHeight;
    final bool isExtreme = ratio > _extremeRatio || ratio < 1 / _extremeRatio;

    double w = originalWidth;
    double h = originalHeight;

    // 缩放到约束内
    if (w > maxW) {
      h = h * (maxW / w);
      w = maxW;
    }
    if (h > maxH) {
      w = w * (maxH / h);
      h = maxH;
    }

    // 极端比例：强制最小边 = minSize，标记裁剪
    if (isExtreme) {
      if (w < minSize) w = minSize;
      if (h < minSize) h = minSize;
      return (width: w, height: h, crop: true);
    }

    // 正常比例：确保不小于 minSize
    if (w < minSize) {
      h = h * (minSize / w);
      w = minSize;
    }
    if (h < minSize) {
      w = w * (minSize / h);
      h = minSize;
    }

    return (width: w, height: h, crop: false);
  }

  /// 从 record 格式的 originalSize 计算
  static ({double width, double height, bool crop}) fromOriginalSize(({int width, int height})? size) {
    if (size == null) return (width: 200, height: 150, crop: false);
    return calc(size.width.toDouble(), size.height.toDouble());
  }
}
