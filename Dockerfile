# ── Stage 1: Build ───────────────────────────────────────────────────
# We use a slim Python image to keep the final image small and secure.
FROM python:3.11-slim AS builder

WORKDIR /app

# Copy only requirements first — Docker caches this layer if unchanged
COPY app/requirements.txt .
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

# ── Stage 2: Final image ─────────────────────────────────────────────
FROM python:3.11-slim

WORKDIR /app

# Copy installed packages from builder stage
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Copy application code
COPY app/ .

# Security: run as non-root user
RUN useradd -m appuser
USER appuser

# Cloud Run injects PORT env variable (default 8080)
ENV PORT=8080
EXPOSE 8080

# Use gunicorn (production-grade server, NOT flask dev server)
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "2", "--timeout", "60", "app:app"]
