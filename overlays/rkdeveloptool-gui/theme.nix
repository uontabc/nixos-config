{ theme, writeText }:
let
  c = theme.colors;
  accent = c.${theme.accent};
  check = writeText "rkdeveloptool-gui-check.svg" ''
    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 16 16">
      <path d="m3.5 8 3 3 6-6" fill="none" stroke="${c.base}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
    </svg>
  '';
  arrow =
    name: rotation:
    writeText "rkdeveloptool-gui-chevron-${name}.svg" ''
      <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 16 16">
        <path d="m4 6 4 4 4-4" transform="rotate(${rotation} 8 8)" fill="none" stroke="${c.subtext1}" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
      </svg>
    '';
  down = arrow "down" "0";
  left = arrow "left" "90";
  right = arrow "right" "270";
in
''
  /* Application-local Tokyo Night; do not load host Qt plugins into bundled Qt. */
  QWidget {
    color: ${c.text};
    background-color: ${c.base};
    font-family: "${theme.fonts.sans}", "${theme.fonts.cjk}";
    selection-color: ${c.text};
    selection-background-color: ${c.selection};
  }
  QLabel, QCheckBox, QRadioButton { background-color: transparent; }
  QLabel:disabled { color: ${c.subtext0}; }
  QMainWindow, QDialog, QMessageBox { background-color: ${c.base}; }
  QGroupBox {
    border: 1px solid ${c.surface1};
    border-radius: 8px;
    margin-top: 16px;
    padding: 12px 8px 8px;
  }
  QGroupBox::title {
    subcontrol-origin: margin;
    subcontrol-position: top left;
    left: 12px;
    padding: 0 6px;
    color: ${accent};
  }
  QLabel#home_status_banner {
    background-color: ${c.surface0};
    border: 1px solid ${c.surface1};
    border-radius: 6px;
  }
  QTabWidget::pane {
    border: 1px solid ${c.surface1};
    border-radius: 8px;
    padding: 6px;
  }
  QTabBar::tab {
    color: ${c.subtext0};
    background-color: ${c.mantle};
    border: 1px solid transparent;
    border-bottom: 2px solid transparent;
    border-top-left-radius: 6px;
    border-top-right-radius: 6px;
    padding: 8px 12px;
    margin-right: 3px;
  }
  QTabBar::tab:selected {
    color: ${accent};
    background-color: ${c.surface0};
    border-bottom-color: ${accent};
  }
  QTabBar::tab:hover:!selected { color: ${c.text}; background-color: ${c.surface1}; }
  QTabBar QToolButton { padding: 2px; min-width: 14px; border-radius: 4px; }
  QToolButton::left-arrow { image: url("${left}"); width: 16px; height: 16px; }
  QToolButton::right-arrow { image: url("${right}"); width: 16px; height: 16px; }
  QPushButton, QToolButton {
    background-color: ${c.surface0};
    border: 1px solid ${c.surface2};
    border-radius: 6px;
    padding: 6px 12px;
    min-height: 18px;
  }
  QPushButton:hover, QToolButton:hover { background-color: ${c.surface1}; border-color: ${accent}; }
  QPushButton:pressed, QToolButton:pressed { background-color: ${c.selection}; }
  QPushButton:focus, QToolButton:focus { border-color: ${accent}; }
  QPushButton:checked, QToolButton:checked { color: ${accent}; background-color: ${c.selection}; }
  QPushButton[class="primary"], QPushButton:default {
    color: ${c.base};
    background-color: ${accent};
    border-color: ${accent};
    font-weight: bold;
  }
  QPushButton[class="primary"]:hover, QPushButton:default:hover {
    background-color: ${c.sky};
    border-color: ${c.sky};
  }
  QPushButton[class="success"] { color: ${c.green}; border-color: ${c.green}; }
  QPushButton[class="success"]:hover { color: ${c.base}; background-color: ${c.green}; }
  QPushButton[class="warning"] { color: ${c.yellow}; border-color: ${c.yellow}; }
  QPushButton[class="warning"]:hover { color: ${c.base}; background-color: ${c.yellow}; }
  QPushButton[class="danger"] { color: ${c.red}; border-color: ${c.red}; }
  QPushButton[class="danger"]:hover { color: ${c.base}; background-color: ${c.red}; }
  QPushButton[class="link"] { color: ${c.sky}; border-color: transparent; background-color: transparent; }
  QPushButton[class="link"]:hover { border-color: ${c.surface2}; background-color: ${c.surface0}; }
  QPushButton:disabled, QToolButton:disabled, QPushButton[class]:disabled, QPushButton:default:disabled {
    color: ${c.overlay2};
    background-color: ${c.surface0};
    border-color: ${c.surface1};
  }
  QLineEdit, QSpinBox, QDoubleSpinBox, QComboBox {
    background-color: ${c.mantle};
    border: 1px solid ${c.surface2};
    border-radius: 5px;
    padding: 5px 8px;
    min-height: 18px;
  }
  QLineEdit:focus, QSpinBox:focus, QDoubleSpinBox:focus, QComboBox:focus { border-color: ${accent}; }
  QLineEdit:disabled, QSpinBox:disabled, QDoubleSpinBox:disabled, QComboBox:disabled { color: ${c.overlay2}; border-color: ${c.surface1}; }
  QComboBox { padding-right: 26px; }
  QComboBox::drop-down {
    subcontrol-origin: padding;
    subcontrol-position: top right;
    width: 24px;
    border: none;
  }
  QComboBox::down-arrow { image: url("${down}"); width: 16px; height: 16px; }
  QComboBox QAbstractItemView { background-color: ${c.surface0}; border: 1px solid ${c.surface2}; outline: none; }
  QTextEdit, QPlainTextEdit, QTextBrowser, QListView, QTreeView, QTableView {
    background-color: ${c.mantle};
    alternate-background-color: ${c.surface0};
    border: 1px solid ${c.surface1};
    border-radius: 6px;
    padding: 5px;
    gridline-color: ${c.surface1};
  }
  QTextEdit, QPlainTextEdit {
    font-family: "${theme.fonts.mono}", "${theme.fonts.cjkMono}";
  }
  QAbstractItemView::item { padding: 4px; }
  QAbstractItemView::item:selected { color: ${c.text}; background-color: ${c.selection}; }
  QHeaderView::section {
    color: ${c.subtext1};
    background-color: ${c.surface0};
    border: none;
    border-bottom: 1px solid ${c.surface2};
    padding: 7px;
  }
  QCheckBox, QRadioButton { spacing: 7px; }
  QCheckBox::indicator, QRadioButton::indicator {
    width: 16px;
    height: 16px;
    border: 1px solid ${c.surface2};
    background-color: ${c.mantle};
  }
  QCheckBox::indicator { border-radius: 4px; }
  QRadioButton::indicator { border-radius: 8px; }
  QCheckBox::indicator:hover, QRadioButton::indicator:hover { border-color: ${accent}; }
  QCheckBox::indicator:checked { background-color: ${accent}; border-color: ${accent}; image: url("${check}"); }
  QRadioButton::indicator:checked { background-color: ${accent}; border: 4px solid ${c.surface2}; }
  QCheckBox::indicator:disabled, QRadioButton::indicator:disabled { background-color: ${c.surface0}; border-color: ${c.surface1}; }
  QProgressBar {
    color: ${c.text};
    background-color: ${c.surface0};
    border: 1px solid ${c.surface1};
    border-radius: 5px;
    min-height: 16px;
    text-align: center;
  }
  QProgressBar::chunk { background-color: ${c.green}; border-radius: 4px; }
  QScrollArea { border: none; }
  QScrollBar:vertical { background-color: ${c.base}; width: 9px; margin: 2px; }
  QScrollBar:horizontal { background-color: ${c.base}; height: 9px; margin: 2px; }
  QScrollBar::handle { background-color: ${c.surface2}; border-radius: 3px; min-width: 24px; min-height: 24px; }
  QScrollBar::handle:hover { background-color: ${c.overlay1}; }
  QScrollBar::add-line, QScrollBar::sub-line { width: 0; height: 0; border: none; }
  QScrollBar::add-page, QScrollBar::sub-page { background: none; }
  QSplitter::handle { background-color: ${c.surface1}; width: 2px; height: 2px; }
  QStatusBar { background-color: ${c.mantle}; border-top: 1px solid ${c.surface1}; }
  QStatusBar::item { border: none; }
  QStatusBar QLabel { background-color: transparent; }
  QMenu, QMenuBar { background-color: ${c.surface0}; border: 1px solid ${c.surface2}; }
  QMenu::item { padding: 6px 20px; background-color: transparent; }
  QMenu::item:selected { color: ${accent}; background-color: ${c.selection}; }
  QMenu::item:disabled { color: ${c.overlay2}; }
  QMenu::separator { height: 1px; background-color: ${c.surface2}; margin: 5px 8px; }
  QToolTip { color: ${c.text}; background-color: ${c.surface1}; border: 1px solid ${accent}; border-radius: 4px; padding: 6px; }
  QSlider::groove:horizontal { background-color: ${c.surface1}; height: 5px; border-radius: 2px; }
  QSlider::sub-page:horizontal { background-color: ${accent}; border-radius: 2px; }
  QSlider::handle:horizontal { background-color: ${accent}; width: 14px; margin: -5px 0; border-radius: 7px; }
''
