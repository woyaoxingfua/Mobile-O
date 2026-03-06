# Mobile-O Project Guide for AI Agents

## Project Overview

Mobile-O is a compact, efficient unified vision-language-diffusion model designed for on-device deployment on mobile devices (iPhone 15+). It performs both multimodal understanding (VQA, OCR, reasoning) and image generation within a single architecture.

**Key Capabilities:**
- **Image Understanding**: Visual question answering, OCR, image reasoning (Image → Text)
- **Image Generation**: 512×512 text-to-image generation (Text → Image)
- **Image Editing**: Instruction-based image editing (Text + Image → Image)
- **Text Chat**: General conversational AI (Text → Text)

**Project Structure:**
- `mobileo/`: Core Python model implementation
- `Mobile-O-App/`: iOS Swift application source code
- `scripts/`: Training shell scripts for different model sizes
- `eval/`: Evaluation pipelines (lmms-eval, GenEval)
- `deepspeed_scripts/`: DeepSpeed configuration files (ZeRO stages)

---

## Technology Stack

### Core Framework (Python Backend)
| Component | Technology |
|-----------|------------|
| Deep Learning | PyTorch 2.3.0, Transformers, Diffusers 0.35.2 |
| Vision Encoder | FastViT (via FastVLM) |
| Language Model | Qwen2-0.5B / Qwen2-1.5B |
| Diffusion Model | SANA 600M (DiT-style) |
| Training | DeepSpeed, Accelerate, PEFT (LoRA) |
| Optimization | xformers, flash_attn, bitsandbytes |

