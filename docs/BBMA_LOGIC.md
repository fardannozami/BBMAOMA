# Logika BBMA Oma Ally — Referensi Teknis

Dokumen ini menjelaskan **apa yang benar-benar dihitung oleh EA**, bukan ringkasan
guidebook. Semua rumus di bawah diambil langsung dari source:

| Bagian | File |
|---|---|
| Deteksi pola per TF | `Include/BBMA_Analysis.mqh` (`AnalyzeTF`) |
| Peran & registry TF | `Include/BBMA_Timeframes.mqh` (`BuildTFList`) |
| Gabungan multi-TF | `Include/BBMA_Signals.mqh` (`UpdateAnalysis`) |
| Entry & exit | `Include/BBMA_Trading.mqh` |
| Guard harian | `Include/BBMA_Risk.mqh` |

Notasi yang dipakai:

```
o1, h1, l1, c1   = Open/High/Low/Close bar TERAKHIR yang sudah tutup (index 1)
o2, h2, l2, c2   = bar sebelumnya (index 2)
bbU, bbL, bbM    = Bollinger Upper / Lower / Mid pada bar yang dirujuk
ma5, ma10        = MA High / MA Low pada bar yang dirujuk
ema              = EMA trend pada bar yang dirujuk
bull1            = c1 > o1
bear1            = c1 < o1
zoneLo/zoneHi    = min(ma5, ma10) / max(ma5, ma10)
```

Semua analisa memakai **bar tertutup** (index 1). Bar yang masih berjalan tidak
pernah dipakai, jadi sinyal tidak repaint.

---

## 1. Indikator dan data

Dibuat per TF yang diaktifkan (`InitHandles`):

| Buffer | Indikator | Parameter default |
|---|---|---|
| BB upper / lower / mid | `iBands` | period `InpBBPeriod` = 20, deviasi `InpBBDeviation` = 2.0, `PRICE_CLOSE` |
| `ma5` | `iMA` SMA | `InpFastMA` = 5, diterapkan ke **PRICE_HIGH** |
| `ma10` | `iMA` SMA | `InpSlowMA` = 10, diterapkan ke **PRICE_LOW** |
| `ema` | `iMA` EMA | `InpTrendEMA` = 50, `PRICE_CLOSE` |
| `atr` | `iATR` | `InpATRPeriod` = 14 |

Penting: MA5 memakai harga **High** dan MA10 memakai harga **Low**. Karena itu
zona MA5/MA10 adalah pita, bukan garis tunggal.

Syarat data minimum (`AnalyzeTF`): `Bars >= 10`, dan jumlah bar yang disalin
`need = InpSetupLookback + 10` (dipangkas ke `Bars - 1`, minimal 8). Kalau kurang,
TF tersebut tidak dianalisa dan sinyal tidak dihitung.

---

## 2. Bias tren

```
trend = +1  jika  c1 > ema[1]  dan  ema[1] >= ema[2]
trend = -1  jika  c1 < ema[1]  dan  ema[1] <= ema[2]
trend =  0  selain itu
```

Lalu filter opsional `InpRequireMAStack` (default `true`):

```
jika trend = +1 dan ma5[1] < ma10[1]  ->  trend = 0
jika trend = -1 dan ma5[1] > ma10[1]  ->  trend = 0
```

Tren butuh dua hal sekaligus: harga di sisi EMA dan slope EMA searah.

---

## 3. Pola per timeframe

Urutan pengecekan di `TFCellStatus` (dashboard) adalah
`Re > Ex > MHV > Full > Rj > Gap`. Itu hanya prioritas **tampilan**; semua flag
dihitung penuh dan bisa aktif bersamaan.

### 3.1 Extreme

```
extremeBuy  = ma10[1] < bbL[1]  &&  l1 <= bbL[1]  &&  bull1
extremeSell = ma5[1]  > bbU[1]  &&  h1 >= bbU[1]  &&  bear1
```

MA harus sudah keluar dari band **dan** candle menolak band tersebut lalu ditutup
berlawanan arah (reversal candle).

### 3.2 CSM (Momentum)

```
csmBuy  = bull1 && c1 > ma5[1]  && c1 > bbU[1]
csmSell = bear1 && c1 < ma10[1] && c1 < bbL[1]
```

CSM = candle menembus MA **dan** menembus band luar. Tidak melihat BB Mid.

### 3.3 CSAK / CSD (Arah)

```
csakBuy  = bull1 && c1 > ma5[1]  && c1 > bbM[1]
csakSell = bear1 && c1 < ma10[1] && c1 < bbM[1]
```

