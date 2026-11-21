{
  bar = {
    order = [ "main" ];
    main = {
      position = "top";
      # Fullscreen windows cover the top layer; overlay would remain above them.
      layer = "top";
      thickness = 33;
      margin_ends = 10;
      margin_edge = 8;
      padding = 15;
      hover_highlight = false;
      widget_spacing = 5;
      radius = 20;
      background_opacity = 1.0;
      shadow = false;
      compositor_blur = false;
      capsule_radius = 7;
      capsule_thickness = 0.79999998584389687;
      show_tooltip = false;
      reserve_space = true;
      start = [ "group:g1" ];
      center = [ "weather" ];
      end = [ "group:g3" ];
      capsule_group = [
        {
          id = "g1";
          members = [
            "workspaces"
            "cpu"
            "ram"
            "temp"
          ];
          enabled = true;
          accordion = false;
          accordion_direction = "end";
          border = "on_primary_container";
          border_width = 1.0;
          fill = "surface_container";
          opacity = 1.0;
          padding = 10.0;
        }
        {
          id = "g3";
          members = [
            "tray"
            "brightness"
            "network"
            "bar"
            "battery"
          ];
          enabled = true;
          accordion = false;
          accordion_direction = "end";
          border = "on_primary_container";
          border_width = 1.0;
          fill = "surface_container";
          opacity = 1.0;
          padding = 6.0;
        }
      ];
    };
  };
  widget = {
    bar = {
      type = "raycursive/niri-displays:bar";
      anchor = false;
      show_resolution = false;
    };
    workspaces = {
      style = "regular";
      change_color_on_hover = false;
      hide_when_empty = true;
      capsule_radius = "auto";
      show_labels = false;
      label_source = "id";
      active_pill_size = 2.1500000000000004;
      focused_output_only = true;
    };
    clock = {
      format = "{:%H:%M:%S}";
      capsule = true;
      capsule_border = "on_primary_container";
      capsule_radius = 5;
    };
    weather = {
      capsule = true;
      capsule_border = "on_primary_container";
      capsule_radius = "auto";
    };
    audio_visualizer = {
      show_when_idle = true;
      width = 220;
    };
    notifications.hide_when_no_unread = true;
    network.show_label = false;
    volume.show_label = false;
    battery.show_label = true;
  };
  dock = {
    enabled = false;
    layer = "overlay";
  };
}
