"""Sliding Kitty tabs, adapted from patricorgi/kitty-sliding-tabs.

Unlike upstream's Retina-only layout, a blank cell carries the actual font
metrics; nine unused cells carry the bounds and live theme colors. The shader
erases this record. Crowded/unsupported layouts use ordinary, instant tabs.
"""

from time import monotonic
from typing import NamedTuple

from kitty.fast_data_types import (
    add_timer,
    get_boss,
    get_options,
    mark_tab_bar_dirty,
    set_tab_bar_render_data,
    viewport_for_window,
)
from kitty.tab_bar import TabBar, as_rgb, draw_tab_with_separator

SLIDE_SECONDS = 0.180
FRAME_SECONDS = 1 / 120
RECORD_CELLS = 9
SIGNATURES = (1, 2, 3, 2)
SHADER = "active-tab-slide-lite"


def active_index_color(draw_data, tab):
    foreground, background = draw_data.tab_fg(tab), draw_data.tab_bg(tab)
    return sum(
        round(0.75 * ((foreground >> shift) & 255) + 0.25 * ((background >> shift) & 255)) << shift
        for shift in (16, 8, 0)
    )


def draw_tab(draw_data, screen, tab, before, max_tab_length, index, is_last, extra_data):
    # A real blank cell is the left margin and the shader's geometry beacon.
    if index == 1 and max_tab_length >= 5:
        background = screen.cursor.bg
        screen.cursor.bg = as_rgb(int(draw_data.default_bg))
        screen.draw(" ")
        screen.cursor.bg = background
        before += 1
        max_tab_length -= 1

    template = draw_data.active_title_template or draw_data.title_template
    if tab.is_active:
        template = template.replace("{fmt.fg.color8}", f"{{fmt.fg._{active_index_color(draw_data, tab):06x}}}")
    padded = draw_data._replace(
        title_template=draw_data.title_template.strip(),
        active_title_template=template.strip(),
        leading_spaces=1,
        trailing_spaces=1,
    )
    tab = tab._replace(title=tab.title.replace("\n", " ").replace("\r", " "))
    return draw_tab_with_separator(
        padded, screen, tab, before, max_tab_length, index, is_last, extra_data
    )


draw_tab._sliding_tabs = True

# Keep the pixel remainder on the right, making cell zero start at pixel zero.
# Preserve the original methods across Kitty's config/module reloads.
native_layout = getattr(TabBar.layout, "_native_layout", TabBar.layout)


def layout(self):
    native_layout(self)
    if not getattr(self.draw_func, "_sliding_tabs", False) or self.is_vertical or not self.laid_out_once:
        return
    g = self.window_geometry
    if self.margin_width != 0 or g.left == 0:
        return
    self.window_geometry = g = g._replace(left=0, right=g.right - g.left)
    self.update_blank_rects(*self._last_viewport)
    set_tab_bar_render_data(self.os_window_id, self.screen, *g[:4])


layout._native_layout = native_layout
TabBar.layout = layout


class TabSlide(NamedTuple):
    layout: tuple
    tab_id: int
    source: tuple
    target: tuple
    started: float

    def bounds(self, now):
        remaining = 1 - min(1.0, max(0.0, (now - self.started) / SLIDE_SECONDS))
        return tuple(
            round(end + (start - end) * remaining**3)
            for start, end in zip(self.source, self.target)
        )


def next_slide(old, layout_key, tab_id, target, now):
    if old is None or old.layout != layout_key:
        return TabSlide(layout_key, tab_id, target, target, now)
    if old.tab_id != tab_id:
        return TabSlide(layout_key, tab_id, old.bounds(now), target, now)
    return old._replace(target=target)


def marker_color(value, signature):
    # Five-bit channels spaced in sRGB survive the linear-color framebuffer.
    packed = value | (signature << 13)
    channels = [96 + 5 * ((packed >> shift) & 31) for shift in (10, 5, 0)]
    return as_rgb((channels[0] << 16) | (channels[1] << 8) | channels[2])


