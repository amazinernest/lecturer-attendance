import 'dart:convert';
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
    List<Student> existingStudents = const [],
  }) {
    final lowerName = fileName.toLowerCase();
    if (lowerName.endsWith('.csv') || lowerName.endsWith('.txt')) {
      return _parseCsv(bytes, courseId, existingMatricNumbers, existingStudents);
    } else if (lowerName.endsWith('.xlsx') || lowerName.endsWith('.xls')) {
      return _parseExcel(bytes, courseId, existingMatricNumbers, existingStudents);
    } else if (lowerName.endsWith('.docx')) {
      return _parseDocx(bytes, courseId, existingMatricNumbers, existingStudents);
    } else if (lowerName.endsWith('.doc')) {
      return _parseDoc(bytes, courseId, existingMatricNumbers, existingStudents);
    } else if (lowerName.endsWith('.pdf')) {
      return _parsePdf(bytes, courseId, existingMatricNumbers, existingStudents);
    } else {
      // Fallback: try CSV first, then raw text extraction
      try {
        final csvRes = _parseCsv(bytes, courseId, existingMatricNumbers, existingStudents);
        if (csvRes.validCount > 0) return csvRes;
      } catch (_) {}
      return _parseRawTextLines(bytes, courseId, existingMatricNumbers, existingStudents);
    }
  }

  static ClassListImportResult _parseCsv(
    Uint8List bytes,
    String courseId,
    List<String> existingMatrics,
    List<Student> existingStudents,
  ) {
    String content;
    try {
      content = utf8.decode(bytes);
    } catch (_) {
      content = String.fromCharCodes(bytes);
    }
    if (content.startsWith('\uFEFF')) {
      content = content.substring(1); // strip BOM
    }

    final normalized = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    // Auto-detect delimiter: comma, semicolon, or tab
    final firstFewLines = normalized.split('\n').take(5).join('\n');
    String delimiter = ',';
    final commaCount = ','.allMatches(firstFewLines).length;
    final semiCount = ';'.allMatches(firstFewLines).length;
    final tabCount = '\t'.allMatches(firstFewLines).length;
    if (semiCount > commaCount && semiCount > tabCount) {
      delimiter = ';';
    } else if (tabCount > commaCount && tabCount > semiCount) {
      delimiter = '\t';
    }

    final rows = CsvToListConverter(
      shouldParseNumbers: false,
      eol: '\n',
      fieldDelimiter: delimiter,
    ).convert(normalized);
    return _processRawRows(rows, courseId, existingMatrics, existingStudents);
  }

  static ClassListImportResult _parseExcel(
    Uint8List bytes,
    String courseId,
    List<String> existingMatrics,
    List<Student> existingStudents,
  ) {
    final excel = Excel.decodeBytes(bytes);
    final rows = <List<dynamic>>[];

    for (final table in excel.tables.keys) {
      final sheet = excel.tables[table];
      if (sheet != null) {
        for (final row in sheet.rows) {
          final rowValues = row.map((cell) => cell?.value?.toString().trim() ?? '').toList();
          if (rowValues.any((c) => c.isNotEmpty)) {
            rows.add(rowValues);
          }
        }
      }
    }

    return _processRawRows(rows, courseId, existingMatrics, existingStudents);
  }

  /// Parse Word DOCX (.docx) files by unzipping word/document.xml and extracting tables/paragraphs
  static ClassListImportResult _parseDocx(
    Uint8List bytes,
    String courseId,
    List<String> existingMatrics,
    List<Student> existingStudents,
  ) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final docFile = archive.findFile('word/document.xml');
      if (docFile == null) {
        return _parseRawTextLines(bytes, courseId, existingMatrics, existingStudents);
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
        return _processRawRows(rows, courseId, existingMatrics, existingStudents);
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

      return _processTextLines(lines, courseId, existingMatrics, existingStudents);
    } catch (_) {
      return _parseRawTextLines(bytes, courseId, existingMatrics, existingStudents);
    }
  }

  /// Parse legacy binary Word DOC (.doc) files by extracting text streams
  static ClassListImportResult _parseDoc(
    Uint8List bytes,
    String courseId,
    List<String> existingMatrics,
    List<Student> existingStudents,
  ) {
    return _parseRawTextLines(bytes, courseId, existingMatrics, existingStudents);
  }

  /// Parse PDF (.pdf) files by decompressing Flate streams and extracting text literals
  static ClassListImportResult _parsePdf(
    Uint8List bytes,
    String courseId,
    List<String> existingMatrics,
    List<Student> existingStudents,
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
        return _parseRawTextLines(bytes, courseId, existingMatrics, existingStudents);
      }

      final fullPdfText = textChunks.join('\n');
      final lines = fullPdfText
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

      return _processTextLines(lines, courseId, existingMatrics, existingStudents);
    } catch (_) {
      return _parseRawTextLines(bytes, courseId, existingMatrics, existingStudents);
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
    List<Student> existingStudents,
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

    return _processTextLines(lines, courseId, existingMatrics, existingStudents);
  }

  /// Process plain text lines to recognize Student Name and Matriculation Numbers
  static ClassListImportResult _processTextLines(
    List<String> lines,
    String courseId,
    List<String> existingMatrics,
    List<Student> existingStudents,
  ) {
    final rawRows = <List<String>>[];

    // Matric number pattern matching common formats: e.g. 2024/001, ENG/19/042, 19/30G/012, 2021104928
    final matricRegex = RegExp(r'\b([A-Z0-9]{2,8}[/-][A-Z0-9/-]{3,12}|\d{6,12})\b', caseSensitive: false);

    for (final line in lines) {
      final matricMatch = matricRegex.firstMatch(line);
      if (matricMatch != null) {
        final matricStr = matricMatch.group(1) ?? '';
        var namePart = line.replaceFirst(matricStr, '');
        namePart = namePart.replaceAll(RegExp(r'^\s*\d+[\.\)\-]?\s*'), ''); // strip leading S/N
        namePart = namePart.replaceAll(RegExp(r'[,:;|\\/]+'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

        if (namePart.isNotEmpty && matricStr.isNotEmpty) {
          rawRows.add([namePart, matricStr]);
        }
      } else if (line.contains(',') || line.contains('\t') || line.contains('|') || line.contains(';')) {
        final parts = line.split(RegExp(r'[,\|\t;]')).map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
        if (parts.length >= 2) {
          rawRows.add(parts);
        }
      }
    }

    return _processRawRows(rawRows, courseId, existingMatrics, existingStudents);
  }

  static ClassListImportResult _processRawRows(
    List<List<dynamic>> rawRows,
    String courseId,
    List<String> existingMatrics,
    List<Student> existingStudents,
  ) {
    final validStudents = <Student>[];
    final errors = <ImportErrorItem>[];
    final seenMatricsInFile = <String>{};
    final existingStudentsByMatric = <String, Student>{
      for (final s in existingStudents) s.matricNumber.trim().toUpperCase(): s
    };

    if (rawRows.isEmpty) {
      return const ClassListImportResult(totalRowsFound: 0, validStudents: [], errors: []);
    }

    // Common Nigerian/International Matric Number Regex
    final matricRegex = RegExp(
      r'([A-Z0-9]{2,8}[/-][A-Z0-9/-]{2,12}|\b\d{6,14}\b)',
      caseSensitive: false,
    );

    // 1. Scan the first 15 rows to find the Header Row
    int headerRowIndex = -1;
    int matricColIndex = -1;
    List<int> nameColIndices = [];

    final maxHeaderScan = rawRows.length > 15 ? 15 : rawRows.length;
    for (int r = 0; r < maxHeaderScan; r++) {
      final rowStr = rawRows[r].map((e) => e?.toString().trim().toLowerCase() ?? '').toList();

      int foundMatric = -1;
      final foundNameCols = <int>[];

      for (int c = 0; c < rowStr.length; c++) {
        final colVal = rowStr[c];
        if (colVal.isEmpty) continue;

        // Matric / Reg No keywords
        final isMatric = colVal.contains('matric') ||
            colVal.contains('mat. no') ||
            colVal.contains('mat no') ||
            colVal.contains('mat_no') ||
            colVal.contains('reg. no') ||
            colVal.contains('reg no') ||
            colVal.contains('reg_no') ||
            colVal.contains('reg number') ||
            colVal.contains('reg. number') ||
            colVal.contains('reg_number') ||
            colVal.contains('reg_num') ||
            colVal.contains('registration') ||
            colVal.contains('admission') ||
            colVal.contains('adm no') ||
            colVal.contains('adm. no') ||
            colVal.contains('roll no') ||
            colVal.contains('roll number') ||
            colVal.contains('index no') ||
            colVal.contains('student id') ||
            colVal.contains('student no') ||
            colVal.contains('student number') ||
            colVal.contains('id no') ||
            colVal.contains('jamb') ||
            colVal == 'reg' ||
            colVal == 'id';

        if (isMatric) {
          foundMatric = c;
        }
        // Name keywords
        else if (colVal.contains('surname') ||
            colVal.contains('last name') ||
            colVal.contains('lastname') ||
            colVal.contains('first name') ||
            colVal.contains('other name') ||
            colVal.contains('firstname') ||
            colVal.contains('other names') ||
            colVal.contains('middle name') ||
            colVal.contains('middle') ||
            colVal.contains('full name') ||
            colVal.contains('fullname') ||
            colVal.contains('name') ||
            colVal.contains('student') ||
            colVal.contains('candidate')) {
          if (!colVal.contains('email') &&
              !colVal.contains('phone') &&
              !colVal.contains('dept') &&
              !colVal.contains('department') &&
              !colVal.contains('faculty') &&
              !colVal.contains('level') &&
              !colVal.contains('programme') &&
              !colVal.contains('session')) {
            foundNameCols.add(c);
          }
        }
      }

      if (foundMatric != -1 && foundNameCols.isNotEmpty) {
        headerRowIndex = r;
        matricColIndex = foundMatric;
        nameColIndices = foundNameCols;
        break;
      }
    }

    List<List<dynamic>> dataRows;
    int startRowNumber;

    if (headerRowIndex != -1) {
      dataRows = rawRows.sublist(headerRowIndex + 1);
      startRowNumber = headerRowIndex + 2;
    } else {
      // If no explicit header row found, auto-detect columns by content
      dataRows = rawRows;
      startRowNumber = 1;

      final sampleCount = dataRows.length > 15 ? 15 : dataRows.length;
      final maxCols = dataRows.fold<int>(0, (max, row) => row.length > max ? row.length : max);

      final matricMatchCounts = List<int>.filled(maxCols, 0);
      final nameScoreCounts = List<int>.filled(maxCols, 0);

      for (int r = 0; r < sampleCount; r++) {
        final row = dataRows[r];
        for (int c = 0; c < row.length; c++) {
          final cellText = row[c]?.toString().trim() ?? '';
          if (cellText.isEmpty) continue;

          if (matricRegex.hasMatch(cellText) && cellText.length <= 25) {
            matricMatchCounts[c]++;
          } else if (RegExp(r'^[a-zA-Z\s\.\,\-]+$').hasMatch(cellText) && cellText.length >= 3 && !RegExp(r'^\d+$').hasMatch(cellText)) {
            nameScoreCounts[c]++;
          }
        }
      }

      int bestMatricCol = -1;
      int maxMatric = 0;
      for (int c = 0; c < maxCols; c++) {
        if (matricMatchCounts[c] > maxMatric) {
          maxMatric = matricMatchCounts[c];
          bestMatricCol = c;
        }
      }

      int bestNameCol = -1;
      int maxName = 0;
      for (int c = 0; c < maxCols; c++) {
        if (c != bestMatricCol && nameScoreCounts[c] > maxName) {
          maxName = nameScoreCounts[c];
          bestNameCol = c;
        }
      }

      matricColIndex = bestMatricCol != -1 ? bestMatricCol : 1;
      nameColIndices = [bestNameCol != -1 ? bestNameCol : 0];
    }

    // Now process all data rows
    int currentRowIndex = startRowNumber;
    for (final row in dataRows) {
      if (row.isEmpty || row.every((c) => c == null || c.toString().trim().isEmpty)) {
        currentRowIndex++;
        continue;
      }

      String rawName = '';
      if (nameColIndices.isNotEmpty) {
        final nameParts = <String>[];
        for (final c in nameColIndices) {
          if (c < row.length) {
            final part = row[c]?.toString().trim() ?? '';
            if (part.isNotEmpty) nameParts.add(part);
          }
        }
        rawName = nameParts.join(' ');
      }

      String rawMatric = '';
      if (matricColIndex != -1 && matricColIndex < row.length) {
        rawMatric = row[matricColIndex]?.toString().trim() ?? '';
      }

      // If either name or matric is empty, scan other cells in the row as fallback!
      if (rawName.isEmpty || rawMatric.isEmpty) {
        for (int c = 0; c < row.length; c++) {
          final cellText = row[c]?.toString().trim() ?? '';
          if (cellText.isEmpty) continue;

          if (rawMatric.isEmpty && matricRegex.hasMatch(cellText)) {
            rawMatric = cellText;
          } else if (rawName.isEmpty && !matricRegex.hasMatch(cellText) && !RegExp(r'^\d+$').hasMatch(cellText) && cellText.length >= 3) {
            rawName = cellText;
          }
        }
      }

      // If Name and Matric were accidentally inverted
      if (matricRegex.hasMatch(rawName) && !matricRegex.hasMatch(rawMatric) && RegExp(r'^[a-zA-Z\s\.\,\-]+$').hasMatch(rawMatric)) {
        final temp = rawName;
        rawName = rawMatric;
        rawMatric = temp;
      }

      // Strip leading S/N numbering if attached to name (e.g. "1. John Doe" -> "John Doe")
      rawName = rawName.replaceAll(RegExp(r'^\s*\d+[\.\)\-]?\s*'), '').trim();
      rawName = rawName.replaceAll(RegExp(r'\s+'), ' ');

      // Normalize matric: clean internal stray spaces (e.g. "CSC / 2021 / 045" -> "CSC/2021/045")
      rawMatric = rawMatric.replaceAll(RegExp(r'\s+'), '').trim();

      if (rawName.isEmpty && rawMatric.isEmpty) {
        currentRowIndex++;
        continue;
      }

      if (rawName.isEmpty) {
        errors.add(ImportErrorItem(
          rowIndex: currentRowIndex,
          rawName: rawName,
          rawMatric: rawMatric,
          issueDescription: 'Missing student name',
        ));
        currentRowIndex++;
        continue;
      }

      if (rawMatric.isEmpty) {
        errors.add(ImportErrorItem(
          rowIndex: currentRowIndex,
          rawName: rawName,
          rawMatric: rawMatric,
          issueDescription: 'Missing matriculation number',
        ));
        currentRowIndex++;
        continue;
      }

      final normalizedMatric = rawMatric.toUpperCase();

      if (seenMatricsInFile.contains(normalizedMatric)) {
        errors.add(ImportErrorItem(
          rowIndex: currentRowIndex,
          rawName: rawName,
          rawMatric: rawMatric,
          issueDescription: 'Duplicate matric number ($rawMatric)',
        ));
        currentRowIndex++;
        continue;
      }

      seenMatricsInFile.add(normalizedMatric);
      final now = DateTime.now();

      // If student already exists in database, preserve existing student ID and update name
      final existing = existingStudentsByMatric[normalizedMatric];
      if (existing != null) {
        validStudents.add(existing.copyWith(
          name: rawName,
          updatedAt: now,
          synced: false,
        ));
      } else {
        validStudents.add(Student(
          id: _uuid.v4(),
          courseId: courseId,
          name: rawName,
          matricNumber: rawMatric,
          createdAt: now,
          updatedAt: now,
          synced: false,
        ));
      }

      currentRowIndex++;
    }

    return ClassListImportResult(
      totalRowsFound: dataRows.length,
      validStudents: validStudents,
      errors: errors,
    );
  }
}
