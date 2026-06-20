# Use slim Python base image
FROM python:3.11-slim

# Set working directory inside container
WORKDIR /app

ENV UV_CACHE_DIR=/tmp/.uv-cache

# Copy dependency files first (better caching)
COPY pyproject.toml uv.lock* ./

# Install uv (dependency manager)
RUN pip install uv

RUN uv sync --frozen --no-dev && rm -rf /tmp/.uv-cache

# Copy project files
COPY . .

RUN chown -R 1000:1000 /app

# Expose FastAPI default port
EXPOSE 8000

CMD ["/app/.venv/bin/uvicorn", "src.api.main:app", "--host", "0.0.0.0", "--port", "8000"]