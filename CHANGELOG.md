# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-03-05

### Added
- Initial release of BCL Convert + QC Pipeline
- Batch processing of multiple BCL runs from CSV input
- BCL Convert demultiplexing (v4.2.7)
- FastQC quality control (v0.12.1)
- Optional fastq_screen contamination screening (v0.15.3)
- MultiQC aggregated reporting with custom titles per run (v1.25.2)
- Docker and Singularity container support via Wave
- SLURM execution profile
- Comprehensive documentation and examples
- Separate output directories per run
- Pipeline execution reports and DAG visualization

### Features
- Custom MultiQC report titles via `multiqc_title` column in input CSV
- Direct BCL Convert samplesheet support (any bcl-convert compatible format)
- Automatic parallelization of multiple runs
- Resume capability for failed workflows
- Resource labels for process requirements
- Version tracking for all tools
