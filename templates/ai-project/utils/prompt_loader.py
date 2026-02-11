#!/usr/bin/env python3
"""
Prompt 加载器 - 管理 YAML Frontmatter 格式的 Prompt 文件

用法:
    loader = PromptLoader("patterns/prompts")
    
    # 加载特定 prompt
    prompt = loader.load("code-review/reviewer", model="kimi-k2.5")
    
    # 渲染模板
    messages = prompt.render(
        code="def foo(): pass",
        language="python",
        context="这是一个示例"
    )
    
    # 获取 API 参数
    response = client.chat.completions.create(
        model=prompt.metadata["parameters"]["model"],
        messages=messages,
        temperature=prompt.metadata["parameters"]["temperature"],
        max_tokens=prompt.metadata["parameters"]["max_tokens"]
    )
"""

from __future__ import annotations

import os
import re
import yaml
from dataclasses import dataclass
from pathlib import Path
from string import Formatter
from typing import Any


@dataclass
class Prompt:
    """表示一个加载的 Prompt"""
    name: str
    content: str
    metadata: dict[str, Any]
    file_path: Path
    
    @property
    def variables(self) -> list[str]:
        """提取模板中的所有变量名"""
        return [
            fname for _, fname, _, _ in Formatter().parse(self.content)
            if fname is not None
        ]
    
    def render(self, **kwargs) -> list[dict[str, str]]:
        """
        渲染 prompt 为消息格式
        
        Returns:
            OpenAI 格式的 messages 列表
        """
        # 检查必需变量
        required = set(self.metadata.get("variables", []))
        provided = set(kwargs.keys())
        missing = required - provided
        if missing:
            raise ValueError(f"缺少必需变量: {missing}")
        
        # 渲染内容
        system_content = self.content.format(**kwargs)
        
        return [
            {"role": "system", "content": system_content}
        ]
    
    def get_api_params(self) -> dict[str, Any]:
        """获取 API 调用参数"""
        params = self.metadata.get("parameters", {})
        return {
            "temperature": params.get("temperature", 0.7),
            "max_tokens": params.get("max_tokens", 2000),
        }


class PromptLoader:
    """
    Prompt 文件加载器
    
    支持按模型选择最优版本，文件命名约定：
    - prompt.md: 通用版本
    - prompt.<model>.md: 特定模型版本（如 prompt.kimi-k2.5.md）
    """
    
    def __init__(self, prompts_dir: str | Path):
        self.prompts_dir = Path(prompts_dir)
        if not self.prompts_dir.exists():
            raise FileNotFoundError(f"Prompt 目录不存在: {prompts_dir}")
    
    def load(self, prompt_path: str, model: str | None = None) -> Prompt:
        """
        加载指定 prompt
        
        Args:
            prompt_path: 相对路径，如 "code-review/reviewer"
            model: 模型名称，用于选择优化版本
        
        Returns:
            Prompt 对象
        """
        base_path = self.prompts_dir / prompt_path
        
        # 尝试查找最优版本
        candidates = []
        if model:
            # 模型特定版本: reviewer.kimi-k2.5.md
            candidates.append(f"{base_path.name}.{model}.md")
            # 简化模型名: reviewer.kimi.md
            model_simple = model.split("-")[0]
            candidates.append(f"{base_path.name}.{model_simple}.md")
        
        # 默认版本: reviewer.md
        candidates.append(f"{base_path.name}.md")
        
        # 查找存在的文件
        file_path = None
        for candidate in candidates:
            candidate_path = base_path.parent / candidate
            if candidate_path.exists():
                file_path = candidate_path
                break
        
        if file_path is None:
            available = list(base_path.parent.glob("*.md")) if base_path.parent.exists() else []
            raise FileNotFoundError(
                f"找不到 prompt: {prompt_path}\n"
                f"尝试的路径: {candidates}\n"
                f"可用文件: {[f.name for f in available]}"
            )
        
        return self._parse_file(file_path)
    
    def list_prompts(self) -> dict[str, list[str]]:
        """
        列出所有可用的 prompts
        
        Returns:
            按类别分组的 prompt 名称列表
        """
        result = {}
        for category_dir in self.prompts_dir.iterdir():
            if not category_dir.is_dir():
                continue
            prompts = []
            for f in category_dir.glob("*.md"):
                # 解析文件名，去掉模型后缀
                name = f.stem
                if "." in name:
                    name = name.split(".")[0]
                if name not in prompts:
                    prompts.append(name)
            if prompts:
                result[category_dir.name] = sorted(prompts)
        return result
    
    def _parse_file(self, file_path: Path) -> Prompt:
        """解析 markdown 文件，提取 frontmatter 和内容"""
        content = file_path.read_text(encoding="utf-8")
        
        # 解析 YAML frontmatter
        pattern = r"^---\s*\n(.*?)\n---\s*\n(.*)$"
        match = re.match(pattern, content, re.DOTALL)
        
        if match:
            try:
                metadata = yaml.safe_load(match.group(1)) or {}
                body = match.group(2).strip()
            except yaml.YAMLError as e:
                raise ValueError(f"YAML 解析错误 in {file_path}: {e}")
        else:
            metadata = {}
            body = content.strip()
        
        return Prompt(
            name=metadata.get("name", file_path.stem),
            content=body,
            metadata=metadata,
            file_path=file_path
        )


# 便捷函数
def load_prompt(prompts_dir: str | Path, prompt_path: str, model: str | None = None) -> Prompt:
    """便捷函数：加载单个 prompt"""
    loader = PromptLoader(prompts_dir)
    return loader.load(prompt_path, model=model)
