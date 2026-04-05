//! 图片处理服务

use image::{DynamicImage, ImageFormat, ImageReader};
use std::io::Cursor;
use thiserror::Error;

/// 图片处理错误
#[derive(Debug, Error)]
pub enum ImageError {
    #[error("图片解码失败: {0}")]
    Decode(String),

    #[error("图片编码失败: {0}")]
    Encode(String),
}

/// 图片处理器
#[derive(Clone)]
pub struct ImageProcessor {
    max_size: u32,
    #[allow(dead_code)]
    quality: u8,
}

impl ImageProcessor {
    pub fn new(max_size: u32, quality: u8) -> Self {
        Self { max_size, quality }
    }

    /// 处理图片：获取宽高 + 生成缩略图
    ///
    /// 返回 (width, height, thumb_webp_data)
    pub fn process(&self, data: &[u8]) -> Result<(u32, u32, Vec<u8>), ImageError> {
        let img = ImageReader::new(Cursor::new(data))
            .with_guessed_format()
            .map_err(|e| ImageError::Decode(e.to_string()))?
            .decode()
            .map_err(|e| ImageError::Decode(e.to_string()))?;

        let width = img.width();
        let height = img.height();

        let thumb = self.generate_thumbnail(&img);
        let thumb_data = self.encode_webp(&thumb)?;

        Ok((width, height, thumb_data))
    }

    fn generate_thumbnail(&self, img: &DynamicImage) -> DynamicImage {
        let (w, h) = (img.width(), img.height());

        if w <= self.max_size && h <= self.max_size {
            return img.clone();
        }

        let ratio = if w > h {
            self.max_size as f32 / w as f32
        } else {
            self.max_size as f32 / h as f32
        };

        let new_w = (w as f32 * ratio) as u32;
        let new_h = (h as f32 * ratio) as u32;

        img.resize(new_w, new_h, image::imageops::FilterType::Lanczos3)
    }

    fn encode_webp(&self, img: &DynamicImage) -> Result<Vec<u8>, ImageError> {
        let mut buf = Cursor::new(Vec::new());
        img.write_to(&mut buf, ImageFormat::WebP)
            .map_err(|e| ImageError::Encode(e.to_string()))?;
        Ok(buf.into_inner())
    }
}
