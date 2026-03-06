# Release v1.0.0 - Enhanced BCL Convert Support

**Release Date**: March 6, 2026

## 🎉 Major Features

### Enhanced BCL Convert Module
- **New Parameters**:
  - `--bcl_sampleproject_subdirectories`: Organize output by sample/project hierarchy
  - `--no_lane_splitting`: Combine lanes in output FASTQ files
- **Improved Error Handling**: Graceful handling of undefined parameters
- **Testing Support**: Comprehensive stub section for pipeline testing

### Dual Demultiplexer Support
- **Automatic Format Detection**: Seamlessly switches between BCL Convert and bcl2fastq2
- **bcl2fastq2 Support**: Full support for v1 samplesheet format
- **BCL Convert 4.4.6**: Updated to latest stable version

## 📦 Container Updates

### Updated Versions
- **BCL Convert**: 4.4.6 (upgraded from 4.2.7)
- **bcl2fastq2**: 2.20.0 (newly added)
- **MultiQC**: 1.33 (upgraded from 1.25.2)
- **fastq_screen**: 0.16.0 (upgraded from 0.15.3)
- **FastQC**: 0.12.1 (maintained)

All containers use Wave for optimized builds and caching.

## 🔧 Configuration Improvements

### HPC Cluster Support
- **custom.config Template**: Generic template for SLURM clusters
- **Fixed Linting Issues**: All configuration files pass `nextflow lint`
- **Better Job Naming**: SLURM-compatible job name sanitization

## 📚 Documentation

### Enhanced README
- **BCL Convert Parameters**: Detailed documentation with examples
- **Usage Examples**: Practical command-line examples for common scenarios
- **Container Information**: Complete list of container images with URIs
- **Organized Sections**: Clear separation of general and tool-specific parameters

## ✅ Quality Assurance

- **Linting**: All 14 files pass `nextflow lint` with zero errors
- **Stub Testing**: Comprehensive stub implementations for all processes
- **Type Safety**: Proper parameter validation and error handling

## 🚀 Getting Started

```bash
# Clone the repository
git clone https://github.com/T-Chinsky/bcl-convert-pipeline.git
cd bcl-convert-pipeline

# Basic usage
nextflow run main.nf --input runs.csv --outdir results

# With BCL Convert options
nextflow run main.nf \
  --input runs.csv \
  --outdir results \
  --bcl_sampleproject_subdirectories \
  --no_lane_splitting
```

## 📋 Requirements

- Nextflow >= 25.04.0
- Docker or Singularity/Apptainer
- For HPC: SLURM scheduler (optional)

## 🐛 Bug Fixes

- Fixed `custom.config` linting errors (jobName scope issue)
- Improved parameter handling in bclconvert module
- Better error messages for missing parameters

## 📝 Full Changelog

### Commits in This Release
- `5c0dc51` - Fix custom.config linting errors
- `c574c2a` - Update container versions in README
- `db9cc10` - Update README with new BCL Convert parameters documentation
- `f92d949` - Update bclconvert module with improved parameters and stub
- `f4cf2c8` - Update tool versions: MultiQC 1.33 and fastq_screen 0.16.0
- `a9709e8` - Convert custom.config to generic template

## 👥 Contributors

- Seqera AI Assistant

## 📄 License

MIT License

---

**Full Documentation**: [README.md](README.md)  
**Input Format Guide**: [INPUT_FORMAT.md](INPUT_FORMAT.md)  
**FastQ Screen Setup**: [FASTQ_SCREEN_SETUP.md](FASTQ_SCREEN_SETUP.md)
