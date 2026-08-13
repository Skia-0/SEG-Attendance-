import csv
import io
from datetime import datetime
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch, cm
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
    PageBreak,
)
from reportlab.lib.enums import TA_CENTER, TA_LEFT


SEG_ORANGE = colors.HexColor("#FF6B00")
SEG_BLACK = colors.HexColor("#1A1A1A")
SEG_GREY = colors.HexColor("#666666")
SEG_LIGHT_GREY = colors.HexColor("#F5F5F5")


class ReportExporter:

    @staticmethod
    def _format_datetime(iso_str):
        if not iso_str:
            return "—"
        try:
            dt = datetime.fromisoformat(iso_str.replace("Z", ""))
            return dt.strftime("%d %b %Y  %H:%M")
        except Exception:
            return iso_str

    @staticmethod
    def _format_time(iso_str):
        if not iso_str:
            return "—"
        try:
            dt = datetime.fromisoformat(iso_str.replace("Z", ""))
            return dt.strftime("%H:%M")
        except Exception:
            return "—"

    # ─── PDF EXPORT ─────────────────────────────────────────
    @classmethod
    def to_pdf(cls, report, hub_name, cohort_name):
        """Generate PDF from a Report row. Returns bytes."""
        buffer = io.BytesIO()
        doc = SimpleDocTemplate(
            buffer,
            pagesize=A4,
            rightMargin=1.5 * cm,
            leftMargin=1.5 * cm,
            topMargin=1.5 * cm,
            bottomMargin=1.5 * cm,
        )

        styles = getSampleStyleSheet()

        title_style = ParagraphStyle(
            "TitleStyle",
            parent=styles["Heading1"],
            fontSize=20,
            textColor=SEG_BLACK,
            spaceAfter=6,
        )
        subtitle_style = ParagraphStyle(
            "SubtitleStyle",
            parent=styles["Normal"],
            fontSize=11,
            textColor=SEG_GREY,
            spaceAfter=16,
        )
        section_style = ParagraphStyle(
            "SectionStyle",
            parent=styles["Heading2"],
            fontSize=12,
            textColor=SEG_ORANGE,
            spaceAfter=6,
            spaceBefore=12,
        )
        body_style = ParagraphStyle(
            "BodyStyle",
            parent=styles["Normal"],
            fontSize=10,
            textColor=SEG_BLACK,
        )

        story = []

        if report.report_type == "session":
            story.extend(
                cls._build_session_pdf(
                    report, hub_name, cohort_name,
                    title_style, subtitle_style,
                    section_style, body_style,
                )
            )
        else:
            story.extend(
                cls._build_cohort_pdf(
                    report, hub_name, cohort_name,
                    title_style, subtitle_style,
                    section_style, body_style,
                )
            )

        doc.build(story, onFirstPage=cls._add_footer,
                  onLaterPages=cls._add_footer)
        pdf_bytes = buffer.getvalue()
        buffer.close()
        return pdf_bytes

    @staticmethod
    def _add_footer(canvas, doc):
        canvas.saveState()
        canvas.setFont("Helvetica", 8)
        canvas.setFillColor(SEG_GREY)
        text = f"SEG Attendance — Internal Document — Page {doc.page}"
        canvas.drawCentredString(A4[0] / 2, 1 * cm, text)
        canvas.restoreState()

    @classmethod
    def _build_session_pdf(cls, report, hub_name, cohort_name,
                           title_s, sub_s, sec_s, body_s):
        story = []
        data = report.data

        # Header
        story.append(Paragraph("SESSION ATTENDANCE REPORT", title_s))
        story.append(Paragraph(
            f"Submitted {cls._format_datetime(report.submitted_at.isoformat() if report.submitted_at else None)}",
            sub_s
        ))

        # Info table
        info_data = [
            ["Hub", hub_name],
            ["Cohort", cohort_name],
            ["Session Title", data.get("session_title", "—")],
            ["Started", cls._format_datetime(data.get("started_at"))],
            ["Ended", cls._format_datetime(data.get("ended_at"))],
        ]
        info_table = Table(info_data, colWidths=[4 * cm, 12 * cm])
        info_table.setStyle(TableStyle([
            ("FONTNAME", (0, 0), (0, -1), "Helvetica-Bold"),
            ("FONTSIZE", (0, 0), (-1, -1), 10),
            ("TEXTCOLOR", (0, 0), (0, -1), SEG_GREY),
            ("TEXTCOLOR", (1, 0), (1, -1), SEG_BLACK),
            ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
            ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ]))
        story.append(info_table)

        # Summary stats
        story.append(Paragraph("ATTENDANCE SUMMARY", sec_s))
        total = data.get("total_learners", 0)
        attended = data.get("attended_count", 0)
        percent = (attended / total * 100) if total > 0 else 0

        summary_data = [
            ["Total Learners", "Present (Complete)",
             "Absent/Partial", "Attendance Rate"],
            [str(total), str(attended),
             str(total - attended), f"{percent:.1f}%"],
        ]
        summary_table = Table(summary_data,
                              colWidths=[4 * cm] * 4)
        summary_table.setStyle(TableStyle([
            ("BACKGROUND", (0, 0), (-1, 0), SEG_BLACK),
            ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
            ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
            ("FONTSIZE", (0, 0), (-1, -1), 9),
            ("ALIGN", (0, 0), (-1, -1), "CENTER"),
            ("BOTTOMPADDING", (0, 0), (-1, -1), 8),
            ("TOPPADDING", (0, 0), (-1, -1), 8),
            ("BACKGROUND", (0, 1), (-1, 1), SEG_LIGHT_GREY),
        ]))
        story.append(summary_table)

        # Attendance detail table
        story.append(Paragraph("DETAILED ATTENDANCE", sec_s))
        attendance = data.get("attendance", [])

        table_data = [["#", "SEG ID", "Name", "IN", "OUT",
                       "Method", "Status"]]
        for i, r in enumerate(attendance, 1):
            in_time = cls._format_time(r.get("checked_in_at"))
            out_time = cls._format_time(r.get("checked_out_at"))
            method = r.get("verification_method") or "—"
            if r.get("is_complete"):
                status = "COMPLETE"
            elif r.get("checked_in_at"):
                status = "PARTIAL"
            else:
                status = "ABSENT"
            table_data.append([
                str(i),
                r.get("seg_id", "—"),
                r.get("full_name", "—"),
                in_time,
                out_time,
                method.upper(),
                status,
            ])

        attendance_table = Table(
            table_data,
            colWidths=[0.8*cm, 3*cm, 5*cm, 1.8*cm, 1.8*cm, 2*cm, 2*cm]
        )
        attendance_table.setStyle(TableStyle([
            ("BACKGROUND", (0, 0), (-1, 0), SEG_ORANGE),
            ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
            ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
            ("FONTSIZE", (0, 0), (-1, 0), 9),
            ("FONTSIZE", (0, 1), (-1, -1), 8),
            ("GRID", (0, 0), (-1, -1), 0.3, SEG_LIGHT_GREY),
            ("ALIGN", (0, 0), (-1, -1), "LEFT"),
            ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
            ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
            ("TOPPADDING", (0, 0), (-1, -1), 5),
        ]))
        story.append(attendance_table)

        return story

    @classmethod
    def _build_cohort_pdf(cls, report, hub_name, cohort_name,
                          title_s, sub_s, sec_s, body_s):
        story = []
        data = report.data

        # Header
        story.append(Paragraph("COHORT CERTIFICATION REPORT",
                               title_s))
        story.append(Paragraph(
            f"Submitted {cls._format_datetime(report.submitted_at.isoformat() if report.submitted_at else None)}",
            sub_s
        ))

        # Info
        info_data = [
            ["Hub", hub_name],
            ["Cohort", data.get("cohort_name", "—")],
            ["Certification Threshold",
             f"{data.get('min_attendance_percent', 0)}%"],
            ["Total Sessions Held",
             str(data.get("total_sessions", 0))],
        ]
        info_table = Table(info_data, colWidths=[6 * cm, 10 * cm])
        info_table.setStyle(TableStyle([
            ("FONTNAME", (0, 0), (0, -1), "Helvetica-Bold"),
            ("FONTSIZE", (0, 0), (-1, -1), 10),
            ("TEXTCOLOR", (0, 0), (0, -1), SEG_GREY),
            ("TEXTCOLOR", (1, 0), (1, -1), SEG_BLACK),
            ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
        ]))
        story.append(info_table)

        # Overall stats
        story.append(Paragraph("OVERALL STATISTICS", sec_s))
        total = data.get("total_learners", 0)
        certified = data.get("certified_count", 0)
        percent = (certified / total * 100) if total > 0 else 0

        stats_data = [
            ["Enrolled", "Certified",
             "Not Certified", "Certification Rate"],
            [str(total), str(certified),
             str(total - certified), f"{percent:.1f}%"],
        ]
        stats_table = Table(stats_data, colWidths=[4 * cm] * 4)
        stats_table.setStyle(TableStyle([
            ("BACKGROUND", (0, 0), (-1, 0), SEG_BLACK),
            ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
            ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
            ("FONTSIZE", (0, 0), (-1, -1), 9),
            ("ALIGN", (0, 0), (-1, -1), "CENTER"),
            ("BOTTOMPADDING", (0, 0), (-1, -1), 8),
            ("TOPPADDING", (0, 0), (-1, -1), 8),
            ("BACKGROUND", (0, 1), (-1, 1), SEG_LIGHT_GREY),
        ]))
        story.append(stats_table)

        # Certified learners
        learners = data.get("learners", [])
        certified_learners = [l for l in learners if l.get("certified")]
        non_certified = [l for l in learners if not l.get("certified")]

        if certified_learners:
            story.append(Paragraph("CERTIFIED LEARNERS", sec_s))
            cert_data = [["#", "SEG ID", "Full Name",
                          "Attended", "Attendance %"]]
            for i, l in enumerate(certified_learners, 1):
                cert_data.append([
                    str(i),
                    l.get("seg_id", "—"),
                    l.get("full_name", "—"),
                    f"{l.get('sessions_attended', 0)}/{l.get('total_sessions', 0)}",
                    f"{l.get('attendance_percent', 0):.1f}%",
                ])
            cert_table = Table(
                cert_data,
                colWidths=[0.8*cm, 3.5*cm, 6*cm, 3*cm, 3*cm]
            )
            cert_table.setStyle(TableStyle([
                ("BACKGROUND", (0, 0), (-1, 0),
                 colors.HexColor("#2E7D32")),
                ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
                ("FONTSIZE", (0, 0), (-1, -1), 9),
                ("GRID", (0, 0), (-1, -1), 0.3, SEG_LIGHT_GREY),
                ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
                ("TOPPADDING", (0, 0), (-1, -1), 5),
            ]))
            story.append(cert_table)

        if non_certified:
            story.append(Paragraph("LEARNERS WHO DID NOT QUALIFY",
                                   sec_s))
            nc_data = [["#", "SEG ID", "Full Name",
                        "Attended", "Attendance %"]]
            for i, l in enumerate(non_certified, 1):
                nc_data.append([
                    str(i),
                    l.get("seg_id", "—"),
                    l.get("full_name", "—"),
                    f"{l.get('sessions_attended', 0)}/{l.get('total_sessions', 0)}",
                    f"{l.get('attendance_percent', 0):.1f}%",
                ])
            nc_table = Table(
                nc_data,
                colWidths=[0.8*cm, 3.5*cm, 6*cm, 3*cm, 3*cm]
            )
            nc_table.setStyle(TableStyle([
                ("BACKGROUND", (0, 0), (-1, 0),
                 colors.HexColor("#C62828")),
                ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
                ("FONTSIZE", (0, 0), (-1, -1), 9),
                ("GRID", (0, 0), (-1, -1), 0.3, SEG_LIGHT_GREY),
                ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
                ("TOPPADDING", (0, 0), (-1, -1), 5),
            ]))
            story.append(nc_table)

        return story

    # ─── CSV EXPORT ─────────────────────────────────────────
    @classmethod
    def to_csv(cls, report, hub_name, cohort_name):
        """Generate CSV from a Report row. Returns string."""
        output = io.StringIO()
        writer = csv.writer(output)

        if report.report_type == "session":
            writer.writerow([
                "Hub", "Cohort", "Session Title",
                "Learner SEG ID", "Learner Name",
                "Check In", "Check Out",
                "Verification Method", "Status"
            ])
            data = report.data
            for r in data.get("attendance", []):
                if r.get("is_complete"):
                    status = "COMPLETE"
                elif r.get("checked_in_at"):
                    status = "PARTIAL"
                else:
                    status = "ABSENT"
                writer.writerow([
                    hub_name,
                    cohort_name,
                    data.get("session_title", ""),
                    r.get("seg_id", ""),
                    r.get("full_name", ""),
                    cls._format_datetime(r.get("checked_in_at")),
                    cls._format_datetime(r.get("checked_out_at")),
                    r.get("verification_method", ""),
                    status,
                ])
        else:
            writer.writerow([
                "Hub", "Cohort",
                "Learner SEG ID", "Learner Name",
                "Sessions Attended", "Total Sessions",
                "Attendance %", "Certified"
            ])
            data = report.data
            for l in data.get("learners", []):
                writer.writerow([
                    hub_name,
                    data.get("cohort_name", ""),
                    l.get("seg_id", ""),
                    l.get("full_name", ""),
                    l.get("sessions_attended", 0),
                    l.get("total_sessions", 0),
                    f"{l.get('attendance_percent', 0):.2f}",
                    "YES" if l.get("certified") else "NO",
                ])

        csv_string = output.getvalue()
        output.close()
        return csv_string