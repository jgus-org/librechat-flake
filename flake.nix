{
  description = "LibreChat (danny-avila/LibreChat) — multi-provider chat UI.";

  inputs = {
    flake-lib.url = "github:jgus-org/flake-lib/v1";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  };

  outputs =
    {
      self,
      flake-lib,
      nixpkgs,
    }:
    flake-lib.lib.eachDefaultSystem (
      system:
      let
        pin = import ./pin.nix;
        inherit (pin)
          npmDepsHash
          sourceHash
          sourceRev
          version
          ;
        source = {
          owner = "danny-avila";
          repo = "LibreChat";
          type = "github";
        };
        pkgs = import nixpkgs { inherit system; };
        inherit (pkgs) lib;
        orgFormatting = flake-lib.lib.mkFormatting {
          inherit self system;
        };

        # Forked from nixpkgs pkgs/by-name/li/librechat/package.nix (the two patches are copied verbatim). Kept deliberately close to upstream so re-syncing on a future nixpkgs bump is a diff, not a rewrite.
        librechat = pkgs.buildNpmPackage (finalAttrs: {
          inherit version;
          inherit npmDepsHash;
          buildInputs = [ pkgs.vips ];
          makeWrapperArgs = [ "--set-default LIBRECHAT_LOG_DIR ./logs" ];
          meta = {
            changelog = "https://www.librechat.ai/changelog/v${version}";
            description = "Open-source app for all your AI conversations, fully customizable and compatible with any AI provider";
            homepage = "https://github.com/danny-avila/LibreChat";
            license = lib.licenses.mit;
            mainProgram = "librechat-server";
          };
          nativeBuildInputs = [
            pkgs.pkg-config
            pkgs.node-gyp
          ];
          # Default nodejs builds 0.8.8; 0.8.7 and 0.8.6 fail their build at the npm cleanup step.
          nodejs = pkgs.nodejs_22;
          npmBuildScript = "frontend";
          npmDepsFetcherVersion = 2;
          npmPruneFlags = [ "--production" ];
          patches = [
            # buildNpmPackage uses `npm pack`, which honours package.json `files`; LibreChat doesn't set it, so add the paths we need (and a `bin` for the auto-generated wrapper).
            ./0001-npm-pack.patch
            # Uploads default to the (immutable) package dir; make them relative to cwd instead.
            ./0002-upload-paths.patch
          ];
          pname = "librechat";
          # npmConfigHook patches only the root node_modules; nested workspace installs (client/, packages/*) need patching too.
          postConfigure = ''
            patchShebangs client/node_modules packages
          '';
          # The api/ and client/ workspace dist dirs vanish after the build (symlink churn); copy them back.
          preFixup = ''
            mkdir -p $out/lib/node_modules/LibreChat/packages/api
            cp -R packages/api/dist/. $out/lib/node_modules/LibreChat/packages/api
            mkdir -p $out/lib/node_modules/LibreChat/packages/client
            cp -R packages/client/dist/. $out/lib/node_modules/LibreChat/packages/client
          '';
          src = pkgs.fetchFromGitHub {
            hash = sourceHash;
            owner = "danny-avila";
            repo = "LibreChat";
            rev = sourceRev;
          };
        });

        update-version = flake-lib.lib.mkUpdateVersion {
          inherit pkgs source;
          # fetcherVersion 2 must match npmDepsFetcherVersion above (it changes the hash).
          artifactHook = flake-lib.lib.mkJsDepsHook {
            inherit pkgs;
            fetcherVersion = 2;
            manager = "npm";
          };
          extraHashes = [ "npmDepsHash" ];
        };

        update-branches = flake-lib.lib.mkUpdateBranches {
          inherit pkgs source;
          minimumTrackingVersion = "0.8.6";
          pinSchema = "github-npm";
        };
      in
      {
        checks.formatting = orgFormatting.check;
        formatter = orgFormatting.formatter;
        packages = {
          inherit librechat update-branches update-version;
          default = librechat;
        };
      }
    );
}
