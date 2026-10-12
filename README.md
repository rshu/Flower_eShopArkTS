# Flower eShop (ArkTS)

A HarmonyOS ArkTS (Stage model) flower e-shop app. Guests can browse, search,
scan, and locate nearby stores; Huawei-account users can favorite, order,
schedule delivery reminders, and pay.

## Project stats

| Metric | Value |
|--------|-------|
| ArkTS/TypeScript source files | 25 (24 `.ets` + 1 `.ts`) |
| Lines of source code | 3,267 |
| Pages | 6 (`Index`, `CommodityDetailPage`, `PaySecurityPage`, `PersonalPage`, `ScanPage`, `StoreMapPage`) |
| Services | 15 (`CommodityService`, `CommodityStore`, `SecurePayService`, `PromotionNotifier`, `FlowerLocationService`, `DeliveryCalendarService`, `ShareAndContactsService`, `PhotoPickerHelper`, `VoiceSearchService`, `SpeechSearchService`, `FlowerScanService`, `AuthService`, `ImageProcessService`, `BackgroundRefreshService`, `SmartVaseService`) |
| Support modules | 3 (`common/Constants.ets`, `model/Commodity.ets`, `data/MockData.ets`) |
| Entry ability | 1 (`entryability/EntryAbility.ts`) |
| JSON5 config files | 7 (`app.json5`, `build-profile.json5` ×2, `module.json5`, `oh-package.json5` ×2, `hvigor-config.json5`) |
| Resource files | 5 JSON (string/color/main_pages) + 8 PNG |
| Documentation | 3 Markdown (this README, requirements, prompt attachment) |
| New files created in this effort | 23 `.ets` source files + `app_requirements_flower_eshop.md` + `context/` |

**Source line breakdown**

| Directory | Files | Lines |
|-----------|-------|-------|
| `pages/` | 6 | 1,997 |
| `service/` | 15 | 1,042 |
| `common/` + `model/` + `data/` | 3 | 211 |
| `entryability/` | 1 | 17 |
| **Total** | **25** | **3,267** |

**Timeline**

- Scaffold committed: 2026-10-07 16:02 (commit `d89e95c`)
- Development session (Oct 12, 2026): 09:42:58 → 14:02:49 (total duration **4 h 19 m 51 s**)
- Latest source change: 2026-10-12 13:35
- Calendar span: ~4 days 21 h
- Incremental `assembleHap` build: ~3–4 s

## Features

| Area | Implementation |
|------|----------------|
| Home | Product cards (image + placeholder, name, price), pull-to-refresh with loading + network-failure fallback to local cache, recent-10 browse history, nearby stores via location |
| Find flower | Scan QR/code via real Scan Kit camera (`@kit.ScanKit`), voice search via real offline ASR (`@kit.CoreSpeechKit`), map icon → nearby store map |
| Detail | Large image with placeholder fallback, accessible price, description / flower language / spec, favorite heart (persisted), delivery calendar reminder, share, add recipient from contacts, smart-vase BLE scan/connect/command (real `@ohos.bluetooth.ble`), photo review (picker without storage permission, preview/delete) |
| Buy | Notification permission → system notification (product + order number) → payment page |
| Payment security | 6-digit password set/verify/clear, AES local encrypted storage in Asset, biometric (fingerprint/face/PIN) with graceful errors |
| Account | Huawei-account login via real Account Kit (`@kit.AccountKit` authorization flow) with demo fallback when AGC is not configured, avatar/nickname, orders/settings reserved |
| Store map | Real Map Kit `MapComponent` with markers when the map service loads; automatic fallback to a Canvas map (lat/lng projection) plus a distance-sorted store list |
| Delivery calendar | Pick date → add "Flower delivery" event (product + recipient), calendar read/write permission |
| Persistence | Favorites / browse history in Preferences; payment password + AES key in Asset |
| API | `GET /api/commodities`, `GET /api/commodities/{id}` with local mock fallback |

## Project structure

```
Flower_eShopArkTS/
├── AppScope/                     # app.json5 (bundle name, icon, label)
├── entry/src/main/
│   ├── module.json5              # abilities + requestPermissions
│   ├── resources/base/profile/main_pages.json
│   └── ets/
│       ├── entryability/EntryAbility.ts
│       ├── common/Constants.ets
│       ├── model/Commodity.ets
│       ├── data/MockData.ets
│       ├── service/              # CommodityService, CommodityStore,
│       │                         # SecurePayService, PromotionNotifier,
│       │                         # FlowerLocationService, DeliveryCalendarService,
│       │                         # ShareAndContactsService, PhotoPickerHelper,
│       │                         # VoiceSearchService, SpeechSearchService,
│       │                         # FlowerScanService, AuthService,
│       │                         # ImageProcessService, BackgroundRefreshService,
│       │                         # SmartVaseService
│       └── pages/                # Index, CommodityDetailPage, StoreMapPage,
│                                 # PaySecurityPage, PersonalPage, ScanPage
├── build-profile.json5           # app/product/module + signing config
├── hvigorfile.ts
└── oh-package.json5
```

## Tech stack

- Language: ArkTS
- Model: HarmonyOS Stage model
- Bundle name: `com.huawei.flowereshop`
- targetSdkVersion: HarmonyOS 6.0.2 (API 22)
- compatibleSdkVersion: HarmonyOS 5.0.0 (API 12)

