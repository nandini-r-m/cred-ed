# Use an official Python runtime as a parent image
# Python 3.10 is specified in render.yaml, let's stick to it for consistency.
# We use a slim-buster image to keep the size down.
FROM python:3.10-slim-buster # <-- This line ensures Python 3.10

# Set the working directory in the container
WORKDIR /app

# Install system dependencies required for numpy and other potential C extensions
# build-essential for general compilation tools
# gfortran for Fortran compiler (often needed by numpy/scipy)
# libopenblas-dev and liblapack-dev for optimized linear algebra libraries
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    gfortran \
    libopenblas-dev \
    liblapack-dev && \
    rm -rf /var/lib/apt/lists/*

# Copy the requirements file into the container
COPY requirements.txt .

# Install Python dependencies
# Upgrade pip and setuptools to ensure compatibility with newer packages
# Use --no-cache-dir to save space
RUN pip install --upgrade pip setuptools wheel
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of your application code
COPY . .

# Run the training script (this will create db.sqlite3)
# This must happen during the build phase so the DB is included in the image
RUN python train.py

# Expose the port that Gunicorn will listen on
EXPOSE 10000

# Command to run the application using Gunicorn
# Use the port defined by Render's environment variable (PORT)
CMD ["gunicorn", "--bind", "0.0.0.0:10000", "app:app"]
