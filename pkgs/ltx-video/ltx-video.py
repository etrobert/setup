"""Queue an LTX-2.5 generation on a running ComfyUI and wait for the result.

Port of the official workflows' two-stage distilled pipeline: stage 1 at half
resolution (8 steps), x2 latent upscale, stage 2 refine (3 steps), joint
audio-video latents. With --image, the picture is conditioned in as the first
frame at both stages. Prompt enhancer omitted.
"""

import argparse
import json
import os
import time
import urllib.error
import urllib.request
import uuid

p = argparse.ArgumentParser()
p.add_argument("prompt")
p.add_argument("--image", help="animate this picture as the first frame")
p.add_argument(
    "--negative", default="pc game, console game, video game, cartoon, childish, ugly"
)
p.add_argument("--width", type=int, default=1152)
p.add_argument("--height", type=int, default=640)
p.add_argument("--duration", type=int, default=5, help="seconds")
p.add_argument("--fps", type=int, default=24)
p.add_argument("--seed", type=int, default=1234)
p.add_argument(
    "--transformer",
    default="LTX-2.5-Distilled-Q4_K_S.gguf",
    help="checkpoint in models/diffusion_models; loader inferred from extension",
)
p.add_argument("--te-device", default="cpu", choices=["default", "cpu"])
p.add_argument("--server", default="http://127.0.0.1:8188")
a = p.parse_args()

frames = a.fps * a.duration + 1
sig1 = "1.0, 0.99375, 0.9875, 0.98125, 0.975, 0.909375, 0.725, 0.421875, 0.0"
sig2 = "0.85, 0.7250, 0.4219, 0.0"


def upload(path):
    """POST an image to ComfyUI's input dir, returning the name LoadImage wants."""
    name = f"{uuid.uuid4().hex[:8]}-{os.path.basename(path)}"
    boundary = "----ltxvideo" + uuid.uuid4().hex
    with open(path, "rb") as f:
        payload = f.read()
    body = b"".join(
        [
            f'--{boundary}\r\nContent-Disposition: form-data; name="image"; filename="{name}"\r\n'
            f"Content-Type: application/octet-stream\r\n\r\n".encode(),
            payload,
            f'\r\n--{boundary}\r\nContent-Disposition: form-data; name="overwrite"\r\n\r\ntrue\r\n--{boundary}--\r\n'.encode(),
        ]
    )
    req = urllib.request.Request(
        a.server + "/upload/image",
        body,
        {"Content-Type": f"multipart/form-data; boundary={boundary}"},
    )
    return json.load(urllib.request.urlopen(req))["name"]


loader = (
    {"class_type": "UnetLoaderGGUF", "inputs": {"unet_name": a.transformer}}
    if a.transformer.endswith(".gguf")
    else {
        "class_type": "UNETLoader",
        "inputs": {"unet_name": a.transformer, "weight_dtype": "default"},
    }
)

