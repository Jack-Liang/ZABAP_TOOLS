*&---------------------------------------------------------------------*
*& Report  ZR_ALV_DEMO_SFLIGHT
*&---------------------------------------------------------------------*
*& 一个程序体验四种 ALV 方式，数据统一取 SFLIGHT 前 100 行：
*&
*&   方式 1  REUSE_ALV_LIST_DISPLAY           函数版列表 ALV
*&   方式 2  REUSE_ALV_GRID_DISPLAY           函数版网格 ALV
*&   方式 3  REUSE_ALV_HIERSEQ_LIST_DISPLAY   函数版层级清单（抬头/行项目）
*&   方式 4  REUSE_ALV_BLOCK_LIST_DISPLAY     函数版块式清单（同屏多段）
*&   方式 5  CL_GUI_ALV_GRID                  OO ALV（需配套屏幕 100，无则兜底）
*&   方式 6  CL_SALV_TABLE                    SALV 模型
*&   方式 7  CL_SALV_HIERARCHICAL_TABLE       SALV 层级表（NW 7.02+ 才有）
*&
*& 层级类方式（3 和 7）需要"抬头 + 行项目"两张表：抬头用航班计划表
*& SPFLI（与 SFLIGHT 一样由 BC_DATA_GENERATOR 生成、各系统都有），
*& 行项目用 SFLIGHT，按 航线+航班号（CARRID+CONNID）关联。
*& 方式 7 在低于 NW 7.02 的系统上类不存在（无法静态编译），r_shier
*& 选项仅给出提示；其写法见配套文章。兄弟类 CL_SALV_TREE（树形）
*& API 类似，同样不演示。
*&
*& 选择屏幕用单选按钮切换方式，F8 执行即可。
*&
*& 手工配套对象（可选，仅方式 3 OO ALV 的"正规用法"需要）：
*&   1) SE51 屏幕 100，流逻辑：
*&        PROCESS BEFORE OUTPUT.
*&          MODULE status_0100.
*&        PROCESS AFTER INPUT.
*&          MODULE user_command_0100.
*&      画板上不用放控件（容器由代码动态创建）。
*&   2) SE41 GUI 状态 STATUS_0100，含 BACK / EXIT / CANC 功能码。
*&   3) 标题 TITLE_0100（任意文本）。
*&   4) 文本符号 TEXT-001 = '选择 ALV 展示方式'。
*&   若未创建屏幕 100，程序自动退化为 screen0 兜底展示（零配置可运行，
*&   网格铺满选择屏，按 F3 返回即退出程序）。
*&
*& 前置条件：SFLIGHT 有数据（没有则先跑 BC_DATA_GENERATOR）。
*&---------------------------------------------------------------------*
REPORT zr_alv_demo_sflight.

TABLES sflight.

*----------------------------------------------------------------------*
* 全局数据
*----------------------------------------------------------------------*
DATA: gt_sflight TYPE TABLE OF sflight,
      gt_hier_h  TYPE TABLE OF spfli,      " 层级方式抬头表：航班计划（须全局：FM 按表名动态 ASSIGN）
      gt_block1  TYPE TABLE OF sflight,    " 块式方式第 1 块（同上）
      gt_block2  TYPE TABLE OF sflight,    " 块式方式第 2 块（同上）
      go_docking TYPE REF TO cl_gui_docking_container,
      go_grid    TYPE REF TO cl_gui_alv_grid.

*----------------------------------------------------------------------*
* 选择屏幕：单选按钮切换 ALV 方式
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
PARAMETERS: r_list  RADIOBUTTON GROUP g1 DEFAULT 'X', " FM：列表 ALV
            r_grid  RADIOBUTTON GROUP g1,             " FM：网格 ALV
            r_hier  RADIOBUTTON GROUP g1,             " FM：层级清单 ALV
            r_block RADIOBUTTON GROUP g1,             " FM：块式清单 ALV
            r_oo    RADIOBUTTON GROUP g1,             " OO：CL_GUI_ALV_GRID
            r_salv  RADIOBUTTON GROUP g1,             " SALV：CL_SALV_TABLE
            r_shier RADIOBUTTON GROUP g1.             " SALV：层级表
SELECTION-SCREEN END OF BLOCK b1.

