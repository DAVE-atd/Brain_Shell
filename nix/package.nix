{
  lib,
  stdenv,
  makeWrapper,
  qt6,
  runtimeDeps,
}:

stdenv.mkDerivation {
  pname = "brain-shell";
  version = "0.2.2";
  src = ./..;

  nativeBuildInputs = [ makeWrapper ];

  phases = [ "installPhase" ];
  installPhase = ''
    mkdir -p $out/share/brain-shell $out/bin
    # Common/ Services/ Widgets/: DMS compatibility layer (qs.* imports of vendored plugins)
    cp -r $src/src $src/shell.qml $src/Common $src/Services $src/Widgets $out/share/brain-shell/
    chmod +x $out/share/brain-shell/src/scripts/*.sh 2>/dev/null || true

    install -Dm755 ${./launcher.sh} $out/bin/.brain-shell-unwrapped
    substituteInPlace $out/bin/.brain-shell-unwrapped --replace-fail "@out@" "$out"

    makeWrapper $out/bin/.brain-shell-unwrapped $out/bin/brain-shell \
      --prefix PATH : "${lib.makeBinPath runtimeDeps}" \
      --prefix QML_IMPORT_PATH : "${qt6.qtmultimedia}/${qt6.qtbase.qtQmlPrefix}" \
      --set BRAIN_SHELL_INSTALL_DIR "$out/share/brain-shell" \
      --set BRAIN_SHELL_NIX "1" \
      --run '[ -z "$BRAIN_SHELL_CONFIG_DIR" ] && export BRAIN_SHELL_CONFIG_DIR="$HOME/.config/Brain_Shell"'
  '';

  meta = {
    description = "Modular session shell for Hyprland built with Quickshell";
    homepage = "https://github.com/Brainitech/Brain_Shell";
    license = lib.licenses.agpl3Plus;
    platforms = lib.platforms.linux;
    mainProgram = "brain-shell";
  };
}
