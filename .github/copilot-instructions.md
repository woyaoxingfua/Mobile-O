# Mobile-O Copilot Instructions

## Build, Test, and Lint

### Python Environment
- **Setup**: Use Conda with Python 3.12.
  ```bash
  conda create -n mobileo python=3.12 -y
  conda activate mobileo
  pip install -r requirements.txt
  ```
- **Dependencies**: Key libraries include `torch`, `diffusers`, `transformers`, `accelerate`, `deepspeed`, and `gradio`.
- **Linting**: No strict configuration found. Follow standard PEP 8 conventions.

### iOS App
- **Prerequisites**: macOS, Xcode 16+, Physical iPhone 15+ (Simulator not supported).
- **Build**: Open `Mobile-O-App/app/MobileO.xcodeproj` in Xcode and run on a physical device.
- **Model Export**: Use `Mobile-O-App/export.py` to convert PyTorch models to CoreML/MLX format.
  ```bash
  python Mobile-O-App/export.py --model Amshaker/Mobile-O-0.5B
  ```

## High-Level Architecture

Mobile-O is a unified multimodal model designed for mobile devices, combining understanding and generation.

### Core Components
1.  **Vision-Language Model (VLM)**:
    -   **Vision Encoder**: Based on FastViT (efficient hybrid architecture).
    -   **LLM Backbone**: Qwen2-0.5B (lightweight autoregressive model).
2.  **Diffusion Decoder**:
    -   **DiT**: Lightweight Diffusion Transformer based on SANA (512x512 generation).
    -   **VAE**: Variational Autoencoder for latent space compression.
3.  **Mobile Conditioning Projector (MCP)**:
    -   Bridges VLM and Diffusion Decoder.
    -   Uses layerwise feature fusion and depthwise-separable 1D convolutions.
    -   Conditions diffusion on weighted VLM hidden states (no query tokens).

### Training Stages
Training scripts are located in `scripts/Mobile-O-0.5B/` (and `1.5B`).
1.  **Pre-training (`pre_train.sh`)**: Aligns DiT & MCP using 9M image-text pairs. Freezes VLM & VAE.
2.  **SFT (`sft.sh`)**: Finetunes DiT & MCP on ~105K high-quality pairs.
3.  **Post-training (`post_train.sh`)**: Jointly optimizes DiT, MCP, LLM (via LoRA), and Vision Encoder on unified quadruplets.

## Key Conventions

### Python Codebase (`mobileo/`)
-   **Model Loading**: Use `mobileo.model.builder.load_pretrained_model(model_path)`.
-   **Conversation Templates**: Defined in `mobileo.conversation`. Use `conv_templates["qwen_2"]`.
-   **Inference Scripts**: Standalone scripts at root (`infer_image_understanding.py`, `infer_image_generation.py`, `infer_image_editing.py`) demonstrate usage.
-   **Path Handling**: Always use absolute paths or paths relative to the repository root.

### Mobile App (`Mobile-O-App/`)
-   **Structure**:
    -   `app/MobileO/Models`: Swift wrappers for CoreML models.
    -   `app/MobileO/Services`: Networking and model management.
    -   `app/MobileO/Views`: SwiftUI interfaces.
-   **Model Management**: The app automatically downloads models on first launch if not manually exported and copied.

### Data Flow
-   **Multimodal Input**: Images are processed by the Vision Encoder, text by the LLM.
-   **Generation**: LLM output (hidden states) conditions the DiT via MCP to generate images.
-   **Understanding**: Standard VLM pipeline (Image -> Encoder -> Projector -> LLM -> Text).
