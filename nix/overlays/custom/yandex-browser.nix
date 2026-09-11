final: _:

final.stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "yandex-browser";
  version = "26.8.1.1022";

  src = final.fetchurl {
    url =
      "https://repo.yandex.ru/yandex-browser/deb/pool/main/y/yandex-browser-stable/"
      + "yandex-browser-stable_${finalAttrs.version}-1_amd64.deb";
    hash = "sha256-auMULz/IeN9fTdXR38pVHDnn+FWtOjwX6nikdj0/uSE=";
  };

  nativeBuildInputs = with final; [
    autoPatchelfHook
    dpkg
    makeWrapper
    wrapGAppsHook3
  ];

  buildInputs = with final; [
    alsa-lib
    at-spi2-core
    cairo
    cups
    dbus
    expat
    glib
    gsettings-desktop-schemas
    gtk3
    libgbm
    libx11
    libxcb
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxkbcommon
    libxrandr
    nspr
    nss
    pango
    (lib.getLib qt5.qtbase)
    (lib.getLib qt6.qtbase)
    stdenv.cc.cc.lib
    systemd
  ];

  runtimeDependencies =
    with final;
    map lib.getLib [
      curl
      fontconfig
      freetype
      gtk3
      libdrm
      libglvnd
      libkrb5
      libpulseaudio
      libva
      libxshmfence
      pipewire
      vulkan-loader
      wayland
    ];

  appendRunpaths = [ "${final.addDriverRunpath.driverLink}/lib" ];

  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;
  dontWrapGApps = true;

  unpackPhase = ''
    runHook preUnpack
    # Nix's build sandbox rejects the Debian sandbox helper's setuid bit.
    dpkg-deb --fsys-tarfile "$src" | tar -x --no-same-permissions
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin" "$out/opt" "$out/share"
    cp -a opt/yandex "$out/opt/"
    cp -a usr/share/. "$out/share/"

    substituteInPlace "$out/opt/yandex/browser/yandex-browser" \
      --replace-fail CHROME_WRAPPER WRAPPER
    substituteInPlace "$out/share/applications/"*.desktop \
      --replace-fail /usr/bin/yandex-browser-stable "$out/bin/yandex-browser"
    substituteInPlace "$out/share/gnome-control-center/default-apps/yandex-browser.xml" \
      --replace-fail /opt/yandex/browser/yandex-browser "$out/bin/yandex-browser"

    for size in 16 24 32 48 64 128 256; do
      install -Dm644 "$out/opt/yandex/browser/product_logo_$size.png" \
        "$out/share/icons/hicolor/''${size}x$size/apps/yandex-browser.png"
    done

    # Use the NixOS-patched loader for Vulkan driver discovery.
    rm "$out/opt/yandex/browser/libvulkan.so.1"
    ln -s "${final.lib.getLib final.vulkan-loader}/lib/libvulkan.so.1" \
      "$out/opt/yandex/browser/libvulkan.so.1"

    runHook postInstall
  '';

  preFixup = ''
    makeShellWrapper "$out/opt/yandex/browser/yandex-browser" "$out/bin/yandex-browser" \
      "''${gappsWrapperArgs[@]}" \
      --prefix LD_LIBRARY_PATH : "${final.lib.makeLibraryPath finalAttrs.runtimeDependencies}" \
      --prefix PATH : "${final.lib.makeBinPath [ final.coreutils ]}" \
      --suffix PATH : "${final.lib.makeBinPath [ final.xdg-utils ]}" \
      --prefix XDG_DATA_DIRS : "${final.addDriverRunpath.driverLink}/share" \
      --set CHROME_WRAPPER "$out/bin/yandex-browser" \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform=wayland --enable-wayland-ime}}"
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    HOME="$TMPDIR" "$out/bin/yandex-browser" --version | grep -F "${finalAttrs.version}"
    runHook postInstallCheck
  '';

  meta = {
    description = "Chromium-based web browser from Yandex";
    homepage = "https://browser.yandex.com/";
    license = final.lib.licenses.unfree;
    sourceProvenance = [ final.lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "yandex-browser";
  };
})
