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

# 全局缓存 - 存储 名称 -> ID 的映射
assistant_map: Dict[str, str] = {}  # 显示名 -> ID
topic_map: Dict[str, str] = {}  # 显示名 -> ID


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
                pass
    return result


def get_tool_result(result: dict) -> Any:
    """从工具调用结果中提取实际数据"""
    if "result" in result:
        return result["result"]
    return result


def get_id_from_display(display_name: str, mapping: Dict[str, str]) -> str:
    """从显示名获取 ID"""
    if not display_name:
        return ""
    return mapping.get(display_name, display_name)


# ===== 数据获取函数 =====

def fetch_and_cache_data(url: str) -> Tuple[List[str], List[str], dict]:
    """获取并缓存助手和话题数据，返回下拉框选项"""
    global assistant_map, topic_map

    assistant_map = {}
    topic_map = {}
    assistant_choices = ["全部"]
    topic_choices = []

    # 获取助手列表
    result = call_tool(url, "get_overview", {})
    data = get_tool_result(result)

    if isinstance(data, dict) and "assistants" in data:
        for a in data["assistants"]:
            name = a.get("name", "未知")
            aid = a.get("id", "")
            count = a.get("topic_count", 0)
            display = f"{name} ({count}个话题)"
            assistant_map[display] = aid
            assistant_choices.append(display)

    # 获取话题列表
    result = call_tool(url, "list_topics", {"limit": 500})
    data = get_tool_result(result)

    if isinstance(data, dict) and "topics" in data:
        for t in data["topics"]:
            name = t.get("name", "未知")
            tid = t.get("id", "")
            assistant = t.get("assistant_name", "")
            # 截断过长的名称
            short_name = name[:50] + "..." if len(name) > 50 else name
            short_assistant = assistant[:15] if assistant else "未知"
            display = f"[{short_assistant}] {short_name}"
            topic_map[display] = tid
            topic_choices.append(display)

    status = {
        "status": "ok",
        "助手数量": len(assistant_map),
        "话题数量": len(topic_map),
        "message": "数据已加载，可以从下拉框选择"
    }

    return assistant_choices, topic_choices, status


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
        "protocolVersion": "2024-11-05",
        "capabilities": {},
        "clientInfo": {"name": "mcp-debug", "version": "1.0.0"}
    })


def test_list_tools(url: str) -> dict:
    """列出所有可用工具"""
    return call_mcp(url, "tools/list", {})


def test_get_overview(url: str) -> dict:
    """获取数据库总览"""
    return call_tool(url, "get_overview", {})


def query_topics(url, assistant_display, date_range, start_date, end_date, offset, limit):
    """根据时间范围查询话题"""
    args = {}

    # 从显示名获取助手 ID
    if assistant_display and assistant_display != "全部":
        assistant_id = get_id_from_display(assistant_display, assistant_map)
        if assistant_id:
            args["assistant_id"] = assistant_id

    # 计算日期范围
    today = datetime.now().date()
    if date_range == "今天":
        args["start_date"] = today.strftime("%Y-%m-%d")
        args["end_date"] = today.strftime("%Y-%m-%d")
    elif date_range == "昨天":
        yesterday = today - timedelta(days=1)
        args["start_date"] = yesterday.strftime("%Y-%m-%d")
        args["end_date"] = yesterday.strftime("%Y-%m-%d")
    elif date_range == "本周":
        week_start = today - timedelta(days=today.weekday())
        args["start_date"] = week_start.strftime("%Y-%m-%d")
        args["end_date"] = today.strftime("%Y-%m-%d")
    elif date_range == "本月":
        month_start = today.replace(day=1)
        args["start_date"] = month_start.strftime("%Y-%m-%d")
        args["end_date"] = today.strftime("%Y-%m-%d")
    elif date_range == "最近7天":
        args["start_date"] = (today - timedelta(days=7)).strftime("%Y-%m-%d")
        args["end_date"] = today.strftime("%Y-%m-%d")
    elif date_range == "最近30天":
        args["start_date"] = (today - timedelta(days=30)).strftime("%Y-%m-%d")
        args["end_date"] = today.strftime("%Y-%m-%d")
    elif date_range == "自定义":
        if start_date and start_date.strip():
            args["start_date"] = start_date.strip()
        if end_date and end_date.strip():
            args["end_date"] = end_date.strip()

    if offset and offset > 0:
        args["offset"] = int(offset)
    if limit and limit > 0:
        args["limit"] = int(limit)

    return call_tool(url, "list_topics", args)


