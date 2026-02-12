# 管道架构速查表

## 核心原则

| 原则 | 说明 |
|-----|------|
| 数据流即程序 | 程序 = 数据在各阶段的流动 |
| 渐进式复杂度 | 从简单开始，按需增加功能 |
| 可观测性 | 每个阶段都可监控、可调试 |

## 三阶段标准

```
[Extract] → [Transform] → [Load]
   输入        处理         输出
```

## 设计决策树

```
需要缓存？
├─ 是 → 添加 Cache Layer
└─ 否 → 继续

需要并行？
├─ 是 → 使用 Parallel Stage
└─ 否 → 顺序执行

需要错误恢复？
├─ 是 → 添加 Checkpoint
└─ 否 → 简单错误处理
```

## 关键接口

```python
class Stage(ABC):
    @abstractmethod
    def process(self, data: Any) -> Any: pass
```
