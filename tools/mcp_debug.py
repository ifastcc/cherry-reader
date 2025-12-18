#!/usr/bin/env python3
"""
MCP Server 调试工具

使用 Gradio 提供 Web 界面，测试 Cherry Reader MCP Server 的各个工具。

使用方法:
    pip install gradio requests
    python mcp_debug.py

然后访问 http://localhost:7860
"""

import json
import requests
import gradio as gr
from datetime import datetime, timedelta
from typing import Any, Optional, List, Tuple, Dict

DEFAULT_URL = "http://127.0.0.1:9527/mcp"

# 全局缓存 - 存储话题选项
topic_list: List[Dict[str, Any]] = []


def call_mcp(url: str, method: str, params: dict = None) -> dict:
    """调用 MCP JSON-RPC 方法"""
    payload = {
        "jsonrpc": "2.0",
        "id": 1,
        "method": method,
    }
    if params:
        payload["params"] = params

    try:
        response = requests.post(
            url,
            json=payload,
            headers={"Content-Type": "application/json"},
            timeout=30
        )
        response.raise_for_status()
        return response.json()
    except requests.exceptions.ConnectionError:
        return {"error": f"连接失败: {url}", "hint": "请确保 Cherry Reader 已启动并开启了 MCP Server"}
    except Exception as e:
        return {"error": str(e)}


def call_tool(url: str, tool_name: str, arguments: dict) -> dict:
    """调用 MCP 工具，返回字典"""
    result = call_mcp(url, "tools/call", {
        "name": tool_name,
        "arguments": arguments
    })
    # 如果结果中有 content，尝试解析 JSON
    if "result" in result and "content" in result["result"]:
        content = result["result"]["content"]
        if isinstance(content, list) and len(content) > 0:
            text = content[0].get("text", "")
            try:
                parsed = json.loads(text)
                return {"tool": tool_name, "arguments": arguments, "result": parsed}
            except:
                return {"tool": tool_name, "arguments": arguments, "result": text}
    return result


def get_tool_result(result: dict) -> Any:
    """从工具调用结果中提取实际数据"""
    if "result" in result:
        return result["result"]
    return result


# ===== 工具调用函数 =====

def test_health(url: str) -> dict:
    """测试健康检查"""
    try:
        health_url = url.replace('/mcp', '/health')
        response = requests.get(health_url, timeout=5)
        return {"endpoint": health_url, "status": "ok", "response": response.json()}
    except Exception as e:
        return {"endpoint": url.replace('/mcp', '/health'), "status": "error", "error": str(e)}


def test_initialize(url: str) -> dict:
    """测试 MCP 初始化"""
    return call_mcp(url, "initialize", {
        "protocolVersion": "2025-03-26",
        "capabilities": {},
        "clientInfo": {"name": "mcp-debug", "version": "1.0.0"}
    })


def test_list_tools(url: str) -> dict:
    """列出所有可用工具"""
    return call_mcp(url, "tools/list", {})


# ===== recall_my_conversations =====

def recall_conversations(url: str, period: str, start_date: str, end_date: str,
                         min_rounds: int, assistant_filter: str, limit: int) -> dict:
    """回顾对话"""
    global topic_list

    args = {}

    if period and period != "全部":
        args["period"] = period

    if period == "custom":
        if start_date and start_date.strip():
            args["start_date"] = start_date.strip()
        if end_date and end_date.strip():
            args["end_date"] = end_date.strip()

    if min_rounds and min_rounds > 0:
        args["min_rounds"] = int(min_rounds)

    if assistant_filter and assistant_filter.strip():
        args["assistant_filter"] = assistant_filter.strip()

    if limit and limit > 0:
        args["limit"] = int(limit)

    result = call_tool(url, "recall_my_conversations", args)

    # 缓存话题列表用于下拉框
    data = get_tool_result(result)
    if isinstance(data, dict) and "topics" in data:
        topic_list = data["topics"]

    return result


# ===== search_past_discussions =====

def search_discussions(url: str, query: str, assistant_filter: str, search_mode: str,
                       min_score: float, time_range_days: int, min_rounds: int, limit: int) -> dict:
    """搜索历史讨论"""
    global topic_list

    if not query or not query.strip():
        return {"error": "请输入搜索关键词"}

    args = {"query": query.strip()}

    if assistant_filter and assistant_filter.strip():
        args["assistant_filter"] = assistant_filter.strip()

    if search_mode:
        args["search_mode"] = search_mode

    if min_score and min_score > 0:
        args["min_score"] = float(min_score)

    if time_range_days and time_range_days > 0:
        args["time_range_days"] = int(time_range_days)

    if min_rounds and min_rounds > 0:
        args["min_rounds"] = int(min_rounds)

    if limit and limit > 0:
        args["limit"] = int(limit)

    result = call_tool(url, "search_past_discussions", args)

    # 缓存话题列表
    data = get_tool_result(result)
    if isinstance(data, dict) and "related_topics" in data:
        topic_list = data["related_topics"]

    return result


