# ─────────────────────────────────────────────────────────────
#  gluqlo —— Fliqlo 风格的翻页时钟屏保（Linux 版）
# ─────────────────────────────────────────────────────────────
#
#  【这是什么】
#    macOS 上那个著名的 Fliqlo 翻页时钟屏保的 Linux 重写版（SDL 实现）。
#    上游：https://github.com/alexanderk23/gluqlo （ISC 许可）
#
#  【★ 不需要哈希、不需要联网】
#    与 pkgs/dunnart 一样，**源码已经 vendor 进本仓库**（./src），
#    所以这个包是纯本地构建：没有 fetchFromGitHub、没有 lib.fakeHash、
#    没有"哈希未填时降级"的分支。`nix build .#gluqlo` 直接就能验证构建。
#
#    为什么这么做：Nix 的固定输出（fetch*）**必须**给出内容哈希，而哈希
#    只能由"真正下载一次"得到 —— 写这份配置的环境无法执行 `nix build`
#    （没有 nix，也没有那台机器），所以原先只能留占位哈希让你本机补。
#    对一个只有 15 KB 的单文件 C 项目来说，直接 vendor 反而更简单可靠
#    （顺带得到"完全离线可构建"）。dunnart 早就用了同样的做法。
#
#  【vendor 的来源与方法（便于日后更新）】
#    上游 tag：v1.1.0（== 570abbb6e8bcf46e7d172c13ba81b3e070d4c3dd）
#    ./src 下这几个文件与上游**逐字节一致**（已用 sha256 校对）：
#        gluqlo.c   Makefile   gluqlo.ttf   LICENSE   UPSTREAM-README.md
#    （未 vendor 的只有 gluqlo.png / gluqlo.xml / gluqlo.desktop —— 见下方说明）
#    更新方法：
#        curl -LO https://github.com/alexanderk23/gluqlo/archive/refs/tags/v1.1.0.tar.gz
#        tar -xzf v1.1.0.tar.gz
#        cp gluqlo-1.1.0/{gluqlo.c,Makefile,gluqlo.ttf,LICENSE} pkgs/gluqlo/src/
#    注意保持 ./src 里的文件为 LF 行尾（仓库 .gitattributes 已把 *.ttf 标记为 binary）。
#
#  【上游构建方式与两个必须处理的坑（已逐行读 Makefile 核实）】
#    纯 GNU Makefile + 单个 C++ 文件（g++），无 meson/cmake。
#    依赖（与上游 README 里给 Arch 的说明一致）：SDL 1.2、SDL_ttf、SDL_gfx、libX11。
#    坑①：Makefile 用裸 `sdl-config`（反引号调用），Nix 沙箱内不在 PATH
#         → postPatch 替换成 SDL dev 输出里的绝对路径。
#    坑②：字体路径是**编译期常量**：
#             CFLAGS=... -DFONT='"$(FONTDIR)/gluqlo.ttf"'
#         FONTDIR 默认是 $(DESTDIR)/usr/share/gluqlo，DESTDIR 为空时就是
#         /usr/share/gluqlo —— 在 Nix 上不存在，运行时会 TTF_OpenFont 失败
#         并直接退出。所以必须用 makeFlags 覆盖 FONTDIR，并把字体装到同一位置。
#    另外上游 `install` 目标带 `install -o root`（沙箱内必然失败），
#    所以自写 installPhase。
#
#  【为什么不装 gluqlo.desktop / .xml / .png】
#    上游会把 gluqlo.desktop 装到 share/applications/screensavers/，本意是让
#    xfce4-screensaver / gnome-screensaver 把它列为一个"屏保主题"。但在 NixOS
#    上这条路走不通（详见 docs/硬件适配说明.md 的屏保一节）：xfce4-screensaver
#    的主题管理器有一份**写死的可执行文件目录白名单**
#    （src/gs-theme-manager.c 的 known_engine_locations），只认
#    /usr/lib{,exec}/xscreensaver 或它自己的安装目录，store 路径会被拒绝。
#    我们用的是真正的 xscreensaver（通过它的 programs 列表启动本程序），
#    因此 .desktop/.xml/.png 都不会被用到，装了反而误导。
# ─────────────────────────────────────────────────────────────
{
  lib,
  stdenv,
  SDL,
  SDL_gfx,
  SDL_ttf,
  libx11,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "gluqlo";
  version = "1.1.0";

  # vendor 进来的源码（无需哈希、无需联网）
  src = ./src;

  # 坑①：把裸 sdl-config 换成 store 里的绝对路径。
  # 用 lib.getExe' (lib.getDev SDL) "sdl-config" 是 nixpkgs 自己打包
  # SDL_ttf / SDL_gfx 时的做法（sdl12-compat 的 sdl-config 在 dev 输出里）。
  postPatch = ''
    substituteInPlace Makefile \
      --replace-fail 'sdl-config' '${lib.getExe' (lib.getDev SDL) "sdl-config"}'
  '';

  # 坑②：字体路径是编译期常量，必须指向**最终 store 路径**。
  #   用 ${placeholder "out"} 而不是 $(out)/$out —— makeFlags 是直接作为 argv
  #   传给 make 的：其中的 $out 不会被 shell 展开，而 $(out) 又会被 make 当成
  #   它自己的变量（展开为空），那样编译出来的字体路径是错的。
  #   Makefile 里 FONTDIR 的默认值会被命令行赋值覆盖 ✓（GNU make 规则）。
  makeFlags = [ "FONTDIR=${placeholder "out"}/share/gluqlo" ];

  buildInputs = [
    SDL # SDL 1.2 API，由 sdl12-compat（nixpkgs 属性名 SDL_compat）提供
    SDL_gfx # SDL_gfxPrimitives.h / SDL_rotozoom.h（翻转动画）
    SDL_ttf # TTF_OpenFont 等
    libx11 # XOpenDisplay（读取 XSCREENSAVER_WINDOW 那条路径）
    # 若你的 nixpkgs 报找不到 libx11，可换成 xorg.libX11
  ];

  # 只装两样东西：二进制 + 字体（字体位置必须与上面的 FONTDIR 一致）
  installPhase = ''
    runHook preInstall

    install -Dm755 gluqlo $out/bin/gluqlo
    install -Dm644 gluqlo.ttf $out/share/gluqlo/gluqlo.ttf

    # ISC 许可要求保留版权声明
    install -Dm644 LICENSE $out/share/doc/gluqlo/LICENSE

    runHook postInstall
  '';

  meta = {
    description = "Fliqlo 风格的翻页时钟屏保（SDL 重写版）";
    longDescription = ''
      gluqlo 是 macOS 上 Fliqlo 翻页时钟屏保的 Linux 重写版本。
      它读取 xscreensaver 提供的 XSCREENSAVER_WINDOW 环境变量，
      因此最自然的用法是挂进 xscreensaver 的 programs 列表。
    '';
    homepage = "https://github.com/alexanderk23/gluqlo";
    license = lib.licenses.isc;
    mainProgram = "gluqlo";
    platforms = lib.platforms.linux;
  };
})
