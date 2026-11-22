# BBMA Oma Ally MTF EA — XAUUSD (Rebuild)

EA MQL5 berbasis strategi **BBMA Oma Ally** dengan konfirmasi multi-timeframe,
khusus **XAUUSD** dan **tanpa scanner**. Timeframe bisa dipilih sendiri dari:
**W1 / D1 / H4 / H1 / M15 / M5**.

> **Penting:** ini bukan hasil decompile file `.ex5` asli (file asli terproteksi).
> Ini implementasi ulang dari aturan strategi yang terdokumentasi di guidebook.
> Selalu uji di **demo / Strategy Tester** sebelum akun riil.

---

## 1. Struktur file

Source dipecah per tanggung jawab supaya mudah dibaca dan dirawat.
Folder `Include/` harus selalu ikut tersalin bersama file `.mq5`.

| File | Isi |
|---|---|
| `BBMA_OmaAlly_MTF.mq5` | Input + event handler (`OnInit`/`OnTick`/`OnTimer`/`OnChartEvent`) + daftar include |
| `Include/BBMA_Types.mqh` | Enum + struct `TFHandles`, `TFAnalysis` |
| `Include/BBMA_State.mqh` | Semua state global (`g_tf`, `g_a`, `g_prepBuy`, ...) + objek `CTrade` |
| `Include/BBMA_Utils.mqh` | Helper teks (`TFToStr`, `TrendStr`, ...), `IsNewBar`, `BufSeries`, `NormalizeLot` |
| `Include/BBMA_Timeframes.mqh` | Registry TF: slot, peran MAJOR/SECOND/THIRD, handle indikator |
| `Include/BBMA_Analysis.mqh` | Deteksi pola BBMA per TF |
| `Include/BBMA_Signals.mqh` | Gabungan TF → PREP/FINAL + teks sinyal |
| `Include/BBMA_Alerts.mqh` | Popup, push, Telegram |
| `Include/BBMA_Trading.mqh` | Entry, lot, SL/TP, close all, aturan exit |
| `Include/BBMA_Risk.mqh` | Batas rugi/target harian, tutup Jumat |
| `Include/BBMA_Dashboard.mqh` | **Dashboard tabel** (mirror gambar referensi): simbol, status per TF (W1–M5), tombol BUY/SELL/CLOSE, Allow, Signals, dan baris Mode + Risk Management di bawah |
| `BBMA_OmaAlly_MTF.ex5` | Hasil kompilasi (0 errors, 0 warnings) |
| `docs/BBMA_LOGIC.md` | **Referensi teknis logika BBMA** (rumus pola, state machine, entry/exit) |
| `README.md` | Panduan ini |

Mau ubah apa → buka file mana:

| Kebutuhan | File |
|---|---|
| Parameter default / tambah input | `BBMA_OmaAlly_MTF.mq5` (blok `input`) |
| Logika pola BBMA (Extreme, MHV, CSM, CSAK, re-entry) | `Include/BBMA_Analysis.mqh` |
| Aturan konfirmasi 2TF/3TF | `Include/BBMA_Signals.mqh` |
| SL/TP, lot, cut-loss, aturan exit | `Include/BBMA_Trading.mqh` |
| Tutup Jumat, limit harian | `Include/BBMA_Risk.mqh` |
| Tampilan panel dan tombol | `Include/BBMA_Dashboard.mqh` |
| Pesan alert / Telegram | `Include/BBMA_Alerts.mqh` |

> Catatan MQL5: variabel `input` hanya boleh dideklarasikan di file `.mq5` utama,
> jadi semua konfigurasi tetap terpusat di `BBMA_OmaAlly_MTF.mq5`.

---

## 2. Cara memasang

1. Restart HFM MT5 (atau Navigator → Expert Advisors → **Refresh**).
2. Buka chart **XAUUSD**.
3. Drag **BBMA_OmaAlly_MTF** ke chart.
4. Aktifkan **Algo Trading** hanya jika ingin auto-entry.

Kalau mengubah source: buka `BBMA_OmaAlly_MTF.mq5` di MetaEditor, tekan **F7**
(Compile). Semua modul di folder `Include/` ikut terkompilasi otomatis.
Pastikan folder `Include/` berada tepat di samping file `.mq5`.

Default = **Semi-Auto**: dashboard + alert + tombol **BUY / SELL / CLOSE ALL**.
EA tidak membuka order sendiri sampai tombol **AUTO** di dashboard dinyalakan.

---

## 3. Memilih Timeframe

Aktifkan TF lewat input:

