# Usage

Use the `Dockerfile` in the home directory only for local dev.
## Sample build cmd
```bash
docker build -t local-onchain-agent .
docker run --rm --net=host local-onchain-agent
```

The two applications `ai-agent` and `frontend` should be deployed as separate apps.
