# Use official R image
FROM rocker/r-ver:4.3.1

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -rf awscliv2.zip aws/

# Install R package dependencies
RUN R -e "install.packages(c('dplyr', 'tidyr', 'lubridate', 'httr', 'jsonlite', 'arrow', 'ggplot2'), repos='https://cloud.r-project.org/')"

# Set working directory
WORKDIR /app

# Copy package files
COPY DESCRIPTION NAMESPACE ./
COPY R/ ./R/
COPY man/ ./man/

# Install the package
RUN R -e "install.packages('.', repos=NULL, type='source')"

# Copy scripts directory
COPY scripts/ ./scripts/

# Create cache directory
RUN mkdir -p cache

# Set entrypoint to run the AWS pipeline script
CMD ["Rscript", "scripts/run_pipeline_aws.R"]