*----------------------------------------------------------------------*
* 主流程：取数 -> 按选项分发
*----------------------------------------------------------------------*
START-OF-SELECTION.
  SELECT * FROM sflight INTO TABLE @gt_sflight UP TO 100 ROWS.
  IF gt_sflight IS INITIAL.
    MESSAGE 'SFLIGHT 没有数据，请先运行 BC_DATA_GENERATOR 生成演示数据' TYPE 'I'.
    RETURN.
  ENDIF.

  CASE abap_true.
    WHEN r_list.
      PERFORM display_list_alv.      " 方式 1
    WHEN r_grid.
      PERFORM display_grid_alv.      " 方式 2
    WHEN r_hier.
      PERFORM display_hierseq_alv.   " 方式 3
    WHEN r_block.
      PERFORM display_block_alv.     " 方式 4
    WHEN r_oo.
      " 方式 5：优先走自建屏幕 100（正规 OO ALV 用法）；
      " 屏幕不存在时退化为 screen0 兜底，避免 DYNPRO_NOT_FOUND dump
      SELECT SINGLE prog FROM d020s INTO @DATA(lv_prog)
        WHERE prog = @sy-repid
          AND dnum = '0100'.
      IF sy-subrc = 0.
        CALL SCREEN 100.
      ELSE.
        PERFORM display_oo_alv_screen0.
      ENDIF.
    WHEN r_salv.
      PERFORM display_salv.          " 方式 6
    WHEN r_shier.
      " 方式 7：CL_SALV_HIERARCHICAL_TABLE 自 NW 7.02 起提供，
      " 低版本系统上类不存在（静态引用无法激活），此处仅提示；
      " 写法见配套文章，老系统请改用方式 3（r_hier）
      MESSAGE 'CL_SALV_HIERARCHICAL_TABLE 需 NW 7.02+，当前系统不可用，请改用方式 3' TYPE 'I'.
  ENDCASE.

*&---------------------------------------------------------------------*
*&      Form  DISPLAY_LIST_ALV
*&---------------------------------------------------------------------*
*      方式 1：REUSE_ALV_LIST_DISPLAY（函数版列表 ALV）
*----------------------------------------------------------------------*
FORM display_list_alv.
  DATA: lt_fcat   TYPE slis_t_fieldcat_alv,
        ls_layout TYPE slis_layout_alv.

  " 从 DDIC 结构 SFLIGHT 自动生成字段目录
  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
    EXPORTING
      i_structure_name = 'SFLIGHT'
    CHANGING
      ct_fieldcat      = lt_fcat
    EXCEPTIONS
      OTHERS           = 1.

  ls_layout-zebra             = abap_true.   " 条纹
  ls_layout-colwidth_optimize = abap_true.   " 列宽自适应

  CALL FUNCTION 'REUSE_ALV_LIST_DISPLAY'
    EXPORTING
      i_structure_name = 'SFLIGHT'
      is_layout        = ls_layout
      it_fieldcat      = lt_fcat
      i_save           = 'A'        " 允许保存布局变式（标准+用户）
    TABLES
      t_outtab         = gt_sflight
    EXCEPTIONS
      OTHERS           = 1.
  IF sy-subrc <> 0.
    MESSAGE 'LIST ALV 调用失败' TYPE 'I'.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  DISPLAY_GRID_ALV
*&---------------------------------------------------------------------*
*      方式 2：REUSE_ALV_GRID_DISPLAY（函数版网格 ALV）
*----------------------------------------------------------------------*
FORM display_grid_alv.
  DATA: lt_fcat   TYPE slis_t_fieldcat_alv,
        ls_layout TYPE slis_layout_alv,
        lt_sort   TYPE slis_t_sortinfo_alv.

  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
    EXPORTING
      i_structure_name = 'SFLIGHT'
    CHANGING
      ct_fieldcat      = lt_fcat
    EXCEPTIONS
      OTHERS           = 1.

  ls_layout-zebra             = abap_true.
  ls_layout-colwidth_optimize = abap_true.

  " 预设排序：航线 + 航班号
  lt_sort = VALUE slis_t_sortinfo_alv(
    ( spos = 1 fieldname = 'CARRID' up = abap_true )
    ( spos = 2 fieldname = 'CONNID' up = abap_true ) ).

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_structure_name = 'SFLIGHT'
      is_layout        = ls_layout
      it_fieldcat      = lt_fcat
      it_sort          = lt_sort
      i_default        = abap_true
      i_save           = 'A'
    TABLES
      t_outtab         = gt_sflight
    EXCEPTIONS
      OTHERS           = 1.
  IF sy-subrc <> 0.
    MESSAGE 'GRID ALV 调用失败' TYPE 'I'.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  DISPLAY_HIERSEQ_ALV
