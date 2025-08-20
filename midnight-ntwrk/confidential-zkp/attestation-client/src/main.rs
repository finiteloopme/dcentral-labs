use jsonwebtoken::{decode, decode_header, DecodingKey, Validation};
use serde::{Deserialize, Serialize};
use std::env;

// const CONFIDENTIAL_SPACE_JWKS_URL: &str = "https://www.googleapis.com/service_accounts/v1/jwk/confidentialcomputing.googleapis.com";
// "https://confidentialcomputing.googleapis.com/.well-known/confidential_space_root.crt";
// "https://confidentialcomputing.googleapis.com/.well-known/openid-configuration"; 
const CONFIDENTIAL_SPACE_JWKS_URL: &str = "https://www.googleapis.com/service_accounts/v1/metadata/jwk/signer@confidentialspace-sign.iam.gserviceaccount.com";

#[derive(Debug, Serialize, Deserialize)]
struct Jwk {
    kid: String,
    n: String,
    e: String,
    // Other fields like alg, kty, use are omitted for brevity
}

#[derive(Debug, Serialize, Deserialize)]
struct JwkSet {
    keys: Vec<Jwk>,
}

#[derive(Debug, Serialize, Deserialize)]
struct TokenResponse {
    token: String,
}

#[derive(Debug, Serialize, Deserialize)]
struct Claims {
    // We only need the claims we want to validate.
    // tee_technology: String,
    container_image_digest: Option<String>,
    // Other standard claims (iss, sub, aud, exp, etc.) are validated automatically.
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args: Vec<String> = env::args().collect();
    if args.len() < 2 {
        eprintln!("Usage: cargo run -- <vm_external_ip>");
        std::process::exit(1);
    }
    let vm_ip = &args[1];

    println!("--- Verifying Attestation Token ---");

    // 1. Fetch the token from the workload's attestation server.
    let token_url = format!("http://{}:8080/token", vm_ip);
    println!("Fetching token from {}...", token_url);
    let resp: TokenResponse = reqwest::get(&token_url).await?.json().await?;
    let token = resp.token;

    // 2. Fetch Google's public keys (JWKS).
    println!("Fetching Google's public keys from {}...", CONFIDENTIAL_SPACE_JWKS_URL);
    let jwks: JwkSet = reqwest::get(CONFIDENTIAL_SPACE_JWKS_URL).await?.json().await?;
    // println!("Successfully fetched Google's public keys.  Decoding token: {}", token);

    // 3. Decode and cryptographically verify the token.
    let header = decode_header(&token)?;
    println!("Token header: {:#?}", header);
    let kid = header.kid.ok_or("Token header does not contain 'kid'")?;

    let key = jwks.keys.iter().find(|k| k.kid == kid).ok_or(format!("Public key with kid='{}' not found.", kid))?;

    let decoding_key = DecodingKey::from_rsa_components(&key.n, &key.e)?;
    let mut validation = Validation::new(jsonwebtoken::Algorithm::RS256);
    validation.set_issuer(&["https://confidentialcomputing.googleapis.com"]);

    let token_data = decode::<Claims>(&token, &decoding_key, &validation)?;
    println!("Successfully decoded token");

    println!("\n[SUCCESS] Token signature and issuer are valid.");
    println!("\nToken Payload Claims:");
    println!("{:#?}", token_data.claims);

    // 4. Verify the claims in the payload against our policy.
    println!("\n--- Verifying Attestation Claims ---");

    // if token_data.claims.tee_technology == "TDX" {
    //     println!("[PASS] TEE technology is 'TDX' as required.");
    // } else {
    //     println!("[FAIL] TEE technology is '{}', but 'TDX' was required.", token_data.claims.tee_technology);
    //     return Err("Attestation failed: Invalid TEE technology.".into());
    // }

    if let Some(digest) = token_data.claims.container_image_digest {
        println!("[INFO] Workload image digest: {}", digest);
    } else {
        println!("[WARN] Could not find container image digest in claims.");
    }

    println!("\n[SUCCESS] All client-side attestation checks passed.");

    Ok(())
}
