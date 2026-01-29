import argparse
import base64
import json
import os
import shlex
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
import re
import shutil
import socket


PROJECT_ROOT = Path(__file__).resolve().parent
IOS_DIR = PROJECT_ROOT / "ios"
DEFAULT_ASC_KEY_ID = "KZM2KMZM68"
DEFAULT_ASC_ISSUER_ID = "0db09752-2c6b-4371-8641-be536322200f"
DEFAULT_ASC_P8_PATH = "/Users/kbaicai/Documents/mmdev/cherryviewer/AuthKey_KZM2KMZM68.p8"
DEFAULT_GIT_CHANGELOG_LIMIT = 20
DEFAULT_LOCAL_PROXY_HOST = "127.0.0.1"
DEFAULT_LOCAL_PROXY_PORT = 7897


@dataclass
class AsciiApiKey:
    key_id: str
    issuer_id: str
    key_content_base64: str


class CommandFailed(RuntimeError):
    def __init__(self, returncode: int, command: list[str], output: str) -> None:
        super().__init__(
            f"Command failed ({returncode}): {shlex.join(command)}")
        self.returncode = returncode
        self.command = command
        self.output = output


def _normalize_proxy_url(raw: str) -> str:
    s = raw.strip()
    if "://" in s:
        return s
    return f"http://{s}"


def _has_proxy_set(env: dict[str, str]) -> bool:
    keys = (
        "http_proxy",
        "https_proxy",
        "all_proxy",
        "HTTP_PROXY",
        "HTTPS_PROXY",
        "ALL_PROXY",
    )
    return any(bool(env.get(k, "").strip()) for k in keys)


def _detect_local_proxy_url() -> str | None:
    try:
        sock = socket.create_connection(
            (DEFAULT_LOCAL_PROXY_HOST, DEFAULT_LOCAL_PROXY_PORT),
            timeout=0.2,
        )
        sock.close()
        return f"http://{DEFAULT_LOCAL_PROXY_HOST}:{DEFAULT_LOCAL_PROXY_PORT}"
    except Exception:
        return None


def _proxy_env(base_env: dict[str, str]) -> dict[str, str]:
    if _has_proxy_set(base_env):
        return {}

    raw = (base_env.get("IOS_PUBLISH_PROXY") or "").strip()
    if raw:
        if raw.lower() in ("off", "false", "0", "none"):
            return {}
        proxy = _normalize_proxy_url(raw)
    else:
        proxy = _detect_local_proxy_url()
        if not proxy:
            return {}

    no_proxy = "localhost,127.0.0.1"
    return {
        "http_proxy": proxy,
        "https_proxy": proxy,
        "all_proxy": proxy,
        "HTTP_PROXY": proxy,
        "HTTPS_PROXY": proxy,
        "ALL_PROXY": proxy,
        "no_proxy": no_proxy,
        "NO_PROXY": no_proxy,
    }


def _run(
    command: list[str],
    cwd: Path | None = None,
    env: dict[str, str] | None = None,
    check: bool = True,
) -> int:
    merged_env = os.environ.copy()
    if env:
        merged_env.update({k: v for k, v in env.items() if v is not None})
    merged_env.update(_proxy_env(merged_env))
    process = subprocess.Popen(
        command,
        cwd=str(cwd) if cwd else None,
        env=merged_env,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1,
    )
    assert process.stdout is not None
    output_lines: list[str] = []
    for line in process.stdout:
        sys.stdout.write(line)
        output_lines.append(line)
    process.wait()
    if check and process.returncode != 0:
        raise CommandFailed(
            int(process.returncode or 1),
            command,
            "".join(output_lines),
        )
    return int(process.returncode or 0)


def _prompt(text: str, default: str | None = None, secret: bool = False) -> str:
    if default:
        prompt = f"{text} [{default}]: "
    else:
        prompt = f"{text}: "
    if secret:
        import getpass

        value = getpass.getpass(prompt)
    else:
        value = input(prompt)
    value = value.strip()
    if not value and default is not None:
        return default
    return value


