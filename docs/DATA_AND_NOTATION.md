# 元素数据与化学角标

## 单一数据源

`assets/data/elements.json` 是主表、详情卡片、搜索和背诵模式共用的唯一元素数据源。应用通过 `ElementRepository` 加载并验证全部 118 条记录。

关键字段：

- `atomicNumber`、`symbol`、`nameZh`、`nameEn`。
- `atomicMassType`、`representativeMassNumber`，区分标准原子量和代表性同位素质量数。
- `period`、`group`、`displayRow`、`displayColumn`、`category`、`block`。
- `electronConfiguration`、`valenceConfiguration`，保留规范字符串用于校验和追溯。
- `electronConfigurationData`、`valenceConfigurationData`，保存惰性气体核心与轨道电子数结构，供统一排版组件读取。
- 物性字段统一保留数值和单位；缺失值使用 `null`。

## 电子排布结构

例如铬的完整排布同时保存为：

```json
{
  "electronConfiguration": "[Ar]3d5 4s1",
  "electronConfigurationData": {
    "nobleGasCore": "Ar",
    "orbitals": [
      {"orbital": "3d", "electrons": 5},
      {"orbital": "4s", "electrons": 1}
    ]
  }
}
```

加载时会校验：

- 轨道格式和每个轨道的最大电子容量。
- 核心电子数与轨道电子数之和是否等于原子序数。
- 结构数据与规范字符串是否一致。
- 价层构型是否与完整排布去除核心后的轨道一致。

## 上标与下标

详情卡片不再直接输出 `3d5` 一类纯字符串。`ElectronConfigurationText` 读取结构化轨道数据，并使用 `RichText`、`TextSpan` 和 `WidgetSpan` 将电子数排版为右上角上标。

通用化学表达式由 `ChemicalFormulaText` 处理：

- 化学式原子数使用下标，例如 `H₂O`。
- 离子电荷使用右上角上标，例如 `SO₄²⁻`。
- `IsotopeSymbolText` 将质量数放在元素符号左上角、原子序数放在左下角。

这些组件使用基线偏移和独立缩放，不依赖普通字符串中的 Unicode 角标。
