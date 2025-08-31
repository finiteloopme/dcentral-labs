# ZKP by Example: Multiplayer Sudoku

This project is a multiplayer Sudoku game where players can compete to solve puzzles the fastest.

## Project Structure

- `backend`: The Rust backend server (Axum).
- `frontend`: The TypeScript and React frontend.
- `Makefile`: Contains commands for building, running, and deploying the application.

## Getting Started

### Prerequisites

- Rust
- Node.js
- Docker
- Google Cloud SDK

### Local Development

1.  **Start the backend:**

    ```bash
    make backend-dev
    ```

2.  **Start the frontend:**

    ```bash
    make frontend-dev
    ```

### Building for Production

```bash
make build
```

### Docker

```bash
make docker-build
```

### Google Cloud Build & Deploy

**Note:** You need to have a Google Cloud project and have the `gcloud` CLI configured.

1.  **Build on GCB:**

    ```bash
    export GCP_PROJECT=<your-gcp-project-id>
    make gcb-build
    ```

2.  **Deploy to Cloud Run:**

    ```bash
    export GCP_PROJECT=<your-gcp-project-id>
    make gcb-deploy
    ```
