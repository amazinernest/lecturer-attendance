/**
 * Client-Side Class List Parser (Excel, CSV, Text)
 * Uses SheetJS to parse university class lists with multi-row header scanning,
 * split name column merging, and matriculation heuristic recognition.
 */

export class ClassListParser {
  /**
   * Parse a File object from an <input type="file"> or drag-and-drop event
   */
  static async parseFile(file, existingStudents = []) {
    const extension = file.name.split('.').pop().toLowerCase();
    const arrayBuffer = await file.arrayBuffer();

    if (extension === 'xlsx' || extension === 'xls' || extension === 'csv' || extension === 'tsv' || extension === 'txt') {
      return this._parseWithSheetJS(arrayBuffer, file.name, existingStudents);
    } else {
      throw new Error(`Unsupported file type .${extension}. Please upload an Excel (.xlsx, .xls) or CSV file.`);
    }
  }

  static _parseWithSheetJS(buffer, fileName, existingStudents) {
    if (!window.XLSX) {
      throw new Error('SheetJS library not loaded');
    }

    const workbook = window.XLSX.read(buffer, { type: 'array' });
    const firstSheetName = workbook.SheetNames[0];
    const worksheet = workbook.Sheets[firstSheetName];

    // Convert sheet to array of rows
    const rawRows = window.XLSX.utils.sheet_to_json(worksheet, { header: 1, defval: '' });

    if (!rawRows || rawRows.length === 0) {
      return { totalRows: 0, validStudents: [], errors: ['File contains no rows or data'] };
    }

    return this._processRawRows(rawRows, fileName, existingStudents);
  }

