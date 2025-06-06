# Use an official Python runtime as a parent image.
# We're specifically choosing Python 3.10 based on your local environment (3.10.8).
# The 'slim-buster' variant is lightweight and based on Debian, suitable for production.
FROM python:3.10-slim-buster

# Set the working directory inside the container.
# All subsequent commands will be run from this directory.
WORKDIR /app

# Install system dependencies required for building Python packages like NumPy and Pandas,
# which often involve C/Fortran extensions.
# 'build-essential' provides compilers (gcc, g++) and make.
# 'gfortran' is the Fortran compiler, essential for many scientific libraries.
# 'libopenblas-dev' and 'liblapack-dev' provide optimized linear algebra libraries
# that NumPy/SciPy can link against for better performance.
# '--no-install-recommends' helps keep the image size down.
# The 'rm -rf /var/lib/apt/lists/*' cleans up apt cache to further reduce image size.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    gfortran \
    libopenblas-dev \
    liblapack-dev && \
    rm -rf /var/lib/apt/lists/*

# Copy your Python dependency file into the container.
# This allows Docker to cache the layer of dependency installation.
COPY requirements.txt .

# Install Python dependencies.
# First, upgrade pip, setuptools, and wheel to their latest versions to avoid
# potential issues with older package installers.
# Then, install your project's dependencies from requirements.txt.
# '--no-cache-dir' prevents pip from storing downloaded packages, saving image space.
RUN pip install --upgrade pip setuptools wheel
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of your application code into the container.
# This copies app.py, train.py, custom_corpus folder, safety_locations.csv, etc.
# The '.' indicates copying everything from the current directory on the host to
# the WORKDIR (/app) in the container.
COPY . .

# Run the training script to create the 'db.sqlite3' database.
# This step is crucial so that the trained chatbot model is baked into the Docker image.
# If this were done at runtime, the database would be ephemeral on Render's free plan.
RUN python train.py

# Expose the port that your Flask application (via Gunicorn) will listen on.
# Render automatically injects a PORT environment variable, and we'll use 10000
# as a consistent internal port, as specified in your render.yaml.
EXPOSE 10000

# Define the command to run your application when the container starts.
# Gunicorn is used to serve the Flask application.
# '--bind 0.0.0.0:10000' tells Gunicorn to listen on all network interfaces
# on port 10000, making it accessible within the Render environment.
# 'app:app' refers to the Flask application instance named 'app' inside the 'app.py' file.
CMD ["gunicorn", "--bind", "0.0.0.0:10000", "app:app"]
