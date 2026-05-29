1. mag_cur_ctrl ，current_set， sada_peak_current_set 建议可选，厂家不一定是电流控制，也可以电压控制
2. motion_mode_set 种电流参数设置，建议可选。厂家不一定是电流控制，也可以电压控制， “电机母线电流零点状态”参数 什么意思，请确认一下。
3. actual_angle_selection 这个不一定完整实现，却决于sada厂家设计。
4. pot_judgment_selection中 ，chan3 这个参数电位计禁止，是关闭电位计，不采集对吗？
5. sada_current_limit_set  确认一下过流保护阈值设置的是母线还是相电流
6. sada_single_event_protection_set 电流相关设置，还是取决于厂家，不一定使用DRV8825
7. sada_parameter_configuration_status_read 电流相关，建议可选

# 三取二








