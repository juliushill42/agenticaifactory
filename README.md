# README.md

```markdown
# Titan Agentic AI Engineer — Backend Orchestration

**Sovereign AI code synthesis engine** — Pure logic synthesizer that outputs validated JSON manifests for multi-agent orchestration.

> **Role**: Pure logic synthesizer. No HTML. No rendering.  
> **Output**: Validated JSON manifest → `/shared_state/manifest.json`

---

## 🏗️ Architectural Overview

This is the **backend orchestration engine** for the Titan Agentic AI system, featuring:

- **LLama.cpp quantized inference** with `llama-cli` backend
- **JSON-only output schema** for agent task synthesis
- **Exclusive process locking** to prevent concurrent runs
- **Atomic manifest writes** with validation
- **Signal trap cleanup** for graceful termination

### Patented Patterns [JCH-2026]

This engine implements architectural patterns covered under the **JCH-2026 provisional patent series**:

| Patent ID | Pattern |
|-----------|---------|
| **JCH-2026-001** | Pedersen ZK audit chain at substrate level |
| **JCH-2026-006** | Sovereign WireGuard mesh with key rotation daemon |
| **JCH-2026-009/010** | WASM isolate + Go gateway + local GGUF routing |
| **JCH-2026-JUDGE-001** | Multi-agent adversarial swarm legal evaluation |

⚠️ **See [PATENT_NOTICE.md](PATENT_NOTICE.md) for full legal text.**

---

## 📦 Requirements

| Component | Version/Path |
|-----------|--------------|
| **Runtime** | Bash 4.x+ |
| **Python** | Python 3.x (for JSON validation) |
| **LLama.cpp** | `llama-cli` binary (quantized build) |
| **Model** | `titan-brain.gguf` (GGUF format) |
| **OS** | Linux (absolute paths configured) |

### Hardware

- **GPU**: Optional (NVIDIA with `n-gpu-layers`)
- **CPU**: Multi-core (default: `$(nproc)` threads)
- **RAM**: 16GB+ recommended for 4096 context

---

## 🚀 Installation

### 1. Set up paths

Edit the script's absolute paths to match your environment:

```bash
# In engineer.sh (top of file):
readonly TITAN_ROOT="/run/media/juliush/TITANSSD/Titan44"
readonly LLAMA_BIN="/run/media/juliush/TITANSSD/TITANSSD/llama_cpp_quant/build/bin/llama-cli"
readonly MODEL="${TITAN_ROOT}/models/titan-brain.ggfn"
```

### 2. Install llama.cpp

```bash
# Build quantized llama-cli
cd llama_cpp_quant
make -j$(nproc)
```

### 3. Download model

```bash
# Place GGUF model at expected path
mkdir -p "${TITAN_ROOT}/models"
wget -O "${TITAN_ROOT}/models/titan-brain.gguf" <model-url>
```

### 4. Create shared state directory

```bash
mkdir -p "${TITAN_ROOT}/shared_state"
mkdir -p "${TITAN_ROOT}/logs"
```

---

## 🔧 Configuration

### Environment Variables

```bash
export CTX_SIZE=4096          # Context window (default: 4096)
export TEMPERATURE=0.1        # Inference temp (default: 0.1, deterministic)
export MAX_TOKENS=512         # Max tokens to generate (default: 512)
export THREADS=$(nproc)       # CPU threads (default: all cores)
export N_GPU_LAYERS=0         # GPU layers (default: 0, CPU-only)
```

### Example: GPU-accelerated run

```bash
export N_GPU_LAYERS=35        # Offload 35 layers to GPU
export THREADS=8              # Limit CPU threads
./engineer.sh "<your prompt>"
```

---

## 🏃 Usage

### Basic invocation

```bash
./engineer.sh "Design a Rust kernel module for WireGuard key rotation"
```

### Output

```bash
✓ Manifest ready: /run/media/juliush/TITANSSD/Titan44/shared_state/manifest.json
```

### Manifest schema

```json
{
  "schema_version": "1.0",
  "session_id": "abc123def456",
  "timestamp": "2026-01-20T14:30:00Z",
  "model": "titan-brain.gguf",
  "status": "SUCCESS",
  "ctx_size": 4096,
  "temperature": 0.1,
  "threads": 16,
  "tasks": [
    {
      "id": "task-001",
      "type": "kernel_module",
      "language": "rust",
      "synopsis": "WireGuard key rotation daemon",
      "complexity": "high",
      "estimated_tokens": 2048,
      "dependencies": [],
      "output_artifact": "src/key_rotation.rs",
      "status": "planned"
    }
  ],
  "architecture": {
    "pattern": "sovereign_mesh",
    "rationale": "Key rotation ensures forward secrecy"
  },
  "risks": [
    {
      "id": "risk-001",
      "severity": "medium",
      "description": "GPU offload may cause latency spikes"
    }
  ],
  "next_action": "synthesize_task_task-001"
}
```

---

## 🛠️ System Design

### Flow

```
┌─────────────────────┐
│ User Prompt         │
└─────────┬───────────┘
          │
          ▼