def test_get_topic_info(url: str, topic_display: str) -> dict:
    """获取话题详情"""
    if not topic_display:
        return {"error": "请选择话题"}
    topic_id = get_id_from_display(topic_display, topic_map)
    if not topic_id:
        return {"error": f"找不到话题 ID: {topic_display}"}
    return call_tool(url, "get_topic_info", {"topic_id": topic_id})


def test_get_conversation(url: str, topic_display: str, mode: str,
                          offset: int, limit: int) -> dict:
    """获取对话内容"""
    if not topic_display:
        return {"error": "请选择话题"}
    topic_id = get_id_from_display(topic_display, topic_map)
    if not topic_id:
        return {"error": f"找不到话题 ID: {topic_display}"}

    args = {"topic_id": topic_id}
    if mode:
        args["mode"] = mode
    if offset and offset > 0:
        args["offset"] = int(offset)
    if limit and limit > 0:
        args["limit"] = int(limit)
    return call_tool(url, "get_conversation", args)


def test_search(url: str, keyword: str, limit: int) -> dict:
    """搜索对话"""
    if not keyword or not keyword.strip():
        return {"error": "请输入搜索关键词"}
    args = {"keyword": keyword.strip()}
    if limit and limit > 0:
        args["limit"] = int(limit)
    return call_tool(url, "search_conversations", args)


def test_activity_summary(url: str, days: int) -> dict:
    """获取活动摘要"""
    args = {}
    if days and days > 0:
        args["days"] = int(days)
    return call_tool(url, "get_activity_summary", args)


def test_related_topics(url: str, topic_display: str, limit: int) -> dict:
    """获取相关话题"""
    if not topic_display:
        return {"error": "请选择话题"}
    topic_id = get_id_from_display(topic_display, topic_map)
    if not topic_id:
        return {"error": f"找不到话题 ID: {topic_display}"}

    args = {"topic_id": topic_id}
    if limit and limit > 0:
        args["limit"] = int(limit)
    return call_tool(url, "get_related_topics", args)


# ===== Gradio UI =====

