# Pinned minimal base. For full MB compliance append the digest:
#   FROM python:3.12.8-slim-bookworm@sha256:<digest>
FROM python:3.12.8-slim-bookworm

WORKDIR /app

# Copy only what we need (never COPY . . — avoids .git/secrets)
COPY main.py ./

# Dedicated non-root user (MB policy)
RUN groupadd -r appgroup && useradd -r -g appgroup appuser
USER appuser

EXPOSE 8080

# Healthcheck (MB policy)
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD python -c "import urllib.request,sys; sys.exit(0) if urllib.request.urlopen('http://localhost:8080/').status==200 else sys.exit(1)" || exit 1

CMD ["python", "main.py"]