def _yes_no(text: str, default: bool = False) -> bool:
    d = "Y/n" if default else "y/N"
    value = input(f"{text} ({d}): ").strip().lower()
    if not value:
        return default
    return value in ("y", "yes", "true", "1")


def _fastlane_mode() -> str:
    return (os.environ.get("IOS_PUBLISH_FASTLANE_MODE") or "bundler").strip().lower()


def _ensure_ruby_bundler_fastlane() -> None:
    if not (IOS_DIR / "Gemfile").exists():
        raise RuntimeError(
            "Missing ios/Gemfile. Please update the repo first.")

    _run(["ruby", "-v"], cwd=IOS_DIR)
    _run(["bundle", "-v"], cwd=IOS_DIR)
    _run(["bundle", "config", "set", "--local",
         "path", "vendor/bundle"], cwd=IOS_DIR)
    try:
        _run(["bundle", "check"], cwd=IOS_DIR, check=True)
    except Exception:
        _run(["bundle", "install"], cwd=IOS_DIR, check=True)


def _ensure_fastlane(mode: str) -> None:
    if mode == "brew":
        if shutil.which("fastlane") is None:
            raise RuntimeError("未找到 fastlane，可先执行：brew install fastlane")
        _run(["fastlane", "--version"], cwd=IOS_DIR, check=True)
        return
    if mode != "bundler":
        raise RuntimeError(f"Unknown fastlane mode: {mode}")
    _ensure_ruby_bundler_fastlane()


def _fastlane_cmd(mode: str) -> list[str]:
    if mode == "brew":
        return ["fastlane"]
    return ["bundle", "exec", "fastlane"]


def _is_ssl_eof_error(output: str) -> bool:
    o = output.lower()
    if "ssl_connect returned" in o and "unexpected eof while reading" in o:
        return True
    if "state=error: unexpected eof while reading" in o:
        return True
    return False


def _git_output(args: list[str]) -> str:
    return subprocess.check_output(
        ["git", *args],
        cwd=str(PROJECT_ROOT),
        text=True,
        stderr=subprocess.DEVNULL,
    ).strip()


def _try_get_last_tag() -> str | None:
    try:
        tag = _git_output(["describe", "--tags", "--abbrev=0"])
        return tag if tag else None
    except Exception:
        return None


def _generate_release_notes_from_git(limit: int = DEFAULT_GIT_CHANGELOG_LIMIT) -> list[str]:
    last_tag = _try_get_last_tag()
    range_args: list[str] = []
    if last_tag:
        range_args = [f"{last_tag}..HEAD"]
    pretty = ["--pretty=format:%h %s"]
    base = ["log", *range_args, *pretty]
    if not range_args:
        base = ["log", f"-n{max(1, int(limit))}", *pretty]
    try:
        out = _git_output(base)
    except Exception:
        return []

    lines: list[str] = []
    for raw in out.splitlines():
        s = raw.strip()
        if not s:
            continue
        if s.lower().startswith("merge "):
            continue
        lines.append(s)
        if len(lines) >= int(limit):
            break
    return lines


def _write_ios_release_notes_from_git(limit: int = DEFAULT_GIT_CHANGELOG_LIMIT) -> Path | None:
    metadata_dir = IOS_DIR / "fastlane" / "metadata"
    if not metadata_dir.exists():
        return None
    targets = sorted(metadata_dir.glob("*/release_notes.txt"))
    if not targets:
        return None

    commits = _generate_release_notes_from_git(limit=limit)
    for p in targets:
        locale = p.parent.name
        if locale.lower() == "en-us":
            if commits:
                safe = [re.sub(r"(?i)\bandroid\b", "mobile", c)
                        for c in commits]
                body = "What's New:\n" + \
                    "\n".join(f"- {c}" for c in safe) + "\n"
            else:
                body = "Bug fixes and performance improvements.\n"
        else:
            if commits:
                safe = [re.sub(r"(?i)\bandroid\b", "移动端", c) for c in commits]
                body = "本次更新：\n" + "\n".join(f"- {c}" for c in safe) + "\n"
            else:
                body = "本次更新：\n- 性能优化与稳定性提升\n- 修复若干已知问题\n"
        p.write_text(body, encoding="utf-8")
    return targets[0]


