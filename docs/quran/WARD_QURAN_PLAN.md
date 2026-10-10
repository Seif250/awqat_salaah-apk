# Ward — Offline Quran Experience: Audit & Implementation Plan

Status: **Proposal for review. No application code, assets, or stored data were changed.**
Base commit audited: `3f870b9` (branch `main`).

Legend used throughout:

- **[V]** Verified: read in the code or checked with a script against the bundled assets.
- **[A]** Assumption: not verified; needs a device test or outside research.
- **[R]** Needs research (external resource, licence, or Golden Quran behaviour that can't be inspected here).

Nothing here was measured on a device. No Flutter SDK was available in the audit environment, so the
test suite wasn't run. Performance statements are based on reading the code, not on profiling.

---

## 0. Executive summary

Ward already has more Quran infrastructure than a typical app. The most valuable piece is the
**complete, word-level King Fahd (QCF V2) page layout for all 604 pages, bundled in the APK** (15 MB,
77,429 words, every one of the 6,236 ayat mapped to its page and line) [V]. A working Mushaf reader,
rich bookmarks with colour/notes/collections, multi-ayah selection, a share-image composer, a Tafsir
screen and a khatmah tracker are all present.

The five problems that stand between the current app and the experience you want:

1. **The Mushaf is not offline.** The glyph fonts that the page layout needs (one font per page,
   V2 and Tajweed V4) are downloaded at runtime from `verses.quran.foundation`. On a fresh install
   without internet, every page shows "تعذر تحميل خط مصحف التجويد" [V].
2. **Runaway background downloads.** Three prefetch routines call themselves recursively and, once a
   reader opens, walk through all 604 pages: ~604 V2 fonts, ~604 V4 fonts and ~604 page PNGs that are
   **never displayed**. Every font is also registered in memory [V by code reading; data volume and
   memory are not measured].
3. **Tafsir is online-only.** It comes from `api.quran.com`, one ayah at a time, cached in
   SharedPreferences [V]. Nothing is bundled.
4. **No Quran text search.** Search covers surah names only (plus a search over your bookmarks) [V].
5. **Personal data is in SharedPreferences JSON blobs and not in the backup.** Bookmarks, collections,
   notes and last-read are in JSON strings that are rewritten in full on every change. The existing
   "Ward backup" exports custom adhkar only [V].

Recommended order: fix offline fonts and the prefetch cascade first (correctness and data cost), then
move personal data to a local SQLite database with a safe one-way migration, then build search,
tags/notes, offline Tafsir, and the reader UX polish on top of that.

---

## 1. Current Quran architecture [V]

```
lib/features/quran/
├── data/
│   ├── models/          ayah, surah, mushaf_page (legacy), qcf_page (word layout),
│   │                    bookmark, bookmark_collection, last_read, tafsir, quran_display_mode
│   └── repositories/
│       ├── quran_repository.dart   ← quran.json + all settings + bookmarks (SharedPreferences)
│       └── tafsir_repository.dart  ← api.quran.com v4 + per-ayah SharedPreferences cache
├── services/
│   ├── qcf_layout_service.dart     ← loads assets/data/qcf_pages/page-NNN.json
│   ├── qcf_font_service.dart       ← downloads + FontLoader-registers per-page fonts
│   ├── mushaf_image_service.dart   ← downloads page PNGs (result unused)
│   └── daily_ayah_service.dart     ← 30 hard-coded ayat (own text copy)
└── presentation/
    ├── bloc/                       ← one QuranBloc for everything
    ├── pages/
    │   ├── quran_page.dart         ← index: surahs / juz / bookmarks tabs
    │   ├── surah_detail_page.dart  ← the reader (3,343 lines, many sheets inline)
    │   ├── bookmarks_page.dart     ← all / collections / recent / search
    │   └── tafsir_screen.dart
    └── widgets/
        ├── quran_page_renderer.dart    ← QCF page painter (15-line grid, frame, banners)
        ├── qcf_mushaf_page_renderer.dart (wrapper)
        ├── bookmark_collection_dialog.dart
        ├── quran_share_composer_dialog.dart + share/* (image layout engine)
        └── juz_list_view, surah_card, quran_last_read_card, settings sheet …
```

### Data sources bundled in the APK [V]

| Asset | Content | Checked |
|---|---|---|
| `assets/data/quran.json` (~1.5 MB) | 114 surahs, 6,236 ayat; per-ayah `text`, `page`, `juz`, `sajda` | 6,236 ayat; 604 pages; 15 sajda flags |
| `assets/data/surahs_meta.json` | name, type, ayah count, start page, juz | — |
| `assets/data/qcf_pages/page-001…604.json` (15 MB) | 15 lines/page; each word has `location` (s:a:w), Uthmani `word`, `qpcV2`/`qpcV1` glyph codes | 604 files; 77,429 words; all 6,236 ayat present; **0 page mismatches** with quran.json |
| `assets/fonts/UthmanicHafs.otf`, `AmiriQuran-Regular.ttf` | Unicode Quran fonts (fallback / share) | — |

### Data that is NOT bundled [V]

| Resource | Source today | Effect offline |
|---|---|---|
| QCF V2 page fonts (604) | `verses.quran.foundation/fonts/quran/hafs/v2/ttf/pN.ttf` | not used by the reader today, which is fixed to Tajweed |
| QCF Tajweed V4 COLRv1 fonts (604) | `…/v4/colrv1/ttf/pN.ttf` | **page can't render** until it is downloaded once |
| Page PNG images (604) | `files.quran.app/hafs/madani/width_1260` | downloaded but never shown |
| Tafsir text | `api.quran.com/api/v4/tafsirs/{id}/by_ayah/{key}` | error unless that exact ayah+tafsir was opened before |
| Tafsir catalogue | same API, falls back to 7 hard-coded books | works (fallback list) |

### Rendering path [V]

`SurahDetailPage` → `PageView(604)` → `QcfLayoutService.loadPage` → `QuranPageRenderer`.
Each line is a `Text.rich` of word spans that use the page font family (`QCF_V4_P{n}`) with the
`qpcV2` codepoint, measured with `TextPainter`, scaled to fit and justified with `wordSpacing`.
If the page model can't load, a legacy Unicode reflow renderer (`_buildLegacyMushafPage`) is used.
`QuranRepository.getQuranDisplayMode()` **always returns Tajweed**, so the V2 monochrome path is
never shown.

### Persistence [V]

All in `SharedPreferences`:

| Key | Content |
|---|---|
| `quran_last_read` | one JSON object (single position) |
| `quran_rich_bookmarks` | JSON array of BookmarkModel (colour, note, collectionIds) |
| `quran_bookmarks` | legacy string list, mirrored on every write |
| `quran_bookmark_collections` | JSON array (5 defaults when empty) |
| `khatmah_checkpoint_page`, `khatmah_target_days`, `khatmah_start_date` | khatmah tracker |
| `mushaf_reading_theme`, `quran_ayah_highlight_color`, `mushaf_font_weight_int`, `quran_font_size`, … | reader prefs |
| `tafsir:{resourceId}:{s:a}` | **one key per cached tafsir entry** |

---

## 2. Feature classification

Status codes: ✅ working · 🟡 works, needs improvement · 🟠 partial · ❌ missing · 📦 depends on unavailable data/assets · 🔍 needs investigation

### 2.1 Main reading experience

| Feature | Status | Notes |
|---|---|---|
| 114 surahs / 604 pages | ✅ [V] | data is complete and consistent |
| Traditional page layout (15 lines, word positions) | 🟡 [V] | pages 1–2 have 8 lines (correct). **Pages 586 and 590 have only 12 lines and no surah-header/basmala rows** for at-Takwir and al-Buruj; needs checking against the printed Mushaf 🔍 |
| Accurate text & diacritics | 🟡 | QCF glyphs are authoritative [V]. The share/copy/sheet text comes from `quran.json` (a different Uthmani encoding, using U+06E1) rendered with the KFGQPC `UthmanicHafs` font; glyph compatibility is not verified 🔍 [A] |
| Typography | 🟡 [V] | `fontFamily: 'Amiri'` is used in 14 places (page header, footer, banners) but **no `Amiri` font is declared or bundled**, so these fall back to the system font. A user-selectable `fontWeight` (400/500/700) is applied to QCF glyph fonts, which makes Flutter synthesise bold glyphs: it alters the calligraphy ⚠ |
| Page navigation (swipe) | ✅ [V] | `PageView`, RTL behaviour to verify on device [A] |
| Surah / Juz / page jump | ✅ [V] | quick-index sheet (3 tabs) |
| Jump to a specific ayah | 🟠 [V] | possible from bookmarks and initial route; no "go to s:a" input |
| Surah / Juz / page info | 🟡 [V] | **Hizb is wrong**: `hizb = ((page-1)/10)+1` is an approximation, not the real hizb boundaries. The juz list uses `juz*2`, which is right for the juz but has no rub' (quarter) data |
| Phone & tablet | 🟠 [A] | single portrait page; no landscape/two-page spread for tablets |
| Distraction-free mode | 🟠 [V] | `toggleControls()` exists, but page tap deliberately keeps the bar visible ("Top bar remains persistently visible") |
| Resume last read | ✅ [V] | single position saved on every page change |
| Last-read shortcut | ✅ [V] | card on index page |

### 2.2 Offline

| Feature | Status | Notes |
|---|---|---|
| Read full Quran offline | 📦❌ [V] | blocked by runtime font download (see §0) |
| Navigate, browse surah/juz | ✅ [V] | metadata is bundled |
| Search Quran text | ❌ [V] | |
| Bookmarks / tags / notes / progress | ✅ [V] | local |
| Tafsir offline | 📦❌ [V] | only ayat already viewed online |
| Copy text | ✅ [V] | from bundled text |
| Share image | 🟡 [V] | renders with bundled `UthmanicHafs`, works offline |

### 2.3 Tags & organisation

The existing **"collections"** already are tags in all but name: many-to-many between ayah and
collection, with a name and a colour [V].

| Feature | Status | Notes |
|---|---|---|
| Create tag | ✅ [V] | `SaveBookmarkCollectionEvent` |
| Rename tag | 🟠 [V] | the repository supports it (`saveCollection` upserts), but no rename UI was found in the code |
| Delete tag | ✅ [V] | removes references from bookmarks |
| Tag colour | ✅ [V] | hex string |
| Several tags per ayah | ✅ [V] | `collectionIds` list |
| Tag many ayat at once | ✅ [V] | `BookmarkMultipleAyatEvent` |
| Browse ayat by tag | ✅ [V] | "المجموعات" tab |
| Search tags | 🟠 [V] | bookmark search exists; tag-name search to confirm 🔍 |
| Remove tag from ayah | ✅ [V] | `RemoveAyahFromCollectionEvent` |
| Tag without bookmarking | ❌ [V] | **design coupling**: tagging an ayah *creates a bookmark*. A tag is stored inside a bookmark record, so removing the bookmark silently removes its tags |
| Dedicated tag manager screen | 🟠 | partly in bookmarks page / dialog |

### 2.4 Bookmarks

| Feature | Status | Notes |
|---|---|---|
| Bookmark ayah, multiple, remove, persist | ✅ [V] | |
| Custom name | ❌ [V] | only `note`; no title field |
| Bookmark indicator on page | ✅ [V] | tinted word background + ribbon colour in app bar |
| History vs. bookmarks | 🟠 [V] | only one last-read slot; no history list |
| Several saved reading positions | 🟠 [V] | the "ribbon" picker exists; its relation to ayah bookmarks to verify 🔍 |
| Bookmark + tag | ✅ [V] (coupled, see above) | |

### 2.5 Tafsir

| Feature | Status | Notes |
|---|---|---|
| Open for ayah, correct reference | ✅ [V] | |
| Several books & switching | ✅ online [V] | 7 Arabic books listed (Muyassar, Sa'di, Ibn Kathir, Baghawi, Tabari, Qurtubi, Wasit) |
| Next / previous ayah | ❌ [V] | |
| Offline | 📦❌ [V] | |
| Attribution | 🟡 [V] | name + author shown; no source/licence line |
| Return to same reading position | ✅ [V] | it is a pushed route |
| No AI-generated content | ✅ [V] | all text comes from the API |

### 2.6–2.7 Ayah interactions & multi-selection

| Feature | Status | Notes |
|---|---|---|
| Select ayah, action sheet | ✅ [V] | **long-press** opens the sheet; single tap does nothing (by design comment) |
| Tafsir / bookmark / tag / copy / share | ✅ [V] | |
| Multi-select, contiguous range | ✅ [V] | adding an ayah in the same surah fills the range |
| Cross-surah selection | 🟡 [V] | allowed, but **share uses only the first surah id and the min/max ayah numbers** → wrong range when selection spans two surahs |
| No partial ayat | ✅ [V] | hit-testing is per word, mapped to whole ayah |
| Hit accuracy across scales | 🟡 [A] | per-word `TextSpan` recognisers; reliable in principle; needs device tests on small/large screens |
| Recogniser lifecycle | 🟡 [V] | a new `AyahGestureRecognizer` is created for every word on every build and never disposed |

### 2.8 Search

| Feature | Status |
|---|---|
| Surah name/number | ✅ [V] |
| Ayah text search, highlighting, open result in Mushaf | ❌ [V] |
| Bookmark search | ✅ [V] |
| Tag / note search | 🟠 [V] |
| Arabic normalisation helper | 🟡 [V] `_normalizeArabic` exists (tashkeel, alef forms, ة/ى) but doesn't strip Quranic marks (U+06D6–U+06ED, U+0671 ٱ is handled) or tatweel |

### 2.9 Copy & share

| Feature | Status | Notes |
|---|---|---|
| Copy one / many with references | ✅ [V] | |
| Share as text | ✅ [V] | |
| Share as image (dedicated composer, multi-page for long ranges) | ✅ [V] | captured with `pixelRatio: 1.0` from the on-screen preview → output resolution depends on the preview size, not a fixed export size 🟡 |
| Device-independent image | 🟡 [V] | see above |
| Cross-surah share | 🟠 [V] | single surah only |

### 2.10 Notes

| Feature | Status | Notes |
|---|---|---|
| Note per ayah, edit, delete | 🟠 [V] | single `note` string on a bookmark ("تدبر"); requires a bookmark |
| Browse ayat with notes, search notes | 🟠 [A] | partially via bookmark search 🔍 |
| Clearly separated from Quran text | ✅ [V] | separate storage |

### 2.11 Progress & memorisation

| Feature | Status | Notes |
|---|---|---|
| Last read | ✅ [V] | |
| Reading history | ❌ [V] | |
| Khatmah plan (30/60/90 days, checkpoint) | ✅ [V] | |
| Progress per surah/juz | ❌ |
| Memorisation marking | 🟠 [V] | only a default "الحفظ والمراجعة" collection |
| Dedicated memorisation position | ❌ |

### 2.12–2.13 Settings, Tajweed, render modes

| Feature | Status | Notes |
|---|---|---|
| Paper themes (ivory/sepia/night) | ✅ [V] | night = light text on dark; with Tajweed COLR fonts, colour contrast on dark paper needs a check 🔍 |
| Tajweed colours | 📦 [V] | from official QCF V4 COLRv1 fonts (not invented) ✅. **COLRv1 rendering on old Android / Impeller** not verified 🔍 [A] |
| Normal (monochrome V2) mode | 🟠 [V] | implemented but force-disabled in the repository |
| Font weight option | ⚠ [V] | synthetic bold on QCF glyphs; should be removed or limited to UI text |
| Font size | 🟡 [V] | used by legacy reflow only; QCF page scales to the screen |

### 2.14 Storage & backup

| Feature | Status |
|---|---|
| Persists across restarts | ✅ [V] |
| Safe migrations | 🟡 [V] legacy→rich bookmark migration exists, but it runs on *read* and uses `DateTime.now()` timestamps |
| Backup / restore of Quran data | ❌ [V] `WardBackup` v1 holds `customAdhkar` + settings only |
| Export / import | ❌ for Quran data |

---

## 3. Bugs and risks found during the audit [V unless marked]

| # | Severity | Finding | Location |
|---|---|---|---|
| B1 | High | Fonts not bundled → reader unusable offline on first use | `qcf_font_service.dart` |
| B2 | High | Recursive prefetch: `_prefetchAdjacent → ensurePageFont → _prefetchAdjacent …` walks all 604 pages in both directions, for V2 and V4; `QcfLayoutService` does the same for layouts and also starts V2 font loading | `qcf_font_service.dart`, `qcf_layout_service.dart` |
| B3 | High | `MushafImageService` downloads 1260-px PNG pages with the same recursive prefetch, but nothing displays them | `mushaf_image_service.dart`, `surah_detail_page.dart:2600` |
| B4 | Medium | Every loaded page font stays registered for the process lifetime (no unload API in Flutter) → memory grows with B2 [A: size not measured] | font service |
| B5 | Medium | Hizb number shown in the header is `page/10`, not the real hizb | `quran_repository.dart` `_buildPagesCache` |
| B6 | Medium | `'Amiri'` font family used but not bundled | renderer, 14 uses |
| B7 | Medium | Synthetic bold applied to QCF glyph fonts | `fontWeight` in renderer |
| B8 | Medium | Pages 586 & 590 lack surah-header and basmala rows 🔍 | `assets/data/qcf_pages` |
| B9 | Medium | Cross-surah selection is shared as a wrong single-surah range | `_shareSelectedAyat` |
| B10 | Low | Tafsir cache = one SharedPreferences key per ayah per book. SharedPreferences loads the whole file into memory at startup, so this grows startup time and memory with use | `tafsir_repository.dart` |
| B11 | Low | Bookmark list is re-decoded from JSON on every call (`getRichBookmarks` is called several times per event) | repository/bloc |
| B12 | Low | Gesture recognisers never disposed | renderer |
| B13 | Low | Legacy renderer highlight compares with `widget.surah.id` instead of `_highlightedSurahId` | `_buildAyahSpans` |
| B14 | Info | `DailyAyahService` holds its own hand-typed copy of 30 ayat (simple-script text) instead of reading the bundled Quran | `daily_ayah_service.dart` |

---

## 4. Target architecture

```
                ┌────────────────────────── bundled, read-only ──────────────────────────┐
                │ quran.db (SQLite, read-only asset)                                      │
                │   ayah(s,a,page,juz,hizb,rub,sajda,text_uthmani,text_search)            │
                │   word(page,line,pos,s,a,w,glyph_v2,glyph_v4?)  ← from qcf_pages json   │
                │   surah, juz, hizb, rub, page meta                                       │
                │   ayah_fts (FTS over text_search)                                        │
                │ fonts: QCF V4 (Tajweed) + V2, bundled or one-time download pack          │
                │ tafsir_muyassar.db (bundled) — others as downloadable packs              │
                └─────────────────────────────────────────────────────────────────────────┘
                ┌────────────────────────── user data, read-write ───────────────────────┐
                │ ward_user.db (SQLite, versioned migrations)                              │
                │   bookmark(id, s, a, title, color, created, updated)                     │
                │   tag(id, name, color, created, updated)                                 │
                │   ayah_tag(s, a, tag_id)          ← independent of bookmarks             │
                │   note(id, s, a, body, created, updated)                                 │
                │   reading_position(kind: last|memorisation|custom, s, a, page, ts)       │
                │   reading_history(page, s, a, ts)  (capped)                              │
                │   khatmah(...)                                                           │
                └─────────────────────────────────────────────────────────────────────────┘
```

Why SQLite: indexed lookups, FTS for search, atomic transactions, real schema migrations, and no
full-file rewrite on every change. Candidate packages: `sqflite` (or `drift` for typed queries and
migration tests) [R: final choice to confirm against minSdk and APK size].

Repositories stay behind the existing `QuranRepository` / `TafsirRepository` interfaces so the UI
can move gradually. The single `QuranBloc` is split by concern (reader, library, search, tafsir)
as each area is rebuilt.

---

## 5. Implementation plan (recommended order)

Each phase is a separate PR, mergeable on its own, with tests.

### Phase 1 — Offline Mushaf & stop the runaway downloads (highest priority)

1. Replace recursive prefetch with a bounded window (current ±2 pages), with no recursion, in
   `QcfFontService` and `QcfLayoutService`.
2. Remove `MushafImageService` usage (it is unused output), or keep it behind a flag if an image
   mode is wanted later.
3. Fonts offline. Two options, decided by the licence check in §11 and APK size:
   - **A. Bundle** V4 Tajweed fonts (and V2 if the monochrome mode is enabled) as assets
     [A: total size unknown, to measure; estimated tens of MB].
   - **B. One-time "Download Mushaf for offline use"** pack with progress, checksum verification,
     resume and a storage indicator; the reader stays usable for downloaded pages.
   Recommendation: B for the APK size, with A as the default if the size is acceptable.
4. Load fonts from disk/assets on demand and keep a small LRU of registered families
   [A: Flutter can't unregister fonts; measure memory with 604 registered families before deciding].
5. Fix `Amiri` (bundle it or switch to a bundled font), remove synthetic bold on QCF glyphs, fix
   hizb/rub' using a real table.
6. Investigate pages 586/590 against the printed Madinah Mushaf and the upstream QPC layout source.

### Phase 2 — Local database & safe migration

1. Add `ward_user.db` with schema v1 (tables in §4).
2. One-time, idempotent migration from SharedPreferences:
   - read `quran_rich_bookmarks` (fall back to `quran_bookmarks`), `quran_bookmark_collections`,
     `quran_last_read`, `khatmah_*`;
   - collections → `tag`; `collectionIds` → `ayah_tag`; `note` → `note`; bookmark → `bookmark`;
   - write inside one transaction, record `migration_done_v1`, and **do not delete** the old keys
     for at least one release (rollback safety);
   - log counts before and after; abort and keep using the old storage if they differ.
3. Move the Tafsir cache out of SharedPreferences into a table, then delete the `tafsir:*` keys
   (cache only, safe to drop).
4. Build the bundled read-only `quran.db` from the existing JSON with a reproducible script in
   `tool/` (no hand edits to text), and add the real hizb/rub' table.

### Phase 3 — Bookmarks, tags, notes as separate features

- Tags independent of bookmarks (tag an ayah without bookmarking it).
- Bookmark title; several named positions; distinct "memorisation position".
- Tag manager screen: create, rename, recolour, delete (with confirmation and a count), search.
- Notes: separate entity, several per ayah allowed or one per ayah (decision for you), list, search.
- "Library" screen with tabs: bookmarks · tags · notes · history.
- Small indicators on the page (bookmark ribbon / note dot) without adding permanent controls.

### Phase 4 — Offline search

- FTS index over a normalised copy of the text (`text_search`), never over the displayed text.
- Normalisation: remove harakat and Quranic annotation marks (U+0610–U+061A, U+064B–U+065F, U+0670,
  U+06D6–U+06ED), tatweel; unify alef forms (أإآٱ→ا), ى/ي, ة/ه, hamza seats (configurable).
- Results show surah:ayah and page, highlight the match, and open the Mushaf on the right page
  with the ayah highlighted.
- Same search box covers tags, notes and bookmarks (separate result groups).
- Direct jump syntax: `2:255`, page number, surah name.

### Phase 5 — Tafsir

- Bundle one short tafsir (Al-Muyassar is the best candidate for size) as a read-only DB
  [R: licence and source file; must come from a trusted dataset, imported by script, unedited].
- Other books: downloadable packs (whole book), with size shown before download, plus attribution
  and source on the screen.
- Next/previous ayah inside the Tafsir screen; keep the reader position on return (already true).
- If a book isn't downloaded and you're offline: clear message plus a download action, never empty
  or invented text.

### Phase 6 — Reader UX polish (Golden-Quran-like)

- Tap toggles bars (true distraction-free mode); long-press selects; drag to extend the selection.
- Ayah action sheet: compact, primary actions first (Tafsir, bookmark, tag, note, copy, share).
- Multi-selection: range handles; correct cross-surah copy/share (split per surah with references).
- Tablet: landscape two-page spread (pages paired correctly, right page = odd).
- Juz/hizb/rub' indicators in the header; rub' markers in the margin if the data supports it [R].
- Night theme verified with Tajweed colours; Ward palette (ivory, forest green, sage, antique gold).

### Phase 7 — Share image

- Off-screen rendering at a fixed export size (e.g. 1080 px wide) with a fixed pixel ratio,
  independent of the device.
- Option to render with the QCF page fonts (exact Mushaf glyphs) instead of Unicode text, when the
  fonts are available offline 🔍.
- Long selections split across images at ayah boundaries (existing engine reused).

### Phase 8 — Progress, history & backup

- Reading history (capped, e.g. the last 200 entries), progress per juz/surah derived from history.
- Memorisation: a dedicated tag + memorisation position; no gamification.
- Extend `WardBackup` to **v2** with a `quran` section (bookmarks, tags, ayah_tags, notes,
  positions, khatmah, reader prefs). v1 files must still import. Preview before import, merge vs.
  replace option, and no import without confirmation.

---

## 6. Files and modules likely affected

| Area | Files |
|---|---|
| Fonts / prefetch | `services/qcf_font_service.dart`, `services/qcf_layout_service.dart`, `services/mushaf_image_service.dart`, `pubspec.yaml` (assets, fonts) |
| Rendering | `widgets/quran_page_renderer.dart`, `widgets/qcf_mushaf_page_renderer.dart`, `pages/surah_detail_page.dart` (split into reader + sheets) |
| Data | `data/repositories/quran_repository.dart`, `tafsir_repository.dart`, new `data/db/*`, new `tool/build_quran_db.dart` |
| Models | `bookmark_model.dart`, `bookmark_collection_model.dart` (→ tag), new `note_model.dart`, `reading_position_model.dart` |
| State | `presentation/bloc/*` (split) |
| Screens | `pages/quran_page.dart`, `pages/bookmarks_page.dart` (→ library), `pages/tafsir_screen.dart`, new search and tag-manager pages |
| Share | `widgets/quran_share_composer_dialog.dart`, `widgets/share/*` |
| Backup | `features/azkar/data/models/ward_backup_model.dart`, `services/backup_service.dart` (better moved to `core/backup`) |
| Tests | `test/quran_*` (update), new migration, search, normalisation and integrity tests |

---

## 7. Database & migration considerations

- Never delete the old SharedPreferences keys in the same release that migrates them.
- Migration is idempotent (`migration_done_v1` flag plus count check) and runs before the bloc loads.
- Keys stay `surah:ayah` (stable across text encodings); never key personal data on a page number
  or word index.
- `bookmark.id` today is `"s:a"`; keep it for compatibility.
- Schema versions with forward migrations only; each migration has a unit test with a snapshot of
  real v1 data.
- Default collections (`fav`, `patience`, `dua`, `hifz`, `important`) become normal user tags; they
  aren't recreated if the user deletes them.

## 8. Offline storage & assets

| Item | Size | Status |
|---|---|---|
| QCF layout JSON (existing) | 15 MB [V] | could shrink a lot as SQLite or compressed [A] |
| quran.json | ~1.5 MB [V] | |
| V4 Tajweed fonts ×604 | unknown [R] | measure before choosing bundle vs. download |
| V2 fonts ×604 | unknown [R] | only if the monochrome mode is enabled |
| Tafsir Muyassar | unknown [R] | bundle candidate |
| Larger tafsirs (Ibn Kathir, Tabari, Qurtubi) | large [A] | download only |

## 9. Performance considerations

- Remove B2/B3: the largest CPU, network, battery and memory cost found [V by code, not measured].
- Load one page's layout and font at a time, with a ±2 window.
- Avoid re-measuring every line with `TextPainter` on each rebuild: cache the computed font size
  and word spacing per (page, line, viewport width).
- Precompute bookmark/tag lookups as `Set<String>` once per state, not a linear scan per word.
- Search on a background isolate, debounced; FTS keeps it fast on old devices [A].
- Measure on a low-end Android device (2–3 GB RAM): cold start, page swipe frame times
  (`flutter run --profile` + DevTools), memory after reading 50 pages, search latency, image export
  time. Record the numbers in the PR; no claims without them.

## 10. Testing & validation

- **Quran integrity tests** (automated): 114 surahs, 6,236 ayat, 604 pages, every ayah on exactly one
  page, word order per ayah continuous, page/juz agreement between data sources, the 15 sajdat, and a
  checksum of the display text so any accidental edit fails CI.
- Layout tests: 15 lines on every page except 1–2 (and the 586/590 decision), each line fits the
  reading width at the smallest supported screen.
- Normalisation tests: search finds `الرحمن` in `ٱلرَّحۡمَٰنِ`, and the displayed text is never altered.
- Migration tests from real SharedPreferences snapshots (legacy only, rich only, both, corrupted JSON).
- Backup round-trip (v1 still imports, v2 full round-trip).
- Golden image tests for the share renderer at a fixed size.
- Manual device checklist: offline first run (airplane mode), tablet landscape, dark theme +
  Tajweed, small phone (360 dp), RTL swipe direction.

## 11. Risks to Quranic accuracy

| Risk | Mitigation |
|---|---|
| Two different text encodings (QCF word text vs `quran.json`) | Pick one authoritative Unicode source for copy/share/search, document it, add a checksum test |
| Unicode text rendered with a font made for another encoding (`UthmanicHafs` + U+06E1 text) | Verify with a sample of difficult ayat; switch to the matching text or font 🔍 |
| Missing header/basmala rows (pages 586/590) | Verify against the printed Mushaf before shipping |
| Synthetic bold on QCF glyphs | Remove |
| Fallback renderer silently replaces the Mushaf font | Keep an explicit "fonts not downloaded" state; don't silently mix fonts on a page |
| Hand-typed text (`DailyAyahService`) | Read the ayah from the bundled data by `s:a` |
| Tafsir mismatch (wrong ayah) | Key strictly by `s:a`; integrity test on imported packs |
| AI content | None used; all content comes from imported datasets |

## 12. Features that depend on external resources [R]

1. QCF V2/V4 fonts. Source: Quran Foundation / KFGQPC. **Licence terms for redistribution inside an
   APK must be confirmed** before bundling.
2. Tafsir datasets (Muyassar, Sa'di, Ibn Kathir, …): a trusted downloadable source and its licence.
3. Hizb / rub' boundaries: a trusted metadata table (e.g. Tanzil metadata) [R: licence].
4. Golden Quran behaviour: it can't be inspected from here. The parity items above (page-faithful
   Mushaf, tap-to-hide bars, long-press actions, tafsir, bookmarks, search, khatmah, colour tags)
   describe common Mushaf-app behaviour and need checking against the real app on a device.
5. Audio recitation: not in your list, so not in this plan.

## 13. How the result approaches Golden Quran

| Golden-Quran-like quality | How Ward gets there |
|---|---|
| Faithful Madinah page | Existing word-level QCF layout + offline fonts + bug fixes (B5–B8) |
| Works with no internet | Phase 1 + bundled DB + Tafsir packs |
| Quiet reading screen | Tap toggles bars; no permanent controls |
| Fast ayah actions | Long-press sheet, range selection, cross-surah correct |
| Personal organisation | Bookmarks, independent colour tags, notes, positions |
| Study | Tafsir with next/previous, multiple books, attribution |
| Find anything | Offline FTS with normalisation + jump syntax |
| Data safety | SQLite with tested migrations + backup v2 |

---

## 14. Decisions needed from you

1. Fonts: **bundle in the APK** or **one-time download pack**?
2. Enable the monochrome (V2) Mushaf mode next to Tajweed, or Tajweed only?
3. Which Tafsir to bundle by default (suggested: Al-Muyassar), and which as downloads?
4. Notes: one note per ayah, or several?
5. Database package: `sqflite` (simpler) or `drift` (typed, easier migration tests)?
6. Tablet two-page spread: in scope now or later?

Once you approve the plan (fully or in part), implementation starts with Phase 1.
