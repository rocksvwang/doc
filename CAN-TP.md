
标准名称通常是 **ISO 15765-2（ISO-TP）**，汽车诊断 UDS 中大量使用。
Linux ，Zephyr 已经先天支持。

# 核心帧类型 

- SF：Single Frame 单帧 
- FF：First Frame  首帧
- CF：Consecutive Frame 连续帧
- FC：Flow Control 流控帧

## 格式

```
CAN ID
  │
  ▼
┌──────┬─────────────────────────────────────┐
│  ID  │              CAN Data               │
└──────┴─────────────────────────────────────┘
             │
             ▼

       CAN Data
	┌──────────────┬──────────────────────────────┐
	│     PCI      │           Payload            │
	│    1 Byte    │                              │
	└──────────────┴──────────────────────────────┘
      │
      ▼
	┌──────────┬──────────┐
	│ 高4 bit  │ 低4 bit  │
	│ 帧类型    │ 类型相关  │
	└──────────┴──────────┘
       
       
```

| 高4 bit | 帧类型 | 低4 bit          |
| ------ | --- | --------------- |
| `0`    | SF  | SF数据长度          |
| `1`    | FF  | FF长度的一部分        |
| `2`    | CF  | Sequence Number |
| `3`    | FC  | Flow Status     |

## 发送时序

```mermaid
sequenceDiagram
    participant TX as 发送端
    participant RX as 接收端

    rect rgb(235, 245, 255)
        Note over TX,RX: 场景一：单帧传输（SF）—— 不需要流控
        TX->>RX: SF：发送完整数据
        Note over RX: 接收完成
    end

    rect rgb(245, 245, 235)
        Note over TX,RX: 场景二：多帧传输—— 需要流控

        TX->>RX: FF：First Frame<br/>携带总长度
        RX->>TX: FC：Flow Control<br/>FS=CTS / BS / STmin

        TX->>RX: CF：SN=1
        Note over TX,RX: 按 STmin 等待

        TX->>RX: CF：SN=2
        Note over TX,RX: 按 STmin 等待

        TX->>RX: CF：SN=3
        Note over TX,RX: 按 STmin 等待

        TX->>RX: CF：SN=4
        Note over TX,RX: 达到 BS

        RX->>TX: FC：Flow Control<br/>FS=CTS / BS / STmin

        TX->>RX: CF：SN=5
        TX->>RX: CF：SN=6
        TX->>RX: ...
        TX->>RX: CF：SN=N

        Note over RX: 数据重组完成
    end
```
