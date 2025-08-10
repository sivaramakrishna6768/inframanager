FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Non-root user
RUN useradd -m appuser
WORKDIR /app

# Install deps
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy app code
COPY src/ /app/

EXPOSE 80
USER appuser

# Production server
CMD ["gunicorn", "-w", "2", "-b", "0.0.0.0:80", "app:app"]
