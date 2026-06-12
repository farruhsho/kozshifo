"""Server-side rendering of official print forms.

First form: MoH Form 025-8 «Амбулатор тиббий карта» (Order № 777, 2017-12-25) —
cover identity + «ОКУЛИСТ КУРИГИ» eye exam + Ташхис/Тавсия/Шифокор.

Cyrillic support: reportlab's built-in Helvetica has no Cyrillic glyphs, so we
register the first TTF found among common system fonts (Windows Arial, Linux
DejaVu, macOS Arial). Helvetica remains the last-resort fallback so PDF
generation never hard-fails on an exotic host.
"""
from __future__ import annotations

import io
from datetime import date
from pathlib import Path

from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.lib.utils import simpleSplit
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen.canvas import Canvas

from app.models.exam import EyeExam

_FONT_CANDIDATES: list[tuple[str, str]] = [
    # (regular, bold)
    (r"C:\Windows\Fonts\arial.ttf", r"C:\Windows\Fonts\arialbd.ttf"),
    ("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
     "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"),
    ("/usr/share/fonts/dejavu/DejaVuSans.ttf", "/usr/share/fonts/dejavu/DejaVuSans-Bold.ttf"),
    ("/System/Library/Fonts/Supplemental/Arial.ttf",
     "/System/Library/Fonts/Supplemental/Arial Bold.ttf"),
]

FONT = "Helvetica"
FONT_BOLD = "Helvetica-Bold"


def _register_fonts() -> None:
    global FONT, FONT_BOLD
    if FONT != "Helvetica":  # already registered
        return
    for regular, bold in _FONT_CANDIDATES:
        if Path(regular).exists():
            pdfmetrics.registerFont(TTFont("CardFont", regular))
            FONT = "CardFont"
            if Path(bold).exists():
                pdfmetrics.registerFont(TTFont("CardFont-Bold", bold))
                FONT_BOLD = "CardFont-Bold"
            else:
                FONT_BOLD = "CardFont"
            return


_PAGE_W, _PAGE_H = A4
_MARGIN = 18 * mm
_LINE = 5.2 * mm


class _Writer:
    """Top-down text flow with automatic page breaks and a repeated footer."""

    def __init__(self, canvas: Canvas):
        self.c = canvas
        self.y = _PAGE_H - _MARGIN

    def _page_break_if_needed(self, needed: float) -> None:
        if self.y - needed < _MARGIN + 10 * mm:
            _draw_footer(self.c)
            self.c.showPage()
            self.y = _PAGE_H - _MARGIN

    def spacer(self, h: float) -> None:
        self.y -= h

    def text(self, label: str, value: str | None = None, *, bold_label: bool = False,
             size: float = 9.5, indent: float = 0) -> None:
        """One labeled line; long values wrap onto continuation lines."""
        value = (value or "").strip()
        full = f"{label} {value}".strip() if value else label
        max_w = _PAGE_W - 2 * _MARGIN - indent
        font = FONT_BOLD if bold_label else FONT
        lines = simpleSplit(full, font, size, max_w) or [""]
        self._page_break_if_needed(len(lines) * _LINE)
        for line in lines:
            self.c.setFont(font, size)
            self.c.drawString(_MARGIN + indent, self.y, line)
            self.y -= _LINE

    def heading(self, title: str, size: float = 11) -> None:
        self._page_break_if_needed(2 * _LINE)
        self.spacer(2 * mm)
        self.c.setFont(FONT_BOLD, size)
        self.c.drawCentredString(_PAGE_W / 2, self.y, title)
        self.y -= _LINE + 1 * mm

    def rule(self) -> None:
        self._page_break_if_needed(_LINE)
        self.c.setLineWidth(0.4)
        self.c.line(_MARGIN, self.y + 1.5 * mm, _PAGE_W - _MARGIN, self.y + 1.5 * mm)
        self.spacer(1.5 * mm)


def _draw_footer(c: Canvas) -> None:
    c.setFont(FONT, 7.5)
    c.drawCentredString(
        _PAGE_W / 2, 11 * mm,
        "Тиббий ҳужжат шакли № 025-8 · ЎзР ССВнинг 2017 йил 25 декабрдаги № 777-сонли буйруғи билан тасдиқланган",
    )


def _fmt(value: object) -> str:
    return "" if value is None else str(value)


def _fmt_date(d: date | None) -> str:
    return d.strftime("%d.%m.%Y") if d else ""


