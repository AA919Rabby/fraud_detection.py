# Use the slim version of Python 3.12
FROM python:3.12-slim

# Set working directory
WORKDIR /app

# Install system dependencies required for compiling Python packages
# (gcc, python3-dev for ML packages; libpq-dev just in case for database)
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install
COPY requirements.txt .

# Upgrade pip to avoid wheel errors, then install packages
RUN pip install --upgrade pip
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of your project code
COPY . .

# Expose port for FastAPI
EXPOSE 8000

# Start the application
CMD ["uvicorn", "src.api:app", "--host", "0.0.0.0", "--port", "8000"]