### Mobile App (iOS Frontend)
| Component | Technology |
|-----------|------------|
| Framework | SwiftUI, CoreML, Metal |
| ML Runtime | MLX (Apple's on-device ML framework) |
| Model Export | CoreML (DiT, VAE, Connector), MLX (LLM) |
| Minimum iOS | 18.0+ |
| Device Support | iPhone 15 Pro / 16 Pro / 17 Pro |

---

## Architecture Details

### Model Components

1. **Vision-Language Model (VLM)**
   - Based on FastVLM architecture
   - Vision encoder: FastViT-based
   - Language model: Qwen2 (0.5B or 1.5B parameters)
   - Handles multimodal understanding tasks

2. **Diffusion Decoder**
   - DiT-style diffusion transformer based on SANA
   - 600M parameters
   - Generates 512×512 images
   - VAE encoder-decoder for latent space operations

3. **Mobile Conditioning Projector (MCP)**
   - Novel lightweight connector (~2.4M params)
   - Bridges VLM and diffusion decoder
   - Uses layerwise feature fusion with temperature-scaled learnable weights
   - Depthwise-separable 1D convolutions + channel attention

### Key Files

| File | Purpose |
|------|---------|
| `mobileo/model/language_model/mobileo.py` | Core model definition (mobileoFastForCausalLM) |
| `mobileo/model/language_model/mobileo_inference.py` | Inference-specific model implementation |
| `mobileo/model/llava_arch.py` | Base LLaVA architecture components |
| `mobileo/model/multimodal_decoder/builder.py` | Diffusion decoder initialization |
| `mobileo/model/multimodal_llava_encoder/builder.py` | Vision encoder initialization |
| `mobileo/model/multimodal_llava_projector/builder.py` | MCP connector initialization |

---

## Development Environment Setup

### Python Environment

```bash
# Create conda environment
conda create -n mobileo python=3.12 -y
conda activate mobileo

# Install dependencies
pip install -r requirements.txt

# Install package in editable mode
pip install -e .
```

**Key Dependencies:**
- PyTorch 2.3.0 with CUDA 12.1 support
- xformers 0.0.26.post1
- transformers, accelerate, peft, bitsandbytes
- diffusers 0.35.2
- deepspeed
- flash_attn 2.6.2
- gradio 4.16.0 (for demo UI)

### iOS Development Environment

- macOS with Xcode 16+
- Physical iPhone 15 or later (Simulator not supported)
- Swift Package Manager dependencies (auto-resolved by Xcode)

---

## Training Pipeline

### Data Preparation

Download training datasets from HuggingFace:

| Stage | Dataset | Size | Download |
|-------|---------|------|----------|
| Pre-training | Mobile-O-Pre-Train | 9M text-image pairs | [HuggingFace](https://huggingface.co/datasets/Amshaker/Mobile-O-Pre-Train) |
| SFT | Mobile-O-SFT | ~105K prompt-image pairs | [HuggingFace](https://huggingface.co/datasets/Amshaker/Mobile-O-SFT) |
| Post-training | Mobile-O-Post-Train | ~105K quadruplet samples | [HuggingFace](https://huggingface.co/datasets/Amshaker/Mobile-O-Post-Train) |

Data format: WebDataset (`.tar` files) with `jpg`/`png` and `txt` columns

### Stage 1: Pre-training (Cross-Modal Alignment)

Trains DiT and MCP on 9M text-image pairs. Visual encoders, LLM backbone, and VAE are frozen.

```bash
bash scripts/Mobile-O-0.5B/pre_train.sh
```

**Key Parameters:**
- 5 epochs, batch size 64
- Learning rate: 5e-5 with cosine schedule
- DeepSpeed ZeRO-3
- Input resolution: 512×512

### Stage 2: Supervised Fine-tuning (SFT)

Finetunes DiT and MCP on curated prompt-image pairs.

```bash
bash scripts/Mobile-O-0.5B/sft.sh
```

**Key Parameters:**
- 20 epochs, batch size 24
- Learning rate: 2e-4
- DeepSpeed ZeRO-1

### Stage 3: Unified Multimodal Post-Training

Joint training on generation and understanding tasks. Uses LoRA for LLM fine-tuning.

```bash
bash scripts/Mobile-O-0.5B/post_train.sh
```

**Key Parameters:**
- 7 epochs
- LoRA: r=16, alpha=32
- Learning rate: 1e-4
- Only VAE remains frozen

### Training Scripts Structure

```
scripts/
├── Mobile-O-0.5B/
│   ├── pre_train.sh    # Stage 1: Pre-training
│   ├── sft.sh          # Stage 2: Supervised Fine-tuning
│   └── post_train.sh   # Stage 3: Post-training with LoRA
└── Mobile-O-1.5B/
    ├── pre_train.sh
    ├── sft.sh
    └── post_train.sh
```

### Merging LoRA Weights

After post-training, merge LoRA adapters with base model:

```bash
python mobileo/merge_lora.py \
    --checkpoint_dir checkpoints/Mobile-O-0.5B-Post-Train/ \
    --base_weights checkpoints/Mobile-O-0.5B-SFT/ \
    --output_dir checkpoints/Mobile-O-0.5B-Post-Train/final_merged_model/
```

---

## Inference

### Download Pre-trained Model

```bash
python -c "from huggingface_hub import snapshot_download; print(snapshot_download(repo_id='Amshaker/Mobile-O-0.5B', repo_type='model', local_dir='checkpoints', allow_patterns=['final_merged_model_23620/*']))"
```

### Image Understanding

```bash
python infer_image_understanding.py \
    --model_path checkpoints/Mobile-O-0.5B/ \
    --image_path assets/cute_cat.png \
    --prompt "What is in the image?"
```

### Image Generation

```bash
python infer_image_generation.py \
    --model_path checkpoints/Mobile-O-0.5B/ \
    --prompt "A vibrant tropical rainforest scene with a scarlet macaw"
```

### Image Editing

```bash
python infer_image_editing.py \
    --model_path checkpoints/Mobile-O-0.5B/ \
    --image_path assets/cute_cat.png \
    --prompt "Make the cat wear a hat"
```

---

## Evaluation

### Image Understanding Evaluation

Uses lmms-eval framework (located in `eval/lmms-eval/`):

```bash
# Setup
cd eval/lmms-eval
pip install -e .

# Run evaluation
bash eval/understanding_eval.sh
```

**Supported benchmarks:** mmmu_val, pope, gqa, textvqa_val, chartqa, seedbench, mmvet

### Image Generation Evaluation (GenEval)

Three-step process:

```bash
# Step 1: Generate images
bash eval/geneval/generation.sh "your/model/path/"

# Step 2: Setup GenEval environment and run object detection
conda create --name geneval python=3.9 -y
conda activate geneval
pip install -r eval/geneval_requirements.txt
bash eval/geneval/evaluate.sh "your/model/path/"

# Step 3: Compute final scores
bash eval/geneval/get_results.sh "your/model/path/"
```

---

## Mobile App (iOS)

### Quick Start

The app automatically downloads required models (~3.6GB) on first launch.

```bash
# Open Xcode project
open Mobile-O-App/app/MobileO.xcodeproj

# Build and run on iPhone 15+
# Cmd + R
```

### Manual Model Export (Optional)

Export PyTorch models to CoreML/MLX formats:

```bash
cd Mobile-O-App

# Export all components
python export.py

# Export specific components
python export.py --only dit vae

# Export with custom quantization
python export.py --only llm --llm-bits 8
```

**Exported Components:**
| Component | Format | Output File |
|-----------|--------|-------------|
| DiT Transformer | CoreML FP32 | `transformer.mlpackage` |
| VAE Decoder | CoreML FP32 | `vae_decoder.mlpackage` |
| Connector | CoreML FP32 | `connector.mlpackage` |
| Vision Encoder | CoreML FP16 | `vision_encoder.mlpackage` |
| LLM (Qwen2) | MLX 4-bit | `llm/` directory |

### App Architecture

```
Mobile-O-App/app/MobileO/
├── App/                    # SwiftUI entry point
├── Models/
│   ├── Chat/              # Chat message models
│   ├── Generation/        # Image generation models
│   ├── Schedulers/        # Diffusion schedulers (DPM-Solver)
│   └── Understanding/     # Vision-language models
├── Services/              # Model download manager
├── ViewModels/            # Chat and settings view models
├── Views/                 # SwiftUI views
├── Video/                 # Camera support
├── Utilities/             # Helper functions
└── Resources/             # CoreML models, config files
```

---

## Build and CI/CD

### GitHub Actions Workflows

| Workflow | File | Purpose |
|----------|------|---------|
| Build iOS IPA | `.github/workflows/build-ios.yml` | Build unsigned IPA with self-signed cert |
| Build iOS (Full) | `.github/workflows/build.yml` | Build with diagnostics |
| Build Debug | `.github/workflows/build-debug.yml` | Debug builds |

### Local iOS Build (macOS only)

```bash
bash build_local.sh
```

### DeepSpeed Configurations

| Config | Purpose |
|--------|---------|
| `deepspeed_scripts/zero1.json` | ZeRO Stage 1 (SFT, Post-training) |
| `deepspeed_scripts/zero2.json` | ZeRO Stage 2 |
| `deepspeed_scripts/zero3.json` | ZeRO Stage 3 (Pre-training) |
| `deepspeed_scripts/zero3_offload.json` | ZeRO-3 with CPU offloading |

---

## Code Conventions

### Python Code Style

- Follow standard Python PEP 8 conventions
- Use type hints where appropriate
- Model classes use camelCase (e.g., `mobileoFastForCausalLM`)
- Utility functions use snake_case
- Constants defined in `mobileo/constants.py`

### Key Constants

```python
# From mobileo/constants.py
DEFAULT_IMAGE_TOKEN = "<image>"
DEFAULT_IM_START_TOKEN = "<im_start>"
DEFAULT_IM_END_TOKEN = "<im_end>"
IMAGE_TOKEN_INDEX = -200
IGNORE_INDEX = -100
```

### Conversation Templates

Available conversation formats in `mobileo/conversation.py`:
- `qwen_2`: Primary template for Mobile-O
- `qwen`: Alternative Qwen template
- `llama_3`, `chatml`, `mpt`: Other supported formats

---

## Testing Strategy

### Manual Testing

1. **Inference Tests**: Run `infer_image_*.py` scripts with sample inputs
2. **Training Tests**: Use small data subset and 1-2 epochs for smoke testing
3. **iOS App**: Test on physical device (iPhone 15+)

### Evaluation Testing

```bash
# Quick understanding test
python infer_image_understanding.py --model_path <path> --image_path <image> --prompt "Describe"

# Quick generation test
python infer_image_generation.py --model_path <path> --prompt "A red apple"
```

---

## Common Issues and Solutions

### Training Issues

| Issue | Solution |
|-------|----------|
| CUDA OOM | Reduce batch size, enable gradient checkpointing, use ZeRO-3 |
| DeepSpeed checkpoint loading | Use `mobileo/merge_lora.py` to merge checkpoints |
| NaN loss | Check learning rate, enable gradient clipping (max_grad_norm) |

### iOS Build Issues

| Issue | Solution |
|-------|----------|
| Code signing errors | Use GitHub Actions workflows for unsigned builds |
| Missing frameworks | Ensure `ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES=YES` |
| Device compatibility | Requires iPhone 15+ (A17 Pro or newer) |

---

## License and Legal

- **License**: CC BY-NC-SA 4.0 (Research and non-commercial use only)
- **Commercial use**: Strictly prohibited without explicit written permission
- **Attribution**: Based on BLIP3o, FastVLM, and SANA architectures

---

## Useful Links

- **Paper**: [arXiv:2602.20161](https://arxiv.org/abs/2602.20161)
- **Project Page**: [https://amshaker.github.io/Mobile-O/](https://amshaker.github.io/Mobile-O/)
- **Live Demo**: [https://mobileo.cvmbzuai.com/](https://mobileo.cvmbzuai.com/)
- **Models**: [HuggingFace Collection](https://huggingface.co/collections/Amshaker/mobile-o-models)
- **Datasets**: [HuggingFace Collection](https://huggingface.co/collections/Amshaker/mobile-o-datasets)
- **iOS App**: [App Store](https://apps.apple.com/app/mobile-o/id6759238106)

---

## Contact and Support

For issues and questions:
1. Check existing GitHub issues
2. Refer to README.md for basic usage
3. Review BUILD_IPA_README.md and LIVECONTAINER_GUIDE.md for iOS-specific issues
