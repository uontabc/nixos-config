"""Run with: kitty +launch modules/desktop/kitty/test_tab_bar.py"""

import importlib.util
from pathlib import Path
from types import SimpleNamespace
import tempfile
import unittest
from unittest.mock import patch

from kitty.fast_data_types import Color
from kitty.tab_bar import CellRange, DrawData, TabBarData, TabExtent
from kitty.types import WindowGeometry

spec = importlib.util.spec_from_file_location("sliding_tab_bar", Path(__file__).with_name("tab_bar.py"))
tabs = importlib.util.module_from_spec(spec)
spec.loader.exec_module(tabs)


def decode_marker(encoded, signature):
    rgb = encoded >> 8
    channels = [(rgb >> shift) & 255 for shift in (16, 8, 0)]
    # Include the sRGB -> linear RGBA16 -> sRGB conversion made by Kitty.
    levels = []
    for channel in channels:
        linear = ((channel / 255 + 0.055) / 1.055) ** 2.4
        linear = round(linear * 65535) / 65535
        srgb = (1.055 * linear ** (1 / 2.4) - 0.055) * 255
        levels.append(round((srgb - 96) / 5))
    packed = (levels[0] << 10) | (levels[1] << 5) | levels[2]
    return packed & 8191 if packed >> 13 == signature else -1


class FakeScreen:
    def __init__(self, columns=100):
        self.columns = columns
        self.cursor = SimpleNamespace(x=30, bg=123)
        self.cells = [" "] * columns
        self.backgrounds = {}

    def line(self, row):
        return self.cells

    def draw(self, text):
        for char in text:
            x = self.cursor.x
            self.cells[x] = char
            self.backgrounds[x] = self.cursor.bg
            self.cursor.x += 1


def draw_data():
    return DrawData(
        leading_spaces=0, sep="", trailing_spaces=0, bell_on_tab="!", alpha=(),
        active_fg=Color(255, 255, 255), active_bg=Color(50, 110, 190),
        inactive_fg=Color(40, 50, 70), inactive_bg=Color(220, 225, 230),
        default_bg=Color(240, 245, 250), title_template=" {index} {title} ",
        active_title_template=None, tab_activity_symbol="*", powerline_style="slanted",
        tab_bar_edge="top", max_tab_title_length=30, max_tab_title_lines=1,
        wrap_width=0, os_window_id=1,
    )