# ===== read_conversation_detail =====

def read_conversation(url: str, topic_display: str, mode: str, start_round: int,
                      round_count: int, include_thinking: bool) -> dict:
    """读取对话详情"""
    # 从显示名提取 topic_id
    topic_id = ""
    if topic_display:
        # 显示格式: "话题名称 (topic_id)"
        if "(" in topic_display and topic_display.endswith(")"):
            topic_id = topic_display.rsplit("(", 1)[-1].rstrip(")")
        else:
            topic_id = topic_display

    if not topic_id:
        return {"error": "请选择或输入话题 ID"}

    args = {"topic_id": topic_id}

    if mode:
        args["mode"] = mode

    if start_round and start_round > 0:
        args["start_round"] = int(start_round)

    if round_count and round_count > 0:
        args["round_count"] = int(round_count)

    if include_thinking:
        args["include_thinking"] = True

    return call_tool(url, "read_conversation_detail", args)


def get_topic_choices() -> List[str]:
    """获取话题下拉框选项"""
    if not topic_list:
        return []

    choices = []
    for t in topic_list:
        name = t.get("topic_name", "未知")
        tid = t.get("topic_id", "")
        rounds = t.get("round_count", 0)
        # 截断过长的名称
        short_name = name[:40] + "..." if len(name) > 40 else name
        display = f"{short_name} [{rounds}轮] ({tid})"
        choices.append(display)

    return choices


def update_topic_dropdown():
    """更新话题下拉框"""
    choices = get_topic_choices()
    return gr.update(choices=choices, value=None if not choices else choices[0])


# ===== Gradio UI =====

