# BCL Convert 4.4.6 Docker Image

This directory contains the Dockerfile to build a Docker image for Illumina BCL Convert 4.4.6.

## Prerequisites

1. Download the BCL Convert 4.4.6 RPM from Illumina:
   - File name should be something like: `bcl-convert-4.4.6-2.el8.x86_64.rpm`
   - Place it in this directory (same location as the Dockerfile)

## Building the Docker Image

### Local Build

```bash
# Navigate to this directory
cd docker/bclconvert/

# Build the image
docker build -t bcl-convert:4.4.6 .

# Or with a custom tag
docker build -t your-dockerhub-username/bcl-convert:4.4.6 .
```

### Push to Docker Hub (Optional)

```bash
# Login to Docker Hub
docker login

# Push the image
docker push your-dockerhub-username/bcl-convert:4.4.6
```

### Push to a Private Registry

```bash
# Tag for your private registry
docker tag bcl-convert:4.4.6 your-registry.com/bcl-convert:4.4.6

# Login to your registry
docker login your-registry.com

# Push
docker push your-registry.com/bcl-convert:4.4.6
```

## Testing the Image

```bash
# Test that BCL Convert is installed correctly
docker run --rm bcl-convert:4.4.6 bcl-convert --version

# Run with a sample command
docker run --rm -v /path/to/data:/data bcl-convert:4.4.6 bcl-convert --help
```

## Using in Nextflow Pipeline

Once built and pushed, update the container directive in `modules/local/bclconvert.nf`:

```groovy
container 'your-dockerhub-username/bcl-convert:4.4.6'
# or
container 'your-registry.com/bcl-convert:4.4.6'
```

## Alternative: Using Wave to Build from Docker Image

If you've pushed to Docker Hub, you can reference it directly in Nextflow without Wave:

```groovy
container 'docker://your-dockerhub-username/bcl-convert:4.4.6'
```

## Troubleshooting

### RPM Installation Fails
- Ensure the RPM file is in the same directory as the Dockerfile
- The Dockerfile uses `alien` to convert the RPM to DEB format for Ubuntu
- If conversion fails, you may need to install dependencies manually

### Permission Issues
- The container runs as root by default
- You may need to adjust file permissions or add a non-root user

### Version Mismatch
- Run `docker run --rm bcl-convert:4.4.6 bcl-convert --version` to verify
- The version should show 4.4.6