class SlidingTabsTests(unittest.TestCase):
    def setUp(self):
        self.options = SimpleNamespace(custom_shaders=(tabs.SHADER,), color8=Color(100, 110, 120))
        self.bar = SimpleNamespace(
            draw_func=tabs.draw_tab, draw_data=draw_data(), screen=FakeScreen(),
            window_geometry=WindowGeometry(0, 10, 1200, 36, 100, 1), os_window_id=1,
            tab_extents=[TabExtent(1, CellRange(0, 10)), TabExtent(2, CellRange(10, 20))],
        )
        self.data = [TabBarData("one", True, tab_id=1), TabBarData("two", False, tab_id=2)]
        self.viewport = (SimpleNamespace(top=36), None, 1200, 800, 12, 26)
        self.timer = self.enterContext(patch.object(tabs, "request_frame"))
        self.enterContext(patch.object(tabs, "get_options", return_value=self.options))
        self.enterContext(patch.object(tabs, "native_update_horizontal", return_value=False))
        self.enterContext(patch.object(tabs, "viewport_for_window", side_effect=lambda _: self.viewport))
        self.clock = self.enterContext(patch.object(tabs, "monotonic", return_value=10.0))

    def render(self):
        self.bar.screen.backgrounds.clear()
        return tabs.update_horizontal(self.bar, self.data)

    def test_all_marker_values_survive_framebuffer_roundtrip(self):
        for signature in (1, 2, 3):
            for value in range(8192):
                self.assertEqual(decode_marker(tabs.marker_color(value, signature), signature), value)

    def test_ease_out_and_endpoints(self):
        slide = tabs.TabSlide((), 1, (10, 110), (210, 410), 5)
        self.assertEqual(slide.bounds(4), (10, 110))
        self.assertEqual(slide.bounds(5), (10, 110))
        self.assertEqual(slide.bounds(5 + tabs.SLIDE_SECONDS / 2), (185, 372))
        self.assertEqual(slide.bounds(6), (210, 410))

    def test_rapid_switch_starts_at_interpolated_position(self):
        old = tabs.TabSlide((1,), 1, (10, 110), (210, 410), 5)
        now = 5 + tabs.SLIDE_SECONDS / 2
        new = tabs.next_slide(old, (1,), 2, (500, 600), now)
        self.assertEqual(new.source, old.bounds(now))
        self.assertEqual(new.bounds(now), old.bounds(now))

    def test_layout_change_snaps_to_new_geometry(self):
        old = tabs.TabSlide((1,), 1, (10, 110), (210, 410), 5)
        new = tabs.next_slide(old, (2,), 2, (500, 600), 5.05)
        self.assertEqual(new.source, new.target)

    def test_static_record_uses_real_metrics_without_timer(self):
        self.render()
        screen = self.bar.screen
        self.assertEqual(decode_marker(screen.backgrounds[0], 3), 12 | (26 << 6))
        self.assertEqual(len(screen.backgrounds), 1 + tabs.RECORD_CELLS)
        self.assertEqual((screen.cursor.x, screen.cursor.bg), (30, 123))
        self.assertEqual(self.bar.draw_data.inactive_bg, self.bar.draw_data.default_bg)
        self.timer.assert_not_called()

    def test_live_palette_is_encoded_in_record(self):
        self.options.color8 = Color(180, 190, 200)
        self.bar.draw_data = self.bar.draw_data._replace(active_bg=Color(80, 90, 100))
        self.render()
        backgrounds = self.bar.screen.backgrounds
        self.assertEqual(backgrounds[95], tabs.as_rgb(int(self.bar.draw_data.active_bg)))
        self.assertEqual(backgrounds[97], tabs.as_rgb(tabs.active_index_color(self.bar.draw_data, self.data[0])))
        self.assertEqual(backgrounds[99], tabs.as_rgb(int(self.options.color8)))

    def test_switch_requests_frames_then_stops(self):
        self.render()
        self.clock.return_value += 0.01
        self.data = [self.data[0]._replace(is_active=False), self.data[1]._replace(is_active=True)]
        self.render()
        self.assertNotEqual(self.bar._tab_slide.source, self.bar._tab_slide.target)
        self.timer.assert_called_once()
        self.timer.reset_mock()
        self.clock.return_value += 1
        self.render()
        self.assertEqual(self.bar._tab_slide.source, self.bar._tab_slide.target)
        self.timer.assert_not_called()

    def assert_fallback(self):
        self.render()
        self.assertIsNone(self.bar._tab_slide)
        self.assertFalse(self.bar.screen.backgrounds)
        self.timer.assert_not_called()

    def test_crowded_bar_emits_no_markers(self):
        self.bar.tab_extents[-1] = TabExtent(2, CellRange(10, 95))
        self.assert_fallback()

    def test_occupied_record_emits_no_markers(self):
        self.bar.screen.cells[-1] = "x"
        self.assert_fallback()

    def test_shader_disabled_emits_no_markers(self):
        self.options.custom_shaders = ()
        self.assert_fallback()

    def test_unsupported_font_metrics_emit_no_markers(self):
        self.viewport = (*self.viewport[:4], 64, 128)
        self.assert_fallback()

    def test_nonzero_inner_margin_emits_no_markers(self):
        self.viewport[0].top += 10
        self.assert_fallback()

    def test_missing_active_tab_emits_no_markers(self):
        self.data = [tab._replace(is_active=False) for tab in self.data]
        self.assert_fallback()


class ShaderTests(unittest.TestCase):
    def test_pipeline_compiles_without_display(self):
        from kitty.shaders.slang import build_custom_shader_pipeline_glsl, parse_pipeline

        path = Path(__file__).resolve().parent / "shaders" / "active-tab-slide-lite.pipeline"
        with tempfile.TemporaryDirectory(prefix="kitty-slide-test-") as cache:
            vertex, fragment, metadata = build_custom_shader_pipeline_glsl(
                parse_pipeline(str(path)), cache_dir=cache
            )
        self.assertTrue(vertex)
        self.assertTrue(fragment)
        self.assertTrue(metadata)


if __name__ == "__main__":
    unittest.main()
