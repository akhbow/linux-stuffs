# Profil Web Statis — Dr. Dwi Wahyu Prabowo, S.Si., M.Eng.

Situs profil akademik statis, single-page, dark "Scholar's Distinction" theme
(navy #00132c + gold #ecc246, Playfair Display + Inter). Didesain dari Google
Stitch (export: `stitch_academic_distinction_portfolio_dr_dwp.zip`), lalu
di-reconcile menjadi HTML + CSS self-contained tanpa dependency Tailwind CDN.

## Struktur
```
profil-dr-dwi/
├── index.html          # satu file statis lengkap + JSON-LD Person
└── assets/
    └── profile.jpg      # foto profil (ganti dgn foto resmi bapak bila perlu)
```

## Cara deploy ke GitHub Pages
1. Inisialisasi repo (lakukan di Jarvis/PC atau via akses GitHub bapak):
   ```
   cd "Works - UNDA/linux-stuffs/lenovo/profil-dr-dwi"
   git init
   git add -A
   git commit -m "Profil statis Dr. Dwi — Stitch design + JSON-LD"
   gh repo create profil-dr-dwi --public --source=. --push   # atau remote manual
   ```
2. Di GitHub: Settings → Pages → Source = branch `main` / `master`, folder `/ (root)`.
3. URL: `https://<user>.github.io/profil-dr-dwi/`
4. (Opsional) Custom domain `dwi.unda.ac.id`: Settings → Pages → Custom domain,
   lalu UNDA ICT set DNS CNAME ke `<user>.github.io`. GitHub otomatis issu SSL.

## Yang sudah diperbaiki dari export Stitch
- Tailwind CDN → CSS self-contained (tanpa dependency eksternal kecuali font).
- Link Connect diisi URL asli (Scholar, ORCID, SINTA, Scopus, WoS, LinkedIn, RG).
- Badge sitasi diisi angka nyata dari vault (5 / 57 / 4 / 1) — Stitch awalnya "—".
- Foto dari URL Google → disimpan lokal `assets/profile.jpg`.
- Ditambah JSON-LD `@type: Person` (name, jobTitle, affiliation, alumniOf, sameAs,
  knowsAbout) → kunci agar Google generate Knowledge Panel.

## Catatan
- Font dimuat dari Google Fonts (perlu internet). Bila ingin 100% offline, download
  font & ubah `<link>` jadi `@font-face` lokal.
- Foto saat ini adalah hasil download dari export Stitch; ganti `assets/profile.jpg`
  dgn foto resmi bapak bila diinginkan.
