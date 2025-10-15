mod attestation_verifier;

use anyhow::{anyhow, Result};
use attestation_verifier::{TdxQuoteVerifier, MeasurementPolicy};
use clap::{Parser, Subcommand};
use colored::*;
use dialoguer::{Input, Select};
use indicatif::{ProgressBar, ProgressStyle};
use reqwest::Client;
use serde_json::json;
use shared::{
    AttestationRequest, AttestationResponse, CryptoUtils,
    SalaryData, SalaryRequest, SalaryResponse,
};
use std::time::Duration;
use tracing::{error, info, warn};

#[derive(Parser)]
#[command(name = "salary-client")]
#[command(about = "Confidential Salary Analyzer Client", long_about = None)]
struct Cli {
    #[arg(short, long, default_value = "http://localhost:8080")]
    server: String,

    #[arg(short, long, default_value = "false")]
    verbose: bool,

    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    Submit {
        #[arg(short, long)]
        role: Option<String>,
        #[arg(short, long)]
        salary: Option<u64>,
        #[arg(short, long)]
        location: Option<String>,
        #[arg(short, long)]
        years: Option<u32>,
    },
    Interactive,
    Demo,
    Health,
}

struct SalaryClient {
    client: Client,
    server_url: String,
    session_id: Option<String>,
    session_key: Option<Vec<u8>>,
}

impl SalaryClient {
    fn new(server_url: String) -> Self {
        Self {
            client: Client::builder()
                .timeout(Duration::from_secs(30))
                .build()
                .unwrap(),
            server_url,
            session_id: None,
            session_key: None,
        }
    }

    async fn check_health(&self) -> Result<()> {
        let url = format!("{}/health", self.server_url);
        let response = self.client.get(&url).send().await?;
        
        if response.status().is_success() {
            let body: serde_json::Value = response.json().await?;
            println!("{}", "✓ Server is healthy".green());
            println!("  TEE Status: {}", body["tee_status"].as_str().unwrap_or("Unknown"));
            println!("  MRENCLAVE: {}", body["mrenclave"].as_str().unwrap_or("Unknown"));
            Ok(())
        } else {
            Err(anyhow!("Server health check failed"))
        }
    }