def _bump_pubspec_build_number() -> tuple[str, str] | None:
    pubspec = PROJECT_ROOT / "pubspec.yaml"
    if not pubspec.exists():
        return None
    content = pubspec.read_text(encoding="utf-8")
    m = re.search(r"(?m)^\s*version:\s*([^\s#]+)\s*$", content)
    if not m:
        return None
    old_version = m.group(1).strip().strip("'\"")
    if "+" in old_version:
        name, build_raw = old_version.split("+", 1)
        try:
            build = int(build_raw)
        except ValueError:
            build = 0
        new_version = f"{name}+{build + 1}"
    else:
        new_version = f"{old_version}+1"
    new_content = content[: m.start(1)] + new_version + content[m.end(1):]
    pubspec.write_text(new_content, encoding="utf-8")
    return old_version, new_version


def _prepare_version_and_notes_for_store() -> None:
    flag = (os.environ.get("IOS_PUBLISH_PREPARE") or "1").strip().lower()
    if flag in ("0", "false", "off", "no", "none"):
        return
    bumped = _bump_pubspec_build_number()
    if bumped:
        old_v, new_v = bumped
        print(f"\n已自增版本号：{old_v} -> {new_v}")
    notes_path = _write_ios_release_notes_from_git()
    if notes_path:
        print(f"已更新更新说明：{notes_path}")


def _list_flutter_ios_simulators() -> list[dict]:
    result = subprocess.check_output(
        ["flutter", "devices", "--machine"],
        text=True,
    )
    devices = json.loads(result)
    ios_simulators: list[dict] = []
    for d in devices:
        if d.get("targetPlatform") == "ios" and bool(d.get("emulator", False)):
            ios_simulators.append(d)
    return ios_simulators


def _choose_simulator_udid() -> str:
    sims = _list_flutter_ios_simulators()
    if not sims:
        raise RuntimeError(
            "No iOS simulators found. Open Xcode once and install a Simulator runtime.")

    print("\n可用 iOS 模拟器：")
    for idx, d in enumerate(sims, start=1):
        print(f"  {idx}. {d.get('name')}  ({d.get('id')})")

    raw = _prompt("选择模拟器序号", default="1")
    try:
        i = int(raw)
    except ValueError:
        raise RuntimeError("请输入数字序号")
    if i < 1 or i > len(sims):
        raise RuntimeError("序号超出范围")
    return str(sims[i - 1]["id"])


def _read_p8_as_base64(p8_path: str) -> str:
    p = Path(p8_path).expanduser()
    if not p.is_absolute():
        p = (Path.cwd() / p).resolve()
    if not p.exists():
        raise RuntimeError(f"找不到 p8 文件: {p}")
    content = p.read_bytes()
    return base64.b64encode(content).decode("ascii")


def _collect_asc_api_key_interactive() -> AsciiApiKey:
    default_key_id = os.environ.get("ASC_KEY_ID") or DEFAULT_ASC_KEY_ID
    default_issuer_id = os.environ.get(
        "ASC_ISSUER_ID") or DEFAULT_ASC_ISSUER_ID

    default_p8_path = os.environ.get("ASC_P8_PATH") or DEFAULT_ASC_P8_PATH
    key_content_env = (os.environ.get("ASC_KEY_CONTENT") or "").strip()

    noninteractive = (os.environ.get("IOS_PUBLISH_NONINTERACTIVE") or "").strip().lower() in (
        "1",
        "true",
        "yes",
    ) or not sys.stdin.isatty()

    if noninteractive:
        key_id = default_key_id
        issuer_id = default_issuer_id
        if key_content_env:
            key_content_base64 = key_content_env
        elif default_p8_path and Path(default_p8_path).expanduser().exists():
            key_content_base64 = _read_p8_as_base64(default_p8_path)
        else:
            raise RuntimeError(
                "非交互模式下未提供 ASC_KEY_CONTENT，且 ASC_P8_PATH 不存在或为空")
        return AsciiApiKey(key_id=key_id, issuer_id=issuer_id, key_content_base64=key_content_base64)

    if not Path(default_p8_path).expanduser().exists():
        default_p8_path = ""

    key_id = _prompt("ASC Key ID（10 位左右字母数字）", default=default_key_id)
    issuer_id = _prompt("ASC Issuer ID（UUID）", default=default_issuer_id)
    p8_path = _prompt("p8 文件路径（推荐，直接填 AuthKey_*.p8 路径）",
                      default=default_p8_path)
    if p8_path:
        key_content_base64 = _read_p8_as_base64(p8_path)
    else:
        key_content_base64 = _prompt("ASC_KEY_CONTENT（base64，一行）", secret=True)
    if not key_id or not issuer_id or not key_content_base64:
        raise RuntimeError("Key ID / Issuer ID / Key Content 不能为空")
    return AsciiApiKey(key_id=key_id, issuer_id=issuer_id, key_content_base64=key_content_base64)


