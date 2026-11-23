"""Tests du cache hors ligne de la version web de l'application mobile"""

from tools.web_service_worker import main


def test_service_worker_caches_every_built_file(tmp_path):
    """Vérifie que tout le site construit est en cache, sous un nom qui suit son contenu."""

    (tmp_path / "assets").mkdir()
    (tmp_path / "index.html").write_text("<html></html>", encoding="utf-8")
    (tmp_path / "assets" / "depart.json.gz").write_bytes(b"\x1f\x8b")

    main(tmp_path)
    vFirst = (tmp_path / "sw.js").read_text(encoding="utf-8")
    main(tmp_path)
    vSame = (tmp_path / "sw.js").read_text(encoding="utf-8")
    (tmp_path / "index.html").write_text("<html>v2</html>", encoding="utf-8")
    main(tmp_path)
    vChanged = (tmp_path / "sw.js").read_text(encoding="utf-8")

    assert '["./", "assets/depart.json.gz", "index.html"]' in vFirst
    assert vFirst == vSame
    assert vFirst.split("\n")[1] != vChanged.split("\n")[1]
    assert "url.origin !== self.location.origin" in vFirst
