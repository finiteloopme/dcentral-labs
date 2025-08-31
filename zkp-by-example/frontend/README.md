# Frontend

This directory contains the React frontend for the multiplayer Sudoku game.

## Configuration

The frontend can be configured using environment variables.

| Environment Variable | Description                                   | Default                  |
| -------------------- | --------------------------------------------- | ------------------------ |
| `VITE_BACKEND_URL`   | The URL of the backend server.                | `http://localhost:3000`  |

### Example

To run the frontend with a different backend URL, you can use the following command:

```bash
VITE_BACKEND_URL=https://my-backend.com npm run dev
```