def _fastlane_env_from_key(k: AsciiApiKey) -> dict[str, str]:
    return {
        "ASC_KEY_ID": k.key_id,
        "ASC_ISSUER_ID": k.issuer_id,
        "ASC_KEY_CONTENT": k.key_content_base64,
    }


def action_screenshots() -> None:
    mode = _fastlane_mode()
    _ensure_fastlane(mode)

    locale = _prompt("截图 locale（建议 zh-Hans 或 en-US）", default="zh-Hans")
    device_name = _prompt("截图设备名称（用于文件名）", default="iPhone 17 Pro")

    use_auto = _yes_no("自动选择一个 iOS 模拟器 UDID？", default=True)
    if use_auto:
        udid = _choose_simulator_udid()
    else:
        udid = _prompt("IOS_SIMULATOR_UDID（从 flutter devices 复制）")

    env = {
        "FASTLANE_LOCALE": locale,
        "FASTLANE_DEVICE_NAME": device_name,
        "IOS_SIMULATOR_UDID": udid,
    }

    _run([*_fastlane_cmd(mode), "ios", "screenshots"],
         cwd=IOS_DIR, env=env, check=True)

    out_dir = PROJECT_ROOT / "ios" / "fastlane" / "screenshots" / locale
    print(f"\n截图输出目录：{out_dir}")


def action_build_ipa() -> None:
    mode = _fastlane_mode()
    _ensure_fastlane(mode)
    _prepare_version_and_notes_for_store()
    _run([*_fastlane_cmd(mode), "ios", "build_ipa"], cwd=IOS_DIR, check=True)
    ipa = PROJECT_ROOT / "build" / "ios" / "ipa" / "Runner.ipa"
    if ipa.exists():
        print(f"\nIPA 已生成：{ipa}")
    else:
        print("\n未在 build/ios/ipa 找到 Runner.ipa，请检查上面的输出日志。")


def action_upload_metadata() -> None:
    mode = _fastlane_mode()
    _ensure_fastlane(mode)
    _prepare_version_and_notes_for_store()
    k = _collect_asc_api_key_interactive()
    _run(
        [*_fastlane_cmd(mode), "ios", "metadata"],
        cwd=IOS_DIR,
        env=_fastlane_env_from_key(k),
        check=True,
    )


def action_upload_testflight() -> None:
    mode = _fastlane_mode()
    _ensure_fastlane(mode)
    _prepare_version_and_notes_for_store()
    k = _collect_asc_api_key_interactive()
    commits = _generate_release_notes_from_git(
        limit=DEFAULT_GIT_CHANGELOG_LIMIT)
    changelog = "\n".join(f"- {c}" for c in commits) if commits else None
    _run(
        [*_fastlane_cmd(mode), "ios", "beta"],
        cwd=IOS_DIR,
        env={**_fastlane_env_from_key(k),
             "TESTFLIGHT_CHANGELOG": changelog or ""},
        check=True,
    )