| Input | Default | Keterangan |
|---|---|---|
| `InpUseD1` | false | Aktifkan 1D |
| `InpUseW1` | false | Aktifkan 1W |
| `InpUseH4` | true | Aktifkan 4H |
| `InpUseH1` | true | Aktifkan 1H |
| `InpUseM15` | true | Aktifkan 15M |
| `InpUseM5` | false | Aktifkan 5M |
| `InpConfirmMode` | 3TF | 2TF atau 3TF |

**Aturan jumlah TF:**

- Mode **2TF** → minimal **2 TF** aktif.
- Mode **3TF** → minimal **3 TF** aktif.

TF ekstra boleh tetap aktif. Semua TF yang ON dianalisis dan tampil di
dashboard, tetapi hanya TF teratas yang masuk rantai konfirmasi:

- mode 2TF → 2 TF tertinggi (MAJOR + SECOND), TF ketiga diabaikan (`g_thirdIdx = -1`).
- mode 3TF → 3 TF tertinggi (MAJOR + SECOND + THIRD).

`CONFIG ERROR` hanya muncul jika TF aktif **kurang** dari kebutuhan mode.

TF yang aktif otomatis diurutkan dari besar ke kecil:

| Posisi | Peran |
|---|---|
| TF tertinggi | **MAJOR** — Re-entry / Full Setup |
| TF tengah | **SECOND** — Re-entry, Extreme, MHV, atau rejection |
| TF terendah | **THIRD** — Extreme, MHV, Re-entry, atau Full Setup |

**Contoh kombinasi:**

| Mode | TF diaktifkan | Major / Second / Third |
|---|---|---|
| 2TF | 4H + 1H | 4H / 1H / — |
| 2TF | 1D + 4H | 1D / 4H / — |
| 2TF | 1H + 15M | 1H / 15M / — |
| 2TF | 4H + 1H + 15M | 4H / 1H / — (15M hanya untuk dashboard) |
| 3TF | 4H + 1H + 15M | 4H / 1H / 15M (default) |
| 3TF | 1D + 4H + 1H | 1D / 4H / 1H |
| 3TF | 1D + 1H + 15M | 1D / 1H / 15M |

Kalau jumlah TF aktif kurang dari kebutuhan mode, EA menulis
`CONFIG ERROR` ke tab Experts dan tidak memberi sinyal/trade.
Contoh: mode 3TF tetapi hanya 2 TF aktif → nyalakan satu TF lagi.

---

## 4. Logika sinyal

### Definisi pola dari guidebook
- **CSAK/CSD**: candle menembus MA5 High dan BB Mid untuk BUY, atau MA10 Low dan BB Mid untuk SELL.
- **CSM**: candle menembus MA5 High dan BB Upper untuk BUY, atau MA10 Low dan BB Lower untuk SELL.
- **Re-entry**: candle menolak MA10 Low (BUY) atau MA5 High (SELL), kemudian candle tertutup berikutnya mengonfirmasi dengan CSAK/CSM searah.
- **Extreme**: MA10 berada di bawah BB Lower untuk BUY atau MA5 berada di atas BB Upper untuk SELL, disertai candle reversal.
- **MHV**: setelah Extreme, harga kembali ke zona MA5/MA10 dan tidak ada CSM berlawanan yang mematahkan extreme.
- **Rejected EMA50**: EMA50 berada di sisi luar BB Mid dan candle menolak EMA50.
- **Gap BB to EMA50**: EMA50 berada di luar BB Lower/Upper dan candle menolak band tersebut.

### Kombinasi multi-timeframe 3TF
Tiga timeframe aktif diurutkan dari tinggi ke rendah dan diperiksa untuk pola guidebook:
- **Full Setup**: Extreme → TPW (sentuh MA5/10) → MHV → Direction → Re-entry.
- **REE**: Re-entry → Extreme → Extreme.
- **RRE**: Re-entry → Re-entry → Extreme.
- **RRM**: Re-entry → Re-entry → MHV.
- **REM**: Re-entry → Extreme → MHV.
- **Diamond Setup**: Re-entry → Rejected EMA50/Gap → Extreme/MHV/Full Setup.

Status pola ditentukan otomatis dari susunan timeframe aktif.

> Rincian rumus tiap pola, urutan bar yang dievaluasi, state machine Full Setup,
> dan semua kondisi entry/exit ada di **[docs/BBMA_LOGIC.md](docs/BBMA_LOGIC.md)**.