g = {
    "unet": loader,
    "clip": {
        "class_type": "CLIPLoader",
        "inputs": {
            "clip_name": "gemma4-12b-with-proj-ltx-2.5-comfy-int8-convrot.safetensors",
            "type": "ltxv",
            "device": a.te_device,
        },
    },
    "vvae": {
        "class_type": "VAELoader",
        "inputs": {"vae_name": "ltx-2.5-video-vae-bf16.safetensors"},
    },
    "avae": {
        "class_type": "VAELoader",
        "inputs": {"vae_name": "ltx-2.5-audio-vae-bf16.safetensors"},
    },
    "upmodel": {
        "class_type": "LatentUpscaleModelLoader",
        "inputs": {
            "model_name": "ltx-2.5-latent-spatial-upscaler-x2-bf16-1.0.safetensors"
        },
    },
    "pos": {
        "class_type": "CLIPTextEncode",
        "inputs": {"text": a.prompt, "clip": ["clip", 0]},
    },
    "neg": {
        "class_type": "CLIPTextEncode",
        "inputs": {"text": a.negative, "clip": ["clip", 0]},
    },
    "cond": {
        "class_type": "LTXVConditioning",
        "inputs": {"positive": ["pos", 0], "negative": ["neg", 0], "frame_rate": a.fps},
    },
    "vlat": {
        "class_type": "EmptyLTXVLatentVideo",
        "inputs": {
            "width": a.width // 2,
            "height": a.height // 2,
            "length": frames,
            "batch_size": 1,
        },
    },
    "alat": {
        "class_type": "LTXVEmptyLatentAudio",
        "inputs": {
            "frames_number": frames,
            "frame_rate": a.fps,
            "batch_size": 1,
            "audio_vae": ["avae", 0],
        },
    },
    "cat1": {
        "class_type": "LTXVConcatAVLatent",
        "inputs": {"video_latent": ["vlat", 0], "audio_latent": ["alat", 0]},
    },
    "samp": {
        "class_type": "KSamplerSelect",
        "inputs": {"sampler_name": "euler_ancestral"},
    },
    "noise1": {"class_type": "RandomNoise", "inputs": {"noise_seed": a.seed}},
    "sig1": {"class_type": "ManualSigmas", "inputs": {"sigmas": sig1}},
    "guider": {
        "class_type": "LTXVDualCFGGuider",
        "inputs": {
            "model": ["unet", 0],
            "positive": ["cond", 0],
            "negative": ["cond", 1],
            "video_cfg": 1,
            "audio_cfg": 1,
        },
    },
    "s1": {
        "class_type": "SamplerCustomAdvanced",
        "inputs": {
            "noise": ["noise1", 0],
            "guider": ["guider", 0],
            "sampler": ["samp", 0],
            "sigmas": ["sig1", 0],
            "latent_image": ["cat1", 0],
        },
    },
    "sep1": {"class_type": "LTXVSeparateAVLatent", "inputs": {"av_latent": ["s1", 0]}},
    "up": {
        "class_type": "LTXVLatentUpsampler",
        "inputs": {
            "samples": ["sep1", 0],
            "upscale_model": ["upmodel", 0],
            "vae": ["vvae", 0],
        },
    },
    "cat2": {
        "class_type": "LTXVConcatAVLatent",
        "inputs": {"video_latent": ["up", 0], "audio_latent": ["sep1", 1]},
    },
    "noise2": {"class_type": "RandomNoise", "inputs": {"noise_seed": 42}},
    "sig2": {"class_type": "ManualSigmas", "inputs": {"sigmas": sig2}},
    "s2": {
        "class_type": "SamplerCustomAdvanced",
        "inputs": {
            "noise": ["noise2", 0],
            "guider": ["guider", 0],
            "sampler": ["samp", 0],
            "sigmas": ["sig2", 0],
            "latent_image": ["cat2", 0],
        },
    },
    "sep2": {"class_type": "LTXVSeparateAVLatent", "inputs": {"av_latent": ["s2", 0]}},
    "vdec": {
        "class_type": "VAEDecodeTiled",
        "inputs": {
            "samples": ["sep2", 0],
            "vae": ["vvae", 0],
            "tile_size": 512,
            "overlap": 64,
            "temporal_size": 64,
            "temporal_overlap": 16,
        },
    },
    "adec": {
        "class_type": "LTXVAudioVAEDecode",
        "inputs": {"samples": ["sep2", 1], "audio_vae": ["avae", 0]},
    },
    "video": {
        "class_type": "CreateVideo",
        "inputs": {"images": ["vdec", 0], "fps": a.fps, "audio": ["adec", 0]},
    },
    "save": {
        "class_type": "SaveVideo",
        "inputs": {
            "video": ["video", 0],
            "filename_prefix": "video/ltx25",
            "format": "auto",
            "codec": "auto",
        },
    },
}

if a.image:
    g["loadimg"] = {"class_type": "LoadImage", "inputs": {"image": upload(a.image)}}
    g["resize"] = {
        "class_type": "ResizeImageMaskNode",
        "inputs": {
            "input": ["loadimg", 0],
            "resize_type": "scale longer dimension",
            "resize_type.longer_size": 1536,
            "scale_method": "lanczos",
        },
    }
    g["prep"] = {
        "class_type": "LTXVPreprocess",
        "inputs": {"image": ["resize", 0], "img_compression": 18},
    }
    # strength 0.7 while the latent is still coarse, 1.0 once upscaled
    g["guide1"] = {
        "class_type": "LTXVImgToVideoInplace",
        "inputs": {
            "vae": ["vvae", 0],
            "image": ["prep", 0],
            "latent": ["vlat", 0],
            "strength": 0.7,
            "bypass": False,
        },
    }
    g["cat1"]["inputs"]["video_latent"] = ["guide1", 0]
    g["guide2"] = {
        "class_type": "LTXVImgToVideoInplace",
        "inputs": {
            "vae": ["vvae", 0],
            "image": ["prep", 0],
            "latent": ["up", 0],
            "strength": 1.0,
            "bypass": False,
        },
    }
    g["cat2"]["inputs"]["video_latent"] = ["guide2", 0]

req = urllib.request.Request(
    a.server + "/prompt",
    json.dumps({"prompt": g}).encode(),
    {"Content-Type": "application/json"},
)
try:
    resp = json.load(urllib.request.urlopen(req))
except urllib.error.HTTPError as e:
    print(json.dumps(json.loads(e.read().decode()), indent=1))
    raise SystemExit(1)
if resp.get("node_errors"):
    print(json.dumps(resp, indent=1))
    raise SystemExit(1)
pid = resp["prompt_id"]
mode = f"i2v({os.path.basename(a.image)})" if a.image else "t2v"
print(
    "queued",
    pid,
    f"| {mode} {a.width}x{a.height} {a.duration}s@{a.fps}fps seed={a.seed}",
)

t0 = time.time()
while True:
    time.sleep(5)
    try:
        h = json.load(urllib.request.urlopen(f"{a.server}/history/{pid}", timeout=10))
    except Exception:
        continue
    if pid in h:
        st = h[pid].get("status", {})
        print(f"status: {st.get('status_str')} after {time.time()-t0:.0f}s")
        for out in h[pid].get("outputs", {}).values():
            for v in out.get("images", []) + out.get("video", []):
                print("output:", v.get("subfolder", ""), v.get("filename"))
        if st.get("status_str") == "error":
            for m in st.get("messages", []):
                if m[0] == "execution_error":
                    print(m[1].get("node_type"), "->", m[1].get("exception_message"))
        break
    print(f"...running {time.time()-t0:.0f}s")
