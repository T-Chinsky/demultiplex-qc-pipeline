# Push BCL Convert Pipeline to GitHub

Your pipeline is ready to push to GitHub! Follow these steps:

## 📋 Quick Steps

### 1. Create a New GitHub Repository

Go to: **https://github.com/new**

- **Repository name**: `bcl-convert-pipeline` (or your preferred name)
- **Description**: "Nextflow pipeline for BCL demultiplexing and comprehensive QC"
- **Visibility**: Choose Public or Private
- ⚠️ **Do NOT** initialize with README, .gitignore, or license (we already have these)

Click **"Create repository"**

### 2. Push Your Local Repository

After creating the repo on GitHub, run these commands:

```bash
cd bcl-convert-pipeline

# Set the default branch to 'main'
git branch -M main

# Add your GitHub repository as remote (replace YOUR_USERNAME)
git remote add origin https://github.com/YOUR_USERNAME/bcl-convert-pipeline.git

# Push to GitHub
git push -u origin main
```

### 3. Verify on GitHub

Visit your repository: `https://github.com/YOUR_USERNAME/bcl-convert-pipeline`

You should see:
- ✅ All files and modules
- ✅ README.md displayed on the homepage
- ✅ Professional structure with LICENSE

## 🚀 Using Your Pipeline

Once pushed, anyone can run your pipeline with:

```bash
nextflow run YOUR_USERNAME/bcl-convert-pipeline \
  --samplesheet /path/to/SampleSheet.csv \
  --run_dir /path/to/bcl/run \
  --outdir results
```

## 📦 What's Included

Your repository contains:

```
bcl-convert-pipeline/
├── .gitignore                    # Git ignore rules
├── LICENSE                       # MIT license
├── README.md                     # User-facing documentation
├── main.nf                       # Main workflow
├── nextflow.config               # Pipeline configuration
├── samplesheet_example.csv       # Example input file
└── modules/                      # Modular process definitions
    ├── bclconvert.nf
    ├── fastqc.nf
    ├── fastq_screen.nf
    └── multiqc.nf
```

## ✅ Quality Checks Passed

- ✅ **Nextflow lint**: All files passed linting
- ✅ **DSL2 syntax**: Modern Nextflow standards
- ✅ **Wave containers**: All tools pre-built and ready
- ✅ **Documentation**: Comprehensive README
- ✅ **Git structure**: Clean, professional repository

## 🎯 Next Steps

After pushing to GitHub:

1. **Add topics** to your repo: `nextflow`, `bioinformatics`, `bcl-convert`, `genomics`
2. **Set up CI/CD** with GitHub Actions (optional)
3. **Share** with your team
4. **Star** the repository for visibility

## 🔧 Troubleshooting

### Authentication Issues

If you get authentication errors, use a Personal Access Token:

1. Go to: https://github.com/settings/tokens
2. Generate a new token with `repo` scope
3. Use the token as your password when pushing

Or set up SSH keys: https://docs.github.com/en/authentication/connecting-to-github-with-ssh

### Already Exists Error

If you get "repository already exists":
```bash
git remote set-url origin https://github.com/YOUR_USERNAME/bcl-convert-pipeline.git
git push -u origin main
```

## 📞 Support

- Nextflow Documentation: https://www.nextflow.io/docs/latest/
- Seqera Community: https://community.seqera.io/
- Wave Containers: https://wave.seqera.io/

---

Happy sequencing! 🧬