*&---------------------------------------------------------------------*
*      方式 3：REUSE_ALV_HIERSEQ_LIST_DISPLAY（层级清单：抬头/行项目）
*      用 SFLIGHT 自拆：按 航线+航班号 分组取首条作抬头，全部记录作行项目
*----------------------------------------------------------------------*
FORM display_hierseq_alv.
  DATA: lt_fcat_h TYPE slis_t_fieldcat_alv,
        lt_fcat_i TYPE slis_t_fieldcat_alv,
        ls_layout TYPE slis_layout_alv,
        ls_key    TYPE slis_keyinfo_alv.

  " 抬头：航班计划表 SPFLI（与 SFLIGHT 一样由 BC_DATA_GENERATOR 生成）
  " 注意：必须用全局内表——FM 按 I_TABNAME_HEADER/ITEM 动态 ASSIGN
  SELECT * FROM spfli INTO TABLE @gt_hier_h.
  IF gt_hier_h IS INITIAL.
    MESSAGE 'SPFLI 没有数据，请先运行 BC_DATA_GENERATOR 生成演示数据' TYPE 'I'.
    RETURN.
  ENDIF.

  " 字段目录：抬头（SPFLI）与行项目（SFLIGHT）各生成一份，
  " 用 TABNAME 区分后拼进同一内表
  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
    EXPORTING
      i_structure_name = 'SPFLI'
    CHANGING
      ct_fieldcat      = lt_fcat_h
    EXCEPTIONS
      OTHERS           = 1.
  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
    EXPORTING
      i_structure_name = 'SFLIGHT'
    CHANGING
      ct_fieldcat      = lt_fcat_i
    EXCEPTIONS
      OTHERS           = 1.
  LOOP AT lt_fcat_h ASSIGNING FIELD-SYMBOL(<fch>).
    <fch>-tabname = 'GT_HIER_H'.
  ENDLOOP.
  LOOP AT lt_fcat_i ASSIGNING FIELD-SYMBOL(<fci>).
    <fci>-tabname = 'GT_SFLIGHT'.
  ENDLOOP.
  APPEND LINES OF lt_fcat_i TO lt_fcat_h.

  ls_layout-zebra      = abap_true.
  ls_layout-expand_all = abap_true.    " 默认全部展开

  " 抬头与行项目的关联键
  ls_key-header01 = 'CARRID'.
  ls_key-item01   = 'CARRID'.
  ls_key-header02 = 'CONNID'.
  ls_key-item02   = 'CONNID'.

  CALL FUNCTION 'REUSE_ALV_HIERSEQ_LIST_DISPLAY'
    EXPORTING
      i_callback_program = sy-repid
      is_layout          = ls_layout
      it_fieldcat        = lt_fcat_h
      is_keyinfo         = ls_key
      i_tabname_header   = 'GT_HIER_H'
      i_tabname_item     = 'GT_SFLIGHT'
    TABLES
      t_outtab_header    = gt_hier_h
      t_outtab_item      = gt_sflight
    EXCEPTIONS
      OTHERS             = 1.
  IF sy-subrc <> 0.
    MESSAGE 'HIERSEQ ALV 调用失败' TYPE 'I'.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  DISPLAY_BLOCK_ALV
