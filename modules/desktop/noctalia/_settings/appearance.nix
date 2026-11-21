{ identity }:
{
  theme = {
    mode = "light";
    shell_mode = "follow";
    source = "custom";
    custom_palette = "Bluney";
    builtin = "Tokyo-Night";
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
    widget_order = [
      "desktop-widget-0000000000000001"
      "desktop-widget-0000000000000003"
      "desktop-widget-0000000000000004"
      "desktop-widget-0000000000000005"
    ];
    grid = {
      cell_size = 16;
      major_interval = 4;
      visible = true;
    };
    widget = {
      desktop-widget-0000000000000001 = {
        type = "clock";
        output = "eDP-1";
        box_height = 144.0;
        box_width = 272.0;
        cx = 152.0;
        cy = 152.0;
        placement_height = 1280.0;
        placement_width = 2048.0;
        rotation = 0.0;
        settings = {
          background_color = "on_tertiary";
          background_opacity = 0.9;
          background_padding = 10;
          background_radius = 12;
          center_text = true;
          clock_style = "digital";
          format = "{:%H:%M:%S}";
        };
      };
      desktop-widget-0000000000000003 = {
        type = "sysmon";
        output = "eDP-1";
        box_height = 48.0;
        box_width = 272.0;
        cx = 152.0;
        cy = 440.0;
        placement_height = 1280.0;
        placement_width = 2048.0;
        rotation = 0.0;
        settings = {
          display = "gauge";
          gauge_layout = "horizontal";
          network_speed_unit = "kb";
          stat = "net_tx";
          stat2 = "net_rx";
        };
      };
      desktop-widget-0000000000000004 = {
        type = "volume";
        output = "eDP-1";
        box_height = 160.0;
        box_width = 272.0;
        cx = 152.0;
        cy = 320.0;
        placement_height = 1280.0;
        placement_width = 2048.0;
        rotation = 0.0;
        settings = {
          background = true;
          background_opacity = 0.9;
          device = "output";
          scroll_step = 5;
          shadow = false;
          show_device = false;
        };
      };
      desktop-widget-0000000000000005 = {
        type = "sysmon";
        output = "eDP-1";
        box_height = 48.0;
        box_width = 272.0;
        cx = 152.0;
        cy = 496.0;
        placement_height = 1280.0;
        placement_width = 2048.0;
        rotation = 0.0;
        settings = {
          display = "gauge";
          stat = "net_rx";
          stat2 = "cpu_temp";
        };
      };
    };
  };
  lockscreen = {
    blurred_desktop = true;
    fingerprint = false;
    # niri-lock-before-sleep handles locking through swayidle instead.
    lock_before_suspend = false;
    transition = [ "fade" ];
  };
  lockscreen_widgets = {
    enabled = true;
    schema_version = 2;
    widget_order = [
      "lockscreen-login-box@eDP-1"
      "lockscreen-login-box@DP-1"
      "lockscreen-widget-0000000000000001"
      "lockscreen-widget-0000000000000002"
    ];
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
      cx = 1024.0;
      cy = 1134.4000244140625;
      placement_height = 1280.0;
      placement_width = 2048.0;
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
        show_media = true;
        show_media_controls = true;
        show_password_reveal = true;
        show_session_buttons = true;
        show_unlock_hint = true;
        show_weather = true;
      };
    };
    widget."lockscreen-login-box@DP-1" = {
      type = "login_box";
      output = "DP-1";
      box_height = 196.0;
      box_width = 810.0;
      cx = 1279.9998779296875;
      cy = 1258.0001220703125;
      placement_height = 1440.0;
      placement_width = 2560.0;
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
        show_media = true;
        show_media_controls = true;
        show_password_reveal = true;
        show_session_buttons = true;
        show_unlock_hint = true;
        show_weather = true;
      };
    };
    widget.lockscreen-widget-0000000000000001 = {
      type = "sysmon";
      output = "eDP-1";
      box_height = 320.0;
      box_width = 400.0;
      cx = 824.0;
      cy = 816.0;
      placement_height = 1280.0;
      placement_width = 2048.0;
      rotation = 0.0;
      settings = {
        background_opacity = 0.9;
        display = "graph";
        stat = "ram_pct";
        stat2 = "cpu_usage";
      };
    };
    widget.lockscreen-widget-0000000000000002 = {
      type = "sysmon";
      output = "eDP-1";
      box_height = 320.0;
      box_width = 384.0;
      cx = 1232.0;
      cy = 816.0;
      placement_height = 1280.0;
      placement_width = 2048.0;
      rotation = 0.0;
      settings = {
        background_opacity = 0.9;
        display = "graph";
        gauge_layout = "horizontal";
        stat = "cpu_usage";
        stat2 = "cpu_freq";
      };
    };
  };
  wallpaper = {
    enabled = true;
    directory = "/home/${identity.username}/Pictures";
    fill_mode = "stretch";
    transition_on_startup = true;
    default.path = "/home/${identity.username}/Pictures/ign_circuit.png";
    last.path = "/home/${identity.username}/Pictures/ign_circuit.png";
    monitors.eDP-1.path = "/home/${identity.username}/Pictures/ign_circuit.png";
    monitors.DP-1.path = "/home/${identity.username}/Pictures/ign_circuit.png";
  };
  # Separate overview wallpaper, following the current GUI-selected image.
  backdrop = {
    enabled = true;
    blur_intensity = 0.5;
    tint_intensity = 0.3;
  };
}