### Status
- **PREP BUY/SELL** — 2 TF sudah konfirmasi, menunggu TF ketiga (mode 3TF).
- **FINAL BUY/SELL** — semua konfirmasi sesuai mode terpenuhi.

---

## 5. Input penting lainnya

| Input | Default | Fungsi |
|---|---|---|
| `InpBBPeriod / InpBBDeviation` | 20 / 2.0 | Bollinger Bands |
| `InpFastMA / InpSlowMA` | 5 / 10 | MA High / MA Low |
| `InpTrendEMA` | 50 | EMA trend |
| `InpSetupLookback` | 20 | Batas bar untuk mencari urutan setup |
| `InpFilterHigherTF` | true | Hanya entry searah tren TF di atas MAJOR (close vs EMA50). Contoh: MAJOR 4H → filter 1D |
| `InpAutoTrade` | false | Full auto sejak EA dipasang (sama dengan tombol AUTO). Di Strategy Tester selalu ON |
| `InpLotMode / InpLot / InpRiskPercent` | Fixed / 0.01 / 1% | Lot. Compounding = risk % dari balance berdasarkan jarak SL, dibagi rata ke semua order layering |
| `InpSLATR / InpRR` | 1.5 / 1.5 | SL berbasis ATR MAJOR TF & RR |
| `InpMaxSpread` | 50 pts | Filter spread XAUUSD |
| `InpMaxPositions` | 0 | Batas posisi terbuka (0 = tanpa batas). Tetap hanya 1 basket (1 arah) sekaligus |
| `InpOrderMode` | Single | Order types: Single (SL/TP) / Instant + Limit / Instant + Stop / Instant + Stop + Limit |
| `InpLevels` | 5 | Jumlah pending order per jenis (limit dan/atau stop) |
| `InpDistancePips` | 10 | Jarak antar pending order. 1 pip = 10 point (XAUUSD 2 digit: 10 pip = $1.00) |
| `InpLayerSLTP` | false | Layering: pasang SL/TP juga di setiap order. Default false sesuai guidebook (TP/SL hanya untuk Single) |
| `InpPendingExpiryHours` | 24 | Hapus pending yang belum tersentuh jika tidak ada posisi terbuka |
| `InpCloseMode` | BB | Exit: MA / BB / reverse signal (lihat bagian Exit) |
| `InpCutLossOnCSM` | true | Cut loss CSM + break EMA50 di SECOND TF |
| `InpSessionBufferMin` | 60 | Tidak ada entry otomatis N menit setelah sesi buka & sebelum sesi tutup |
| `InpDailyTargetPct` | 0 | Target harian % (0 = off). Tercapai → close all, stop sampai besok |
| `InpDailyLossPct` | 3% | Batas rugi harian. Tercapai → close all, stop sampai besok |
| `InpFridayClose` | true | Tutup semua posisi & pending menjelang sesi Jumat tutup (fallback `InpFridayHour`) |
| `InpTrailStartPct / InpTrailLockPct` | 0 / 0 | Trailing %: saat floating profit basket ≥ Start % balance, kunci profit; level kunci ikut naik (peak − (Start − Lock)) |

Pemetaan dari preset EA SharpShooter (`xau.set`):

| SharpShooter | EA ini |
|---|---|
| `AlertD1/H4/H1/M15` | `InpUseD1/H4/H1/M15` |
| `OpenPos` (2TF/3TF) | `InpConfirmMode` |
| `FilterHigherTF` | `InpFilterHigherTF` |
| `Compounding / RiskPerTrade / RiskRatio / LotStart` | `InpLotMode / InpRiskPercent / InpRR / InpLot` |
| `OrderTypes2` | `InpOrderMode` (0 Single, 1 +Limit, 2 +Stop, 3 +Stop+Limit) |
| `CloseAtBB` | `InpCloseMode` (0 MA, 1 BB, 2 Reverse) |
| `Levels / base_distance / maxPos` | `InpLevels / InpDistancePips / InpMaxPositions` |
| `Timer` | `InpSessionBufferMin` |
| `DailyTargetPercent / DailyLossPercent / Stop_On_CloseMarket` | `InpDailyTargetPct / InpDailyLossPct / InpFridayClose` |
| `StartTrailPerc / ProfitToLock` | `InpTrailStartPct / InpTrailLockPct` |

### Dashboard tabel (keterangan sinyal)

Panel utama menampilkan tabel status sinyal per timeframe:

