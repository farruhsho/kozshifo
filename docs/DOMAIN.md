# Clinical domain — ground truth (KO'Z SHIFO)

Real-world data captured from the clinic. **This is authoritative** — models,
seed data, and print templates must match it. Source: physical device nameplates
and the clinic's official paper patient card (photos, 2026-06).

---

## 1. Medical devices currently in the clinic

These are the **first two `Device` records to seed**, and the first two
integrations to support.

### 1.1 Ophthalmic A/B Ultrasound System
| Field | Value |
|-------|-------|
| Device type | Ophthalmic A/B ultrasound system (A-scan biometry + B-scan imaging) |
| Manufacturer | Chongqing Kanghuaruiming S&T Co., Ltd |
| Manufacturer address | No.5, Road 1, TongJiaXi Industry Park, Beibei, Chongqing, China |
| EU representative | LUXUS LEBENSWELT GMBH — Kochstr. 1, 47877, Willich, Germany |
| Model | **CAS-2000BER** |
| Serial No. | **53789467** *(last digit partly obscured on the plate — verify)* |
| Manufacture date | 2019-03 |
| Power | AC 220V/240V, 50/60 Hz, 300 VA |
| Working model | Intermission (intermittent) movement |
| Safety class | Class I, Type B; CE |
| Clinical output | A-scan biometry (axial length, ACD, lens thickness → IOL calc); B-scan images. Used for the card's **"Кўз A/B-скан текшеруви"**. |

### 1.2 Auto Refractometer
| Field | Value |
|-------|-------|
| Device type | Auto refractometer (objective refraction; many units also do keratometry) |
| Brand / Model | Supore **RMK-700** |
| Manufacturer | Shanghai Supore Instruments Co., Ltd — No.800, Yeji Road, Shanghai, China |
| Voltage / Power | AC 100–240V, 50/60 Hz, 75 VA |
| Serial No. | **2103540749** |
| Asset / inventory code | **CP-RMK-700A00749** (barcode on unit) |
| Useful life | 10 years · www.supore.com · CE |
| Clinical output | Refraction per eye: **SPH / CYL / AXIS** (OD & OS) → feeds the card's `Visus … коррекция билан, sph/cyl/ax`. |

### Device → examination mapping (the integration value)
- **RMK-700 (refractometer)** → auto-fills the **Visus sph/cyl/ax** fields (OD/OS) of the eye exam.
- **CAS-2000BER (A/B ultrasound)** → attaches **B-scan images + A-scan biometry** to the visit ("Кўз A/B-скан текшеруви").

> Integration reality: these are budget instruments that typically **lack DICOM/HL7**.
> Plan for: (1) **manual entry**, (2) **file/image import** (upload or watched folder)
> now; pluggable **protocol adapters** (serial/USB/HL7/DICOM) later. Don't assume DICOM.

---

## 2. Patient card = MoH Form 025-8 "Амбулатор тиббий карта"

The clinic's legal outpatient record. **Republic of Uzbekistan, Ministry of Health,
approved by Order № 777 of 2017-12-25, medical document form № 025-8.**
Header: «KO'Z SHIFO» klinikasi. The system must capture **and be able to print** this card.

### 2.1 Cover — patient identity
| Form label (uz) | Meaning | Maps to |
|-----------------|---------|---------|
| Бемор коди | Patient code | `Patient.mrn` |
| 1. Фамилия | Last name | `last_name` |
| 2. Исми | First name | `first_name` |
| 3. Туғилган сана | Date of birth | `birth_date` |
| 4. Тел. | Phone | `phone` |
| 5. Доимий яшаш жойи | Permanent residence | `address` |
| 6. Иш (ўқиш) жойи | Place of work / study | **new** `workplace` |
| 7.1 Диспансеризация — айнан шу муассасада | Dispensary follow-up in THIS clinic (district № + name) | **new** `dispensary_here` |
| 7.2 Диспансеризация — бошқа муассасада | Dispensary follow-up in ANOTHER org (org name) | **new** `dispensary_other` |

> Note: the official cover has no middle name / gender / email fields. Keep our
> existing optional `middle_name`, `gender`, `email` — superset is fine.

### 2.2 Oculist examination — «ОКУЛИСТ КУРИГИ» (the eye exam record)
Attached to a **Visit**. Fields, in form order:

| Form label (uz) | Meaning | Type |
|-----------------|---------|------|
| Сана | Exam date | date |
| Шикоятлари | Complaints | text |
| Visus OD … ; коррекция билан, sph / cyl / ax | Right-eye VA (uncorrected) + correction | va + sph/cyl/axis |
| Visus OS … ; коррекция билан, sph / cyl / ax | Left-eye VA (uncorrected) + correction | va + sph/cyl/axis |
| Анамнез | Anamnesis / history | text |
| Кўз ички босими: OD / OS | Intraocular pressure (IOP) | numeric per eye |
| Орбита | Orbit | text |
| Кўз олмаси | Eyeball / globe | text |
| Қовоқлар | Eyelids | text |
| Коньюктива | Conjunctiva | text |
| Кўз ёш аъзолари | Lacrimal apparatus | text |
| Шох парда | Cornea | text |
| Олд камера | Anterior chamber | text |
| Рангдор парда | Iris | text |
| Қорачиқ | Pupil | text |
| Гавҳар | Lens (crystalline) | text |
| Шишасимон тана | Vitreous body | text |
| Кўз туби | Fundus | text |
| Кўз A/B-скан текшеруви | A/B-scan exam (links to CAS-2000BER results) | ref + note |

Field-type guidance: VA as string (`"1.0"`, `"0.5"`, `"сч/пальцев"`); SPH/CYL as
`Numeric(4,2)` (0.25 steps, signed); AXIS as int 0–180; IOP as `Numeric(4,1)` mmHg
(or string for `Tn`/palpation). Slit-lamp structures are free text (optionally OD/OS).

### 2.3 Conclusion
| Form label (uz) | Meaning | Type |
|-----------------|---------|------|
| Ташхис | Diagnosis | text (+ optional ICD-10 code) |
| Тавсия | Recommendations / prescription | text |
| Шифокор | Doctor (signature) | `doctor_id` (FK user) |
