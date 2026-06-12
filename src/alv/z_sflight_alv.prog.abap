*&---------------------------------------------------------------------*
*& Report Z_SFLIGHT_ALV
*&---------------------------------------------------------------------*
*& Creat By Jack.Liang
*& 1.使用到的表sflight航班表
*& 2.定义选择屏幕，含有单值参数P_PRICE(PARAMETER)和S_DATE(SELECT-OPTIONS)
*& 3.为价格设定默认值3000，为查询周期设定默认值为当前月，即起止日期分别为当前月的第一天和最后一天
*& 4.查询航班日期(fldate)在指定周期范围内并且航空运费(price)低于指定价格的所有航班记录
*& 5.按航班日期降序排序
*& 6.使用alv方式输出查询结果
*& 6.航班数据生成 BC_DATA_GEN
*&---------------------------------------------------------------------*
REPORT z_sflight_alv.

*引用类型组SLIS是系统定义的类型组，ALV相关操作的类型都在其中
TYPE-POOLS:SLIS.
DATA: I_FIELDS TYPE LVC_T_FCAT." Field symbol for field catalog

*定义表工作区
TABLES:sflight.
DATA itab_sflight TYPE TABLE OF sflight.  "定义内表,存放查询结果


DATA:ld_curdate  LIKE sy-datum,            "定义日期类型变量,记录当前日期
     ld_lastdate LIKE sy-datum.           "定义日期类型变量,记录当前日期所在月份最后一天的日期


*定义选择屏幕，可定义块区域对不同功能的选择条件进行分组显示
*此处注意：代码编辑完成后保存并激活，然后进入：系统菜单-〉转到->文本元素->选择文本
*定义屏幕块区域的文本标题和各相关选择条件的描述文本，完毕后同样需要对选择文本执行激活操作


*---------------------------------------------------------*
*SELECTION-SCREEN
*---------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK blk WITH FRAME TITLE TEXT-001.
  PARAMETER p_price TYPE i OBLIGATORY.  "定义单值输入参数，航班价格，类型为整型且为必选项
  SELECT-OPTIONS s_date FOR sflight-fldate.
  "定义选择区间参数，航班日期，可以多值输入，也可以直接定义上下限
SELECTION-SCREEN END OF BLOCK blk.


*---------------------------------------------------------*
*INITIALIZATION
*---------------------------------------------------------*
INITIALIZATION.

  p_price = '3000'.
  PERFORM initdate.      "调用子程序InitDate，指定查询周期为当前月


*选择条件输入后，开始执行查询前，对所输入的条件进行约束性检查
*---------------------------------------------------------*
*AT SELECTION-SCREEN
*---------------------------------------------------------*
  IF s_date-low IS INITIAL.   "没用指定查询日期，则调用MESSAGE方法，提示错误信息，注意MESSAGE方法的使用
    MESSAGE e888(sabapdocu) WITH '请输入查询日期'.
  ENDIF.


*---------------------------------------------------------*
*START-OF-SELECTION
*---------------------------------------------------------*
START-OF-SELECTION.
  PERFORM getdata.        "从数据库中将符合指定日期和航班运费价格的数据取出存放到内表中


END-OF-SELECTION.

  PERFORM setfieldcat.      "调用子程序,设置ALV输出的字段目录属性

  PERFORM displaybyalv.     "调用子程序以ALV方式输出查询结果


*---------------------------------------------------------*
*FORM INITDATE
*根据当前月份初始化查询日期区间
*---------------------------------------------------------*
FORM initdate.
  ld_curdate = sy-datum."从系统变量sy-datum中获取当前日期，并赋值给变量ld_curdate
  CALL FUNCTION 'RP_LAST_DAY_OF_MONTHS'
  "调用功能模块RP_LAST_DAY_OF_MONTHS 取得当前月最后一天的日期，输出结果赋值给变量ld_lastdate
    EXPORTING
      day_in            = ld_curdate
    IMPORTING
      last_day_of_month = ld_lastdate
    EXCEPTIONS
      day_in_no_date    = 1.


  ld_curdate+6(2) = '01'.             "修改当前日期为当前月的第一天


  s_date-low = ld_curdate.
  s_date-high = ld_lastdate.
  APPEND s_date.


ENDFORM. "INITDATE
*---------------------------------------------------------*
*FORM GETDATA
*从数据库中获取数据
*---------------------------------------------------------*
FORM getdata.
* 插入数据
  DATA:nt_sflight TYPE sflight.
  nt_sflight-carrid = 'LH'.
  nt_sflight-connid = '454'.
  nt_sflight-fldate = sy-datum.
  nt_sflight-price = '1499'.
  nt_sflight-planetype = 'A319'.
  nt_sflight-seatsmax = '350'.


  INSERT INTO sflight VALUES nt_sflight.