*&---------------------------------------------------------------------*
*      方式 4：REUSE_ALV_BLOCK_LIST_DISPLAY（块式清单：同屏多段）
*      把 SFLIGHT 前 50 行 / 后 50 行拆成两块演示
*----------------------------------------------------------------------*
FORM display_block_alv.
  DATA: lt_fcat1  TYPE slis_t_fieldcat_alv,
        lt_fcat2  TYPE slis_t_fieldcat_alv,
        lt_events TYPE slis_t_event,
        ls_layo   TYPE slis_layout_alv.

  " 注意：输出表必须是全局内表——DISPLAY 时 FM 按 I_TABNAME 动态 ASSIGN，
  " 局部变量按名字找不到，会导致内部调用 CALL_FUNCTION_PARM_MISSING dump
  gt_block1 = gt_sflight.
  gt_block2 = gt_sflight.
  DELETE gt_block1 FROM 51.     " 第 1 块：前 50 行
  DELETE gt_block2 TO 50.       " 第 2 块：后 50 行

  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
    EXPORTING
      i_structure_name = 'SFLIGHT'
    CHANGING
      ct_fieldcat      = lt_fcat1
    EXCEPTIONS
      OTHERS           = 1.
  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
    EXPORTING
      i_structure_name = 'SFLIGHT'
    CHANGING
      ct_fieldcat      = lt_fcat2
    EXCEPTIONS
      OTHERS           = 1.
  LOOP AT lt_fcat1 ASSIGNING FIELD-SYMBOL(<f1>).
    <f1>-tabname = 'GT_BLOCK1'.
  ENDLOOP.
  LOOP AT lt_fcat2 ASSIGNING FIELD-SYMBOL(<f2>).
    <f2>-tabname = 'GT_BLOCK2'.
  ENDLOOP.

  ls_layo-zebra = abap_true.

  " 标准事件表（对齐 SAP 标准演示程序 BALVBT01 的调用序列）
  CALL FUNCTION 'REUSE_ALV_EVENTS_GET'
    EXPORTING
      i_list_type = 0
    IMPORTING
      et_events   = lt_events
    EXCEPTIONS
      OTHERS      = 1.

  " 三段式调用：INIT -> APPEND（每段一次）-> DISPLAY
  CALL FUNCTION 'REUSE_ALV_BLOCK_LIST_INIT'
    EXPORTING
      i_callback_program = sy-repid.

  CALL FUNCTION 'REUSE_ALV_BLOCK_LIST_APPEND'
    EXPORTING
      is_layout   = ls_layo
      it_fieldcat = lt_fcat1
      i_tabname   = 'GT_BLOCK1'
      it_events   = lt_events
    TABLES
      t_outtab    = gt_block1
    EXCEPTIONS
      OTHERS      = 1.

  CALL FUNCTION 'REUSE_ALV_BLOCK_LIST_APPEND'
    EXPORTING
      is_layout   = ls_layo
      it_fieldcat = lt_fcat2
      i_tabname   = 'GT_BLOCK2'
      it_events   = lt_events
    TABLES
      t_outtab    = gt_block2
    EXCEPTIONS
      OTHERS      = 1.

  CALL FUNCTION 'REUSE_ALV_BLOCK_LIST_DISPLAY'
    EXCEPTIONS
      program_error = 1
      OTHERS        = 2.
  IF sy-subrc <> 0.
    MESSAGE 'BLOCK ALV 调用失败' TYPE 'I'.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  DISPLAY_OO_ALV
*&---------------------------------------------------------------------*
*      方式 3：CL_GUI_ALV_GRID（OO ALV）
*      容器用 Docking Container 撑满屏幕，不用在画板上画控件
*----------------------------------------------------------------------*
FORM display_oo_alv.
  DATA ls_layout TYPE lvc_s_layo.

  IF go_docking IS INITIAL.
    " Docking 容器：extension 足够大即铺满整屏
    CREATE OBJECT go_docking
      EXPORTING
        repid     = sy-repid
        dynnr     = '0100'
        side      = cl_gui_docking_container=>dock_at_left
        extension = 3000.

    CREATE OBJECT go_grid
      EXPORTING
        i_parent = go_docking.
  ENDIF.

  ls_layout-zebra      = abap_true.
  ls_layout-cwidth_opt = abap_true.
  ls_layout-sel_mode   = 'A'.        " 允许多行选择

  " 不传字段目录：I_STRUCTURE_NAME 会让网格自动从 DDIC 结构生成
  " （如需自定义目录，可用 LVC_FIELDCATALOG_MERGE_GET——部分系统没有此 FM，
  "  替代方案：REUSE_ALV_FIELDCATALOG_MERGE + LVC_TRANSFER_FROM_SLIS 转换）
  go_grid->set_table_for_first_display(
    EXPORTING
      i_structure_name = 'SFLIGHT'
      is_layout        = ls_layout
    CHANGING
      it_outtab        = gt_sflight
    EXCEPTIONS
      OTHERS           = 1 ).
  IF sy-subrc <> 0.
    MESSAGE 'OO ALV 调用失败' TYPE 'I'.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  DISPLAY_OO_ALV_SCREEN0
