FROM rockylinux:8

# Metadata
LABEL maintainer="your-email@example.com"
LABEL description="bcl2fastq2 v2.20 - Illumina demultiplexing software"
LABEL version="2.20.0"

# Install dependencies required by bcl2fastq2
RUN yum install -y \
    which \
    procps \
    unzip \
    && yum clean all \
    && rm -rf /var/cache/yum

# Copy the RPM file (you'll need to place it in the same directory as this Dockerfile)
COPY bcl2fastq2-*.rpm /tmp/

# Install bcl2fastq2 from RPM
RUN yum install -y /tmp/bcl2fastq2-*.rpm \
    && rm -f /tmp/bcl2fastq2-*.rpm \
    && yum clean all

# Verify installation
RUN bcl2fastq --version

# Set working directory
WORKDIR /data

# Default command
CMD ["bcl2fastq", "--help"]
