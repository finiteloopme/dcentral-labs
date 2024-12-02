// use anvil::http::response;
use reqwest::Client;
use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::error::Error;
use anyhow::anyhow;

use crate::coprocessor::img::handler::{download_and_encode_image, get_mime_type};

#[derive(Debug, Deserialize, Serialize)]
struct Candidate {
    content: Content,
}

#[derive(Debug, Deserialize, Serialize)]
struct Content {
    parts: Vec<Part>,
}

#[derive(Debug, Deserialize, Serialize)]
struct Part {
    // #[serde(default)]
    text: Option<String>,
    // #[serde(default)]
    inline_data: Option<InlineData>,
}

#[derive(Debug, Deserialize, Serialize)]
struct InlineData {
    mime_type: String,
    data: String,
}

#[derive(Debug, Deserialize, Serialize)]
struct GeminiRequest {
    contents: Vec<Content>,
}

#[derive(Debug, Deserialize, Serialize)]
struct GeminiResponse {
    candidates: Vec<Candidate>,
}

/// Creates a GeminiRequest from the given image URL, ready to be sent to the
/// Gemini API. The request will contain two parts: a text part with the string
/// "Identify all objects in this image.", and a text part with the image URL.
async fn create_genai_request(image_url: &str) -> Result<GeminiRequest, Box<dyn Error>> {
    let (image_data, image_format) = download_and_encode_image(image_url).await?;
    Ok(GeminiRequest {
        contents: vec![Content {
            parts: vec![
                Part {
                    text: Some("Identify all objects in this image. Return the objects as a JSON array with `objects` as a key.".to_string()),
                    inline_data: None,
                },
                Part {
                    text: None,
                    inline_data: Some(InlineData {
                        mime_type: get_mime_type(image_format).to_string(),
                        data: image_data,
                    }),
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
    // construct the URL - this pattern is useful for unit testing
    let api_url = std::env::var("GEMINI_API_URL")
        .unwrap_or_else(|_| "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent".to_string());
    // construct the raw request
    let raw_request = client
        .post(api_url)
        .query(&[("key", api_key)])
        .header("Content-Type", "application/json")
        .body(serde_json::to_string(&gemini_request).unwrap())
        // .body("{\"contents\": [{\"parts\": [{\"text\": \"Identify all objects in this image.\"},{\"inline_data\": {\"mime_type\": \"image/jpeg\",\"data\": \"\"}}]}]}")
        .build()?; // build the request
    // println!("Calling genai with this request: {:#?}", raw_request);
    // println!("Calling genai with this request body: {:#?}", raw_request.body());
    // Execute the request
    let raw_response = client.execute(raw_request).await;
    // println!("Raw response: {:?}", &raw_response);
    match raw_response {
        Ok(response) => {
            // Status: 200, assume success and try to create a valid response
            let _response = response.json::<GeminiResponse>().await?;
            Ok(_response)
        },
        Err(error) => {
            Err(Box::new(error))
        }
    }
}

/// Extracts the identified objects from the Gemini API response.
async fn process_genai_response(response: &GeminiResponse) -> Result<Vec<String>, Box<dyn Error>> {
    // println!("Processing genai response: {:#?}", response);
    let json_str = response
        .candidates
        .first()
        .and_then(|candidate| candidate.content.parts.first())
        .and_then(|part| part.text.as_ref())
        .unwrap();
    // println!("JSON string: {}", json_str);
    let mut lines: Vec<&str> = json_str.lines().collect();
    // Remove the first line if it starts with "```json"
    if lines.first().map_or(false, |&line| line.trim().starts_with("```json")) {
        lines.remove(0);
    }
    
    // Remove the last line if it's just "```"
    if lines.last().map_or(false, |&line| line.trim() == "```") {
        lines.pop();
    }
    
    // Join the remaining lines
    lines.join("\n");
    // Parse the JSON string
    let parsed: Value = serde_json::from_str(&lines.concat())?;


    // Extract the "objects" array
    let objects = parsed["objects"]
        .as_array()
        .ok_or_else(|| anyhow!("'objects' field is not an array"))?;

    // Convert each object to a String
    let object_list: Vec<String> = objects
        .iter()
        .filter_map(|obj| Some(obj.as_str().unwrap().to_string() + ", ").map(String::from))
        .collect();

    // Return the list of objects
    Ok(object_list)
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
    use crate::coprocessor::img::handler::get_sample_test_image_url;

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
                                        "text": r#"```json
    {
      "objects": [
        "Cat",
        "Sofa",
        "Plant"
      ]
    }
    ```"#
                                    }
                                ]
                            }
                        }
                    ]
                }));
        });
    
        let api_url = format!("{}/v1beta/models/gemini-pro-vision:generateContent", server.base_url());
        std::env::set_var("GEMINI_API_URL", api_url);
    
        let image_url = &get_sample_test_image_url();
        let result = analyze_image(image_url, "test_api_key").await;
    
        mock.assert();
    
        assert!(result.is_ok());
        let objects = result.unwrap();
        assert_eq!(objects, vec!["Cat, ", "Sofa, ", "Plant, "]);
    }
    
    #[tokio::test]
    async fn test_create_genai_request() {
        let image_url = &get_sample_test_image_url();
        let result = create_genai_request(image_url).await;

        assert!(result.is_ok());
        let request = result.unwrap();

        assert_eq!(request.contents.len(), 1);
        assert_eq!(request.contents[0].parts.len(), 2);

        assert!(
            request.contents[0].parts[0].text.as_ref().unwrap().contains(
                &"Identify all objects in this image."
            )
        );
        assert!(request.contents[0].parts[0].inline_data.is_none());

        // assert_eq!(request.contents[0].parts[1].text, Some(image_url.to_string()));
        assert!(request.contents[0].parts[1].inline_data.is_some());
        assert!(request.contents[0].parts[1].text.is_none());
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
                        text: Some(r#"```json
    {
      "objects": [
        "Cat",
        "Dog",
        "Bird"
      ]
    }
    ```"#.to_string()),
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
        assert_eq!(objects, vec!["Cat, ", "Dog, ", "Bird, "]);
    }
    
    #[tokio::test]
    async fn test_process_genai_response_empty() {
        // Create an empty response
        let response = GeminiResponse {
            candidates: vec![Candidate {
                content: Content {
                    parts: vec![Part {
                        text: Some(r#"```json
    {
      "objects": []
    }
    ```"#.to_string()),
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
        assert!(objects.is_empty());
        println!("Empty response test passed successfully");
    }
    
    /// Test the analyze_image function with an actual API key and a test image.
    ///
    /// This test is currently disabled because it depends on a valid API key.
    /// To run this test, replace the API key with your own valid API key.
    ///
    /// This test will fail if the API key is invalid or if the test image is not accessible.
    ///
    #[tokio::test]
    async fn test_actual_analyze_image(){
    //     let test_image_url = get_sample_test_image_url();
        
    //     println!("Analyzing test image from URL: {}", test_image_url);
        
    //     // Use the same API key as in your original code
    //     let api_key = "$GEMINI_API_KEY";
        
    //     let results = analyze_image(&test_image_url, api_key).await.unwrap();
        
    //     // println!("Objects detected in the test image: {:#?}", results);
    //     assert!(!results.is_empty());
    }
}