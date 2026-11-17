{ identity }:
{
  theme = {
    mode = "light";
    shell_mode = "follow";
    source = "custom";
    custom_palette = "Bluney";
    terminal_colors = "palette";
    sync_color_scheme = true;
    wallpaper_scheme = "m3-content";
    templates = {
      # Match the installed desktop; Nix owns integration, Noctalia owns colors.
      builtin_ids = [
        "btop"
        "gtk3"
        "gtk4"
        "kitty"
        "niri"
        "qt"
      ];
      enable_builtin_templates = true;
      enable_community_templates = false;
    };
  };
  desktop_widgets = {
    schema_version = 2;
    widget_order = [ ];
    grid = {
      cell_size = 16;
      major_interval = 4;
      visible = true;
    };
    widget = { };
  };
  lockscreen.blurred_desktop = true;
  lockscreen_widgets = {
    enabled = false;
    schema_version = 2;
    widget_order = [ "lockscreen-login-box@eDP-1" ];
    grid = {
      cell_size = 16;
      major_interval = 4;
      visible = true;
    };
    widget."lockscreen-login-box@eDP-1" = {
      type = "login_box";
      output = "eDP-1";
      box_height = 196.0;
      box_width = 810.0;
      cx = 853.5;
      cy = 945.62872314453125;
      placement_height = 1067.0;
      placement_width = 1707.0;
      rotation = 0.0;
      settings = {
        background_color = "surface_container";
        background_opacity = 0.88;
        background_radius = 12.0;
        center_password_text = false;
        input_opacity = 1.0;
        input_radius = 6.0;
        layout = "regular";
        show_caps_lock = true;
        show_keyboard_layout = true;
        show_login_button = true;
        # In release 5.4.1 show_media also includes playback controls.
        show_media = true;
        show_password_reveal = true;
        show_session_buttons = true;
        show_unlock_hint = true;
        show_weather = true;
      };
    };
  };
  wallpaper = {
    enabled = true;
    directory = "/home/${identity.username}/Pictures";
    fill_mode = "stretch";
    transition_on_startup = true;
    default.path = "/home/${identity.username}/Pictures/file_00000000ad5c81fdb4c4b8b5650399cc.png";
    last.path = "/home/${identity.username}/Pictures/file_00000000ad5c81fdb4c4b8b5650399cc.png";
    monitors.eDP-1.path = "/home/${identity.username}/Pictures/file_00000000ad5c81fdb4c4b8b5650399cc.png";
  };
  # Separate overview wallpaper, following the current GUI-selected image.
  backdrop = {
    enabled = true;
    blur_intensity = 0.5;
    tint_intensity = 0.3;
  };
}
