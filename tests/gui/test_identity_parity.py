"""Tests de l'identité visuelle commune au bureau, au web et au téléphone

Les trois interfaces racontent la même piscine : bleu du bassin, turquoise de l'eau,
jaune du plongeoir. Ces tests relisent les trois sources et échouent dès que l'une
s'écarte des autres.
"""

import json
import re
from pathlib import Path

import pytest

from gui.theme import THEME_ACCENTS, THEMES

ROOT = Path(__file__).resolve().parents[2]
THEME_DART = ROOT / "mobile" / "lib" / "theme.dart"
THEME_CSS = ROOT / "web" / "static" / "css" / "01-theme.css"
MANIFEST = ROOT / "web" / "static" / "manifest.webmanifest"
MOBILE_MANIFEST = ROOT / "mobile" / "web" / "manifest.json"


def get_dart_colors():
    """Retourne les couleurs nommées de theme.dart, en #RRGGBB majuscules."""

    vSource = THEME_DART.read_text(encoding="utf-8")
    rColors = {
        vName: f"#{vHex.upper()}"
        for vName, vHex in re.findall(
            r"const (\w+Color) = Color\(0xFF([0-9A-Fa-f]{6})\);", vSource
        )
    }

    return rColors


def get_css_blocks():
    """Retourne les variables de 01-theme.css : thème clair, sombre, et sombre sans JavaScript."""

    vBlocks = {"light": {}, "dark": {}, "auto-dark": {}}
    vCurrent = None

    for vLine in THEME_CSS.read_text(encoding="utf-8").splitlines():
        if vLine.strip() == ":root,":
            vCurrent = "light"
        elif ':root[data-theme="dark"]' in vLine and "{" in vLine:
            vCurrent = "dark"
        elif ":root:not([data-theme])" in vLine:
            vCurrent = "auto-dark"
        vMatch = re.match(r"\s*--([a-z-]+):\s*(#[0-9a-fA-F]{6});", vLine)

        if vMatch and vCurrent:
            vBlocks[vCurrent][vMatch.group(1)] = vMatch.group(2).upper()

    return vBlocks


def test_mobile_colours_are_the_desktop_palette():
    """Le bassin, l'eau et le grand bain du téléphone sont ceux du bureau."""

    vDart = get_dart_colors()

    assert vDart["primaryColor"] == THEMES["light"]["primary"]
    assert vDart["deepColor"] == THEMES["light"]["primary_dark"]
    assert vDart["deepColor"] == THEMES["light"]["banner_end"]
    assert vDart["waterColor"] == THEMES["dark"]["primary"]


@pytest.mark.parametrize(
    "pBlock,pTheme", [("light", "light"), ("dark", "dark"), ("auto-dark", "dark")]
)
def test_web_css_matches_the_desktop_palette(pBlock, pTheme):
    """Chaque variable du web reprend la valeur du bureau, thème clair et sombre."""

    vCss = get_css_blocks()[pBlock]
    vExpected = {
        vName.replace("_", "-"): vColor for vName, vColor in THEMES[pTheme].items()
    }
    vExpected = {vName: vColor for vName, vColor in vExpected.items() if vName in vCss}
    vAccents = THEME_ACCENTS[pTheme]
    vExpected.update({vName: vColors[0] for vName, vColors in vAccents.items()})
    vExpected.update(
        {f"{vName}-light": vColors[1] for vName, vColors in vAccents.items()}
    )

    assert vCss
    assert {vName: vCss[vName] for vName in vExpected if vName in vCss} == {
        vName: vColor.upper() for vName, vColor in vExpected.items() if vName in vCss
    }
    # Les variables essentielles sont bien présentes, pas seulement celles qui concordent
    for vName in ("background", "surface", "primary", "primary-dark", "banner-start"):
        assert vName in vCss


def test_light_and_dark_backgrounds_are_the_phone_ones():
    """Le fond du téléphone, clair comme sombre, est celui du bureau et du web."""

    vSource = THEME_DART.read_text(encoding="utf-8")

    assert "Color(0xFFF2FAFB)" in vSource
    assert "Color(0xFF0A1F27)" in vSource
    assert THEMES["light"]["background"] == "#F2FAFB"
    assert THEMES["dark"]["background"] == "#0A1F27"


def test_browser_bar_and_installed_app_use_the_same_blue():
    """La barre du navigateur et l'application installée portent le bleu du bassin."""

    vWeb = json.loads(MANIFEST.read_text(encoding="utf-8"))
    vMobile = json.loads(MOBILE_MANIFEST.read_text(encoding="utf-8"))

    assert vWeb["theme_color"].upper() == THEMES["light"]["primary"]
    assert vMobile["theme_color"].upper() == THEMES["light"]["primary"]
    assert vWeb["background_color"].upper() == THEMES["light"]["background"]
