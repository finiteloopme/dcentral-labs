use base64::{engine::general_purpose, Engine as _};
use reqwest::Client;
use serde::{Deserialize, Serialize};
use std::error::Error;
use tokio;

#[derive(Deserialize, Serialize)]
struct Candidate {
    content: Content,
}

#[derive(Deserialize, Serialize)]
struct Content {
    parts: Vec<Part>,
}

#[derive(Deserialize, Serialize)]
struct Part {
    #[serde(default)]
    text: Option<String>,
    #[serde(default)]
    inline_data: Option<InlineData>,
}

#[derive(Deserialize, Serialize)]
struct InlineData {
    mime_type: String,
    data: String,
}

#[derive(Deserialize, Serialize)]
struct GeminiRequest {
    contents: Vec<Content>,
}

#[derive(Deserialize, Serialize)]
struct GeminiResponse {
    candidates: Vec<Candidate>,
}

/// Creates a GeminiRequest from the given image URL, ready to be sent to the
/// Gemini API. The request will contain two parts: a text part with the string
/// "Identify all objects in this image.", and a text part with the image URL.
async fn create_genai_request(image_url: &str) -> Result<GeminiRequest, Box<dyn Error>> {
    Ok(GeminiRequest {
        contents: vec![Content {
            parts: vec![
                Part {
                    text: Some("Identify all objects in this image.".to_string()),
                    inline_data: None,
                },
                Part {
                    text: Some(image_url.to_string()),
                    inline_data: None,
                },
            ],
        }],
    })
}

/// Calls the Gemini API with the given GeminiRequest and API key, and returns the
/// response as a GeminiResponse. The Gemini API URL is taken from the GEMINI_API_URL
/// environment variable, or defaults to the URL for the 'gemini-pro-vision' model.
async fn call_genai_api(gemini_request: &GeminiRequest, api_key: &str) -> Result<GeminiResponse, Box<dyn Error>> {
    let client = Client::new();
    let api_url = std::env::var("GEMINI_API_URL")
        .unwrap_or_else(|_| "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro-vision:generateContent".to_string());
    let response: GeminiResponse = client
        .post(api_url)
        .query(&[("key", api_key)])
        .json(&gemini_request)
        .send()
        .await?
        .json().await?;
    Ok(response)
}

/// Extracts the identified objects from the Gemini API response.
async fn process_genai_response(response: &GeminiResponse) -> Result<Vec<String>, Box<dyn Error>> {
    let objects = response
        .candidates
        .first()
        .and_then(|candidate| candidate.content.parts.first())
        .and_then(|part| part.text.as_ref())
        .map(|text| {
            text.lines()
                .filter_map(|line| {
                    if line.starts_with('-') {
                        Some(line[1..].trim().to_string())
                    } else {
                        None
                    }
                })
                .collect()
        })
        .unwrap_or_default();
    Ok(objects)
}

/// Analyzes an image using the Gemini API to identify objects in the image.
///
/// # Arguments
///
/// * `image_url` - A string slice containing the URL of the image to analyze.
/// * `api_key` - A string slice that holds the Gemini API key.
///
/// # Returns
///
/// Returns a Result containing a Vec of String with identified objects, or an error.
pub async fn analyze_image(image_url: &str, api_key: &str) -> Result<Vec<String>, Box<dyn Error>> {
    // Prepare the request payload
    let request = create_genai_request(image_url).await?;

    // Send request to Gemini API
    let response: GeminiResponse = call_genai_api(&request, api_key).await?;

    // Extract the identified objects from the response
    let objects = process_genai_response(&response).await?;

    Ok(objects)
}

#[cfg(test)]
mod tests {
    use super::*;
    use httpmock::MockServer;
    use httpmock::Method::POST;

