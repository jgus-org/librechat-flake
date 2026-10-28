# librechat-flake

A Nix flake that packages [LibreChat](https://github.com/danny-avila/LibreChat), the open-source multi-provider AI chat UI, tracking upstream releases.

## What it publishes

- `packages.<system>.librechat` — the LibreChat server, also exposed as `packages.<system>.default`. The entry point is `librechat-server` (`nix run github:jgus-org/librechat-flake`).

Consume it as a flake input:

```nix
inputs.librechat.url = "github:jgus-org/librechat-flake";

# ...
input-pkgs.librechat = librechat.packages.${system}.librechat;
```

## Runtime assumptions

- The server needs a reachable MongoDB and is configured through upstream's environment variables (MONGO_URI, OPENAI_API_KEY, and friends — see the [upstream documentation](https://www.librechat.ai/docs)). Meilisearch and the RAG API are optional companions.
- Uploaded files (`./uploads`), generated images (`./images`), and the default log directory (`./logs`, via `LIBRECHAT_LOG_DIR`) are resolved relative to the process working directory, and custom client assets are read from the working directory. Run the server from a writable directory (or override the environment) rather than assuming everything lives in the package.

## Platform support

Built for `x86_64-linux`, `aarch64-linux`, and `aarch64-darwin`.

See [LICENSE.md](LICENSE.md) for licensing and copyright, and [NOTICE.md](NOTICE.md) for the terms of upstream and distributed artifacts.
