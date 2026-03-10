# BCL QC Pipeline - Documentation Index

## 🚀 Quick Navigation

### **New Users - Start Here!**
1. **[QUICK_START.md](QUICK_START.md)** - Get running in 5 minutes
2. **[README.md](README.md)** - Complete usage guide and reference

### **Having Issues?**
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - Common problems and solutions

### **Understanding the Pipeline**
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Design, data flow, and structure
- **[README.md § Pipeline Output](README.md#pipeline-output)** - Output files and formats

### **Testing**
- **[tests/README.md](tests/README.md)** - Testing guide and infrastructure

---

## 📚 Document Guide

| Document | Purpose | Audience |
|----------|---------|----------|
| **QUICK_START.md** | Fastest path to running pipeline | End users |
| **README.md** | Complete documentation and reference | All users |
| **TROUBLESHOOTING.md** | Error solutions and debugging | Users having issues |
| **ARCHITECTURE.md** | Technical design and data flow | Developers |
| **tests/README.md** | Testing procedures | Developers/QA |

---

## 🎯 Common Tasks

### I want to...

| Task | Go to |
|------|-------|
| **Run the pipeline** | [QUICK_START.md § Basic Usage](QUICK_START.md#2-run-the-pipeline) |
| **Understand parameters** | [README.md § Parameters](README.md#parameters) |
| **Fix an error** | [TROUBLESHOOTING.md](TROUBLESHOOTING.md) |
| **Run tests** | [tests/README.md § Quick Start](tests/README.md#-quick-start) |
| **Understand workflow** | [ARCHITECTURE.md § Data Flow](ARCHITECTURE.md#-detailed-data-flow) |
| **Add a new module** | [ARCHITECTURE.md § Extension Points](ARCHITECTURE.md#-extension-points) |
| **Check outputs** | [README.md § Pipeline Output](README.md#pipeline-output) |

---

## 📁 Project Structure

```
demultiplex-qc-pipeline/
│
├── 📖 Documentation
│   ├── INDEX.md (this file)
│   ├── QUICK_START.md
│   ├── README.md
│   ├── TROUBLESHOOTING.md
│   └── ARCHITECTURE.md
│
├── 🔬 Pipeline Code
│   ├── main.nf
│   ├── nextflow.config
│   ├── workflows/
│   ├── subworkflows/
│   └── modules/
│
├── ⚙️ Configuration
│   └── conf/
│       ├── base.config
│       ├── modules.config
│       └── test.config
│
└── 🧪 Testing
    └── tests/
        ├── README.md
        ├── *.nf.test
        └── data/
```

---

## ✅ Pipeline Status

| Component | Status |
|-----------|--------|
| **Code Quality** | ✅ All files pass `nextflow lint` |
| **Documentation** | ✅ Comprehensive docs complete |
| **Test Infrastructure** | ✅ nf-test framework configured |
| **Production Ready** | ✅ Ready for deployment |

---

## 🎓 Learning Path

### Beginner
1. Read [QUICK_START.md](QUICK_START.md)
2. Run test profile: `nextflow run main.nf -profile test,docker`
3. Try with your data using examples in QUICK_START.md

### Intermediate
1. Read full [README.md](README.md)
2. Understand parameters and configuration
3. Run tests: `nf-test test tests/`
4. Explore [ARCHITECTURE.md](ARCHITECTURE.md) data flow

### Advanced
1. Study [ARCHITECTURE.md](ARCHITECTURE.md) module structure
2. Review [tests/README.md](tests/README.md) for test patterns
3. Explore extending pipeline (adding modules, modifying workflows)

---

## 🆘 Getting Help

1. **Check error message** → [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
2. **Search documentation** → Use this INDEX.md
3. **Check GitHub issues** → https://github.com/T-Chinsky/demultiplex-qc-pipeline/issues
4. **Ask community** → Nextflow Slack: https://nextflow.io/slack-invite.html

---

## 🔗 External Resources

- **Nextflow Documentation**: https://www.nextflow.io/docs/latest/
- **nf-core Guidelines**: https://nf-co.re/docs/
- **nf-test Documentation**: https://www.nf-test.com/
- **BCLConvert**: Illumina sequencing documentation
- **MultiQC**: https://multiqc.info/

---

**Ready to start?** → Go to [QUICK_START.md](QUICK_START.md) 🚀
