# Use official R image
FROM rocker/r-ver:4.4.2

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    unzip \
    # Build tools
    pkg-config \
    cmake \
    git \
    # Compression (httpuv needs this)
    zlib1g-dev \
    # Graphics/Fonts
    libfontconfig1-dev \
    libfreetype6-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    # Image formats
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    # Git support
    libgit2-dev \
    # X11
    libx11-dev \
    # Documentation
    pandoc \
    && rm -rf /var/lib/apt/lists/*

# Install AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -rf awscliv2.zip aws/

# Set working directory
WORKDIR /app

# Install renv package for dependency management
RUN R -e "install.packages('renv', repos='https://cloud.r-project.org/')"

# Copy renv configuration files
COPY renv.lock renv.lock
COPY .Rprofile .Rprofile
COPY renv/activate.R renv/activate.R
COPY renv/settings.json renv/settings.json

# Restore R packages from renv lockfile
# This installs exact versions specified in renv.lock
RUN R -e "renv::restore()"

# Copy package files
COPY DESCRIPTION NAMESPACE ./
COPY R/ ./R/
COPY man/ ./man/

# Copy scripts directory
COPY scripts/ ./scripts/

# Create cache directory
RUN mkdir -p cache

# Disable renv autoloader - use pre-installed packages from Docker build
ENV RENV_CONFIG_AUTOLOADER_ENABLED=FALSE

# Set entrypoint to run the AWS pipeline script
CMD ["Rscript", "scripts/run_pipeline_aws.R"]
