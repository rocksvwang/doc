1. mag_cur_ctrl ，current_set， sada_peak_current_set 建议可选，厂家不一定是电流控制，也可以电压控制
2. motion_mode_set 种电流参数设置，建议可选。厂家不一定是电流控制，也可以电压控制， “电机母线电流零点状态”参数 什么意思，请确认一下。
3. actual_angle_selection 这个不一定完整实现，却决于sada厂家设计。
4. pot_judgment_selection中 ，chan3 这个参数电位计禁止，是关闭电位计，不采集对吗？
5. sada_current_limit_set  确认一下过流保护阈值设置的是母线还是相电流
6. sada_single_event_protection_set 电流相关设置，还是取决于厂家，不一定使用DRV8825
7. sada_parameter_configuration_status_read 电流相关，建议可选
8. **表B.1综合电子硬件状态获取值** 请按类别解耦合，不能统一上报，影响API性能，因有些状态需要及时获取，sada状态其他接口有重复。

# 三取二

1. 此功能一般需要外置FPGA进行完成，此为单点风险。如果FPGA不能工作，FLASH即便正常CPU也无法工作。
2. 已经启动顺序3->2->1 顺序启动，三个都顺序启动不了时，此时三取二也没有意义。
3. 什么时候开始三取二，是否可以给出流程图示，或者详细文字表述。
4. 启动前三取二对比，如果我的内核+文件系统32MB，fpga 什么时候 对三个flash读取+对比完成，什么时候覆盖，全覆盖还是block覆盖，什么时候cpu才能启动。能满足启动需求吗？
5. 因综合电子为长开机，