*&---------------------------------------------------------------------*
*      方式 3 的兜底：未建屏幕 100 时，以当前屏幕（screen0）为父容器
*      直接铺满展示，零配置可运行；返回（F3）即退出程序
*----------------------------------------------------------------------*
FORM display_oo_alv_screen0.
  DATA ls_layout TYPE lvc_s_layo.

  CREATE OBJECT go_grid
    EXPORTING
      i_parent = cl_gui_container=>screen0.

  ls_layout-zebra      = abap_true.
  ls_layout-cwidth_opt = abap_true.

  go_grid->set_table_for_first_display(
    EXPORTING
      i_structure_name = 'SFLIGHT'
      is_layout        = ls_layout
    CHANGING
      it_outtab        = gt_sflight
    EXCEPTIONS
      OTHERS           = 1 ).
  IF sy-subrc <> 0.
    MESSAGE 'OO ALV 调用失败' TYPE 'I'.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  DISPLAY_SALV
*&---------------------------------------------------------------------*
*      方式 4：CL_SALV_TABLE（SALV 模型）
*----------------------------------------------------------------------*
FORM display_salv.
  TRY.
      " 工厂方法直接出全屏 ALV，无需字段目录、无需屏幕
      cl_salv_table=>factory(
        IMPORTING
          r_salv_table = DATA(lo_salv)
        CHANGING
          t_table      = gt_sflight ).

      lo_salv->get_columns( )->set_optimize( abap_true ).                  " 列宽优化
      lo_salv->get_display_settings( )->set_striped_pattern( abap_true ).  " 条纹
      lo_salv->get_display_settings( )->set_list_header( 'SALV：航班清单' ).
      lo_salv->get_functions( )->set_all( abap_true ).                     " 全部工具栏

      lo_salv->get_sorts( )->add_sort( 'CARRID' ).                         " 预设排序
      lo_salv->get_aggregations( )->add_aggregation( 'PRICE' ).            " 价格合计

      " 单价列高亮（红色系）
      " SET_COLOR 是子类 CL_SALV_COLUMN_TABLE 的方法，GET_COLUMN 返回基类引用，需转型
      CAST cl_salv_column_table(
        lo_salv->get_columns( )->get_column( 'PRICE' )
      )->set_color( VALUE lvc_s_colo( col = 6 ) ).

      lo_salv->display( ).
    CATCH cx_salv_msg cx_salv_not_found
          cx_salv_existing cx_salv_data_error INTO DATA(lx_salv).
      MESSAGE lx_salv->get_text( ) TYPE 'I'.
  ENDTRY.
ENDFORM.

*&---------------------------------------------------------------------*
*&      Module  STATUS_0100  OUTPUT
*&---------------------------------------------------------------------*
*      屏幕 100 的 PBO：首次进入时创建容器并展示 ALV
*----------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  SET PF-STATUS 'STATUS_0100'.    " 需自建，至少含 BACK/EXIT/CANC
  SET TITLEBAR  'TITLE_0100'.
  IF go_docking IS INITIAL.
    PERFORM display_oo_alv.
  ENDIF.
ENDMODULE.

*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*      屏幕 100 的 PAI：返回选择屏幕
*----------------------------------------------------------------------*
MODULE user_command_0100 INPUT.
  " 功能码取决于 SE41 里 STATUS_0100 的定义方式：
  " 直接给按钮分配标准功能键（F3/F15/F12）时，功能码是 &F03/&F15/&F12；
  " 自定义按钮命名常用 BACK/EXIT/CANC。两种都兼容。
  CASE sy-ucomm.
    WHEN '&F03' OR '&F15' OR '&F12'
      OR 'BACK' OR 'EXIT' OR 'CANC'.
      LEAVE TO SCREEN 0.
  ENDCASE.
ENDMODULE.

