#!/usr/bin/env python3
"""
三阶段标准化模式示例

Ingest -> Transform -> Deliver
"""

from dataclasses import dataclass
from pathlib import Path
from typing import Any


# ============ 数据资产定义 ============

@dataclass
class RawData:
    """原始数据资产"""
    source: str
    content: bytes
    metadata: dict


@dataclass
class CleanedData:
    """清洗后数据资产"""
    source: str
    records: list[dict]
    schema: dict


@dataclass
class AnalysisResult:
    """分析结果资产"""
    metrics: dict
    insights: list[str]
    timestamp: str


@dataclass
class Report:
    """最终报告资产"""
    format: str  # "json", "markdown", "pdf"
    content: Any
    destination: str


# ============ Stage 定义 ============

class IngestStage:
    """摄入阶段：从外部源获取数据"""
    
    VERSION = "1.0.0"
    
    # 显式契约声明
    INPUT_SCHEMA = {"source_path": str}
    OUTPUT_SCHEMA = {"raw_data": RawData}
    
    def execute(self, source_path: str) -> dict:
        """
        执行摄入
        
        Args:
            source_path: 数据源路径
            
        Returns:
            {"raw_data": RawData}
        """
        path = Path(source_path)
        content = path.read_bytes()
        
        raw_data = RawData(
            source=str(path),
            content=content,
            metadata={
                "size": len(content),
                "format": path.suffix,
            }
        )
        
        return {"raw_data": raw_data}


class TransformStage:
    """转换阶段：核心业务逻辑（清洗、分析）"""
    
    VERSION = "1.0.0"
    
    INPUT_SCHEMA = {"raw_data": RawData}
    OUTPUT_SCHEMA = {
        "cleaned_data": CleanedData,
        "analysis": AnalysisResult
    }
    
    def execute(self, raw_data: RawData) -> dict:
        """
        执行转换：清洗 + 分析
        
        注意：这是一个纯转换函数，无副作用
        """
        # 1. 清洗
        cleaned = self._clean(raw_data)
        
        # 2. 分析
        analysis = self._analyze(cleaned)
        
        return {
            "cleaned_data": cleaned,
            "analysis": analysis
        }
    
    def _clean(self, raw_data: RawData) -> CleanedData:
        """数据清洗"""
        # 实际实现...
        records = []  # 解析后的记录
        return CleanedData(
            source=raw_data.source,
            records=records,
            schema={}
        )
    
    def _analyze(self, cleaned_data: CleanedData) -> AnalysisResult:
        """数据分析"""
        # 实际实现...
        return AnalysisResult(
            metrics={},
            insights=[],
            timestamp="2025-02-12T00:00:00Z"
        )


class DeliverStage:
    """交付阶段：输出到目标位置"""
    
    VERSION = "1.0.0"
    
    INPUT_SCHEMA = {
        "cleaned_data": CleanedData,
        "analysis": AnalysisResult
    }
    OUTPUT_SCHEMA = {"report": Report}
    SIDE_EFFECTS = ["file_write"]  # 显式声明副作用
    
    def __init__(self, output_dir: str):
        self.output_dir = Path(output_dir)
    
    def execute(self, cleaned_data: CleanedData, analysis: AnalysisResult) -> dict:
        """
        执行交付
        
        注意：此阶段有副作用（文件写入）
        """
        # 生成报告
        report_content = {
            "data_summary": {
                "source": cleaned_data.source,
                "record_count": len(cleaned_data.records)
            },
            "analysis": {
                "metrics": analysis.metrics,
                "insights": analysis.insights
            }
        }
        
        report = Report(
            format="json",
            content=report_content,
            destination=str(self.output_dir / "report.json")
        )
        
        # 执行副作用：写入文件
        self._write_report(report)
        
        return {"report": report}
    
    def _write_report(self, report: Report) -> None:
        """写入报告文件（副作用）"""
        import json
        
        self.output_dir.mkdir(parents=True, exist_ok=True)
        path = Path(report.destination)
        
        with open(path, "w") as f:
            json.dump(report.content, f, indent=2)
        
        print(f"[Side Effect] Report written to: {path}")


# ============ Pipeline 编排 ============

class ThreeStagePipeline:
    """三阶段管道编排器"""
    
    def __init__(self, output_dir: str):
        self.ingest = IngestStage()
        self.transform = TransformStage()
        self.deliver = DeliverStage(output_dir)
    
    def run(self, source_path: str) -> dict:
        """
        执行完整管道
        
        数据流：
            source_path 
                -> IngestStage -> raw_data
                -> TransformStage -> (cleaned_data, analysis)
                -> DeliverStage -> report
        """
        print("=" * 50)
        print("Stage 1: Ingest")
        print("=" * 50)
        ingest_result = self.ingest.execute(source_path)
        
        print("\n" + "=" * 50)
        print("Stage 2: Transform")
        print("=" * 50)
        transform_result = self.transform.execute(
            ingest_result["raw_data"]
        )
        
        print("\n" + "=" * 50)
        print("Stage 3: Deliver")
        print("=" * 50)
        deliver_result = self.deliver.execute(
            transform_result["cleaned_data"],
            transform_result["analysis"]
        )
        
        return {
            "raw_data": ingest_result["raw_data"],
            "cleaned_data": transform_result["cleaned_data"],
            "analysis": transform_result["analysis"],
            "report": deliver_result["report"]
        }


# ============ 使用示例 ============

if __name__ == "__main__":
    # 创建管道实例
    pipeline = ThreeStagePipeline(output_dir="./output")
    
    # 执行管道
    result = pipeline.run(source_path="./data/input.csv")
    
    print("\n" + "=" * 50)
    print("Pipeline Complete!")
    print("=" * 50)
    print(f"Final report: {result['report'].destination}")
