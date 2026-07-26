#!/usr/bin/env python3
"""feishu_push.py 测试 — 参数解析 + 配置加载 + 错误路径"""
import json
import os
import sys
import tempfile
import unittest
import subprocess

SCRIPTS = os.path.join(os.path.dirname(__file__), "..", "scripts")
FEISHU_PUSH = os.path.join(SCRIPTS, "feishu_push.py")

# 有效凭证内容
VALID_CONF = """FEISHU_APP_ID=cli_test123
FEISHU_APP_SECRET=test_secret_xxx
FEISHU_RECEIVE_ID=ou_test456
"""


class TestFeishuPush(unittest.TestCase):
    """通过子进程 + 临时配置文件测试"""

    def _mkconf(self, content=VALID_CONF):
        """创建临时配置文件，返回 (conf_path, home_dir)"""
        tmpdir = tempfile.mkdtemp()
        conf = os.path.join(tmpdir, ".fleet-dashboard.conf")
        with open(conf, "w") as f:
            f.write(content)
        return conf, tmpdir

    def _run(self, *args, stdin_text=None, conf_content=VALID_CONF):
        """运行 feishu_push.py, 返回 (exitcode, stdout, stderr)"""
        _, home = self._mkconf(conf_content)
        # Windows: ~ 展开优先 USERPROFILE，需同时覆盖
        env = {**os.environ, "HOME": home, "USERPROFILE": home}
        r = subprocess.run(
            [sys.executable, FEISHU_PUSH, *args],
            env=env, input=stdin_text,
            capture_output=True, text=True, timeout=10
        )
        return r.returncode, r.stdout, r.stderr

    # ── 参数解析 ──

    def test_missing_message(self):
        """-m 空字符串 → exit 1"""
        code, out, err = self._run("-m", "")
        self.assertEqual(code, 1)

    def test_missing_both(self):
        """无 -m 且无 stdin → exit 1"""
        code, out, err = self._run()
        self.assertEqual(code, 1)

    def test_help(self):
        """--help 正常输出"""
        code, out, err = self._run("--help")
        self.assertEqual(code, 0)
        self.assertTrue(len(out + err) > 0)

    # ── 配置文件 ──

    def test_no_conf_file(self):
        """配置文件不存在 → exit 2"""
        env = {**os.environ, "HOME": "/nonexistent", "USERPROFILE": "/nonexistent"}
        r = subprocess.run(
            [sys.executable, FEISHU_PUSH, "-m", "test"],
            env=env, capture_output=True, text=True, timeout=10
        )
        self.assertEqual(r.returncode, 2)

    def test_missing_key(self):
        """缺少必填字段 → exit 2"""
        code, out, err = self._run(
            "-m", "test",
            conf_content="FEISHU_APP_ID=cli\n# no SECRET or RECEIVE_ID\n"
        )
        self.assertEqual(code, 2)

    def test_conf_valid(self):
        """有效配置 — 加载后尝试 HTTP (网络不可达 → exit 3)"""
        conf = "FEISHU_APP_ID=cli\nFEISHU_APP_SECRET=sec\nFEISHU_RECEIVE_ID=ou\n"
        code, out, err = self._run("-m", "test", conf_content=conf)
        # exit 3 = token fetch 网络不可达; exit 2 = 配置错误
        self.assertNotEqual(code, 2, msg=f"unexpected exit 2: {err}")

    # ── 消息格式 ──

    def test_stdin_pipe(self):
        """stdin 管道 → 消息正确传入（验证不会报 exit 1）"""
        code, out, err = self._run(stdin_text="pipe test message")
        # 无 -m 时从 stdin 读取, 配置正确则不应报 exit 1
        self.assertNotEqual(code, 1)

    def test_message_arg(self):
        """-m 参数 → 消息正确传入"""
        code, out, err = self._run("-m", "arg test message")
        self.assertNotEqual(code, 1)


if __name__ == "__main__":
    if not os.path.exists(FEISHU_PUSH):
        print(f"SKIP: {FEISHU_PUSH} not found")
        sys.exit(0)
    unittest.main(verbosity=2)