Sama seperti CSM tetapi cukup menembus BB **Mid**. Flag ini dipakai di dua tempat:
konfirmasi re-entry dan sebagai "direction" pada Full Setup.

### 3.4 Re-entry

Re-entry memakai **dua bar**: bar 2 menolak MA, bar 1 mengonfirmasi.

```
rejectedBuyMA  = l2 <= ma10[2] && c2 > ma10[2]      // ekor menembus MA10 Low, close balik di atas
rejectedSellMA = h2 >= ma5[2]  && c2 < ma5[2]       // ekor menembus MA5 High, close balik di bawah

reentryBuy  = rejectedBuyMA  && (csakBuy  || csmBuy)
reentrySell = rejectedSellMA && (csakSell || csmSell)
```

Catatan: rejection BUY memakai **MA10**, rejection SELL memakai **MA5**. Konfirmasi
boleh CSAK (cukup BB Mid) atau CSM (menembus band luar).

### 3.5 MHV (Market Hilang Volume)

MHV dipakai untuk memastikan Extreme masih valid saat harga kembali ke zona MA.
Langkahnya:

1. Cari bar Extreme terakhir di dalam lookback (`i = 2 .. maxI`).
   Yang diambil adalah **index terkecil** (paling baru).
2. Cek apakah Extreme sudah dipatahkan. Untuk BUY, patah jika ada bar
   `i = extremeBar-1 .. 1` dengan:

   ```
   bear1 && c < ma10[i] && c < bbL[i] && c < extremeLow
   ```

   untuk SELL kebalikannya (`bull`, `c > ma5[i]`, `c > bbU[i]`, `c > extremeHigh`).
3. Cek harga sekarang masih menyentuh zona MA:

   ```
   atMAZone = l1 <= zoneHi && h1 >= zoneLo
   ```

4. Hasil:

   ```
   mhvBuy  = extremeBuyBar  ditemukan && !broken && atMAZone
   mhvSell = extremeSellBar ditemukan && !broken && atMAZone
   mhv     = mhvBuy || mhvSell
   ```

### 3.6 Rejected EMA50 dan GAP ke band

```
rejectionBuy  = ema[1] <  bbM[1] && l1 <= ema[1] && c1 > ema[1] && bull1
rejectionSell = ema[1] >  bbM[1] && h1 >= ema[1] && c1 < ema[1] && bear1

gapBuy  = ema[1] < bbL[1] && l1 <= bbL[1] && c1 > bbL[1] && bull1
gapSell = ema[1] > bbU[1] && h1 >= bbU[1] && c1 < bbU[1] && bear1
```

`rejection` = EMA sebagai support/resistance di dalam band.
`gap` = EMA sudah di luar band, lalu harga menolak **band** itu (bukan EMA).

### 3.7 Konfirmasi TF2

```
tf2Buy  = gapBuy  || rejectionBuy
tf2Sell = gapSell || rejectionSell
```

Inilah satu-satunya flag SECOND TF yang dipakai untuk entry. `tf2` **tidak**
mencakup Extreme/MHV/re-entry.

### 3.8 Direction setelah MHV

Dihitung dalam satu loop dari bar **tertua ke terbaru** (`i = maxI .. 1`):

```
jika bar i = Extreme        -> seenExtreme = true, passedMhv = false
jika seenExtreme dan csmSell menembus low bar berikutnya -> reset (extreme batal)
jika seenExtreme dan bar menyentuh zona MA -> passedMhv = true
jika passedMhv dan bar i adalah CSAK searah -> dirAfterMhv = true
```

Arti: Extreme → harga kembali ke MA (MHV valid) → muncul candle arah. Flag ini
adalah tahap "Direction" pada Full Setup.

### 3.9 Full Setup (Extreme → TPW → MHV → Direction → Re-entry)

Loop yang sama (`i = maxI .. 1`, tertua ke terbaru) menjalankan state machine:

```
Extreme terdeteksi        -> mulai urutan, simpan extremeLow/extremeHigh
CSM berlawanan menembus   -> urutan dibatalkan
   level extreme
harga sentuh zona MA/TPW  -> tahap TPW selesai
kembali ke zona MA        -> tahap MHV selesai (tanpa CSM berlawanan)
muncul candle arah (CSAK) -> tahap Direction selesai
rejection MA + arah       -> fullSetup = true
```

Dua detail implementasi yang perlu diketahui:

- `extremeLow`/`extremeHigh` di-reset setiap kali Extreme baru muncul.
- `fullSetup` bersifat **latch di dalam window lookback**: sekali `true`, nilainya
  tidak kembali ke `false` sebelum muncul Extreme baru. Tidak ada syarat "harga
  masih di atas level tertentu" setelah tahap Direction.

