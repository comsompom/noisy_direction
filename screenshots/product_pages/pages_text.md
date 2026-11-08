

#### 2. German (`de-DE` – Germany, Austria, Switzerland)
* **Promotional Text (151 / 170 chars):**
  > Lärmquellen sofort lokalisieren. Finde störenden Nachbarschaftslärm, Brummtöne oder Klappern mit 360°-Kompass-Scan. Schnell, präzise und 100 % offline.
* **Deep Link:**
  `noiseradar://scan`
* *Target angle:* Neighborhood quiet hours (*Ruhestörung*), hums (*Brummton*), and acoustic diagnostics.

---

#### 3. Japanese (`ja` – Japan)
* **Promotional Text (78 / 170 chars):**
  > 音の発生源を360°スキャンで特定！気になる騒音や振動、異音の方向をiPhoneのマイクとコンパスで素早く探知します。録音なし・安心の完全オフライン処理。
* **Deep Link:**
  `noiseradar://scan`
* *Target angle:* Apartment wall/floor noise (*騒音*), unwanted vibrations, and complete privacy (no audio uploaded).

---

### Tier 2: High Search Volume & Cultural Fit

#### 4. Korean (`ko` – South Korea)
* **Promotional Text (88 / 170 chars):**
  > 소음이 발생하는 위치를 360도 스캔으로 즉시 탐지! 층간소음, 정체불명의 웅웅거림, 기계 소음의 방향을 빠르게 찾아냅니다. 녹음 없는 안전한 100% 오프라인 측정.
* **Deep Link:**
  `noiseradar://scan`
* *Target angle:* Apartment inter-floor noise (*층간소음*), mechanical hums, offline safety.

---

#### 5. French (`fr-FR` – France, Belgium, Switzerland, Canada)
* **Promotional Text (153 / 170 chars):**
  > Localisez l’origine des bruits en 360° ! Identifiez bruits de voisinage, bourdonnements ou vibrations avec précision. Rapide, privé et 100 % hors ligne.
* **Deep Link:**
  `noiseradar://scan`
* *Target angle:* Neighbor noise, unexplained vibrations, precision utility tool.

---

#### 6. Spanish (`es-ES`, `es-419` – Spain, Mexico, US Hispanic)
* **Promotional Text (155 / 170 chars):**
  > Localiza el origen de cualquier sonido en 360°. Detecta ruidos de vecinos, zumbidos o vibraciones de forma rápida y precisa. 100 % privado y sin conexión.
* **Deep Link:**
  `noiseradar://scan`
* *Target angle:* Neighbor disturbance, rattles, and offline functionality.

---

### Tier 3: Secondary Expansion

#### 7. Traditional Chinese (`zh-Hant` – Taiwan, Hong Kong)
* **Promotional Text (70 / 170 chars):**
  > 360° 全方位快速追蹤噪音來源！使用 iPhone 麥克風與指南針精準定位鄰居噪音、異音與震動。無需聯網，100% 離線保障隱私。
* **Deep Link:**
  `noiseradar://scan`

---

#### 8. Italian (`it` – Italy, Switzerland)
* **Promotional Text (151 / 170 chars):**
  > Individua l'origine di qualsiasi rumore a 360°! Trova rumori dei vicini, ronzii e vibrazioni con microfono e bussola. Veloce, preciso e 100% offline.
* **Deep Link:**
  `noiseradar://scan`

---

#### 9. Portuguese (`pt-BR` – Brazil, Portugal)
* **Promotional Text (159 / 170 chars):**
  > Localize a origem de qualquer som em 360°! Encontre barulhos de vizinhos, zumbidos e vibrações usando o microfone e a bússola. Rápido, preciso e 100% offline.
* **Deep Link:**
  `noiseradar://scan`

---

### Quick Implementation Checklist
1. **Match with Screenshot Captions:** Ensure that the first 1–2 screenshots in each CPP echo the same phrasing (e.g., using "Ruhestörung" for German, "층간소음" for Korean, "騒音" for Japanese).
2. **Deep Link Verification:** If testing deep links, test entering `noiseradar://scan` inside Safari on a test device; if the app opens directly to the scan screen, your scheme is working properly. If nothing happens, leave the deep link blank in App Store Connect so it defaults to opening the app normally.


