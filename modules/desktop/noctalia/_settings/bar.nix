{
  bar = {
    order = [ "main" ];
    main = {
      position = "top";
      # Fullscreen windows cover the top layer; overlay would remain above them.
      layer = "top";
      thickness = 35;
      # Release 5.4.1 uses logical pixels: 20% of 2560 / 1.5, rounded.
      margin_ends = 341;
      margin_edge = 8;
      padding = 15;
      hover_highlight = false;
      widget_spacing = 4;
      radius = 10;
      background_opacity = 1.0;
      shadow = false;
      reserve_space = true;
      start = [ "workspaces" ];
      center = [ "clock" ];
      end = [
        "tray"
        "network"
        "volume"
        "battery"
        "bar"
      ];
    };
  };
  widget = {
    bar = {
      type = "raycursive/niri-displays:bar";
      anchor = true;
      show_resolution = false;
    };
    workspaces = {
      style = "regular";
      change_color_on_hover = false;
      hide_when_empty = true;
      show_labels = true;
      label_source = "id";
    };
    clock.format = "{:%H:%M:%S}";
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