def create_ui():
    with gr.Blocks(title="MCP Server 调试工具", theme=gr.themes.Soft()) as app:
        gr.Markdown("# 🍒 Cherry Reader MCP Server 调试工具")
        gr.Markdown("**新版工具**: `recall_my_conversations`, `search_past_discussions`, `read_conversation_detail`")

        with gr.Row():
            url_input = gr.Textbox(
                label="MCP Server URL",
                value=DEFAULT_URL,
                scale=3
            )
            health_btn = gr.Button("🏥 健康检查", scale=1)

        status_output = gr.JSON(label="状态", open=True)
        health_btn.click(test_health, inputs=[url_input], outputs=[status_output])

        with gr.Tabs():
            # 基础测试
            with gr.Tab("🔧 基础"):
                gr.Markdown("### MCP 协议基础测试")
                with gr.Row():
                    init_btn = gr.Button("Initialize", scale=1)
                    list_btn = gr.Button("List Tools", scale=1)
                base_output = gr.JSON(label="结果", open=True)
                init_btn.click(test_initialize, inputs=[url_input], outputs=[base_output])
                list_btn.click(test_list_tools, inputs=[url_input], outputs=[base_output])

            # recall_my_conversations
            with gr.Tab("📅 回顾对话"):
                gr.Markdown("""### recall_my_conversations

回顾某段时间内聊过的内容，按话题分组返回用户问题列表。

**使用场景**: "这周聊了什么"、"最近在关注什么"、"回顾一下我的对话"
                """)

                with gr.Row():
                    recall_period = gr.Radio(
                        label="时间范围",
                        choices=["today", "yesterday", "this_week", "this_month",
                                 "last_7_days", "last_30_days", "custom"],
                        value="this_week",
                        scale=3
                    )

                with gr.Row(visible=False) as custom_date_row:
                    recall_start = gr.Textbox(label="开始日期", placeholder="YYYY-MM-DD", scale=1)
                    recall_end = gr.Textbox(label="结束日期", placeholder="YYYY-MM-DD", scale=1)

                recall_period.change(
                    lambda x: gr.update(visible=(x == "custom")),
                    inputs=[recall_period],
                    outputs=[custom_date_row]
                )

                with gr.Row():
                    recall_min_rounds = gr.Number(label="最小轮次", value=1, precision=0)
                    recall_limit = gr.Number(label="数量限制", value=100, precision=0)

                recall_assistant = gr.Textbox(
                    label="助手筛选（可选）",
                    placeholder="如 Claude、GPT，支持空格分隔多个关键词"
                )

                recall_btn = gr.Button("获取对话回顾", variant="primary")
                recall_output = gr.JSON(label="结果", open=True)

                recall_btn.click(
                    recall_conversations,
                    inputs=[url_input, recall_period, recall_start, recall_end,
                            recall_min_rounds, recall_assistant, recall_limit],
                    outputs=[recall_output]
                )

            # search_past_discussions
            with gr.Tab("🔍 搜索讨论"):
                gr.Markdown("""### search_past_discussions

搜索历史讨论过的相关话题，支持语义搜索和关键词搜索。

**使用场景**: "之前聊过XX吗"、"找一下关于XX的讨论"、"有没有讨论过XX"
                """)

                search_query = gr.Textbox(
                    label="搜索关键词（必填）",
                    placeholder="如：人生意义、职业规划、代码重构"
                )

                with gr.Row():
                    search_mode = gr.Radio(
                        label="搜索模式",
                        choices=["semantic", "keyword"],
                        value="semantic",
                        scale=2
                    )
                    search_min_score = gr.Slider(
                        label="最小相似度（仅语义搜索）",
                        minimum=0,
                        maximum=1,
                        value=0.5,
                        step=0.1,
                        scale=2
                    )

                with gr.Row():
                    search_time_range = gr.Number(label="时间范围（天，0=全部）", value=0, precision=0)
                    search_min_rounds = gr.Number(label="最小轮次", value=1, precision=0)
                    search_limit = gr.Number(label="数量限制", value=30, precision=0)

                search_assistant = gr.Textbox(
                    label="助手筛选（可选）",
                    placeholder="如 Claude、GPT，支持空格分隔多个关键词"
                )

                search_btn = gr.Button("搜索", variant="primary")
                search_output = gr.JSON(label="结果", open=True)

                search_btn.click(
                    search_discussions,
                    inputs=[url_input, search_query, search_assistant, search_mode,
                            search_min_score, search_time_range, search_min_rounds, search_limit],
                    outputs=[search_output]
                )

            # read_conversation_detail
            with gr.Tab("💬 对话详情"):
                gr.Markdown("""### read_conversation_detail

读取某个话题的完整对话内容。

**使用场景**: 需要查看具体某个话题的详细问答（需要先用其他工具获取 topic_id）

**模式说明**:
| 模式 | 说明 |
|------|------|
| queries_only | 仅用户问题 |
| mainline | 主线对话（用户问题 + 选中的回复）|
| full | 完整对话（包含所有多模型回复）|
                """)

                with gr.Row():
                    conv_topic = gr.Dropdown(
                        label="选择话题",
                        choices=[],
                        value=None,
                        allow_custom_value=True,
                        scale=3
                    )
                    refresh_topics_btn = gr.Button("🔄 刷新列表", scale=1)

                refresh_topics_btn.click(
                    update_topic_dropdown,
                    outputs=[conv_topic]
                )

                conv_mode = gr.Radio(
                    label="获取模式",
                    choices=["queries_only", "mainline", "full"],
                    value="mainline"
                )

                with gr.Row():
                    conv_start_round = gr.Number(label="起始轮次", value=0, precision=0)
                    conv_round_count = gr.Number(label="获取轮数", value=10, precision=0)
                    conv_include_thinking = gr.Checkbox(label="包含思考过程", value=False)

                conv_btn = gr.Button("读取对话", variant="primary")
                conv_output = gr.JSON(label="结果", open=True)

                conv_btn.click(
                    read_conversation,
                    inputs=[url_input, conv_topic, conv_mode, conv_start_round,
                            conv_round_count, conv_include_thinking],
                    outputs=[conv_output]
                )

                # 当回顾或搜索完成后自动更新下拉框
                recall_btn.click(
                    update_topic_dropdown,
                    outputs=[conv_topic]
                )
                search_btn.click(
                    update_topic_dropdown,
                    outputs=[conv_topic]
                )

        gr.Markdown("""
---
### 🚀 快速开始

1. 确保 Cherry Reader 已启动并开启 MCP Server
2. 点击「🏥 健康检查」验证连接
3. 使用「📅 回顾对话」或「🔍 搜索讨论」获取话题列表
4. 在「💬 对话详情」中查看具体对话内容

### 📝 工具说明

| 工具 | 用途 | 必填参数 |
|------|------|---------|
| `recall_my_conversations` | 时间维度回顾对话 | 无 |
| `search_past_discussions` | 搜索历史讨论 | query |
| `read_conversation_detail` | 读取对话详情 | topic_id |

### 💡 提示

- **语义搜索**需要配置 Embedding 服务，否则会自动降级到关键词搜索
- 点击 JSON 结果中的 **▶** 可以展开/折叠
- 话题列表会在「回顾对话」或「搜索讨论」后自动缓存，可在「对话详情」中选择
        """)

    return app


if __name__ == "__main__":
    app = create_ui()
    app.launch(
        server_name="127.0.0.1",
        server_port=7860,
        share=False
    )
