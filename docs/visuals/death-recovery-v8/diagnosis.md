# 死亡闪退修复（2026-09-09）

已复现实际报错：`Unrecognized field name "race"`，调用链为 `updateRaceRunners → updateContinuousMechanic → renderFrame`。复活函数删掉 race/bus 状态准备下一次物理更新重建，但交互循环 break 后可能立即绘制，直接访问不存在的字段，异常退出后 onCleanup 关闭窗口。旧测试总是在 reset 后先 stepLevel 再绘制，因此漏检。

修复：resetToCheckpoint 返回前以 dt=0 重建连续世界状态及碰撞，不推进游戏时间；实际交互循环传入当前 cfg，保留用户参数。清除复活函数里旧的隐形攀爬门重建分支。未使用 try/catch 吞掉异常，也没有关闭死亡或车辆伤害。

新测试 testDeathRenderRecovery 在七个检查点各死亡两次，等待正常死亡倒计时，复活后不运行任何额外物理步，直接 renderFrame/drawnow，检查图窗仍存在且恢复三颗共享爱心。修复前第一例报错，修复后 14 例通过；公交伤害、屋顶安全、恢复检查和 Code Analyzer 零问题通过。完整回归见 regression.txt。此前渲染性能与 Windows 实机未验收问题没有在本轮宣称解决。