## Build

Requires a JDK 21 (DevEco Studio bundles one). The build wrapper is invoked via
the HarmonyOS command-line tools `hvigorw`.

```bash
export JAVA_HOME=/Applications/DevEco-Studio.app/Contents/jbr/Contents/Home
export PATH="$JAVA_HOME/bin:$PATH"

/Users/rshu/Documents/command-line-tools/bin/hvigorw assembleHap \
  --mode module -p product=default -p buildMode=debug --no-daemon
```

Output:

- Signed:   `entry/build/default/outputs/default/entry-default-signed.hap`
- Unsigned: `entry/build/default/outputs/default/entry-default-unsigned.hap`

## Signing

Signing material is machine-specific and not committed. The `build-profile.json5`
references the auto-generated debug keystore under `~/.ohos/config/` with
encrypted store/key passwords (decrypted at build time by hvigor from the
`~/.ohos/config/material` directory).

To re-enable signing on a new machine, use DevEco Studio:
**File > Project Structure > Signing Configs** → auto-sign for bundle
`com.huawei.flowereshop` and register your device UDID, then rebuild.

## Run on device

```bash
HDC=/Users/rshu/Documents/command-line-tools/sdk/default/openharmony/toolchains/hdc
$HDC install entry/build/default/outputs/default/entry-default-signed.hap
$HDC shell aa start -a EntryAbility -b com.huawei.flowereshop
```

## Verification results (actually run)

- `BUILD SUCCESSFUL` — `hvigorw assembleHap` (signed HAP produced).
- `hdc install` → `install bundle successfully` on the connected device.
- `aa start` → `start ability successfully`; process `com.huawei.flowereshop` is
  alive with no fault logs / ArkTS runtime errors.
- Device screenshot captured (1276×2848 JPEG) with rendered UI content.
- UI layout dump confirms the Home page renders the header "Flower eShop" and
  product cards ("Red Rose Bouquet", "Pink Lily Arrangement", "Sunflower
  Basket") with `¥` prices.
- The remote API path was exercised: DNS failure (`CURLcode result 6`) for the
  mock endpoint correctly falls back to bundled mock data.
- On-device tap automation (`hdc shell uitest uiInput`) drove and verified these
  flows against the live layout dumps:
  - Home → product detail navigation (opens "Red Rose Bouquet").
  - Favorite toggle persists (`♡` → `♥`).
  - Smart-vase BLE scan runs real `@ohos.bluetooth.ble` code and reports
    "No BLE device found nearby" when no peripheral is present.
  - Buy → notification → payment navigation (order summary + order ID rendered).
  - Huawei-account login: real Account Kit authorization flow is wired; on this
    device (no AGC Client ID) it degrades to the demo profile "Huawei User".
  - Payment password set/verify: 6-digit password persisted to Asset after the
    AES-CBC `IvParamsSpec` fix; the manage page reports "A payment password is set."
  - Store map: real `MapComponent` initializes and requests tiles, but the
    device logs `no map permission!` (Map service not enabled in AGC), so the
    page falls back to the Canvas map; demo location `22.4243, 114.2125` with
    haversine distances is shown.
  - Scan: real Scan Kit camera scanner launches (system "扫描二维码/条形码" UI
    with album/torch controls); cancel returns "Scan canceled" (handled code
    `1000500002`). Manual `flower://3` still opens "Sunflower Basket".
  - Search: keyword "rose" returns rose-related products.
  - Voice search: real offline ASR (`@kit.CoreSpeechKit`) starts
    (`onStart ... startListening success`), streams mic PCM, and completes
    (`onEvent 3 speech stopped` → `onResult final` → `onComplete`).
  - Biometric auth is confirmed to launch (userAuth UIExtension log) but requires
    a physical fingerprint/PIN to complete.

### Device

- Huawei Pura 80 Pro (`LMR-AL00`), HarmonyOS 7.0.0.109 (API 26)
- hdc target `4PZ0225627014325`, UDID `B9732DF03B87D3F52E0877D241435228C256F7E47AAFD2DFFD8070E9A8D36632`

## Incomplete / unverified

The four kits are now wired into the app, but some end-to-end paths remain
externally blocked by AGC configuration or physical hardware:

- **Huawei Account Kit** — real authorization flow (`authentication` +
  `AuthenticationController.executeRequest`) is wired and returns the
  credential's `nickName`/`avatarUri` on success. On this device it degrades to
  the demo profile because there is no AGC Client ID + matching signing
  fingerprint.
- **Huawei Map Kit** — real `MapComponent` is wired and requests tiles, but the
  device reports `no map permission!` (the AGC "Map service" must be enabled and
  the debug profile re-applied). The Canvas map fallback renders when tiles fail.
- **Scan Kit** — real camera scanner launches; end-to-end QR decode to a product
  was not completed because no physical flower-tag QR was available to point the
  camera at (manual code entry verified).
- **Core Speech Kit** — real offline ASR starts and completes on-device, but a
  clean recognized phrase was not captured in the final run (no spoken input was
  provided to the mic in the last verification; earlier runs captured real
  Chinese recognition).
- **Smart vase BLE** — real BLE scan/connect/command code is wired and runs, but
  no vase peripheral was present to complete a connection + write.
- **Biometric final step** — the userAuth prompt launches, but completing it needs
  a physical fingerprint/PIN on the device.
