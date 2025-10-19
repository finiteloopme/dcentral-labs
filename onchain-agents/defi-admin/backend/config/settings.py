from pydantic import BaseSettings
from typing import Optional

class Settings(BaseSettings):
    app_name: str = "DeFi Admin"
    version: str = "0.1.0"
    debug: bool = True
    
    api_host: str = "0.0.0.0"
    api_port: int = 8000
    
    database_url: str = "sqlite:///./defi_admin.db"
    redis_url: str = "redis://localhost:6379"
    
    # Chain configuration is now in chains.toml
    chains_config_path: str = "config/chains.toml"
    
    openai_api_key: Optional[str] = None
    
    defillama_api_url: str = "https://api.llama.fi"
    coingecko_api_url: str = "https://api.coingecko.com/api/v3"
    
    cors_origins: list = ["http://localhost:3000", "http://localhost:3001"]
    
    class Config:
        env_file = ".env"

settings = Settings()