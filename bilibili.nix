# ─────────────────────────────────────────────────────────────
#  Bilibili 客户端与"看视频不烧 CPU"的完整方案
# ─────────────────────────────────────────────────────────────
#
#  ── 好消息：不需要自己打包 ──────────────────────────────────
#  nixpkgs 26.05 里已经有 `pkgs.bilibili`（构建自上游 msojocs/bilibili-linux
#  的官方 .deb，用系统 Electron 运行）。这里只做两件事：
#    1. 安装官方客户端与备用播放工具
#    2. 把"为什么还卡"的排查方法写清楚
#
#  ── 关键背景：Haswell 只能硬解 H.264 ────────────────────────
#      **B 站必须让它在 AVC(H.264) 上解码，绝不能让 HEVC/AV1 落到软解。**
#      B 站客户端 → 播放器右下角齿轮 → 更多播放设置 → 解码策略 → 选「AVC 解码」
#
#  ⚠️ 客户端内的解码策略设置是**存在服务端账号里**的，重装系统后
#     用同一账号登录通常会自动带回来；如果发现没有，按上面路径再设一次。
# ─────────────────────────────────────────────────────────────
{ pkgs, ... }:
{
  environment.systemPackages =
    with pkgs;
    [
      # ── 官方桌面客户端 ────────────────────────────────────
      # 需要 nixpkgs.config.allowUnfree = true（已在 configuration.nix 打开）
      bilibili

      # ── 备用方案 A：mpv + yt-dlp 直接看 B 站 ───────────────
      # yt-dlp 对 B 站的支持是一等公民（有专门的 extractor，
      # 支持合集、番剧、收藏夹、UP 主空间等 URL 形式）。
      # mpv 的 VA-API 支持与 Chromium 无关，所以在 Haswell 上
      # 硬解**确实可用** —— 这是这台机器上看 1080p60 最省 CPU 的方式。
      mpv
      yt-dlp

      # ── 备用方案 B：终端版客户端（可选，适合 SSH 里刷 B 站）──
      # bilibili-tui

      # ── 顺手准备一些"看视频"必备的小工具 ────────────────────
      # 下载 B 站视频/音频（配合 yt-dlp 使用）
      # 注意：BBDown / bililive-go 目前不在 nixpkgs 里，不要指望能直接装
      aria2 # 多线程下载器（yt-dlp 可以 -N 或 --downloader aria2c 调用）
      mediainfo # 查看视频的真实编码格式（验证是不是 AVC）
    ];

  # ─────────────────────────────────────────────────────────
  #  部署后自检：确认 bilibili 客户端真的在硬解
  #
  #  ① 先确认客户端启动时带上了我们注入的参数：
  #       ps aux | grep -o -- '--enable-features=[^ ]*' | head
  #     应该能看到包含 AcceleratedVideoDecodeLinuxGL 的那一串。
  #
  #  ② 播放一个 1080p 视频，然后**最硬核也最可靠**的验证：
  #       cat /proc/$(pgrep -f "type=gpu-process.*bilibili" | head -1)/fdinfo/* \
  #         | grep drm-engine-video
  #     输出里有非零的 "drm-engine-video:  <时间>" 增长，就是真的在用 GPU 解码。
  #
  #  ③ 同时用 intel_gpu_top 观察 Video 引擎占用（另开一个终端）：
  #       sudo intel_gpu_top
  #
  #  ④ 用 mediainfo 看正在播的视频编码：
  #       mediainfo 视频文件 | grep -i "codec\|format"
  #     若显示 HEVC/AV1 → 回客户端把解码策略改成 AVC（H.264）。
  #
  #  ⑤ 如果一切正常但 CPU 还是高：
  #     大概率是"弹幕渲染"或"网页动画"而非解码 —— 关掉弹幕对比一下即可确认。
  #
  #  ── 用 mpv 看 B 站的推荐写法（最省 CPU）──────────────────
  #      mpv --hwdec=vaapi \
  #          --ytdl-format='bv*[vcodec^=avc1]+ba/b' \
  #          'https://www.bilibili.com/video/BVxxxxxxxxx'
  #      （--ytdl-format 强制挑选 avc1 编码的视频流，
  #        避免 yt-dlp 默认选到 4K 的 HEVC 流让老 CPU 软解）
  #
  #  ── 如果你只是想要一个"能看 B 站"的备胎 ──────────────────
  #      Flathub 上有第三方客户端 wiliwili（应用 ID: cn.xfangfang.wiliwili），
  #      用 flatpak install flathub cn.xfangfang.wiliwili 安装即可。
  #      注意 Flathub 上**没有**官方 B 站客户端（com.bilibili.* 不存在）。
  # ─────────────────────────────────────────────────────────
}
