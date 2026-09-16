# Backend prototype

The backend currently lives in [`notebooks/agentrag_backend.ipynb`](notebooks/agentrag_backend.ipynb). It is a research and demonstration notebook that contains the retrieval pipeline and a FastAPI wrapper.

## Pipeline responsibilities

1. Accept PDF, DOCX, TXT, CSV, or Markdown uploads.
2. Extract and clean text while retaining source metadata.
3. Split documents into chunks of approximately 800 characters with 150-character overlap.
4. Create normalized `BAAI/bge-small-en-v1.5` embeddings and index them with FAISS.
5. Retrieve relevant context with similarity search and maximal marginal relevance.
6. Let `ImprovedReActAgent` search the index before asking `Mistral-Nemo-Instruct-2407` to produce an answer.

## API surface

- `GET /` - health message.
- `POST /upload-file/` - multipart upload under the `file` field.
- `POST /query` - JSON body with a `query` string.

## Prototype boundaries

This notebook is intentionally kept as the source of the current implementation, but it should not be mistaken for a production backend. It currently uses in-memory retrieval state, a local upload directory, permissive CORS, and development-oriented tunnel code. The hardening path is documented in [`../docs/architecture.md`](../docs/architecture.md) and the root README.
