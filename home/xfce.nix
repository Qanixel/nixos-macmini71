{ ... }:

{
  # 空闲 10 分钟挂起、15 分钟关闭显示器；视频播放器/浏览器的 inhibitors 仍可阻止熄屏。
  # 当前 xfce4-power-manager 的 dpms-enabled 为 false，显示器会一直常亮；这里显式打开。
  xfconf.settings."xfce4-power-manager" = {
    "xfce4-power-manager/dpms-enabled" = true;
    "xfce4-power-manager/dpms-on-ac-sleep" = {
      type = "uint";
      value = 10;
    };
    "xfce4-power-manager/dpms-on-ac-off" = {
      type = "uint";
      value = 15;
    };
  };
}
