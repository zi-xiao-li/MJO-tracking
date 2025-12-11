% 假设你已经通过 build_mjo_segments 得到了 Seg 结构
K_real = 1:0.1:25;  
ref_lon = 90;       % 参考经度

data_all = track_mjo_all_years(Seg, K_real, ref_lon);

% 写出到 Excel（与 PropagationInfo.xlsx 完全兼容）
writematrix(data_all, 'D:\project\output\PropagationInfo.xlsx');