def action_upload_appstore() -> None:
    mode = _fastlane_mode()
    _ensure_fastlane(mode)
    _prepare_version_and_notes_for_store()
    k = _collect_asc_api_key_interactive()
    try:
        _run(
            [*_fastlane_cmd(mode), "ios", "release"],
            cwd=IOS_DIR,
            env=_fastlane_env_from_key(k),
            check=True,
        )
    except CommandFailed as e:
        if mode != "brew" and _is_ssl_eof_error(e.output) and shutil.which("fastlane") is not None:
            print("\n检测到 fastlane SSL 连接异常，尝试改用 Homebrew 版 fastlane 重试一次…")
            _ensure_fastlane("brew")
            _run(
                [*_fastlane_cmd("brew"), "ios", "release"],
                cwd=IOS_DIR,
                env=_fastlane_env_from_key(k),
                check=True,
            )
            return
        raise


def interactive_menu() -> None:
    while True:
        print(
            "\n选择要执行的动作：\n"
            "  1) 生成截图（fastlane ios screenshots）\n"
            "  2) 构建 IPA（fastlane ios build_ipa）\n"
            "  3) 仅更新 App Store 文案/截图（fastlane ios metadata）\n"
            "  4) 上传 TestFlight（fastlane ios beta）\n"
            "  5) 上传 App Store（仅二进制，fastlane ios release）\n"
            "  0) 退出\n"
        )
        choice = _prompt("输入序号", default="0")
        if choice == "0":
            return
        try:
            if choice == "1":
                action_screenshots()
            elif choice == "2":
                action_build_ipa()
            elif choice == "3":
                action_upload_metadata()
            elif choice == "4":
                action_upload_testflight()
            elif choice == "5":
                action_upload_appstore()
            else:
                print("无效选项，请重试。")
        except CommandFailed as e:
            if _is_ssl_eof_error(e.output):
                print(
                    "\n上传过程中出现 SSL 连接异常（unexpected eof while reading）。\n"
                    "通常是 Ruby/OpenSSL 环境或网络/代理导致，不是 Fastfile 逻辑错误。\n\n"
                    "优先解决方案：\n"
                    "  1) 安装自带 OpenSSL 的 fastlane：brew install fastlane\n"
                    "  2) 然后使用：IOS_PUBLISH_FASTLANE_MODE=brew python ios_publish.py release\n\n"
                    "如果仍失败：\n"
                    "  - 换网络/关闭代理/VPN 后重试\n"
                    "  - 在 ios 目录检查 OpenSSL：ruby -ropenssl -e 'puts OpenSSL::OPENSSL_VERSION'\n"
                )
            else:
                print(f"\n执行失败：{e}")
        except Exception as e:
            print(f"\n执行失败：{e}")


def main() -> None:
    parser = argparse.ArgumentParser(prog="ios_publish.py")
    sub = parser.add_subparsers(dest="cmd")

    sub.add_parser("menu")
    sub.add_parser("screenshots")
    sub.add_parser("build_ipa")
    sub.add_parser("metadata")
    sub.add_parser("beta")
    sub.add_parser("release")
    sub.add_parser("prepare")

    args = parser.parse_args()

    cmd = args.cmd or "menu"
    try:
        if cmd == "menu":
            interactive_menu()
        elif cmd == "screenshots":
            action_screenshots()
        elif cmd == "build_ipa":
            action_build_ipa()
        elif cmd == "metadata":
            action_upload_metadata()
        elif cmd == "beta":
            action_upload_testflight()
        elif cmd == "release":
            action_upload_appstore()
        elif cmd == "prepare":
            _prepare_version_and_notes_for_store()
        else:
            raise RuntimeError(f"Unknown command: {cmd}")
    except CommandFailed as e:
        if _is_ssl_eof_error(e.output):
            print(
                "\n上传过程中出现 SSL 连接异常（unexpected eof while reading）。\n"
                "通常是 Ruby/OpenSSL 环境或网络/代理导致。\n\n"
                "优先解决方案：\n"
                "  1) brew install fastlane\n"
                "  2) IOS_PUBLISH_FASTLANE_MODE=brew python ios_publish.py release\n"
            )
        else:
            print(str(e))
        raise SystemExit(e.returncode)
    except Exception as e:
        print(str(e))
        raise SystemExit(1)


if __name__ == "__main__":
    main()
