import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import '../../shared/models/student.dart';
import 'package:uuid/uuid.dart';

class ImportErrorItem {
  final int rowIndex;
  final String rawName;
  final String rawMatric;
  final String issueDescription;

  const ImportErrorItem({
    required this.rowIndex,
    required this.rawName,
    required this.rawMatric,
    required this.issueDescription,
  });
}

class ClassListImportResult {
  final int totalRowsFound;
  final List<Student> validStudents;
  final List<ImportErrorItem> errors;

  const ClassListImportResult({
    required this.totalRowsFound,
    required this.validStudents,
    required this.errors,
  });

  bool get hasErrors => errors.isNotEmpty;
  int get validCount => validStudents.length;
  int get errorCount => errors.length;
}

class ClassListParser {
  ClassListParser._();

  static final _uuid = const Uuid();

  /// Parse CSV, XLSX, XLS, PDF, DOC, or DOCX bytes into validated Student records
  static ClassListImportResult parseFile({
    required Uint8List bytes,
    required String fileName,
    required String courseId,
    List<String> existingMatricNumbers = const [],
  }) {
    final lowerName = fileName.toLowerCase();
    if (lowerName.endsWith('.csv') || lowerName.endsWith('.txt')) {
      return _parseCsv(bytes, courseId, existingMatricNumbers);
    } else if (lowerName.endsWith('.xlsx') || lowerName.endsWith('.xls')) {
      return _parseExcel(bytes, courseId, existingMatricNumbers);
    } else if (lowerName.endsWith('.docx')) {
      return _parseDocx(bytes, courseId, existingMatricNumbers);
    } else if (lowerName.endsWith('.doc')) {
      return _parseDoc(bytes, courseId, existingMatricNumbers);
    } else if (lowerName.endsWith('.pdf')) {
      return _parsePdf(bytes, courseId, existingMatricNumbers);
    } else {
      // Fallback: try CSV first, then raw text extraction
      try {
        final csvRes = _parseCsv(bytes, courseId, existingMatricNumbers);
        if (csvRes.validCount > 0) return csvRes;
      } catch (_) {}
      return _parseRawTextLines(bytes, courseId, existingMatricNumbers);
    }
  }

  static ClassListImportResult _parseCsv(
    Uint8List bytes,
    String courseId,
    List<String> existingMatrics,
  ) {
    final content = String.fromCharCodes(bytes);
    // Normalize line endings then parse
    final normalized = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final rows = const CsvToListConverter(
      shouldParseNumbers: false,
      eol: '\n',
    ).convert(normalized);
    return _processRawRows(rows, courseId, existingMatrics);
  }

  static ClassListImportResult _parseExcel(
    Uint8List bytes,
    String courseId,
    List<String> existingMatrics,
  ) {
    final excel = Excel.decodeBytes(bytes);
    final rows = <List<dynamic>>[];

    for (final table in excel.tables.keys) {
      final sheet = excel.tables[table];
      if (sheet != null) {
        for (final row in sheet.rows) {
          final rowValues = row.map((cell) => cell?.value?.toString() ?? '').toList();
          rows.add(rowValues);
        }
      }
    }

    return _processRawRows(rows, courseId, existingMatrics);
  }

  /// Parse Word DOCX (.docx) files by unzipping word/document.xml and extracting tables/paragraphs
  static ClassListImportResult _parseDocx(
    Uint8List bytes,
    String courseId,
    List<String> existingMatrics,
  ) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final docFile = archive.findFile('word/document.xml');
      if (docFile == null) {
        return _parseRawTextLines(bytes, courseId, existingMatrics);
      }

      final contentBytes = docFile.content as List<int>;
      final xmlString = String.fromCharCodes(contentBytes);

      final rows = <List<String>>[];

      // Extract table rows (<w:tr>)
      final trRegExp = RegExp(r'<w:tr\b[^>]*>(.*?)</w:tr>', dotAll: true);
      final trMatches = trRegExp.allMatches(xmlString);

      for (final trMatch in trMatches) {
        final trContent = trMatch.group(1) ?? '';
        final tcRegExp = RegExp(r'<w:tc\b[^>]*>(.*?)</w:tc>', dotAll: true);
        final cells = tcRegExp.allMatches(trContent).map((tcMatch) {
          final tcContent = tcMatch.group(1) ?? '';
          final textRegExp = RegExp(r'<w:t\b[^>]*>(.*?)</w:t>', dotAll: true);
          return textRegExp.allMatches(tcContent).map((m) => m.group(1) ?? '').join().trim();
        }).toList();

        if (cells.isNotEmpty && cells.any((c) => c.isNotEmpty)) {
          rows.add(cells);
        }
      }

