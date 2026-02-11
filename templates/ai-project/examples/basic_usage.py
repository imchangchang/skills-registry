#!/usr/bin/env python3
"""
Prompt 管理系统使用示例
演示如何加载、渲染和使用 prompts
"""

import os
from pathlib import Path

from openai import OpenAI
from utils.prompt_loader import PromptLoader, load_prompt


# 配置
PROMPTS_DIR = Path(__file__).parent.parent / "prompts"
API_KEY = os.getenv("KIMI_API_KEY", "your-api-key")
BASE_URL = "https://api.moonshot.cn/v1"


def example_basic_usage():
    """基础用法：加载并渲染 prompt"""
    print("=" * 50)
    print("示例 1: 基础用法")
    print("=" * 50)
    
    loader = PromptLoader(PROMPTS_DIR)
    
    # 加载代码审查 prompt（自动选择 kimi-k2.5 版本）
    prompt = loader.load("code-review/reviewer", model="kimi-k2.5")
    
    print(f"加载的 Prompt: {prompt.name}")
    print(f"版本: {prompt.metadata.get('version')}")
    print(f"适用模型: {prompt.metadata.get('models')}")
    print(f"模板变量: {prompt.variables}")
    print()
    
    # 渲染模板
    messages = prompt.render(
        code="def hello():\n    print('world')",
        language="python",
        context="这是一个简单的示例函数"
    )
    
    print("渲染后的消息:")
    print(messages[0]["content"][:500] + "...")


def example_model_selection():
    """演示模型特定版本的选择"""
    print("\n" + "=" * 50)
    print("示例 2: 模型特定版本选择")
    print("=" * 50)
    
    loader = PromptLoader(PROMPTS_DIR)
    
    # 加载 Kimi 版本
    kimi_prompt = loader.load("code-review/reviewer", model="kimi-k2.5")
    print(f"Kimi 版本: {kimi_prompt.file_path.name}")
    print(f"  Temperature: {kimi_prompt.get_api_params()['temperature']}")
    
    # 加载 GPT-4o 版本（如果有）
    try:
        gpt_prompt = loader.load("code-review/reviewer", model="gpt-4o")
        print(f"GPT-4o 版本: {gpt_prompt.file_path.name}")
        print(f"  Temperature: {gpt_prompt.get_api_params()['temperature']}")
    except FileNotFoundError:
        print("GPT-4o 版本不存在")


def example_api_call():
    """完整 API 调用示例"""
    print("\n" + "=" * 50)
    print("示例 3: 完整 API 调用")
    print("=" * 50)
    
    client = OpenAI(api_key=API_KEY, base_url=BASE_URL)
    loader = PromptLoader(PROMPTS_DIR)
    
    # 加载系统提示词
    system_prompt = loader.load("chat/system-assistant")
    messages = system_prompt.render()
    
    # 添加用户消息
    messages.append({"role": "user", "content": "你好，请介绍一下自己"})
    
    # 获取 API 参数
    params = system_prompt.get_api_params()
    
    print(f"调用参数: {params}")
    print("发送请求...")
    
    # 调用 API
    try:
        response = client.chat.completions.create(
            model="kimi-k2.5",
            messages=messages,
            **params
        )
        print(f"回复: {response.choices[0].message.content[:200]}...")
    except Exception as e:
        print(f"API 调用失败: {e}")


def example_list_prompts():
    """列出所有可用的 prompts"""
    print("\n" + "=" * 50)
    print("示例 4: 列出所有 Prompts")
    print("=" * 50)
    
    loader = PromptLoader(PROMPTS_DIR)
    prompts = loader.list_prompts()
    
    for category, names in prompts.items():
        print(f"\n[{category}]")
        for name in names:
            print(f"  - {name}")


def example_vision_task():
    """视觉任务示例"""
    print("\n" + "=" * 50)
    print("示例 5: 视觉分析任务")
    print("=" * 50)
    
    loader = PromptLoader(PROMPTS_DIR)
    
    # 加载视觉分析 prompt
    prompt = loader.load("vision/image-analyzer", model="kimi-k2.5")
    messages = prompt.render(analysis_type="technical")
    
    # 添加图片消息
    messages.append({
        "role": "user",
        "content": [
            {"type": "text", "text": "请分析这张图片"},
            # 实际使用时添加图片
            # {
            #     "type": "image_url",
            #     "image_url": {"url": "data:image/png;base64,..."}
            # }
        ]
    })
    
    print(f"视觉分析 Prompt 已准备")
    print(f"内容预览: {messages[0]['content'][:300]}...")


def example_structured_output():
    """结构化输出示例"""
    print("\n" + "=" * 50)
    print("示例 6: 结构化数据提取")
    print("=" * 50)
    
    loader = PromptLoader(PROMPTS_DIR)
    
    # 加载数据提取 prompt
    prompt = loader.load("structured-output/data-extractor")
    
    schema = """
    提取以下字段:
    - name: 人名 (string)
    - age: 年龄 (number)
    - email: 邮箱 (string)
    """
    
    examples = """
    示例:
    输入: "张三，30岁，邮箱是 zhangsan@example.com"
    输出: {"name": "张三", "age": 30, "email": "zhangsan@example.com"}
    """
    
    messages = prompt.render(
        text="李四今年25岁，联系方式是 lisi@company.cn",
        schema_description=schema,
        examples=examples
    )
    
    print(f"结构化提取 Prompt 已准备")
    print(f"要求 JSON 输出: {prompt.metadata.get('parameters', {}).get('response_format')}")


if __name__ == "__main__":
    # 运行所有示例
    example_basic_usage()
    example_model_selection()
    example_list_prompts()
    example_vision_task()
    example_structured_output()
    
    # API 调用示例需要有效的 API Key
    # example_api_call()