*从数据中将符合选择条件的航班记录读取到内表中
  SELECT * FROM sflight
      INTO TABLE itab_sflight
      WHERE fldate IN s_date AND price < p_price.
*按照航班日期降序排列查询结果
  SORT itab_sflight BY fldate DESCENDING.
ENDFORM.  "GETDATA
*---------------------------------------------------------*
*FORM SETFIELDCAT
*根据业务需要，设定内表数据在ALV表格中输出的属性
*---------------------------------------------------------*
FORM setfieldcat.

  DATA:wa_field    TYPE lvc_s_fcat,
*定义字段属性工作区变量，定义内表中各字段变量在表格中输出的属性
       it_fieldcat TYPE TABLE OF lvc_s_fcat. "定义字段目录组变量，是与wa_field同结构类型的内表
  DATA: lv_col_pos TYPE i.
  CLEAR wa_field.


*定义宏代码
  DEFINE addfieldcat.
    ADD 1 TO lv_col_pos.
    wa_field-col_pos = lv_col_pos.     "字段在表格中对应的列顺序
    wa_field-fieldname = &1.   "内表中的字段名称，注意：必须用大写字母
    wa_field-reptext = &2.   "对应的列头文本
    wa_field-just = &3.        "列对齐方式，可以取值：L 居左对齐，R 居右对齐， C 居中对齐
    "wa_field-fix_column = &4.        "固定列
    "wa_field-emphasize = &5.        "加颜色，如'C510'
*添加字段属性到字段目录表中
    APPEND wa_field TO it_fieldcat.
    CLEAR wa_field.
  END-OF-DEFINITION.


*调用预定义的宏代码，逐个将要显示字段的属性设定添加到字段目录组中
  addfieldcat 'CARRID' '航线承运人ID' 'L'.
  addfieldcat 'CONNID' '航班连接ID' 'L'.
  addfieldcat 'FLDATE' '航班日期' 'L'.
  addfieldcat 'PRICE' '航空运费' 'R'.
  addfieldcat 'PLANETYPE' '飞机类型' 'L'.
  addfieldcat 'SEATSMAX' '座位数量' 'C'.


  i_fields = it_fieldcat.
ENDFORM.  "SETFIELDCAT


*---------------------------------------------------------*
*FORM DISPLAYBYALV
*用ALV方式显示查询结果
*---------------------------------------------------------*
FORM displaybyalv.
  DATA:gs_layout TYPE lvc_s_layo.   "定义ALV表格属性变量，设置相关显示属性
  DATA:g_repid LIKE sy-repid.               "定义变量,记录当前程序名


  gs_layout-cwidth_opt = 'X'.     "设置ALV表格输出的时候，列宽根据数据长度自动适应
  gs_layout-zebra = 'X'.                 "设置aLV表格输出的时候，数据行背景色交替显示
  g_repid = sy-repid.


*调用功能模块REUSE_ALV_GRID_DISPLAY完成ALV的显示输出
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY_LVC'
    EXPORTING
      i_callback_program = g_repid         "回调的程序名
*     I_CALLBACK_PF_STATUS_SET = 'SET_PF_STATUS'
*     I_CALLBACK_USER_COMMAND  = 'USER_COMMAND'
      is_layout_lvc      = gs_layout
      it_fieldcat_lvc    = i_fields
    TABLES
      t_outtab           = itab_sflight
    EXCEPTIONS
      program_error      = 1
      OTHERS             = 2.
ENDFORM.            "DISPLAYBYALV
*&--------------------------------------------------------------------*
*&      Form  set_pf_status    "链接 ALV标准状态栏
*&--------------------------------------------------------------------*
*       text
*---------------------------------------------------------------------*
FORM set_pf_status USING rt_extab TYPE slis_t_extab.
  SET PF-STATUS 'STATUS' .
ENDFORM.                    "set_pf_status
*&--------------------------------------------------------------------*
*&      Form  user_command
*&--------------------------------------------------------------------*
*       text
*---------------------------------------------------------------------*
FORM user_command USING r_ucomm LIKE sy-ucomm
rs_selfield TYPE slis_selfield.
  CASE r_ucomm.
*    WHEN '&IC1'."双击
    WHEN 'ADD'.


    WHEN OTHERS.
  ENDCASE.
ENDFORM.                    "user_command