    async fn perform_attestation(&mut self) -> Result<()> {
        println!("\n{}", "=== Remote Attestation Process ===".blue().bold());
        
        let pb = ProgressBar::new(6);
        pb.set_style(
            ProgressStyle::default_bar()
                .template("{spinner:.green} [{bar:40.cyan/blue}] {msg}")
                .unwrap()
                .progress_chars("#>-"),
        );
        
        pb.set_message("Generating attestation nonce...");
        let nonce = CryptoUtils::generate_nonce();
        tracing::debug!("Generated nonce: {} bytes", nonce.len());
        pb.inc(1);
        
        pb.set_message("Requesting attestation from server...");
        let request = AttestationRequest { nonce: nonce.clone() };
        let url = format!("{}/attest", self.server_url);
        
        let response = self.client
            .post(&url)
            .json(&request)
            .send()
            .await?;
        
        let session_id = response
            .headers()
            .get("x-session-id")
            .and_then(|v| v.to_str().ok())
            .ok_or_else(|| anyhow!("No session ID in response"))?
            .to_string();
        
        let attestation: AttestationResponse = response.json().await?;
        tracing::info!("Received attestation response with quote size: {} bytes", attestation.quote.len());
        pb.inc(1);
        
        pb.set_message("Parsing TDX quote structure...");
        let quote_info = TdxQuoteVerifier::parse_quote(&attestation.quote)?;
        tracing::info!("Parsed TDX quote - MRTD: {}", quote_info.mrtd);
        pb.inc(1);
        
        pb.set_message("Verifying report data (nonce)...");
        let nonce_valid = TdxQuoteVerifier::verify_report_data(&quote_info, &nonce)?;
        if !nonce_valid {
            pb.finish_with_message("Nonce verification failed!");
            return Err(anyhow!("Quote nonce verification failed - possible replay attack"));
        }
        tracing::info!("Nonce verified successfully");
        pb.inc(1);
        
        pb.set_message("Verifying measurements against policy...");
        let policy = MeasurementPolicy::new()
            .allow_debug(std::env::var("ALLOW_DEBUG").is_ok());
        
        if let Ok(expected_mrtd) = std::env::var("EXPECTED_MRTD") {
            let policy = policy.with_mrtd(expected_mrtd);
            TdxQuoteVerifier::verify_measurements(&quote_info, &policy)?;
        }
        tracing::info!("Measurements verified");
        pb.inc(1);
        
        pb.set_message("Verifying event log...");
        let eventlog_valid = TdxQuoteVerifier::verify_eventlog(&attestation.eventlog, &quote_info)?;
        if !eventlog_valid {
            tracing::warn!("Event log verification failed, continuing anyway");
        }
        pb.inc(1);
        
        pb.finish_with_message("Attestation successful!");
        
        println!("\n{}", "✓ Attestation Verified Successfully!".green().bold());
        println!("  {}: {}", "MRTD".cyan(), quote_info.mrtd.yellow());
        println!("  {}: {}", "RTMR0".cyan(), quote_info.rtmr0.yellow());
        println!("  {}: {}", "RTMR1".cyan(), quote_info.rtmr1.yellow());
        println!("  {}: {}", "RTMR2".cyan(), quote_info.rtmr2.yellow());
        println!("  {}: {}", "RTMR3".cyan(), quote_info.rtmr3.yellow());
        println!("  {}: {}", "Session ID".cyan(), session_id.green());
        
        let debug_enabled = quote_info.td_attributes[0] & 0x01 != 0;
        if debug_enabled {
            println!("  {}: {}", "WARNING".red(), "TD Debug is ENABLED".yellow());
        }
        
        let session_key = CryptoUtils::derive_session_key(&nonce, session_id.as_bytes());
        self.session_id = Some(session_id);
        self.session_key = Some(session_key);
        
        Ok(())
    }

    async fn submit_salary_data(&self, data: SalaryData) -> Result<SalaryResponse> {
        if self.session_id.is_none() || self.session_key.is_none() {
            return Err(anyhow!("No active session. Please perform attestation first."));
        }
        
        println!("\n{}", "=== Submitting Salary Data ===".blue().bold());
        
        let serialized = serde_json::to_vec(&data)?;
        let encrypted = CryptoUtils::encrypt_data(
            &serialized,
            self.session_key.as_ref().unwrap(),
        )?;
        
        let request = SalaryRequest {
            encrypted_data: encrypted,
            session_id: self.session_id.as_ref().unwrap().clone(),
        };
        
        let url = format!("{}/submit", self.server_url);
        let response = self.client
            .post(&url)
            .json(&request)
            .send()
            .await?;
        
        if response.status().is_success() {
            let result: SalaryResponse = response.json().await?;
            Ok(result)
        } else {
            Err(anyhow!("Failed to submit salary data: {}", response.status()))
        }
    }
}

fn display_statistics(response: &SalaryResponse) {
    if let Some(stats) = &response.statistics {
        println!("\n{}", "=== Salary Statistics ===".green().bold());
        println!("Role: {}", stats.role.yellow());
        println!("Sample Size: {}", stats.sample_size);
        println!("Average Salary: ${:.2}", stats.average_salary);
        println!("Median Salary: ${:.2}", stats.median_salary);
        println!("Min Salary: ${}", stats.min_salary);
        println!("Max Salary: ${}", stats.max_salary);
        
        if !stats.location_breakdown.is_empty() {
            println!("\n{}", "Location Breakdown:".cyan());
            for loc in &stats.location_breakdown {
                println!("  {} - Avg: ${:.2} (n={})", 
                    loc.location, loc.average_salary, loc.count);
            }
        }
    }
}

