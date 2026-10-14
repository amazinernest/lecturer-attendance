/**
 * Institutional PDF Report Generator for Lecturer Attendance Portal
 * Uses jsPDF and autoTable to produce executive attendance matrices and sign-off sheets.
 */

export class ReportExporter {
  static generateCourseMatrixPdf({
    course,
    students,
    sessions,
    records,
    lecturerName = 'Dr. Lecturer'
  }) {
    if (!window.jspdf || !window.jspdf.jsPDF) {
      throw new Error('jsPDF library not loaded');
    }

    const { jsPDF } = window.jspdf;
    const doc = new jsPDF({
      orientation: sessions.length > 8 ? 'landscape' : 'portrait',
      unit: 'pt',
      format: 'a4'
    });

    const primaryColor = [15, 23, 42]; // Slate 900
    const accentColor = [56, 189, 248]; // Sky 400
    const greenColor = [16, 185, 129];
    const redColor = [239, 68, 68];

    // Compute student attendance statistics
    const recordMap = new Map(); // `${sessionId}_${studentId}` -> boolean
    for (const r of records) {
      if (r.status === 'present') {
        recordMap.set(`${r.attendance_session_id}_${r.student_id}`, true);
      }
    }

    const studentStats = students.map((s, idx) => {
      let attended = 0;
      const sessionStatuses = sessions.map(sess => {
        const isPresent = recordMap.has(`${sess.id}_${s.id}`);
        if (isPresent) attended++;
        return isPresent ? 'P' : 'A';
      });

      const totalHeld = sessions.length > 0 ? sessions.length : 1;
      const pct = Math.round((attended / totalHeld) * 100);
      const isEligible = pct >= 75;

      return {
        sn: idx + 1,
        name: s.name,
        matric: s.matricNumber,
        sessionStatuses,
        attended,
        pct,
        status: isEligible ? 'ELIGIBLE (>=75%)' : pct >= 50 ? 'WARNING (50-74%)' : 'BARRED (<50%)'
      };
    });

    const totalStudents = students.length;
    const totalClasses = sessions.length;
    const eligibleCount = studentStats.filter(s => s.pct >= 75).length;
    const avgPct = totalStudents > 0
      ? Math.round(studentStats.reduce((acc, s) => acc + s.pct, 0) / totalStudents)
      : 0;

    // 1. Header Banner
    doc.setFillColor(15, 23, 42);
    doc.rect(0, 0, doc.internal.pageSize.width, 70, 'F');

    doc.setFont('helvetica', 'bold');
    doc.setFontSize(16);
    doc.setTextColor(255, 255, 255);
    doc.text('OFFICIAL COURSE ATTENDANCE & EXAMINATION ELIGIBILITY MATRIX', 30, 32);

    doc.setFontSize(11);
    doc.setFont('helvetica', 'normal');
    doc.setTextColor(148, 163, 184);
    doc.text(`${course.courseCode}: ${course.courseTitle} • ${course.academicSession || '2024/2025'} Session`, 30, 52);

    // 2. Course Meta & KPI summary
    let curY = 90;
    doc.setFontSize(9);
    doc.setTextColor(51, 65, 85);
    doc.setFont('helvetica', 'bold');
    doc.text(`Department: ${course.department || 'N/A'}`, 30, curY);
    doc.text(`Level/Semester: ${course.level || 'N/A'} • ${course.semester || 'First'} Sem`, 220, curY);
    doc.text(`Lecturer: ${lecturerName}`, 420, curY);
    doc.text(`Generated: ${new Date().toLocaleDateString('en-GB')}`, doc.internal.pageSize.width - 150, curY);

    curY += 20;

    // KPI Cards Block
    const kpiWidth = (doc.internal.pageSize.width - 60 - 30) / 4;
    const kpis = [
      { label: 'Total Enrolled', val: `${totalStudents}` },
      { label: 'Lectures Held', val: `${totalClasses} / ${course.expectedClasses || 15}` },
      { label: 'Class Average', val: `${avgPct}%` },
      { label: 'Exam Eligible', val: `${eligibleCount} / ${totalStudents}` }
    ];

    kpis.forEach((kpi, i) => {
      const x = 30 + i * (kpiWidth + 10);
      doc.setFillColor(241, 245, 249);
      doc.roundedRect(x, curY, kpiWidth, 38, 4, 4, 'F');
      doc.setFontSize(8);
      doc.setTextColor(100, 116, 139);
      doc.setFont('helvetica', 'normal');
      doc.text(kpi.label, x + 8, curY + 14);
      doc.setFontSize(12);
      doc.setFont('helvetica', 'bold');
      doc.setTextColor(15, 23, 42);
      doc.text(kpi.val, x + 8, curY + 30);
    });

    curY += 52;

    // 3. Table Construction
    const headers = [
      'S/N',
      'Student Full Name',
      'Matric Number',
      ...sessions.map((_, i) => `C${i + 1}`),
      'Att.',
      'Pct %',
      'Exam Status'
    ];

    const body = studentStats.map(s => [
      s.sn,
      s.name,
      s.matric,
      ...s.sessionStatuses,
      s.attended,
      `${s.pct}%`,
      s.status
    ]);

    doc.autoTable({
      startY: curY,
      head: [headers],
      body: body,
      theme: 'grid',
      styles: {
        fontSize: 8,
        cellPadding: 4,
        textColor: [30, 41, 59]
      },
      headStyles: {
        fillColor: [15, 23, 42],
        textColor: [255, 255, 255],
        fontStyle: 'bold'
      },
      alternateRowStyles: {
        fillColor: [248, 250, 252]
      },
      columnStyles: {
        0: { cellWidth: 26, halign: 'center' },
        1: { cellWidth: 140, fontStyle: 'bold' },
        2: { cellWidth: 85, fontStyle: 'bold' },
        [headers.length - 3]: { halign: 'center', fontStyle: 'bold' },
        [headers.length - 2]: { halign: 'center', fontStyle: 'bold' },
        [headers.length - 1]: { cellWidth: 95, fontStyle: 'bold' }
      },
      didParseCell: function(data) {
        if (data.section === 'body' && data.column.index === headers.length - 1) {
          const val = data.cell.raw;
          if (val.includes('ELIGIBLE')) {
            data.cell.styles.textColor = [16, 185, 129];
          } else if (val.includes('WARNING')) {
            data.cell.styles.textColor = [217, 119, 6];
          } else {
            data.cell.styles.textColor = [239, 68, 68];
          }
        }
      }
    });

    // 4. Sign-Off Section
    let finalY = doc.lastAutoTable.finalY + 30;
    if (finalY > doc.internal.pageSize.height - 80) {
      doc.addPage();
      finalY = 50;
    }

    const sigWidth = (doc.internal.pageSize.width - 60 - 40) / 3;
    const sigTitles = [
      'Course Lecturer / Coordinator',
      'Head of Department (H.O.D)',
      'Dean of Faculty / School'
    ];

    sigTitles.forEach((t, i) => {
      const x = 30 + i * (sigWidth + 20);
      doc.setDrawColor(148, 163, 184);
      doc.line(x, finalY + 25, x + sigWidth, finalY + 25);
      doc.setFontSize(8);
      doc.setFont('helvetica', 'bold');
      doc.setTextColor(30, 41, 59);
      doc.text(t, x, finalY + 38);
      doc.setFont('helvetica', 'normal');
      doc.setTextColor(148, 163, 184);
      doc.text('Signature & Date', x, finalY + 50);
    });

    // Save
    doc.save(`${course.courseCode}_Attendance_Matrix.pdf`);
    return doc;
  }
}
