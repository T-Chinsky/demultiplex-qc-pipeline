FROM ubuntu:22.04

# Metadata
LABEL maintainer="your-email@example.com"
LABEL description="BCL Convert 4.4.6 - Illumina demultiplexing software"
LABEL version="4.4.6"

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && \
    apt-get install -y \
    alien \
    procps \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Copy the RPM file (you'll need to place it in the same directory as this Dockerfile)
COPY bcl-convert-*.rpm /tmp/

# Convert RPM to DEB and install BCL Convert
RUN cd /tmp && \
    alien -i bcl-convert-*.rpm && \
    rm -f /tmp/bcl-convert-*.rpm

# Verify installation
RUN bcl-convert --version

# Set working directory
WORKDIR /data

# Default command
CMD ["bcl-convert", "--help"]
