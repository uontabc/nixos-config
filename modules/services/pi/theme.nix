{ ... }:
{
  flake.modules.nixos.pi-theme =
    {
      inputs,
      lib,
      pkgs,
      ...
    }:
    let
      theme = import ../../../lib/theme.nix;
      upstream = builtins.fromJSON (builtins.readFile "${inputs.pi}/VERSION.json");
      source = pkgs.fetchFromGitHub {
        owner = "earendil-works";
        repo = "pi";
        inherit (upstream) rev hash;
      };
      roles = {
        accent = "mauve";
        border = "surface1";
        borderAccent = "mauve";
        borderMuted = "surface0";
        text = "text";
        muted = "subtext0";
        dim = "overlay0";
        success = "green";
        error = "red";
        warning = "yellow";
        selectedBg = "surface0";
        userMessageBg = "surface0";
        userMessageText = "text";
        customMessageBg = "mantle";
        customMessageText = "text";
        customMessageLabel = "mauve";
        thinkingText = "subtext0";
        toolPendingBg = "mantle";
        toolSuccessBg = "base";
        toolErrorBg = "surface0";
        toolTitle = "mauve";
        toolOutput = "text";
        toolDiffAdded = "green";
        toolDiffRemoved = "red";
        toolDiffContext = "overlay1";
        mdHeading = "mauve";
        mdLink = "blue";
        mdLinkUrl = "overlay1";
        mdCode = "green";
        mdCodeBlock = "teal";
        mdCodeBlockBorder = "surface1";
        mdQuote = "subtext0";
        mdQuoteBorder = "mauve";
        mdHr = "surface1";
        mdListBullet = "mauve";
        mdBold = "peach";
        mdItalic = "lavender";
        syntaxComment = "overlay1";
        syntaxKeyword = "mauve";
        syntaxFunction = "blue";
        syntaxVariable = "text";
        syntaxString = "green";
        syntaxNumber = "peach";
        syntaxType = "yellow";
        syntaxOperator = "sky";
        syntaxPunctuation = "overlay2";
        thinkingMinimal = "overlay0";
        thinkingLow = "teal";
        thinkingMedium = "blue";
        thinkingHigh = "mauve";
        thinkingXhigh = "lavender";
        thinkingMax = "pink";
        bashMode = "peach";
      };
      piTheme = pkgs.runCommand "fleet-mocha.json" { nativeBuildInputs = [ pkgs.jq ]; } ''
        jq --argjson palette ${lib.escapeShellArg (builtins.toJSON theme.colors)} \
           --argjson roles ${lib.escapeShellArg (builtins.toJSON roles)} '
          .name = "fleet-mocha" | .appearance = "dark" | .vars = $palette |
          .colors |= with_entries(.value = ($roles[.key] //
            (if (.key | test("Bg$")) then "base"
             elif (.key | test("[Bb]order")) then "surface1" else "text" end))) |
          .export = {pageBg: "base", cardBg: "mantle", infoBg: "surface0"}
        ' ${source}/packages/coding-agent/src/modes/interactive/theme/dark.json > "$out"
      '';
    in
    {
      programs.pi.coding-agent = {
        themes = [ piTheme ];
        settings.theme = theme.name;
      };
    };
}
