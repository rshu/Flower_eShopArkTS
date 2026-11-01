# Flower eShop (ArkTS)

花店电商 App，基于 HarmonyOS ArkTS（Stage 模型）。依据 `app_requirements_flower_eshop.md`
实现，可在 Pura 80 Pro 真机运行。

## 功能

| 页面 | 说明 |
|------|------|
| 首页 | 商品列表、下拉刷新、浏览历史（最近 10 条）、扫一扫/语音/定位/地图/我的入口 |
| 商品详情 | 大图、价格、花语、规格、收藏、立即购买（系统通知）、优惠与服务入口 |
| 支付安全 | 6 位支付密码 AES-256-CBC 加密存储、验证、清除 |
| 我的 | 华为账号登录（预留）、支付安全入口、订单/设置（预留） |
| 门店地图 | 占位页（需 Map Kit + AGC API Key） |

> 依赖 AGC / Kit 配置的能力（扫码、语音、地图、华为登录、定位、日历、分享、
> 通讯录、蓝牙、生物认证）当前为「功能预留」占位，未接入真实服务。

## 技术栈

- 语言：ArkTS（TypeScript 超集）
- 模型：HarmonyOS Stage 模型
- bundle name：`com.huawei.flowereshop.icode`
- compileSdkVersion：HarmonyOS 6.0.2 (API 22)
- compatibleSdkVersion：HarmonyOS 5.0.0 (API 12)

## 项目结构

```
entry/src/main/ets/
├── entryability/EntryAbility.ts
├── model/
│   ├── Commodity.ets           # 数据模型 + mock 商品数据
│   └── AppState.ets            # 跨页传递选中商品 id
├── store/
│   └── CommodityStore.ets      # Preferences 持久化（收藏 / 浏览历史）
├── service/
│   ├── CommodityService.ets    # 商品获取（模拟网络 + 本地降级）
│   ├── SecurePayService.ets    # 支付密码 AES 加解密 + 存取
│   └── PromotionNotifier.ets   # 订单通知
└── pages/
    ├── Index.ets               # 首页
    ├── CommodityDetailPage.ets # 商品详情
    ├── PaySecurityPage.ets     # 支付安全
    ├── PersonalPage.ets        # 我的
    └── StoreMapPage.ets        # 门店地图（占位）
```

## 构建

```bash
hvigorw assembleHap --mode module -p product=default -p buildMode=debug --no-daemon
```

签名 HAP 输出到 `entry/build/default/outputs/default/entry-default-signed.hap`。

## 签名

签名材料与机器相关，不提交到仓库。在 DevEco Studio 中通过
**File > Project Structure > Signing Configs** 为对应 bundle name 和
设备 UDID 启用自动签名后重新构建。

## 运行

```bash
hdc install entry/build/default/outputs/default/entry-default-signed.hap
hdc shell aa start -a EntryAbility -b com.huawei.flowereshop.icode
```

## 测试

- Huawei Pura 80 Pro，HarmonyOS 真机

## 开发记录

- 开始时间：2026-11-01 15:09:53 HKT
- 结束时间：2026-11-01 15:24:45 HKT
- 总时长：约 15 分钟（14 分 52 秒）
- 模型 API token 消耗：约 70,000 tokens（估算值，含输入 + 输出）

> 说明：运行环境未暴露精确的 token 计费口径，以上 token 数为估算，
> 实际用量请以所用平台的大模型用量报表为准。
