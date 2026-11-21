# MSI Afterburner 配置备份

显卡：**NVIDIA GeForce RTX 4070 SUPER**（驱动 32.0.16.2101，2026-11-21 记录）

## 备份内容

| 文件 | 说明 |
|---|---|
| `VEN_10DE&DEV_2783...cfg` | **设备配置主文件**，超频参数（核心/显存/功耗/风扇）都在这里 |
| `MSIAfterburner.cfg` | 主程序设置（自启动、OSD 等） |
| `Profile1~4.cfg` | 配置档位文件（目前为空壳） |

## 原厂备份时的参数（2026-11-21）

| 项目 | 值 |
|---|---|
| PowerLimit | 110% |
| CoreClkBoost | +165 MHz |
| MemClkBoost | +200 MHz |
| FanSpeed | 30% |

## 两套推荐档位

### 日常档

| 项目 | 值 |
|---|---|
| 核心 | **+200 MHz** |
| 显存 | **+1000 MHz** |
| 功耗 | 110% |
| 风扇 | 自动 / 50% |

### 激进档

| 项目 | 值 |
|---|---|
| 核心 | **+230 MHz** |
| 显存 | **+1300 MHz** |
| 功耗 | 110% |
| 风扇 | **70%（手动）** |

## 恢复方法

1. 关闭 MSI Afterburner
2. 把本目录的 cfg 复制回
   `C:\Program Files (x86)\MSI Afterburner\Profiles\`
3. 重新打开 Afterburner

## 注意

- **关掉 Afterburner 超频就失效**，它必须常驻
- 设置里要勾选：随 Windows 启动 / 启动时最小化 / **启动时应用设置**
- 显存 +1300 是抽奖，花屏就退到 +1000 → +800
- 部分游戏的反作弊会拦 RTSS OSD，进不去游戏时先关 OSD（不是关超频）
- 温度建议控制在 83°C 以下
