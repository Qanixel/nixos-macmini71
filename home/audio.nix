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

    # 基础链路：autogain 做 EBU R128 响度归一化，limiter 兜底峰值。
    # target 的数值越低越安静：-24 LUFS 比 EBU R128 默认的 -23 略低。
    # 若整体仍偏大，可先把 autogain 的 output-gain 调到 -3 / -6，再考虑更低 target。
    # 日常微调可以在 EasyEffects GUI 里做；GUI 修改只影响运行态，固化需改回这里。
    extraPresets = {
      Macmini = {
        output = {
          blocklist = [ ];

          plugins_order = [
            "autogain#0"
            "limiter#0"
          ];

          "autogain#0" = {
            bypass = false;
            target = -24.0;
            reference = "Geometric Mean (MSI)";
            "maximum-history" = 15;
            "silence-threshold" = -70.0;
            "input-gain" = 0.0;
            "output-gain" = 0.0;
          };

          "limiter#0" = {
            bypass = false;
            threshold = -1.5;
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