def create_ui():
    with gr.Blocks(title="MCP Server 调试工具", theme=gr.themes.Soft()) as app:
        gr.Markdown("# 🍒 Cherry Reader MCP Server 调试工具")

        with gr.Row():
            url_input = gr.Textbox(
                label="MCP Server URL",
                value=DEFAULT_URL,
                scale=3
            )
            health_btn = gr.Button("🏥 健康检查", scale=1)
            refresh_btn = gr.Button("🔄 加载数据", scale=1, variant="primary")

        status_output = gr.JSON(label="状态", open=True)
        health_btn.click(test_health, inputs=[url_input], outputs=[status_output])

        with gr.Tabs():
            # 基础测试
            with gr.Tab("🔧 基础"):
                with gr.Row():
                    init_btn = gr.Button("Initialize", scale=1)
                    list_btn = gr.Button("List Tools", scale=1)
                base_output = gr.JSON(label="结果", open=True)
                init_btn.click(test_initialize, inputs=[url_input], outputs=[base_output])
                list_btn.click(test_list_tools, inputs=[url_input], outputs=[base_output])

            # get_overview
            with gr.Tab("📊 Overview"):
                overview_btn = gr.Button("获取数据库总览")
                overview_output = gr.JSON(label="结果", open=True)
                overview_btn.click(test_get_overview, inputs=[url_input], outputs=[overview_output])

            # list_topics
            with gr.Tab("📋 Topics"):
                with gr.Row():
                    topics_assistant = gr.Dropdown(
                        label="选择助手",
                        choices=["全部"],
                        value="全部",
                        scale=2
                    )
                    topics_date_range = gr.Radio(
                        label="时间范围",
                        choices=["全部", "今天", "昨天", "本周", "本月", "最近7天", "最近30天", "自定义"],
                        value="全部",
                        scale=2
                    )
                with gr.Row(visible=False) as custom_date_row:
                    topics_start = gr.Textbox(label="开始日期", placeholder="YYYY-MM-DD", scale=1)
                    topics_end = gr.Textbox(label="结束日期", placeholder="YYYY-MM-DD", scale=1)

                topics_date_range.change(
                    lambda x: gr.update(visible=(x == "自定义")),
                    inputs=[topics_date_range],
                    outputs=[custom_date_row]
                )

                with gr.Row():
                    topics_offset = gr.Number(label="Offset", value=0, precision=0)
                    topics_limit = gr.Number(label="Limit", value=20, precision=0)
                topics_btn = gr.Button("获取话题列表")
                topics_output = gr.JSON(label="结果", open=True)

                topics_btn.click(
                    query_topics,
                    inputs=[url_input, topics_assistant, topics_date_range,
                            topics_start, topics_end, topics_offset, topics_limit],
                    outputs=[topics_output]
                )

            # get_topic_info
            with gr.Tab("📄 Topic Info"):
                topic_info_dropdown = gr.Dropdown(
                    label="选择话题",
                    choices=[],
                    value=None,
                    allow_custom_value=True
                )
                topic_info_btn = gr.Button("获取话题详情")
                topic_info_output = gr.JSON(label="结果", open=True)
                topic_info_btn.click(
                    test_get_topic_info,
                    inputs=[url_input, topic_info_dropdown],
                    outputs=[topic_info_output]
                )

            # get_conversation
            with gr.Tab("💬 Conversation"):
                conv_topic_dropdown = gr.Dropdown(
                    label="选择话题",
                    choices=[],
                    value=None,
                    allow_custom_value=True
                )
                conv_mode = gr.Radio(
                    label="模式",
                    choices=["mainline", "queries_only", "full"],
                    value="mainline"
                )
                with gr.Row():
                    conv_offset = gr.Number(label="Offset", value=0, precision=0)
                    conv_limit = gr.Number(label="Limit", value=50, precision=0)
                conv_btn = gr.Button("获取对话内容")
                conv_output = gr.JSON(label="结果", open=True)
                conv_btn.click(
                    test_get_conversation,
                    inputs=[url_input, conv_topic_dropdown, conv_mode, conv_offset, conv_limit],
                    outputs=[conv_output]
                )

            # search_conversations
            with gr.Tab("🔍 Search"):
                search_keyword = gr.Textbox(label="搜索关键词", placeholder="输入要搜索的内容")
                search_limit = gr.Number(label="Limit", value=20, precision=0)
                search_btn = gr.Button("搜索")
                search_output = gr.JSON(label="结果", open=True)
                search_btn.click(
                    test_search,
                    inputs=[url_input, search_keyword, search_limit],
                    outputs=[search_output]
                )

            # get_activity_summary
            with gr.Tab("📈 Activity"):
                activity_days = gr.Number(label="统计天数", value=7, precision=0)
                activity_btn = gr.Button("获取活动摘要")
                activity_output = gr.JSON(label="结果", open=True)
                activity_btn.click(
                    test_activity_summary,
                    inputs=[url_input, activity_days],
                    outputs=[activity_output]
                )

            # get_related_topics
            with gr.Tab("🔗 Related"):
                related_topic_dropdown = gr.Dropdown(
                    label="选择参考话题",
                    choices=[],
                    value=None,
                    allow_custom_value=True
                )
                related_limit = gr.Number(label="Limit", value=5, precision=0)
                related_btn = gr.Button("获取相关话题")
                related_output = gr.JSON(label="结果", open=True)
                related_btn.click(
                    test_related_topics,
                    inputs=[url_input, related_topic_dropdown, related_limit],
                    outputs=[related_output]
                )

        # 刷新数据按钮 - 更新所有下拉框
        def refresh_all_dropdowns(url):
            assistant_choices, topic_choices, status = fetch_and_cache_data(url)
            return (
                gr.update(choices=assistant_choices, value="全部"),
                gr.update(choices=topic_choices, value=None),
                gr.update(choices=topic_choices, value=None),
                gr.update(choices=topic_choices, value=None),
                status
            )

        refresh_btn.click(
            refresh_all_dropdowns,
            inputs=[url_input],
            outputs=[
                topics_assistant,
                topic_info_dropdown,
                conv_topic_dropdown,
                related_topic_dropdown,
                status_output
            ]
        )

        gr.Markdown("""
        ---
        ### 🚀 快速开始
        1. 确保 Cherry Reader 已启动并开启 MCP Server
        2. **点击「🔄 加载数据」按钮** 加载助手和话题列表
        3. 然后就可以从下拉框选择助手/话题了

        ### 📝 说明
        - 下拉框显示名称，自动转换为 ID 调用 API
        - 点击 JSON 结果中的 **▶** 可以展开/折叠

        ### 💬 对话模式
        | 模式 | 说明 |
        |------|------|
        | mainline | 主线对话（用户问题 + 选中的回复）|
        | queries_only | 仅用户问题 |
        | full | 完整对话（包含所有多模型回复）|
        """)

    return app


if __name__ == "__main__":
    app = create_ui()
    app.launch(
        server_name="127.0.0.1",
        server_port=7860,
        share=False
    )