      if (rows.isNotEmpty) {
        return _processRawRows(rows, courseId, existingMatrics);
      }

      // If no table, extract paragraph text lines (<w:p>)
      final pRegExp = RegExp(r'<w:p\b[^>]*>(.*?)</w:p>', dotAll: true);
      final pMatches = pRegExp.allMatches(xmlString);
      final lines = <String>[];

      for (final pMatch in pMatches) {
        final pContent = pMatch.group(1) ?? '';
        final textRegExp = RegExp(r'<w:t\b[^>]*>(.*?)</w:t>', dotAll: true);
        final text = textRegExp.allMatches(pContent).map((m) => m.group(1) ?? '').join().trim();
        if (text.isNotEmpty) lines.add(text);
      }

      return _processTextLines(lines, courseId, existingMatrics);
    } catch (_) {
      return _parseRawTextLines(bytes, courseId, existingMatrics);
    }
  }

  /// Parse legacy binary Word DOC (.doc) files by extracting text streams
  static ClassListImportResult _parseDoc(
    Uint8List bytes,
    String courseId,
    List<String> existingMatrics,
  ) {
    return _parseRawTextLines(bytes, courseId, existingMatrics);
  }

  /// Parse PDF (.pdf) files by decompressing Flate streams and extracting text literals
  static ClassListImportResult _parsePdf(
    Uint8List bytes,
    String courseId,
    List<String> existingMatrics,
  ) {
    try {
      final textChunks = <String>[];

      // Scan PDF streams
      final pdfString = String.fromCharCodes(bytes);
      final streamRegExp = RegExp(r'stream\r?\n(.*?)\r?\nendstream', dotAll: true);
      final matches = streamRegExp.allMatches(pdfString);

      for (final m in matches) {
        final rawStream = m.group(1) ?? '';
        // Attempt ZLib / Flate decompression
        try {
          final streamBytes = Uint8List.fromList(rawStream.codeUnits);
          final decompressed = ZLibDecoder().decodeBytes(streamBytes);
          final decompressedText = String.fromCharCodes(decompressed);
          _extractPdfTextTokens(decompressedText, textChunks);
        } catch (_) {
          // If not compressed or raw
          _extractPdfTextTokens(rawStream, textChunks);
        }
      }

      // Fallback: if stream extraction produced no tokens, extract raw ASCII text lines
      if (textChunks.isEmpty) {
        return _parseRawTextLines(bytes, courseId, existingMatrics);
      }

      final fullPdfText = textChunks.join('\n');
      final lines = fullPdfText
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

      return _processTextLines(lines, courseId, existingMatrics);
    } catch (_) {
      return _parseRawTextLines(bytes, courseId, existingMatrics);
    }
  }

  static void _extractPdfTextTokens(String pdfContent, List<String> output) {
    // PDF text literals inside (...) Tj or [(...)] TJ
    final tjRegExp = RegExp(r'\(([^)]+)\)\s*Tj', dotAll: true);
    for (final match in tjRegExp.allMatches(pdfContent)) {
      final val = match.group(1)?.trim();
      if (val != null && val.isNotEmpty) output.add(val);
    }

    final arrayTjRegExp = RegExp(r'\[\s*\(([^\]]+)\)\s*\]\s*TJ', dotAll: true);
    for (final match in arrayTjRegExp.allMatches(pdfContent)) {
      final rawArray = match.group(1) ?? '';
      final innerLiteral = RegExp(r'\(([^)]+)\)');
      for (final inner in innerLiteral.allMatches(rawArray)) {
        final val = inner.group(1)?.trim();
        if (val != null && val.isNotEmpty) output.add(val);
      }
    }
  }

  /// Extracts printable ASCII/UTF-8 text lines from raw bytes
  static ClassListImportResult _parseRawTextLines(
    Uint8List bytes,
    String courseId,
    List<String> existingMatrics,
  ) {
    final buffer = StringBuffer();
    for (final b in bytes) {
      if ((b >= 32 && b <= 126) || b == 10 || b == 13 || b == 9) {
        buffer.writeCharCode(b);
      } else {
        buffer.write(' ');
      }
    }

    final rawText = buffer.toString();
    final lines = rawText
        .split(RegExp(r'[\r\n]+'))
        .map((l) => l.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((l) => l.length >= 5)
        .toList();

    return _processTextLines(lines, courseId, existingMatrics);
  }

  /// Process plain text lines to recognize Student Name and Matriculation Numbers
  static ClassListImportResult _processTextLines(
    List<String> lines,
    String courseId,
    List<String> existingMatrics,
  ) {
    final rawRows = <List<String>>[];

    // Matric number pattern matching common formats: e.g. 2024/001, ENG/19/042, 19/30G/012, 2021104928
    final matricRegex = RegExp(r'\b([A-Z0-9]{2,8}[/-][A-Z0-9/-]{3,12}|\d{6,12})\b', caseSensitive: false);

    for (final line in lines) {
      final matricMatch = matricRegex.firstMatch(line);
      if (matricMatch != null) {
        final matricStr = matricMatch.group(1) ?? '';
        // Name is the remaining text on the line, stripped of S/N digits, delimiters, and matric
        var namePart = line.replaceFirst(matricStr, '');
        namePart = namePart.replaceAll(RegExp(r'^\s*\d+[\.\)\-]?\s*'), ''); // strip leading S/N
        namePart = namePart.replaceAll(RegExp(r'[,:;|\\/]+'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

        if (namePart.isNotEmpty && matricStr.isNotEmpty) {
          rawRows.add([namePart, matricStr]);
        }
      } else if (line.contains(',') || line.contains('\t') || line.contains('|')) {
        final parts = line.split(RegExp(r'[,\|\t]')).map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
        if (parts.length >= 2) {
          rawRows.add(parts);
        }
      }
    }

    return _processRawRows(rawRows, courseId, existingMatrics);
  }

  static ClassListImportResult _processRawRows(
    List<List<dynamic>> rawRows,
    String courseId,
    List<String> existingMatrics,
  ) {
    final validStudents = <Student>[];
    final errors = <ImportErrorItem>[];
    final seenMatricsInFile = <String>{...existingMatrics.map((e) => e.trim().toUpperCase())};

    int nameColIndex = 0;
    int matricColIndex = 1;
    bool hasHeader = false;

    if (rawRows.isEmpty) {
      return const ClassListImportResult(totalRowsFound: 0, validStudents: [], errors: []);
    }

    // Header detection
    final firstRowStr = rawRows.first.map((e) => e.toString().toLowerCase()).toList();
    for (int i = 0; i < firstRowStr.length; i++) {
      final colVal = firstRowStr[i];
      if (colVal.contains('name') || colVal.contains('student')) {
        nameColIndex = i;
        hasHeader = true;
      } else if (colVal.contains('matric') || colVal.contains('id') || colVal.contains('number')) {
        matricColIndex = i;
        hasHeader = true;
      }
    }

    final dataRows = hasHeader ? rawRows.sublist(1) : rawRows;
    int rowIndex = hasHeader ? 2 : 1;

    for (final row in dataRows) {
      if (row.isEmpty || row.every((c) => c == null || c.toString().trim().isEmpty)) {
        rowIndex++;
        continue; // skip completely empty rows
      }

      final rawName = (row.length > nameColIndex ? row[nameColIndex]?.toString() : '')?.trim() ?? '';
      final rawMatric = (row.length > matricColIndex ? row[matricColIndex]?.toString() : '')?.trim() ?? '';

      if (rawName.isEmpty && rawMatric.isEmpty) {
        rowIndex++;
        continue;
      }

      if (rawName.isEmpty) {
        errors.add(ImportErrorItem(
          rowIndex: rowIndex,
          rawName: rawName,
          rawMatric: rawMatric,
          issueDescription: 'Missing student name',
        ));
        rowIndex++;
        continue;
      }

      if (rawMatric.isEmpty) {
        errors.add(ImportErrorItem(
          rowIndex: rowIndex,
          rawName: rawName,
          rawMatric: rawMatric,
          issueDescription: 'Missing matriculation number',
        ));
        rowIndex++;
        continue;
      }

      final normalizedMatric = rawMatric.toUpperCase();

      if (seenMatricsInFile.contains(normalizedMatric)) {
        errors.add(ImportErrorItem(
          rowIndex: rowIndex,
          rawName: rawName,
          rawMatric: rawMatric,
          issueDescription: 'Duplicate matric number ($rawMatric)',
        ));
        rowIndex++;
        continue;
      }

      seenMatricsInFile.add(normalizedMatric);
      final now = DateTime.now();

      validStudents.add(Student(
        id: _uuid.v4(),
        courseId: courseId,
        name: rawName,
        matricNumber: rawMatric,
        createdAt: now,
        updatedAt: now,
        synced: false,
      ));

      rowIndex++;
    }

    return ClassListImportResult(
      totalRowsFound: dataRows.length,
      validStudents: validStudents,
      errors: errors,
    );
  }
}
