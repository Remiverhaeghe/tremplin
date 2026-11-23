// CV en Word (.docx), écrit à la main : un fichier zip de quelques pages XML. Le texte reste du
// vrai texte, avec des styles de titres, pour que Word comme les logiciels de tri le lisent.

import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import 'cv_document.dart';

String _esc(String pText) =>
    pText.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');

/// Couleur d'accent par défaut des titres, en hexadécimal sans dièse.
const cvAccent = '1F5F8B';

String _run(String pText, {bool pBold = false, String? pColor, int? pSize, bool pItalic = false}) {
  final vProps = StringBuffer()
    ..write(pBold ? '<w:b/>' : '')
    ..write(pItalic ? '<w:i/>' : '')
    ..write(pColor != null ? '<w:color w:val="$pColor"/>' : '')
    ..write(pSize != null ? '<w:sz w:val="$pSize"/>' : '');

  return '<w:r><w:rPr>$vProps</w:rPr><w:t xml:space="preserve">${_esc(pText)}</w:t></w:r>';
}

String _para(String pRuns, {String? pStyle, int pAfter = 60, bool pBullet = false}) {
  final vProps = StringBuffer()
    ..write(pStyle != null ? '<w:pStyle w:val="$pStyle"/>' : '')
    ..write(pBullet ? '<w:ind w:left="284" w:hanging="200"/>' : '')
    ..write('<w:spacing w:after="$pAfter"/>');

  return '<w:p><w:pPr>$vProps</w:pPr>$pRuns</w:p>';
}

String _body(CvDocument pDocument, String pAccent) {
  final rBody = StringBuffer()
    ..write(_para(_run(pDocument.name, pBold: true, pColor: pAccent, pSize: 44), pStyle: 'Title'));
  if (pDocument.headline.isNotEmpty) {
    rBody.write(_para(_run(pDocument.headline, pSize: 26), pAfter: 80));
  }
  if (pDocument.contactLines.isNotEmpty) {
    rBody.write(_para(_run(pDocument.contactLines.join('  |  '), pSize: 20), pAfter: 160));
  }
  for (final vSection in pDocument.sections) {
    rBody.write(_para(_run(vSection.heading, pBold: true, pColor: pAccent, pSize: 26),
        pStyle: 'Heading1', pAfter: 80));
    for (final vBlock in vSection.blocks) {
      final vHead = [vBlock.title, vBlock.detail].where((pPart) => pPart.isNotEmpty).join(' - ');
      if (vHead.isNotEmpty) {
        rBody.write(
          _para(
            _run(vHead, pBold: true) +
                (vBlock.dates.isEmpty ? '' : _run('   ${vBlock.dates}', pItalic: true, pSize: 20)),
            pStyle: 'Heading2',
            pAfter: 40,
          ),
        );
      } else if (vBlock.dates.isNotEmpty) {
        rBody.write(_para(_run(vBlock.dates, pItalic: true, pSize: 20)));
      }
      final vBullets = vBlock.title.isNotEmpty && vBlock.lines.length > 1;
      for (final vLine in vBlock.lines) {
        rBody.write(_para(_run(vBullets ? '• $vLine' : vLine), pBullet: vBullets));
      }
    }
  }

  return rBody.toString();
}

const _styles = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
<w:docDefaults><w:rPrDefault><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri" w:cs="Calibri"/><w:sz w:val="21"/><w:lang w:val="fr-FR"/></w:rPr></w:rPrDefault></w:docDefaults>
<w:style w:type="paragraph" w:default="1" w:styleId="Normal"><w:name w:val="Normal"/></w:style>
<w:style w:type="paragraph" w:styleId="Title"><w:name w:val="Title"/><w:basedOn w:val="Normal"/></w:style>
<w:style w:type="paragraph" w:styleId="Heading1"><w:name w:val="heading 1"/><w:basedOn w:val="Normal"/><w:pPr><w:keepNext/><w:spacing w:before="200"/><w:pBdr><w:bottom w:val="single" w:sz="6" w:space="1" w:color="BFBFBF"/></w:pBdr></w:pPr></w:style>
<w:style w:type="paragraph" w:styleId="Heading2"><w:name w:val="heading 2"/><w:basedOn w:val="Normal"/><w:pPr><w:keepNext/><w:spacing w:before="80"/></w:pPr></w:style>
</w:styles>''';

const _types = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
<Default Extension="xml" ContentType="application/xml"/>
<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
<Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
</Types>''';

const _rootRels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''';

const _documentRels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>''';

/// Le CV en .docx : page A4, marges de 1,8 cm.
Uint8List buildCvDocx(CvDocument pDocument, {String pAccent = cvAccent}) {
  final vDocument = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:body>${_body(pDocument, pAccent)}<w:sectPr><w:pgSz w:w="11906" w:h="16838"/><w:pgMar w:top="1020" w:right="1020" w:bottom="1020" w:left="1020" w:header="0" w:footer="0" w:gutter="0"/></w:sectPr></w:body></w:document>''';
  final vArchive = Archive();
  void add(String pName, String pContent) {
    final vBytes = utf8.encode(pContent);
    vArchive.addFile(ArchiveFile(pName, vBytes.length, vBytes));
  }

  add('[Content_Types].xml', _types);
  add('_rels/.rels', _rootRels);
  add('word/document.xml', vDocument);
  add('word/styles.xml', _styles);
  add('word/_rels/document.xml.rels', _documentRels);

  return Uint8List.fromList(ZipEncoder().encode(vArchive));
}