┌─────────────────────┐
│ Sanitize (2000 char │
│ cap, strip control) │
└─────────┬───────────┘
          │
          ▼
┌─────────────────────┐
│ System Prefix +     │
│ JSON Schema         │
└─────────┬───────────┘
          │
          ▼
┌─────────────────────┐
│ llama-cli Inference │
│ (GGUF model)        │
└─────────┬───────────┘
          │
          ▼
┌─────────────────────┐
│ Extract JSON Block  │
│ (regex {...})       │
└─────────┬───────────┘
          │
          ▼
┌─────────────────────┐
│ Wrap in Manifest    │
│ (add metadata)      │
└─────────┬───────────┘
          │
          ▼
┌─────────────────────┐
│ Validate JSON       │
│ (python3 json.load) │
└─────────┬───────────┘
          │
          ▼
┌─────────────────────┐
│ Atomic Write        │
│ (mktemp → mv)       │
└─────────────────────┘
```

### Safety mechanisms

| Mechanism | Purpose |
|-----------|---------|
| **Exclusive lock** | Prevents concurrent engineer runs |
| **Signal traps** | Cleanup lock file on EXIT/INT/TERM |
| **JSON validation** | Python `json.load()` before write |
| **Atomic writes** | `mktemp` + `mv` for crash safety |
| **Prompt sanitization** | 2000 char cap, control char strip |

---

## 📁 Project Structure

```
titan-agentic-engineer/
├── engineer.sh           # Main orchestration script
├── README.md
├── PATENT_NOTICE.md
├── LICENSE
├── models/
│   └── titan-brain.gguf  # GGUF model (download separately)
├── shared_state/
│   ├── manifest.json     # Output manifest
│   └── .engineer.lock    # Process lock
└── logs/
    └── engineer_YYYYMMDD.log  # Runtime logs
```

---

## 🔐 Security

- **Prompt sanitization**: Strips control characters, caps at 2000 chars
- **Process locking**: Exclusive lock prevents race conditions
- **Local-only inference**: No network calls, model runs offline
- **JSON schema enforcement**: System prefix forces valid JSON output

---

## 🧪 Testing

### Validate JSON extraction

```bash
./engineer.sh "Return JSON with one task" 
cat shared_state/manifest.json | python3 -m json.tool
```

### Test error handling

```bash
# Missing model
rm -f models/titan-brain.gguf
./engineer.sh "test"  # Should exit with code 3

# Concurrent run
./engineer.sh "test1"
./engineer.sh "test2"  # Should exit with code 4 (already running)
```

---

## 🚨 Error Codes

| Code | Meaning |
|------|---------|
| **1** | Cannot create directory |
| **2** | `llama-cli` not executable |
| **3** | Model not found |
| **4** | Already running (lock conflict) |
| **5** | Inference failed |
| **6** | JSON extraction failed |
| **7** | Manifest wrap failed |
| **8** | Final validation failed |

Logs: `${TITAN_ROOT}/logs/engineer_YYYYMMDD.log`

---

## 📝 License

**Proprietary** — TitanU AI LLC

© 2026 Julius Cameron Hill (JCH-2026). All rights reserved.

This repository is part of the **JCH-2026 provisional patent series**.  
See [PATENT_NOTICE.md](PATENT_NOTICE.md) for patent and licensing details.

### Licensing inquiries

**Julius C. Hill**  
Nashville, Tennessee, US  
TitanU AI LLC  
Email: [your-email@titanu.ai](mailto:your-email@titanu.ai)

---

## 🧑‍💻 Author

**Julius Cameron Hill (JCH-2026)**  
Polyglot systems architect | AI agent orchestration specialist  
Nashville, Tennessee, US

---

⚖️ **Built for acquisition readiness. Production-hardened. Sovereign by design.**

⚠️ **Patent Notice**: Pattern replication ≠ clean room immunity. See [PATENT_NOTICE.md](PATENT_NOTICE.md).
```

Save this as `README.md` in your `titan-agentic-engineer` repo. You now have:

1. `engineer.sh` — the orchestration script
2. `README.md` — full documentation with schema, usage, error codes
3. `PATENT_NOTICE.md` — patent notice (from earlier)
4. `LICENSE` — proprietary license file
