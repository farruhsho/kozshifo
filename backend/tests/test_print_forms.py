"""Guards the receipt/print-form font so Cyrillic never regresses to tofu.

The bug we lock out: reportlab's built-in Helvetica has no Cyrillic glyphs, so on
a host without a system font (Docker slim / Cloud Run) every Cyrillic character
printed as a black .notdef box. We now bundle DejaVuSans under
``app/assets/fonts`` and register it first; if that ever breaks, FONT silently
falls back to Helvetica and receipts tofu again — these tests fail loudly first.
"""
from types import SimpleNamespace
from datetime import date, datetime
from decimal import Decimal

from reportlab.pdfbase import pdfmetrics

from app.core import print_forms as pf


def test_bundled_cyrillic_font_is_registered():
    pf._register_fonts()
    # Not the Helvetica fallback — the bundled DejaVu (registered as CardFont).
    assert pf.FONT == "CardFont"
    assert pf.FONT_BOLD == "CardFont-Bold"


def test_font_covers_cyrillic_and_receipt_symbols():
    pf._register_fonts()
    face = pdfmetrics.getFont("CardFont").face
    # Russian + Uzbek Cyrillic and every non-ASCII glyph the receipt draws
    # (warning sign, true minus, multiplication sign, bullet, guillemets, degree).
    for ch in "АячёҳўқғЎ⚠−×•«»°":
        assert ord(ch) in face.charToGlyph, f"missing glyph: {ch!r}"


def test_receipt_renders_with_emergency_discount_and_ticket():
    item = SimpleNamespace(
        service_name="Консультация офтальмолога",
        quantity=2,
        total=Decimal("300000"),
    )
    patient = SimpleNamespace(
        patient_no="P-00000007", mrn="MRN7", full_name="Иванов Иван Иванович"
    )
    visit = SimpleNamespace(
        patient=patient,
        visit_no="V-0042",
        priority=1,
        priority_reason="Травма глаза",
        items=[item],
        total_amount=Decimal("300000"),
        discount_value=Decimal("30000"),
        discount_reason="Пенсионер",
        payable=Decimal("270000"),
        balance=Decimal("0"),
    )
    payment = SimpleNamespace(
        receipt_no="R-0042",
        created_at=datetime(2026, 6, 16, 14, 30),
        method="cash",
        amount=Decimal("270000"),
    )
    pdf = pf.build_receipt_pdf(payment, visit, queue_ticket_number="D-001")
    assert pdf[:5] == b"%PDF-"
    assert len(pdf) > 1000


def _rx_exam(*, with_refraction: bool = True):
    patient = SimpleNamespace(
        full_name="Иванов Иван Иванович",
        birth_date=date(1990, 1, 1),
    )
    visit = SimpleNamespace(visit_no="V-0042")
    doctor = SimpleNamespace(full_name="Петров Пётр Петрович")
    return SimpleNamespace(
        patient=patient,
        visit=visit,
        doctor=doctor,
        exam_date=date(2026, 6, 12),
        od_sph=Decimal("-1.25") if with_refraction else None,
        od_cyl=Decimal("-0.50") if with_refraction else None,
        od_axis=170 if with_refraction else None,
        os_sph=Decimal("-1.00") if with_refraction else None,
        os_cyl=Decimal("-0.25") if with_refraction else None,
        os_axis=10 if with_refraction else None,
        diagnosis="Миопия слабой степени OU",
        icd10="H52.1",
        recommendations="очковая коррекция, повторный осмотр через 6 мес.",
    )


def test_prescription_renders_with_refraction():
    pdf = pf.build_prescription_pdf(_rx_exam(with_refraction=True))
    assert pdf[:5] == b"%PDF-"
    assert len(pdf) > 1000


def test_prescription_renders_without_refraction():
    # Glasses block omitted but the document still renders (назначения only).
    pdf = pf.build_prescription_pdf(_rx_exam(with_refraction=False))
    assert pdf[:5] == b"%PDF-"
    assert len(pdf) > 1000


def test_prescription_uses_cyrillic_font():
    # Regression guard: the prescription must use the bundled CardFont, not the
    # Cyrillic-blind Helvetica fallback (otherwise every «Рецепт» prints as tofu).
    pf._register_fonts()
    assert pf.FONT == "CardFont"
    assert pf.FONT_BOLD == "CardFont-Bold"
