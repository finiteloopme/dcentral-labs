
use base64::{engine::general_purpose, Engine as _};
use reqwest::Client;
use std::error::Error;

/// Enum representing supported image formats
#[derive(Debug, PartialEq)]
pub enum ImageFormat {
    PNG,
    JPEG,
    WEBP,
    HEIC,
    HEIF,
    Unknown,
}

/// Returns a sample image URL for testing purposes. The image is a free vector
/// image from Freepik, and is a detailed sketch of various objects on a white
/// background.
pub fn get_sample_test_image_url() -> String {
    "https://img.freepik.com/premium-vector/detailed-sketches-various-objects-white-background_1323048-72114.jpg".to_string()
}

/// Returns the MIME type associated with the given image format, or
/// "application/octet-stream" if the format is unknown.
pub fn get_mime_type(image_format: ImageFormat) -> &'static str {
    match image_format {
        ImageFormat::PNG => "image/png",
        ImageFormat::JPEG => "image/jpeg",
        ImageFormat::WEBP => "image/webp",
        ImageFormat::HEIC => "image/heic",
        ImageFormat::HEIF => "image/heif",
        ImageFormat::Unknown => "application/octet-stream",
    }
}

/// Checks if the downloaded image is PNG, JPEG, WEBP, HEIC, or HEIF.
///
/// # Arguments
///
/// * `image_data` - A slice of bytes containing the image data.
///
/// # Returns
///
/// Returns an ImageFormat enum indicating the image format.
pub fn check_image_format(image_data: &[u8]) -> ImageFormat {
    if image_data.len() < 12 {
        return ImageFormat::Unknown;
    }

    match &image_data[0..12] {
        // PNG signature
        [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, ..] => ImageFormat::PNG,
        
        // JPEG signature
        [0xFF, 0xD8, 0xFF, ..] => ImageFormat::JPEG,
        
        // WEBP signature
        [0x52, 0x49, 0x46, 0x46, _, _, _, _, 0x57, 0x45, 0x42, 0x50] => ImageFormat::WEBP,
        
        // HEIC/HEIF signature (both use the same file signature)
        [0x00, 0x00, 0x00, _, 0x66, 0x74, 0x79, 0x70, 0x68, 0x65, 0x69, 0x63] |
        [0x00, 0x00, 0x00, _, 0x66, 0x74, 0x79, 0x70, 0x68, 0x65, 0x69, 0x78] |
        [0x00, 0x00, 0x00, _, 0x66, 0x74, 0x79, 0x70, 0x6D, 0x69, 0x66, 0x31] => {
            // Check for specific brands to differentiate between HEIC and HEIF
            if image_data.len() >= 16 {
                match &image_data[8..12] {
                    [0x68, 0x65, 0x69, 0x63] | [0x68, 0x65, 0x69, 0x78] => ImageFormat::HEIC,
                    [0x6D, 0x69, 0x66, 0x31] | [0x6D, 0x73, 0x66, 0x31] => ImageFormat::HEIF,
                    _ => ImageFormat::Unknown,
                }
            } else {
                ImageFormat::Unknown
            }
        },
        
        _ => ImageFormat::Unknown,
    }
}

// Update the download_and_encode_image function to use the new ImageFormat enum
pub async fn download_and_encode_image(image_url: &str) -> Result<(String, ImageFormat), Box<dyn Error>> {
    let client = Client::new();
    let response = client.get(image_url).send().await?;

    if !response.status().is_success() {
        return Err(format!("Failed to download image: HTTP {}", response.status()).into());
    }

    let image_bytes = response.bytes().await?;
    let image_format = check_image_format(&image_bytes);
    let base64_image = general_purpose::STANDARD.encode(&image_bytes);

    Ok((base64_image, image_format))
}

#[cfg(test)]
mod tests {
    use super::*;
    use httpmock::MockServer;
    use httpmock::Method::GET;

    #[test]
    fn test_check_image_format_png() {
        let png_data = vec![0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D];
        assert_eq!(check_image_format(&png_data), ImageFormat::PNG);
    }

    #[test]
    fn test_check_image_format_jpeg() {
        let jpeg_data = vec![0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01];
        assert_eq!(check_image_format(&jpeg_data), ImageFormat::JPEG);
    }

    #[test]
    fn test_check_image_format_webp() {
        let webp_data = vec![0x52, 0x49, 0x46, 0x46, 0x00, 0x00, 0x00, 0x00, 0x57, 0x45, 0x42, 0x50];
        assert_eq!(check_image_format(&webp_data), ImageFormat::WEBP);
    }

    #[test]
    fn test_check_image_format_heic() {
        let heic_data = vec![0x00, 0x00, 0x00, 0x18, 0x66, 0x74, 0x79, 0x70, 0x68, 0x65, 0x69, 0x63, 0x00, 0x00, 0x00, 0x00];
        assert_eq!(check_image_format(&heic_data), ImageFormat::HEIC);
    }

    #[test]
    fn test_check_image_format_heif() {
        let heif_data = vec![0x00, 0x00, 0x00, 0x18, 0x66, 0x74, 0x79, 0x70, 0x6D, 0x69, 0x66, 0x31, 0x00, 0x00, 0x00, 0x00];
        assert_eq!(check_image_format(&heif_data), ImageFormat::HEIF);
    }

    #[test]
    fn test_check_image_format_unknown() {
        let unknown_data = vec![0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B];
        assert_eq!(check_image_format(&unknown_data), ImageFormat::Unknown);
    }

    #[test]
    fn test_check_image_format_too_short() {
        let short_data = vec![0xFF, 0xD8, 0xFF];
        assert_eq!(check_image_format(&short_data), ImageFormat::Unknown);
    }

    #[tokio::test]
    async fn test_download_and_encode_image() {
        // Start a mock server
        let server = MockServer::start();

        // Create a mock image (1x1 pixel, black)
        let image_data = vec![137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0, 0, 13, 73, 68, 65, 84, 120, 156, 99, 0, 1, 0, 0, 5, 0, 1, 13, 10, 45, 180, 0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130];

        // Set up a mock endpoint for the image
        let mock = server.mock(|when, then| {
            when.method(GET)
                .path("/test-image.png");
            then.status(200)
                .header("Content-Type", "image/png")
                .body(image_data.clone());
        });

        // Call the function with the mock server URL
        let image_url = format!("{}/test-image.png", server.base_url());
        let result = download_and_encode_image(&image_url).await;

        // Assert that the mock was called
        mock.assert();

        // Check the result
        assert!(result.is_ok());
        let (base64_image, _img_format) = result.unwrap();
        
        // Verify that the result is a valid base64 encoding of the original image data
        let decoded = general_purpose::STANDARD.decode(base64_image).unwrap();
        assert_eq!(decoded, image_data);
    }
    #[test]
    fn test_get_mime_type_known_formats() {
        assert_eq!(get_mime_type(ImageFormat::PNG), "image/png");
        assert_eq!(get_mime_type(ImageFormat::JPEG), "image/jpeg");
        assert_eq!(get_mime_type(ImageFormat::WEBP), "image/webp");
        assert_eq!(get_mime_type(ImageFormat::HEIC), "image/heic");
        assert_eq!(get_mime_type(ImageFormat::HEIF), "image/heif");
    }

    #[test]
    fn test_get_mime_type_unknown_format() {
        assert_eq!(get_mime_type(ImageFormat::Unknown), "application/octet-stream");
    }
}