    #[tokio::test]
    async fn test_analyze_image() {
        let server = MockServer::start();

        let mock = server.mock(|when, then| {
            when.method(POST)
                .path("/v1beta/models/gemini-pro-vision:generateContent")
                .query_param("key", "test_api_key")
                .header("Content-Type", "application/json");
            then.status(200)
                .header("Content-Type", "application/json")
                .json_body(serde_json::json!({
                    "candidates": [
                        {
                            "content": {
                                "parts": [
                                    {
                                        "text": "The image contains:\n- Cat\n- Sofa\n- Plant"
                                    }
                                ]
                            }
                        }
                    ]
                }));
        });

        let api_url = format!("{}/v1beta/models/gemini-pro-vision:generateContent", server.base_url());
        std::env::set_var("GEMINI_API_URL", api_url);

        let image_url = "https://example.com/test-image.jpg";
        let result = analyze_image(image_url, "test_api_key").await;

        mock.assert();

        assert!(result.is_ok());
        let objects = result.unwrap();
        assert_eq!(objects, vec!["Cat", "Sofa", "Plant"]);
    }

    #[tokio::test]
    async fn test_create_genai_request() {
        let image_url = "https://example.com/test-image.jpg";
        let result = create_genai_request(image_url).await;

        assert!(result.is_ok());
        let request = result.unwrap();

        assert_eq!(request.contents.len(), 1);
        assert_eq!(request.contents[0].parts.len(), 2);

        assert_eq!(
            request.contents[0].parts[0].text,
            Some("Identify all objects in this image.".to_string())
        );
        assert!(request.contents[0].parts[0].inline_data.is_none());

        assert_eq!(request.contents[0].parts[1].text, Some(image_url.to_string()));
        assert!(request.contents[0].parts[1].inline_data.is_none());
    }


    #[tokio::test]
    async fn test_call_genai_api() {
        // Set the maximum number of mock servers to 1
        std::env::set_var("HTTPMOCK_MAX_SERVERS", "1");
        // Create a mock server
        let server = MockServer::start();

        // Create a mock for the Gemini API endpoint
        let mock = server.mock(|when, then| {
            when.method(POST)
                .path("/v1beta/models/gemini-pro-vision:generateContent")
                .query_param("key", "test_api_key")
                .header("Content-Type", "application/json");
            then.status(200)
                .header("Content-Type", "application/json")
                .json_body(serde_json::json!({
                    "candidates": [
                        {
                            "content": {
                                "parts": [
                                    {
                                        "text": "Test response"
                                    }
                                ]
                            }
                        }
                    ]
                }));
        });

        // Override the Gemini API URL with our mock server URL
        let api_url = format!("{}/v1beta/models/gemini-pro-vision:generateContent", server.base_url());
        std::env::set_var("GEMINI_API_URL", api_url);

        // Create a dummy request
        let request = GeminiRequest {
            contents: vec![Content {
                parts: vec![Part {
                    text: Some("Test request".to_string()),
                    inline_data: None,
                }],
            }],
        };

        // Call the function
        let result = call_genai_api(&request, "test_api_key").await;

        // Assert that the mock was called
        mock.assert();

        // Check the result
        assert!(result.is_ok());
        let response = result.unwrap();
        assert_eq!(response.candidates.len(), 1);
        assert_eq!(response.candidates[0].content.parts.len(), 1);
        assert_eq!(
            response.candidates[0].content.parts[0].text,
            Some("Test response".to_string())
        );
    }

    #[tokio::test]
    async fn test_process_genai_response() {
        // Create a test response
        let response = GeminiResponse {
            candidates: vec![Candidate {
                content: Content {
                    parts: vec![Part {
                        text: Some("The image contains:\n- Cat\n- Dog\n- Bird".to_string()),
                        inline_data: None,
                    }],
                },
            }],
        };

        // Call the function
        let result = process_genai_response(&response).await;

        // Check the result
        assert!(result.is_ok());
        let objects = result.unwrap();
        assert_eq!(objects, vec!["Cat", "Dog", "Bird"]);
    }

    #[tokio::test]
    async fn test_process_genai_response_empty() {
        // Create an empty response
        let response = GeminiResponse {
            candidates: vec![],
        };

        // Call the function
        let result = process_genai_response(&response).await;

        // Check the result
        assert!(result.is_ok());
        let objects = result.unwrap();
        assert!(objects.is_empty());
    }
}