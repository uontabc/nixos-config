{ theme }:
{
  shell = {
    font_family = theme.fonts.mono;
    lang = "zh-Hans";
    polkit_agent = true;
    launch_apps_as_systemd_services = true;
    settings_expand_all_groups = true;
    screen_corners = {
      enabled = true;
      size = 24;
    };
    panel_anchor_bar = "main";
    panel = {
      control_center_placement = "floating";
      wallpaper_placement = "floating";
    };
    shadow.direction = "center";
    launcher = {
      layout = "simple";
      compact = true;
      categories = false;
      show_navigation_labels = false;
      show_settings_button = false;
      show_session_button = false;
      show_app_origin_indicator = false;
    };
  };
  plugins = {
    auto_update = "all";
    enabled = [ "raycursive/niri-displays" ];
  };
  plugin_settings."raycursive/niri-displays" = {
    # The panel may make temporary changes; Nix owns persistent output defaults.
    scale_presets = [ ];
    panel_layer = "top";
    panel_placement = "floating";
    panel_position = "center";
  };
  audio.colorize_icons = true;
  control_center.width = 710;
  location.auto_locate = true;
  idle.behavior = {
    lock = {
      enabled = true;
      timeout = 600;
      action = "lock";
    };
    screen-off = {
      enabled = true;
      timeout = 660;
      action = "screen_off";
    };
  };
}