def request_frame(self):
    if getattr(self, "_tab_slide_timer", None):
        return

    def next_frame(_timer_id):
        self._tab_slide_timer = None
        boss = get_boss()
        manager = boss.os_window_map.get(self.os_window_id) if boss is not None else None
        if manager is not None and not manager.tab_bar_hidden and manager.tab_bar_should_be_visible:
            manager.update_tab_bar_data()
            mark_tab_bar_dirty(self.os_window_id, True)

    self._tab_slide_timer = add_timer(next_frame, FRAME_SECONDS, False)


native_update_horizontal = getattr(
    TabBar.update_horizontal, "_native_update_horizontal", TabBar.update_horizontal
)


def update_horizontal(self, data):
    enabled = getattr(self.draw_func, "_sliding_tabs", False)
    if enabled:
        # Noctalia can supply a different inactive background. The moving fill
        # needs one uniform base, so use the live terminal background instead.
        self.draw_data = self.draw_data._replace(inactive_bg=self.draw_data.default_bg)
    changed = native_update_horizontal(self, data)
    if not enabled or SHADER not in get_options().custom_shaders:
        self._tab_slide = None
        return changed

    active = next((tab for tab in data if tab.is_active), None)
    extent = next(
        (item.x for item in self.tab_extents if active is not None and item.tab_id == active.tab_id),
        None,
    )
    screen = self.screen
    g = self.window_geometry
    central, _, width, _, cell_width, cell_height = viewport_for_window(self.os_window_id)
    slot = screen.columns - RECORD_CELLS
    after_tabs = max((item.x.end for item in self.tab_extents), default=0)
    # Zero inner margin places the record's sampling row immediately above
    # central_area. Unsupported geometry never emits visible metadata cells.
    if (
        extent is None
        or g.left != 0
        or g.bottom != central.top
        or not (1 <= cell_width < 64 and 1 <= cell_height < 128)
        or screen.columns != width // cell_width
        or slot <= after_tabs
        or any(screen.line(0)[x] not in (" ", "\x00") for x in (0, *range(slot, screen.columns)))
    ):
        self._tab_slide = None
        return changed

    target = (max(1, extent.start) * cell_width, extent.end * cell_width)
    layout_key = (tuple(g), cell_width, cell_height, tuple(tab.tab_id for tab in data))
    now = monotonic()
    slide = next_slide(getattr(self, "_tab_slide", None), layout_key, active.tab_id, target, now)
    if slide.source == slide.target or now - slide.started >= SLIDE_SECONDS:
        slide = slide._replace(source=target)
    values = (*slide.bounds(now), *target)
    if target[1] <= target[0] or any(value < 0 or value >= 8192 for value in values):
        self._tab_slide = None
        return changed
    self._tab_slide = slide

    cursor = screen.cursor
    previous_x, previous_bg = cursor.x, cursor.bg
    try:
        cursor.x = 0
        cursor.bg = marker_color(cell_width | (cell_height << 6), 3)
        screen.draw(" ")
        cursor.x = slot
        for value, signature in zip(values, SIGNATURES):
            cursor.bg = marker_color(value, signature)
            screen.draw(" ")
        palette = (
            self.draw_data.tab_bg(active),
            self.draw_data.tab_fg(active),
            active_index_color(self.draw_data, active),
            int(self.draw_data.inactive_fg),
            int(get_options().color8),
        )
        for color in palette:
            cursor.bg = as_rgb(color)
            screen.draw(" ")
    finally:
        cursor.x, cursor.bg = previous_x, previous_bg

    # Static rounded tabs do not run a periodic timer.
    if slide.source != slide.target:
        request_frame(self)
    return changed


update_horizontal._native_update_horizontal = native_update_horizontal
TabBar.update_horizontal = update_horizontal
