{ ... }:

{
  # EasyEffects 按上游推荐方式工作：
  #   - 物理声卡（USB DAC）保持系统默认 sink；
  #   - processAllOutputs 把应用输出自动接到 EasyEffects 虚拟 sink；
  #   - 不把 EasyEffects 自己设为默认 sink，避免环路和路由混乱。
  services.easyeffects = {
    enable = true;

    # 启动时加载下面定义的 output preset。
    preset = {
      output = "Macmini";
    };

    # 只做透明的峰值保护：-1 dBFS、关闭自动增益补偿。
    # 不添加 EQ / 压缩 / 声场效果，避免改变原有听感。
    extraPresets = {
      Macmini = {
        output = {
          blocklist = [ ];
          plugins_order = [ "limiter#0" ];
          "limiter#0" = {
            bypass = false;
            threshold = -1.0;
            "gain-boost" = false;
          };
        };
      };
    };

    settings = {
      EffectsPipelines.processAllOutputs = true;
      StreamOutputs.useDefaultOutputDevice = true;
    };
  };
}
