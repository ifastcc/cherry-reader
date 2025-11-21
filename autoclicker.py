import tkinter as tk
from tkinter import ttk, messagebox
import threading
import time
from pynput.mouse import Controller, Button
from pynput import keyboard

class AutoClickerApp:
    def __init__(self, root):
        self.root = root
        self.root.title("极速连点器 (MacOS)")
        self.root.geometry("350x350")
        self.root.resizable(False, False)

        # 状态变量
        self.running = False
        self.click_thread = None
        self.mouse = Controller()
        self.click_count = 0
        
        # 默认参数
        self.hotkey = keyboard.Key.f8
        self.hotkey_name = "F8"

        # 界面布局
        self.create_widgets()
        
        # 键盘监听器
        self.listener = keyboard.Listener(on_press=self.on_key_press)
        self.listener.start()

        # 绑定关闭事件
        self.root.protocol("WM_DELETE_WINDOW", self.on_closing)

    def create_widgets(self):
        # 样式
        style = ttk.Style()
        style.configure("TButton", font=("Arial", 12))
        style.configure("TLabel", font=("Arial", 11))

        # 标题
        title_label = ttk.Label(self.root, text="Python 连点器", font=("Arial", 16, "bold"))
        title_label.pack(pady=15)

        # 输入区域框架
        input_frame = ttk.Frame(self.root)
        input_frame.pack(pady=10, padx=20, fill="x")

        # 间隔设置
        ttk.Label(input_frame, text="点击间隔 (毫秒):").grid(row=0, column=0, sticky="w", pady=5)
        self.interval_var = tk.StringVar(value="1")  # 默认1ms
        self.interval_entry = ttk.Entry(input_frame, textvariable=self.interval_var, width=10)
        self.interval_entry.grid(row=0, column=1, sticky="e", pady=5)
        ttk.Label(input_frame, text="(设为0则全速)").grid(row=0, column=2, sticky="w", padx=5)

        # 次数限制
        ttk.Label(input_frame, text="停止次数 (0为无限):").grid(row=1, column=0, sticky="w", pady=5)
        self.limit_var = tk.StringVar(value="0")
        self.limit_entry = ttk.Entry(input_frame, textvariable=self.limit_var, width=10)
        self.limit_entry.grid(row=1, column=1, sticky="e", pady=5)

        # 按钮设置 (鼠标左键/右键)
        ttk.Label(input_frame, text="鼠标按键:").grid(row=2, column=0, sticky="w", pady=5)
        self.button_var = tk.StringVar(value="left")
        btn_frame = ttk.Frame(input_frame)
        btn_frame.grid(row=2, column=1, columnspan=2, sticky="w")
        ttk.Radiobutton(btn_frame, text="左键", variable=self.button_var, value="left").pack(side="left", padx=0)
        ttk.Radiobutton(btn_frame, text="右键", variable=self.button_var, value="right").pack(side="left", padx=10)

        # 状态显示
        self.status_label = ttk.Label(self.root, text=f"状态: 已停止 (按 {self.hotkey_name} 启动/暂停)", foreground="red")
        self.status_label.pack(pady=20)

        # 计数显示
        self.count_label = ttk.Label(self.root, text="已点击: 0")
        self.count_label.pack(pady=5)

        # 控制按钮
        self.toggle_btn = ttk.Button(self.root, text="启动 (Start)", command=self.toggle_clicking)
        self.toggle_btn.pack(pady=10, ipadx=20, ipady=5)
        
        # 说明
        note = ttk.Label(self.root, text="注意: 需要辅助功能权限\n极速模式下可能会导致系统稍有卡顿", font=("Arial", 10), foreground="gray")
        note.pack(side="bottom", pady=10)

    def toggle_clicking(self):
        if self.running:
            self.stop_clicking()
        else:
            self.start_clicking()

    def start_clicking(self):
        try:
            self.interval = float(self.interval_var.get()) / 1000.0
            self.limit = int(self.limit_var.get())
        except ValueError:
            messagebox.showerror("错误", "请输入有效的数字")
            return

        self.running = True
        self.click_count = 0
        self.update_status(True)
        
        # 启动点击线程
        self.click_thread = threading.Thread(target=self.click_loop)
        self.click_thread.daemon = True
        self.click_thread.start()

    def stop_clicking(self):
        self.running = False
        self.update_status(False)

    def update_status(self, is_running):
        if is_running:
            self.status_label.config(text=f"状态: 运行中... (按 {self.hotkey_name} 暂停)", foreground="green")
            self.toggle_btn.config(text="停止 (Stop)")
            self.interval_entry.config(state="disabled")
            self.limit_entry.config(state="disabled")
        else:
            self.status_label.config(text=f"状态: 已停止 (按 {self.hotkey_name} 启动)", foreground="red")
            self.toggle_btn.config(text="启动 (Start)")
            self.interval_entry.config(state="normal")
            self.limit_entry.config(state="normal")

    def click_loop(self):
        btn = Button.left if self.button_var.get() == "left" else Button.right
        
        # 预先计算目标
        limit = self.limit
        interval = self.interval
        
        next_time = time.perf_counter()

        while self.running:
            # 执行点击
            self.mouse.click(btn)
            self.click_count += 1
            
            # 更新计数 (为了不影响性能，每10次或者更长时间更新一次UI)
            if self.click_count % 10 == 0:
                self.root.after(0, lambda c=self.click_count: self.count_label.config(text=f"已点击: {c}"))

            # 检查次数限制
            if limit > 0 and self.click_count >= limit:
                self.stop_clicking()
                break

            # 延时控制
            if interval > 0:
                # 忙等待以获得更高精度 (特别是 <1ms 时)
                next_time += interval
                # 如果系统发生严重滞后，重置 next_time 以避免死循环追赶
                if next_time < time.perf_counter() - 0.1:
                     next_time = time.perf_counter() + interval

                while time.perf_counter() < next_time:
                    if not self.running: 
                        break
                    # 空循环，消耗 CPU 但精度高
                    pass
            else:
                # 全速模式，不等待
                pass

    def on_key_press(self, key):
        if key == self.hotkey:
            # 在主线程中切换，避免线程冲突
            self.root.after(0, self.toggle_clicking)

    def on_closing(self):
        self.running = False
        self.listener.stop()
        self.root.destroy()

if __name__ == "__main__":
    root = tk.Tk()
    app = AutoClickerApp(root)
    root.mainloop()