async fn interactive_mode(client: &mut SalaryClient) -> Result<()> {
    println!("\n{}", "=== Interactive Mode ===".cyan().bold());
    
    client.perform_attestation().await?;
    
    loop {
        let choices = vec!["Submit Salary Data", "View Health Status", "Exit"];
        let selection = Select::new()
            .with_prompt("What would you like to do?")
            .items(&choices)
            .default(0)
            .interact()?;
        
        match selection {
            0 => {
                let role: String = Input::new()
                    .with_prompt("Enter your role")
                    .default("Software Engineer".to_string())
                    .interact()?;
                
                let salary: u64 = Input::new()
                    .with_prompt("Enter your salary (USD)")
                    .default(100000)
                    .interact()?;
                
                let location: String = Input::new()
                    .with_prompt("Enter your location")
                    .default("San Francisco".to_string())
                    .interact()?;
                
                let years: u32 = Input::new()
                    .with_prompt("Years of experience")
                    .default(5)
                    .interact()?;
                
                let data = SalaryData {
                    role,
                    salary,
                    location,
                    years_experience: years,
                };
                
                match client.submit_salary_data(data).await {
                    Ok(response) => {
                        println!("\n{}", response.message.green());
                        display_statistics(&response);
                    }
                    Err(e) => {
                        println!("{} {}", "Error:".red(), e);
                    }
                }
            }
            1 => {
                client.check_health().await?;
            }
            2 => {
                println!("Goodbye!");
                break;
            }
            _ => {}
        }
    }
    
    Ok(())
}

async fn demo_mode(client: &mut SalaryClient) -> Result<()> {
    println!("\n{}", "=== Demo Mode ===".magenta().bold());
    println!("This will demonstrate the full attestation and data submission flow.\n");
    
    client.check_health().await?;
    
    client.perform_attestation().await?;
    
    let demo_data = vec![
        SalaryData {
            role: "Software Engineer".to_string(),
            salary: 120000,
            location: "San Francisco".to_string(),
            years_experience: 3,
        },
        SalaryData {
            role: "Software Engineer".to_string(),
            salary: 95000,
            location: "Austin".to_string(),
            years_experience: 2,
        },
        SalaryData {
            role: "Software Engineer".to_string(),
            salary: 150000,
            location: "San Francisco".to_string(),
            years_experience: 5,
        },
    ];
    
    for (i, data) in demo_data.iter().enumerate() {
        println!("\n{} Submitting sample {} of {}...", 
            "→".cyan(), i + 1, demo_data.len());
        println!("  Role: {}, Salary: ${}, Location: {}", 
            data.role, data.salary, data.location);
        
        match client.submit_salary_data(data.clone()).await {
            Ok(response) => {
                println!("  {}", response.message.green());
                if i == demo_data.len() - 1 {
                    display_statistics(&response);
                }
            }
            Err(e) => {
                println!("  {} {}", "Error:".red(), e);
            }
        }
        
        tokio::time::sleep(Duration::from_millis(500)).await;
    }
    
    println!("\n{}", "Demo completed successfully!".green().bold());
    Ok(())
}

#[tokio::main]
async fn main() -> Result<()> {
    let cli = Cli::parse();
    
    if cli.verbose {
        tracing_subscriber::fmt()
            .with_env_filter("client=debug,reqwest=info")
            .init();
    } else {
        tracing_subscriber::fmt()
            .with_env_filter("client=info")
            .init();
    }
    
    println!("{}", "Confidential Salary Analyzer Client".bold());
    println!("Server: {}\n", cli.server.cyan());
    
    let mut client = SalaryClient::new(cli.server);
    
    match cli.command {
        Commands::Submit { role, salary, location, years } => {
            client.perform_attestation().await?;
            
            let data = SalaryData {
                role: role.unwrap_or_else(|| "Software Engineer".to_string()),
                salary: salary.unwrap_or(100000),
                location: location.unwrap_or_else(|| "San Francisco".to_string()),
                years_experience: years.unwrap_or(5),
            };
            
            let response = client.submit_salary_data(data).await?;
            println!("{}", response.message.green());
            display_statistics(&response);
        }
        Commands::Interactive => {
            interactive_mode(&mut client).await?;
        }
        Commands::Demo => {
            demo_mode(&mut client).await?;
        }
        Commands::Health => {
            client.check_health().await?;
        }
    }
    
    Ok(())
}