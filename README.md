# Plak! AI

Plak! Ai: The first Alpha Version (v0.1.0-alpha)

<p align="center">
  <img src="logo.svg" alt="Plak! AI" width="350">
</p>

It's like a Jarvis, but—unlike other solutions—totally local (except STT, but we'll get to that later) and very optimized for regular PC users. You can run Plak AI using a GPU with just 4GB VRAM (e.g. GTX 1650). But as you know, that comes with a cost.

Plak AI uses Gemma 3 : 4B on the backend via Ollama. Yes, it might not seem that capable or scholarly at first, but let me remind you: we only have 4GB VRAM to work with (at least the project is very ambitious regarding optimization). Even so, Gemma 3 : 4B is great under these conditions. Let me explain:

When I was planning this project, I was looking for a good LLM model and my options were:
* Qwen 2.5 : 3B
* Mistral : 3B
* Llama 3.2 : 3B

Let me get this straight: these models are not bad, but they have lower parameter counts. Actually, I didn't want to use a weak model—because if it's not smart enough, how could we trust it to become a system-wide desktop assistant?

Later, I came across Gemma 3. It had very strong points. i.e.:

* **Heavy Knowledge Distillation:** It was trained using distillation from much larger models, meaning it packs the reasoning power of a 7B-8B class model into a compact 4B footprint.
* **Hybrid Local/Global Attention:** It alternates between local and global attention layers, drastically reducing KV-cache memory usage and boosting generation speed on limited VRAM.
* **Massive Multilingual Tokenizer:** The expanded vocabulary means it handles non-English languages (like Turkish) far more efficiently without wasting tokens or slowing down.
* You can read more about it here: https://huggingface.co/blog/gemma3

and in terms of the speed-knowledge balance, it was unmatched. So I think I picked the best model for these hardware limits.

### So, what can you do with this AI assistant right now?
* Actually, for now, you can just talk with it. I am sorry about that.

### In the future:
Ladies and gentlemen, you will have a local Siri / Google Assistant alternative for computers in your hands, with no internet required:
* You can open songs, music, files, etc.
* At the end of the day, you will have a completely private AI you can ask everyday things.

### Optimization & Challenges
Guys, I told you about the difficulties of local LLMs, but there are so many more.
First of all, STT was unexpectedly hard work. Yes, I set up a local one, but performance wasn't great. I don't recommend using it locally yet. You will probably need the cloud for that, but don't worry, I have a solution.
Because of this, cloud-based STT is currently the most viable workaround. The codebase includes an optional **Groq API** implementation purely as a fast and free reference example for Whisper transcription, but the architecture is modular—you can easily swap it out for OpenAI Whisper, Deepgram, or any local STT pipeline you prefer. (Note: Groq is a third-party service; API availability and rate limits depend on their own terms). 

At least I set up 2 local TTS models, and one of them works mostly flawlessly: Piper-TTS. Even though the other model has a better voice, it was much slower. Still, you can try both.

### Committed Features (First preview — keep expectations low!)
* UI created using QML
* STT/TTS and LLM integrated
* Core blueprint verified
