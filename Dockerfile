FROM python:3.12-slim

# Install system dependencies including ffmpeg for audio/video extraction
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy dependency definition
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy backend application source
COPY src/backend /app/src/backend
COPY .env /app/.env

# Expose internal API port
EXPOSE 8000

# Command to run internal worker controller server
CMD ["python", "-m", "src.backend.main"]