`InpSetupLookback` (default 20) menentukan seberapa jauh kebelakang urutan ini
dicari. Menaikkan nilainya membuat Full Setup lebih mudah muncul, tetapi setup
yang sudah lama tetap bisa terbaca.

---

## 4. Peran timeframe

TF yang aktif diurutkan otomatis dari besar ke kecil (`BuildTFList`):

| Posisi | Variabel | Peran |
|---|---|---|
| TF tertinggi | `g_majorIdx` | **MAJOR** — tren + re-entry/Full Setup |
| TF kedua | `g_secondIdx` | **SECOND** — konfirmasi `tf2` + cut-loss |
| TF ketiga | `g_thirdIdx` | **THIRD** — hanya dipakai mode 3TF |

Aturan validasi (`g_configOk`):

- mode 2TF → minimal 2 TF aktif
- mode 3TF → minimal 3 TF aktif

TF ekstra **boleh aktif**. Semua TF yang ON tetap dianalisa dan muncul di
dashboard, tetapi hanya TF teratas yang masuk rantai konfirmasi. Di mode 2TF,
`g_thirdIdx = -1` sehingga TF ketiga tidak berpengaruh ke sinyal. Kalau TF aktif
kurang dari kebutuhan mode, EA menulis `CONFIG ERROR` dan tidak memberi
sinyal/trade sama sekali.

Contoh dengan 4H + 1H + 15M aktif:

| Mode | MAJOR | SECOND | THIRD | TF ekstra |
|---|---|---|---|---|
| 2TF | 4H | 1H | — | 15M (dashboard saja) |
| 3TF | 4H | 1H | 15M | — |

---

## 5. Sinyal multi-timeframe

Semua dihitung ulang hanya saat ada bar baru pada salah satu TF aktif
(`OnTick` → `IsNewBar` → `UpdateAnalysis`).

### 5.1 PREP (persiapan 2 TF)

```
prepBuy  = major.reentryBuy  && second.tf2Buy
prepSell = major.reentrySell && second.tf2Sell
```

PREP = TF besar sudah re-entry, TF kedua memberi gap / rejected EMA50.

### 5.2 FINAL mode 2TF

```
finalBuy  = prepBuy
finalSell = prepSell
```

Di mode 2TF tidak ada syarat ketiga: sinyal 2 TF langsung final.

### 5.3 FINAL mode 3TF

Diamond:

```
diamondBuy = major.reentryBuy && second.tf2Buy &&
             (third.extremeBuy || third.mhvBuy || third.fullSetupBuy)
```

Pola lain, dicek berurutan (yang pertama cocok dipakai sebagai nama setup):

| Prioritas | Pola | Syarat |
|---|---|---|
| 1 | `FULL SETUP` | salah satu dari major/second/third `fullSetupBuy` |
| 2 | `REE` | major Re && second Ex && third Ex |
| 3 | `RRE` | major Re && second Re && third Ex |
| 4 | `RRM` | major Re && second Re && third MHV |
| 5 | `REM` | major Re && second Ex && third MHV |
| 6 | `DIAMOND` | major Re && second `tf2` && third Ex/MHV/Full |

`finalBuy = (pola BUY tidak kosong)`, dan hal yang sama untuk SELL.

### 5.4 Konflik dan edge

```
jika finalBuy && finalSell  -> keduanya dimatikan (tidak ada sinyal)
```

Alert dan auto-entry hanya dipicu oleh **rising edge**:

```
eventFinalBuy  = finalBuy  && !prevFinalBuy
eventPrepBuy   = prepBuy   && !prevPrepBuy && !finalBuy
```

Jadi sinyal yang bertahan beberapa bar tidak diulang. PREP hanya di-alert kalau
`InpAlertPreparation = true` dan belum menjadi FINAL.

---

## 6. Alur eksekusi

```
OnInit
  InitTFArrays -> BuildTFList (validasi + peran TF)
  InitHandles (per TF aktif)
  CreateDashboard, timer 700 ms

OnTick
  UpdateDaily
  jika ada bar baru di TF aktif -> UpdateAnalysis (analisa + sinyal + alert)
  ManagePositions
  konsumsi eventFinalBuy/Sell -> OpenTrade bila g_autoTrade

OnTimer (700 ms)
  UpdateDaily, ManagePositions, UpdateDashboard
```

Analisa hanya jalan di bar baru, sedangkan manajemen posisi dan guard harian
jalan di setiap tick dan setiap timer.

---

## 7. Entry

