# Flower eShop (ArkTS)

A minimal HarmonyOS ArkTS (Stage model) application scaffold for a flower e-shop.

## Current feature

Prints **"Welcome to Flower eshop!"** to the HiLog and renders it on the home page.

## Project structure

```
Flower_eShopArkTS/
├── AppScope/              # Application-level config and resources
│   ├── app.json5          # Bundle name, icon, label
│   └── resources/
├── entry/                 # Entry module
│   └── src/main/
│       ├── ets/
│       │   ├── entryability/EntryAbility.ts
│       │   └── pages/Index.ets
│       ├── module.json5
│       └── resources/
├── build-profile.json5    # App/product/module build config
├── hvigorfile.ts
└── oh-package.json5
```

## Tech stack

- Language: ArkTS (superset of TypeScript)
- Model: HarmonyOS Stage model
- Bundle name: `com.huawei.flowereshop`
- compileSdkVersion: HarmonyOS 6.0.2 (API 22)
- compatibleSdkVersion: HarmonyOS 5.0.0 (API 12)

## Build

```bash
hvigorw assembleHap --mode module -p product=default -p buildMode=debug --no-daemon
```

The signed HAP is written to `entry/build/default/outputs/default/entry-default-signed.hap`.

## Signing

Signing material is machine-specific and is intentionally not committed. In DevEco
Studio, enable auto-signing under **File > Project Structure > Signing Configs** for
the bundle name and your device's UDID, then rebuild.

## Run on device

```bash
hdc install entry/build/default/outputs/default/entry-default-signed.hap
hdc shell aa start -a EntryAbility -b com.huawei.flowereshop
```

## Tested on

- Huawei Pura 80 Pro (LMR-AL00), HarmonyOS 7.0.0.109