```
BBMA Oma Ally Analyzer Dashboard EA  XAUUSD
SYMBOLS  W1  D1  H4  H1  M15  M5  Close All         Allow  Signals
XAUUSD   --  --  --  Re  --   --  [BUY][SELL][CLOSE] x      --
Full Auto Mode  |  TFs: 4H/1H/15M  |  3TF
Risk Management Controller is Active
```

Arti sel TF:

| Tanda | Arti |
|---|---|
| `--` | TF tidak aktif / belum ada data bar |
| `Re` hijau | Re-entry terconfirim arah BUY (TF MAJOR) |
| `Re` merah | Re-entry terconfirim arah SELL (TF MAJOR) |
| `UP` / `DN` | Tren naik / turun (belum re-entry) |
| `B/S` | Kedua arah terconfirim sekaligus |

Tombol di bawah kolom **Close All** (klik untuk eksekusi semi-auto):

| Tombol | Fungsi |
|---|---|
| BUY | Buka posisi BUY |
| SELL | Buka posisi SELL |
| CLOSE | Tutup semua posisi (Close All) |
| AUTO | Nyalakan/matikan auto-trade (hijau = ON, abu-abu = OFF) |

Kolom **Allow** menampilkan `✓` (hijau) jika tombol **AUTO** nyala dan tidak diblokir, `✗` (merah) jika tidak.

Kolom **Signals** menampilkan sinyal gabungan: `BUY` / `SELL` / `PREP BUY` / `PREP SELL` / `--`.

Baris bawah menampilkan mode (`Full Auto Mode` hijau / `Semi Auto Mode` abu-abu), TF yang aktif, serta status Risk Management Controller (`Active` hijau / `Inactive` merah). `CONFIG ERROR` hanya dicetak ke tab Experts saat TF aktif kurang dari kebutuhan mode.

Input tampilan:

| Input | Default | Fungsi |
|---|---|---|
| `InpShowPanel` | true | Tampilkan/sembunyikan dashboard |
| `InpPanelCorner` | CORNER_LEFT_UPPER | Sudut penempatan panel |
| `InpPanelX / InpPanelY` | 20 / 30 | Jarak X dan Y panel |
| `InpFontSize` | 9 | Ukuran font panel |

### Exit
Semua aturan exit berlaku untuk seluruh basket (semua posisi + pending ditutup sekaligus).

- **At MA** — BUY ditutup saat harga break MA10 Low MAJOR TF, SELL saat break MA5 High.
- **At BB** — take profit di upper/lower Bollinger Bands MAJOR TF.
- **At reverse signal** — saat harga menyentuh top/low BB MAJOR, SL semua posisi dipindah ke
  entry (SL+). Basket ditutup saat ada Extreme berlawanan di MAJOR, CSM berlawanan di SECOND,
  atau sinyal final berlawanan.
- **Cut-loss** — CSM melawan posisi + harga menembus EMA50 di SECOND TF.
- **Trailing %** — lihat `InpTrailStartPct / InpTrailLockPct`.
- Mode Single juga punya SL/TP (ATR × `InpSLATR`, RR `InpRR`).

---

## 6. Telegram (opsional)

1. Isi `InpTelegramToken` dan `InpTelegramChat`.
2. `InpAlertTelegram = true`.
3. MT5 → **Tools → Options → Expert Advisors → Allow WebRequest for listed URL**:
   ```
   https://api.telegram.org
   ```
4. Jika belum di-whitelist, log menampilkan error `4060`.

---

## 7. Pengujian

- **Strategy Tester** (Ctrl+R): pilih XAUUSD, TF chart bebas, model
  *Every tick based on real ticks*. Auto-trade otomatis ON di tester; dashboard
  hanya digambar di mode visual supaya optimasi cepat.
- Mulai dengan tombol **AUTO** mati di akun demo.
- Cek tab **Experts** untuk log sinyal/error.

---

## 8. Tuning

- Sinyal terlalu sering: naikkan `InpSetupLookback` hanya jika ingin memperluas
  pencarian Full Setup; entry pola lain mengikuti definisi guidebook.
- Sinyal terlalu jarang: periksa urutan timeframe dan definisi candle rejection.
- Kombinasi swing: **1D + 4H + 1H** (3TF) atau **4H + 1H** (2TF).
- Kombinasi intraday: **4H + 1H + 15M** (3TF) atau **1H + 15M** (2TF).

---

## 9. Disclaimer

Trading XAUUSD/CFD berisiko tinggi. EA ini alat bantu analisis/eksekusi, bukan
jaminan profit. Tidak berafiliasi dengan The SharpShooter EA atau Oma Ally.
Gunakan dengan risiko sendiri.
