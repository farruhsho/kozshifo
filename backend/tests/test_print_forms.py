"""Guards the receipt/print-form font so Cyrillic never regresses to tofu.

The bug we lock out: reportlab's built-in Helvetica has no Cyrillic glyphs, so on
a host without a system font (Docker slim / Cloud Run) every Cyrillic character
printed as a black .notdef box. We now bundle DejaVuSans under
``app/assets/fonts`` and register it first; if that ever breaks, FONT silently
falls back to Helvetica and receipts tofu again — these tests fail loudly first.
"""
from types import SimpleNamespace
from datetime import datetime
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
