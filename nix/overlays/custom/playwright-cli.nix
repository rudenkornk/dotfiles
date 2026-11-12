final: prev:

# Taken from https://github.com/Vanadium5000/nixconf/blob/2e5232e54063186ed18bbcc5d88ea68e5d0c6a27/modules/_pkgs/playwright-cli.nix

final.buildNpmPackage {
  pname = "playwright-cli";
  version = "0.1.23";

  src = final.fetchFromGitHub {
    owner = "microsoft";
    repo = "playwright-cli";
    rev = "v0.1.23";
    hash = "sha256-MqeB9U8676YOlB6JbX5Dcp2PeWftQcmbTUPp9dS5t+U=";
  };

  npmDepsHash = "sha256-GQjH0Zwf9cYuuM6m4mM2Xwz6qWuJTsXsj0nCSm71BlY=";

  dontNpmBuild = true;

  nativeBuildInputs = [ final.makeBinaryWrapper ];

  postInstall = ''
    # Copy skill files to a clean accessible path.
    mkdir -p $out/share/skills
    cp -r $out/lib/node_modules/@playwright/cli/skills/playwright-cli $out/share/skills/playwright-cli

    # TODO: Return to stable after upgrading to 26.11; Chromium 147 breaks Wayland scaling below 100%.
    chromium_dir=$(ls "${final.unstable.playwright-driver.browsers}" | grep '^chromium-' | head -1)
    chrome_subdir=$(ls "${final.unstable.playwright-driver.browsers}/$chromium_dir" | grep '^chrome-linux' | head -1)
    executable="${final.unstable.playwright-driver.browsers}/$chromium_dir/$chrome_subdir/chrome"

    mkdir -p $out/share/playwright-cli
    cat > $out/share/playwright-cli/playwright-cli.json << EOF
    {
      "browser": {
        "browserName": "chromium",
        "isolated": false,
        "saveSession": true,
        "launchOptions": {
          "executablePath": "$executable",
          "headless": false,
          "persistent": true
        }
      }
    }
    EOF
  '';

  postFixup = # bash
    ''
      wrapProgram $out/bin/playwright-cli \
        --unset HTTP_PROXY \
        --unset http_proxy \
        --unset HTTPS_PROXY \
        --unset https_proxy \
        --run "export PLAYWRIGHT_MCP_USER_DATA_DIR=\"\''${PLAYWRIGHT_MCP_USER_DATA_DIR-\$HOME/.config/chromium/}\"" \
        --set-default PLAYWRIGHT_MCP_CONFIG $out/share/playwright-cli/playwright-cli.json
    '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [ final.versionCheckHook ];
  versionCheckProgramArg = "--version";

  meta = {
    description = "Playwright CLI for browser automation from coding agents";
    homepage = "https://github.com/microsoft/playwright-cli";
    changelog = "https://github.com/microsoft/playwright-cli/releases/tag/v0.1.23";
    license = final.lib.licenses.asl20;
    platforms = final.lib.platforms.linux;
    mainProgram = "playwright-cli";
  };
}