def _visus_line(eye: str, va: str | None, sph, cyl, axis, va_cc: str | None) -> str:
    corr = []
    if sph is not None:
        corr.append(f"sph {sph}")
    if cyl is not None:
        corr.append(f"cyl {cyl}")
    if axis is not None:
        corr.append(f"ax {axis}°")
    correction = ", ".join(corr) if corr else "—"
    cc = f" = {va_cc}" if va_cc else ""
    return f"Visus {eye} {_fmt(va) or '—'} ; коррекция билан: {correction}{cc}"


def build_exam_card_pdf(exam: EyeExam) -> bytes:
    """Render the full Form 025-8 card for one exam (visit/patient/doctor joined)."""
    _register_fonts()
    patient = exam.patient
    visit = exam.visit
    buf = io.BytesIO()
    c = Canvas(buf, pagesize=A4)
    c.setTitle(f"Form 025-8 — {patient.full_name} — {visit.visit_no}")
    w = _Writer(c)

    # Header
    c.setFont(FONT, 8)
    c.drawString(_MARGIN, w.y, "«KO'Z SHIFO» klinikasi")
    c.drawRightString(_PAGE_W - _MARGIN, w.y, "Тиббий ҳужжат шакли № 025-8")
    w.spacer(_LINE * 2)
    w.heading("АМБУЛАТОР ТИББИЙ КАРТА", size=13)
    w.text(f"Бемор коди: {patient.mrn}    Ташриф: {visit.visit_no}", bold_label=True)
    w.rule()

    # Cover — identity (DOMAIN.md §2.1, form order)
    w.text("1. Фамилия:", patient.last_name)
    w.text("2. Исми:", patient.first_name)
    w.text("3. Туғилган сана:", _fmt_date(patient.birth_date))
    w.text("4. Тел.:", patient.phone)
    w.text("5. Доимий яшаш жойи:", patient.address)
    w.text("6. Иш (ўқиш) жойи:", patient.workplace)
    w.text("7.1. Диспансеризация (айнан шу муассасада):", patient.dispensary_here)
    w.text("7.2. Диспансеризация (бошқа муассасада):", patient.dispensary_other)

    # Eye exam — «ОКУЛИСТ КУРИГИ» (DOMAIN.md §2.2, form order)
    w.heading("ОКУЛИСТ КУРИГИ")
    w.text("Сана:", _fmt_date(exam.exam_date))
    w.text("Шикоятлари:", exam.complaints)
    w.text(_visus_line("OD", exam.od_va, exam.od_sph, exam.od_cyl, exam.od_axis, exam.od_va_cc))
    w.text(_visus_line("OS", exam.os_va, exam.os_sph, exam.os_cyl, exam.os_axis, exam.os_va_cc))
    w.text("Анамнез:", exam.anamnesis)
    iop = f"OD {_fmt(exam.iop_od) or '—'} / OS {_fmt(exam.iop_os) or '—'} мм с.у."
    w.text("Кўз ички босими:", iop)
    for label, value in (
        ("Орбита:", exam.orbit),
        ("Кўз олмаси:", exam.eyeball),
        ("Қовоқлар:", exam.eyelids),
        ("Коньюктива:", exam.conjunctiva),
        ("Кўз ёш аъзолари:", exam.lacrimal),
        ("Шох парда:", exam.cornea),
        ("Олд камера:", exam.anterior_chamber),
        ("Рангдор парда:", exam.iris),
        ("Қорачиқ:", exam.pupil),
        ("Гавҳар:", exam.lens),
        ("Шишасимон тана:", exam.vitreous),
        ("Кўз туби:", exam.fundus),
    ):
        w.text(label, value)
    w.text("Кўз A/B-скан текшеруви:", exam.ab_scan_note)

    # Conclusion (DOMAIN.md §2.3)
    w.rule()
    diagnosis = exam.diagnosis or ""
    if exam.icd10:
        diagnosis = f"{diagnosis}  (МКБ-10: {exam.icd10})".strip()
    w.text("Ташхис:", diagnosis, bold_label=True)
    w.text("Тавсия:", exam.recommendations, bold_label=True)
    doctor_name = exam.doctor.full_name if exam.doctor else ""
    w.text("Шифокор:", f"{doctor_name}    имзо: _________________", bold_label=True)

    _draw_footer(c)
    c.save()
    return buf.getvalue()
