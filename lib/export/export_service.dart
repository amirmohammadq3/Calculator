import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';

class ExportService {
  /// ذخیره‌ی یک فایل متنی ساده شامل عبارت و جواب
  static Future<bool> exportTxt(String expression, String result) async {
    final content = 'عبارت:\n$expression\n\nجواب:\n$result\n';
    final bytes = Uint8List.fromList(utf8.encode(content));
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'ذخیره‌ی جواب (txt)',
      fileName: 'calc_result.txt',
      bytes: bytes,
      type: FileType.custom,
      allowedExtensions: const ['txt'],
    );
    return path != null;
  }

  /// ساخت یک فایل xlsx معتبر و کمینه (بدون نیاز به پکیج سنگین) که شامل
  /// عبارت در سلول A1 و جواب در سلول A2 است.
  static Future<bool> exportXlsx(String expression, String result) async {
    final bytes = _buildXlsx(expression, result);
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'ذخیره‌ی جواب (Excel)',
      fileName: 'calc_result.xlsx',
      bytes: bytes,
      type: FileType.custom,
      allowedExtensions: const ['xlsx'],
    );
    return path != null;
  }

  static String _escape(String s) =>
      s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;');

  static Uint8List _buildXlsx(String expression, String result) {
    final archive = Archive();
    void add(String name, String content) {
      final data = utf8.encode(content);
      archive.addFile(ArchiveFile(name, data.length, data));
    }

    add('[Content_Types].xml', '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
<Default Extension="xml" ContentType="application/xml"/>
<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
</Types>''');

    add('_rels/.rels', '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
</Relationships>''');

    add('xl/_rels/workbook.xml.rels', '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
</Relationships>''');

    add('xl/workbook.xml', '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
<sheets><sheet name="نتیجه" sheetId="1" r:id="rId1"/></sheets>
</workbook>''');

    final rows = StringBuffer();
    rows.write('<row r="1"><c r="A1" t="inlineStr"><is><t xml:space="preserve">عبارت</t></is></c>'
        '<c r="B1" t="inlineStr"><is><t xml:space="preserve">${_escape(expression)}</t></is></c></row>');
    rows.write('<row r="2"><c r="A2" t="inlineStr"><is><t xml:space="preserve">جواب</t></is></c>'
        '<c r="B2" t="inlineStr"><is><t xml:space="preserve">${_escape(result)}</t></is></c></row>');

    add('xl/worksheets/sheet1.xml', '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
<sheetData>$rows</sheetData>
</worksheet>''');

    final out = ZipEncoder().encode(archive);
    return Uint8List.fromList(out!);
  }
}
