"""Couleurs, thèmes clair et sombre et feuille de style de l'interface"""

import re
from pathlib import Path
from string import Template

from PySide6.QtCore import Qt
from PySide6.QtGui import QColor, QGuiApplication, QPalette

from gui.icons import stylesheet_path
from job.cosmetics import get_accent_colors

THEME_FILE = Path(__file__).with_name("theme.qss")

# « Auto » suit le thème de Windows, comme le téléphone suit le sien.
THEME_CHOICES = {"system": "Auto", "light": "Clair", "dark": "Sombre"}

# Réglage qui mémorise le choix du thème
THEME_SETTING = "appearance/theme"

# Taille du texte en pourcentage, mémorisée comme le thème
TEXT_SCALE_SETTING = "appearance/text_scale"
TEXT_SCALES = {90: "90 %", 100: "100 %", 115: "115 %", 130: "130 %"}

FONT_SIZE_PATTERN = re.compile(r"font-size:\s*(\d+)px")

THEMES = {
    "light": {
        "background": "#F2FAFB",
        "surface": "#FFFFFF",
        "surface_alt": "#F6FBFC",
        "border": "#D3E6EA",
        "heading": "#0B2B36",
        "text": "#17323B",
        "muted": "#4A6670",
        "on_primary": "#FFFFFF",
        "primary": "#0E6F8C",
        "primary_dark": "#0B4F66",
        "primary_light": "#E0F3F6",
        "primary_gradient": "#2FB8C7",
        "banner_text": "#DFF6F9",
        "banner_start": "#0E6F8C",
        "banner_end": "#0B4F66",
        "banner_title": "#FFFFFF",
        "success": "#15803D",
        "success_light": "#E7F7EC",
        "warning": "#8A5F00",
        "warning_light": "#FFF4D6",
        "danger": "#C81E1E",
        "danger_light": "#FDECEC",
    },
    "dark": {
        "background": "#0A1F27",
        "surface": "#102B35",
        "surface_alt": "#14323E",
        "border": "#214452",
        "heading": "#EAF7F9",
        "text": "#CFE3E8",
        "muted": "#8FB0B9",
        "on_primary": "#06222B",
        "primary": "#35C2CF",
        "primary_dark": "#7FDDE6",
        "primary_light": "#123A47",
        "primary_gradient": "#0E6F8C",
        "banner_text": "#D4F1F5",
        "banner_start": "#0E6F8C",
        "banner_end": "#0B4F66",
        "banner_title": "#FFFFFF",
        "success": "#22C55E",
        "success_light": "#132A1F",
        "warning": "#F59E0B",
        "warning_light": "#2E2310",
        "danger": "#F87171",
        "danger_light": "#3A1A1C",
    },
}

# Couleur principale et fond des cartes statistiques, par thème
THEME_ACCENTS = {
    "light": {
        "blue": ("#0E6F8C", "#E0F3F6"),
        "green": ("#15803D", "#E7F7EC"),
        "amber": ("#8A5F00", "#FFF1CC"),
        "purple": ("#7C3AED", "#F1EAFE"),
    },
    "dark": {
        "blue": ("#35C2CF", "#123A47"),
        "green": ("#4ADE80", "#132A1F"),
        "amber": ("#FFC23D", "#33260A"),
        "purple": ("#C084FC", "#251A3A"),
    },
}

# Couleurs du thème actif, mises à jour sur place par apply_theme pour que
# les modules qui les ont importées voient toujours les bonnes valeurs.
COLORS = dict(THEMES["light"])
ACCENTS = dict(THEME_ACCENTS["light"])


def is_dark_theme():
    """Indique si le thème actif est le thème sombre."""

    rIsDark = COLORS == THEMES["dark"]

    return rIsDark


def resolve_theme(pChoice):
    """Traduit un choix de thème en thème réel ; system suit Windows."""

    rTheme = pChoice

    if pChoice not in THEMES:
        vScheme = QGuiApplication.styleHints().colorScheme()
        rTheme = "dark" if vScheme == Qt.ColorScheme.Dark else "light"

    return rTheme


def scale_font_sizes(pStylesheet, pTextScale):
    """Agrandit ou réduit chaque taille de texte de la feuille de style."""

    rStylesheet = FONT_SIZE_PATTERN.sub(
        lambda pMatch: f"font-size: {round(int(pMatch[1]) * pTextScale / 100)}px",
        pStylesheet,
    )

    return rStylesheet


def build_stylesheet(pTextScale=100):
    """Retourne la feuille de style, ses variables remplacées par les couleurs et
    ses tailles de texte mises à l'échelle choisie.
    """

    # Dépannage : une variable $nom de theme.qss absente de COLORS lève KeyError
    # au démarrage ; une propriété CSS inconnue de Qt est ignorée sans erreur.
    rStylesheet = Template(THEME_FILE.read_text(encoding="utf-8")).substitute(
        COLORS,
        chevron_up=stylesheet_path("chevron-up"),
        chevron_down=stylesheet_path("chevron-down"),
    )

    if pTextScale != 100:
        rStylesheet = scale_font_sizes(rStylesheet, pTextScale)

    return rStylesheet


def build_palette():
    """Retourne la palette Qt correspondant aux couleurs du thème actif."""

    rPalette = QPalette()

    for vRole, vColor in (
        (QPalette.ColorRole.Window, COLORS["background"]),
        (QPalette.ColorRole.Base, COLORS["surface"]),
        (QPalette.ColorRole.AlternateBase, COLORS["surface_alt"]),
        (QPalette.ColorRole.Button, COLORS["surface"]),
        (QPalette.ColorRole.Text, COLORS["text"]),
        (QPalette.ColorRole.WindowText, COLORS["text"]),
        (QPalette.ColorRole.ButtonText, COLORS["text"]),
        (QPalette.ColorRole.PlaceholderText, COLORS["muted"]),
        (QPalette.ColorRole.Highlight, COLORS["primary"]),
        (QPalette.ColorRole.HighlightedText, COLORS["on_primary"]),
        (QPalette.ColorRole.Link, COLORS["primary"]),
        (QPalette.ColorRole.Mid, COLORS["border"]),
        (QPalette.ColorRole.ToolTipBase, COLORS["heading"]),
        (QPalette.ColorRole.ToolTipText, COLORS["surface"]),
    ):
        rPalette.setColor(vRole, QColor(vColor))

    return rPalette


def apply_theme(pApplication, pChoice, pTextScale=100, pAccent=None):
    """Applique un thème, une couleur d'accent et une taille de texte ; retourne le thème."""

    rTheme = resolve_theme(pChoice)

    COLORS.clear()
    COLORS.update(THEMES[rTheme])
    COLORS.update(get_accent_colors(pAccent, rTheme))
    ACCENTS.clear()
    ACCENTS.update(THEME_ACCENTS[rTheme])

    pApplication.setPalette(build_palette())
    pApplication.setStyleSheet(build_stylesheet(pTextScale))

    return rTheme
