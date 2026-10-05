# ─────────────────────────────────────────────────────────────
#  dunnart —— 轻量级 Home Assistant MQTT 传感器上报守护进程
# ─────────────────────────────────────────────────────────────
#
#  【旧系统怎么做的】
#  旧系统（Arch）直接使用上游预编译的 6.7 MB 二进制 /opt/dunnart/dunnart，
#  再手工放一份 /etc/systemd/system/dunnart.service。
#  问题：二进制不可追溯、无法保证与配置一致、升级全靠手动替换。
#
#  【NixOS 怎么做（取其精华）】
#  把上游 Go 源码 vendor 进本仓库并用 buildGoModule 从源码构建，
#  于是 dunnart 变成 nix store 里一个可复现、可回滚、可用 nix store gc
#  清理的包；systemd 单元由 modules/dunnart.nix 声明式生成。
#
#  【去其糟粕】
#  6.7 MB 的预编译二进制不再入库；旧配置里针对 Arch 的 apt/pacman 传感器
#  已被移除（见 modules/dunnart.nix 里生成的 YAML）。
# ─────────────────────────────────────────────────────────────
{
  lib,
  buildGoModule,
}:

let
  # ⚠️ 首次构建必做一步：
  #    $ nix build .#dunnart
  #    error: hash mismatch in fixed-output derivation ... got: sha256-XXXX
  #    把 "got:" 后面的 sha256-... 覆盖到下面这一行，再重新构建即可。
  #    （这是 buildGoModule 计算 go.mod 依赖树 vendor 哈希的标准流程；
  #      本仓库刻意不猜一个假值进去，以免留下一个"看起来能过"的错误哈希。）
  #
  # 为什么要有 hashIsPlaceholder：
  #    在哈希填好之前，任何引用本包的 systemd 服务 / systemPackages 都会让
  #    整份配置构建失败。所以本包通过 passthru 暴露"哈希是否已填"这一事实，
  #    modules/dunnart.nix 据此决定是否启用服务，并在未填时给出构建警告。
  vendorHash = lib.fakeHash;
in
buildGoModule rec {
  pname = "dunnart";
  # 本地 vendor 的源码快照对应上游 commit a1ca09d3afb1c8351ae77966945fc65aff8575ef
  # （取自旧系统 Backup/opt/dunnart/.git/packed-refs）
  version = "unstable-a1ca09d";

  src = ./src;

  # 复刻上游 Makefile 的 LDFLAGS：-ldflags "-s -w -X=main.version=$(VERSION)"
  # 其中 $(VERSION) 来自 `git describe`，在 nix 沙箱里没有 .git，故直接写入版本号。
  ldflags = [
    "-s"
    "-w"
    "-X=main.version=${version}"
  ];

  inherit vendorHash;

  # 上游没有 *_test.go；在老 CPU 上跳过 test 阶段可以省下不少时间
  doCheck = false;

  # Go 只编译出单一二进制，禁止 buildGoModule 再去处理其他子包
  subPackages = [ "." ];

  passthru = {
    # 供上层模块判断"哈希是否还没填"（见 modules/dunnart.nix）
    hashIsPlaceholder = vendorHash == lib.fakeHash;
  };

  meta = {
    description = "Lightweight remote system monitoring over MQTT for Home Assistant";
    homepage = "https://github.com/warthog618/dunnart";
    license = lib.licenses.mit;
    mainProgram = "dunnart";
    platforms = lib.platforms.linux;
  };
}