`OpenTrade(dir)` menolak entry bila salah satu benar:

| Cek | Keterangan |
|---|---|
| `!g_configOk` | jumlah TF tidak sesuai mode |
| `g_blocked` | limit harian / tutup Jumat aktif |
| `!TERMINAL_TRADE_ALLOWED` / `!MQL_TRADE_ALLOWED` | trading dimatikan |
| jumlah posisi | `InpAllowLayering = false` → maksimum 1 posisi; selain itu `InpMaxPositions` |
| `InpMaxSpread` | spread melebihi batas (default 50 pts) |
| ATR | ATR MAJOR nol (fallback THIRD, lalu gagal) |

Jarak SL:

```
dist = max( ATR_major * InpSLATR,
            InpMinSLPoints * _Point,
            (stopsLevel + InpStopBufferPts) * _Point )

BUY : SL = price - dist,  TP = price + dist * InpRR
SELL: SL = price + dist,  TP = price - dist * InpRR
```

Lot (`CalcLot`):

- `LOT_FIXED` → `InpLot`.
- `LOT_COMPOUND` → `balance * InpRiskPercent% / lossPerLot`, dengan
  `lossPerLot = (dist / tickSize) * tickValue`.
- Selalu dibulatkan ke `SYMBOL_VOLUME_STEP` dan dijepit min/max. Kalau margin
  yang dibutuhkan > 90% free margin, lot diperkecil agar muat.

---

## 8. Exit

Diperiksa per posisi pada setiap tick/timer, berurutan. Cek pertama yang cocok
langsung menutup posisi.

| Urutan | Aturan | BUY | SELL |
|---|---|---|---|
| 1 | Cut-loss (`InpCutLossOnCSM`) | SECOND `csmSell` && `bid < ema50` | SECOND `csmBuy` && `ask > ema50` |
| 2 | `CLOSE_AT_MA` | `bid <= ma5` MAJOR | `ask >= ma10` MAJOR |
| 3 | `CLOSE_AT_BB` | `bid >= bbU` MAJOR | `ask <= bbL` MAJOR |
| 4 | `CLOSE_AT_REVERSE` | `finalSell` | `finalBuy` |

Cut-loss memakai EMA50 dan CSM dari **SECOND** TF, sedangkan target profit
memakai MA/BB dari **MAJOR** TF.

---

## 9. Guard risiko harian

`UpdateDaily` jalan di tick dan timer:

- Ganti hari (`dt.day` berubah) → `g_dayStartBalance = balance`, `g_blocked = false`.
- Selama tidak blocked:
  - `DailyPct <= -InpDailyLossPct` → `CloseAll()`, blocked, alert.
  - `DailyPct >= InpDailyTargetPct` (jika > 0) → `CloseAll()`, blocked, alert.
- `InpFridayClose` dan `day_of_week == 5` dan `hour >= InpFridayHour`
  (default 22 server) → `CloseAll()`, blocked. Blocked bertahan sampai ganti hari.

`DailyPct` dihitung dari **equity** terhadap balance awal hari, bukan dari closed P/L.

---

## 10. Status yang tampil

Dashboard (`TFCellStatus`), prioritas teks per sel:

| Teks | Sumber flag |
|---|---|
| `Re` | `reentryBuy` / `reentrySell` |
| `Ex` | `extremeBuy` / `extremeSell` |
| `MHV` | `mhvBuy` / `mhvSell` |
| `Full` | `fullSetupBuy` / `fullSetupSell` |
| `Rj` | `rejectionBuy` / `rejectionSell` |
| `Gap` | `gapBuy` / `gapSell` |
| `B/S` | BUY dan SELL sama-sama terdeteksi |
| `UP` / `DN` | hanya bias tren |
| `--` | TF OFF atau belum ada bar |

Kolom **Signals** memakai `finalBuy/finalSell` lalu `prepBuy/prepSell`:
`BUY` / `SELL` / `PREP BUY` / `PREP SELL` / `--`.

---

## 11. Ringkasan keterbatasan

- Analisa per TF memakai **satu window** (`InpSetupLookback + 10` bar); kejadian
  lebih lama dari itu tidak terlihat.
- `tf2` hanya gap/rejection. Extreme/MHV di SECOND TF tidak pernah memicu entry
  di mode 2TF, meskipun tampil di dashboard.
- Full Setup bersifat latch di dalam window (lihat 3.9).
- Mode 2TF mengabaikan TF ketiga sepenuhnya (`g_thirdIdx = -1`), termasuk untuk
  ATR fallback.
- EA hanya untuk XAUUSD: ada peringatan di log bila simbol bukan XAU/GOLD.
