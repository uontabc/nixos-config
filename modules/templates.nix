{ ... }:
{
  # Templates remain independent flakes, without a system dimension here.
  flake.templates = {
    python = {
      path = ../templates/python;
      description = "python project with pinned dependencies and direnv";
    };
    rust = {
      path = ../templates/rust;
      description = "rust project with pinned dependencies and direnv";
    };
    cpp = {
      path = ../templates/cpp;
      description = "cpp project with pinned dependencies and direnv";
    };
  };
}