  static _processRawRows(rawRows, fileName, existingStudents) {
    const matricRegex = /([A-Z0-9]{2,8}[/-][A-Z0-9/-]{2,12}|\b\d{6,14}\b)/i;

    const existingMatricSet = new Set(
      existingStudents.map(s => s.matricNumber.trim().toUpperCase())
    );

    // 1. Multi-row header scanning (rows 0-15)
    let headerRowIndex = -1;
    let matricColIndex = -1;
    let nameColIndices = [];

    const maxHeaderScan = Math.min(rawRows.length, 15);
    for (let r = 0; r < maxHeaderScan; r++) {
      const row = rawRows[r].map(cell => (cell ? cell.toString().trim().toLowerCase() : ''));

      let foundMatric = -1;
      const foundNames = [];

      for (let c = 0; c < row.length; c++) {
        const val = row[c];
        if (!val) continue;

        const isMatric =
          val.includes('matric') ||
          val.includes('mat. no') ||
          val.includes('mat no') ||
          val.includes('mat_no') ||
          val.includes('reg. no') ||
          val.includes('reg no') ||
          val.includes('reg_no') ||
          val.includes('reg number') ||
          val.includes('reg. number') ||
          val.includes('registration') ||
          val.includes('admission') ||
          val.includes('roll no') ||
          val.includes('roll number') ||
          val.includes('student id') ||
          val.includes('student no') ||
          val.includes('id no') ||
          val.includes('jamb') ||
          val === 'reg' ||
          val === 'id';

        if (isMatric) {
          foundMatric = c;
        } else if (
          val.includes('surname') ||
          val.includes('last name') ||
          val.includes('lastname') ||
          val.includes('first name') ||
          val.includes('other name') ||
          val.includes('firstname') ||
          val.includes('other names') ||
          val.includes('middle name') ||
          val.includes('middle') ||
          val.includes('full name') ||
          val.includes('name') ||
          val.includes('student') ||
          val.includes('candidate')
        ) {
          if (
            !val.includes('email') &&
            !val.includes('phone') &&
            !val.includes('department') &&
            !val.includes('dept') &&
            !val.includes('faculty') &&
            !val.includes('level') &&
            !val.includes('session')
          ) {
            foundNames.push(c);
          }
        }
      }

      if (foundMatric !== -1 && foundNames.length > 0) {
        headerRowIndex = r;
        matricColIndex = foundMatric;
        nameColIndices = foundNames;
        break;
      }
    }

    let dataRows = [];
    let startRowIndex = 1;

    if (headerRowIndex !== -1) {
      dataRows = rawRows.slice(headerRowIndex + 1);
      startRowIndex = headerRowIndex + 2;
    } else {
      // Content-based heuristic fallback
      dataRows = rawRows;
      startRowIndex = 1;

      const sampleSize = Math.min(dataRows.length, 15);
      const maxCols = dataRows.reduce((max, r) => Math.max(max, r.length), 0);

      const matricMatchCounts = new Array(maxCols).fill(0);
      const nameScoreCounts = new Array(maxCols).fill(0);

      for (let r = 0; r < sampleSize; r++) {
        const row = dataRows[r];
        for (let c = 0; c < row.length; c++) {
          const txt = row[c] ? row[c].toString().trim() : '';
          if (!txt) continue;

          if (matricRegex.test(txt) && txt.length <= 25) {
            matricMatchCounts[c]++;
          } else if (/^[a-zA-Z\s.,'-]+$/.test(txt) && txt.length >= 3 && !/^\d+$/.test(txt)) {
            nameScoreCounts[c]++;
          }
        }
      }

      let bestMatric = 1;
      let maxMatric = 0;
      for (let c = 0; c < maxCols; c++) {
        if (matricMatchCounts[c] > maxMatric) {
          maxMatric = matricMatchCounts[c];
          bestMatric = c;
        }
      }

      let bestName = 0;
      let maxName = 0;
      for (let c = 0; c < maxCols; c++) {
        if (c !== bestMatric && nameScoreCounts[c] > maxName) {
          maxName = nameScoreCounts[c];
          bestName = c;
        }
      }

      matricColIndex = bestMatric;
      nameColIndices = [bestName];
    }

    // Process all data rows
    const validStudents = [];
    const errors = [];
    const seenMatricsInFile = new Set();

    let currentRow = startRowIndex;
    for (const row of dataRows) {
      if (!row || row.every(c => !c || c.toString().trim() === '')) {
        currentRow++;
        continue;
      }

      let rawName = '';
      if (nameColIndices.length > 0) {
        const parts = [];
        for (const c of nameColIndices) {
          if (c < row.length && row[c]) {
            const part = row[c].toString().trim();
            if (part) parts.push(part);
          }
        }
        rawName = parts.join(' ');
      }

      let rawMatric = '';
      if (matricColIndex !== -1 && matricColIndex < row.length && row[matricColIndex]) {
        rawMatric = row[matricColIndex].toString().trim();
      }

      // Fallback row cell scan if one is empty
      if (!rawName || !rawMatric) {
        for (let c = 0; c < row.length; c++) {
          const cell = row[c] ? row[c].toString().trim() : '';
          if (!cell) continue;

          if (!rawMatric && matricRegex.test(cell)) {
            rawMatric = cell;
          } else if (!rawName && !matricRegex.test(cell) && !/^\d+$/.test(cell) && cell.length >= 3) {
            rawName = cell;
          }
        }
      }

      // Inverted column auto-fix
      if (matricRegex.test(rawName) && !matricRegex.test(rawMatric) && /^[a-zA-Z\s.,'-]+$/.test(rawMatric)) {
        const temp = rawName;
        rawName = rawMatric;
        rawMatric = temp;
      }

      // Strip leading numbering: "1. John Doe" -> "John Doe"
      rawName = rawName.replace(/^\s*\d+[\.\)\-]?\s*/, '').trim();

      if (!rawName && !rawMatric) {
        currentRow++;
        continue;
      }

      if (!rawName) {
        errors.push(`Row ${currentRow}: Missing student name for matric "${rawMatric}"`);
        currentRow++;
        continue;
      }

      if (!rawMatric) {
        errors.push(`Row ${currentRow}: Missing matriculation number for "${rawName}"`);
        currentRow++;
        continue;
      }

      const normalizedMatric = rawMatric.toUpperCase();

      if (seenMatricsInFile.has(normalizedMatric)) {
        errors.push(`Row ${currentRow}: Duplicate matric number "${rawMatric}" in file`);
        currentRow++;
        continue;
      }

      seenMatricsInFile.add(normalizedMatric);

      validStudents.push({
        id: 'std_' + Math.random().toString(36).substring(2, 9),
        name: rawName,
        matricNumber: rawMatric,
        isExisting: existingMatricSet.has(normalizedMatric)
      });

      currentRow++;
    }

    return {
      totalRowsFound: dataRows.length,
      validStudents: validStudents,
      validCount: validStudents.length,
      errors: errors,
      hasErrors: errors.length > 0
    };
  }
}
