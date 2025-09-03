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

## Proof Generation and Verification

### Proof Generation

1. A user submits a Sudoku solution to the backend.
2. The backend sends a proof request to the `proof-service`.
3. The `proof-service` generates a proof and sends it back to the backend.
4. The backend stores the proof and marks the puzzle as solved.

### Proof Verification

1. A user can verify a proof for a solved puzzle.
2. The frontend provides a UI to submit the proof, and public inputs.
3. The UI sends a request to the `proof-service` to verify the proof.
4. The `proof-service` verifies the proof and returns the result.

For more details on the input required by the verification service, please refer to the `dummy-proof-request.json` file in the `proof-service` directory.

### Building for Production

```bash
make build
```

### Docker

```bash
make docker-build
```

This will build Docker images for the `backend`, `frontend`, and `proof-service`.

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
>
    make gcb-deploy
    ```
