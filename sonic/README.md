# Usage

Use the `Dockerfile` in the home directory only for local dev.
## Sample build cmd
```bash
docker build -t local-onchain-agent .
docker run --rm --net=host local-onchain-agent
```

## Local dev
```bash
# ai-agent
pnpm dev
# frontend
npm start
```

The two applications `ai-agent` and `frontend` should be deployed as separate apps.
