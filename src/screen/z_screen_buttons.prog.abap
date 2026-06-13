*&---------------------------------------------------------------------*
*& Report Z_SCREEN_BUTTONS
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT z_screen_buttons.
TABLES: sscrfields.

SELECTION-SCREEN BEGIN OF BLOCK blk01 WITH FRAME TITLE TEXT-t01.
*SELECTION-SCREEN SKIP 1."跳过一行
  SELECTION-SCREEN PUSHBUTTON /1(14) TEXT-000 USER-COMMAND sm300.
  SELECTION-SCREEN PUSHBUTTON 20(14) TEXT-001 USER-COMMAND sm301.
  SELECTION-SCREEN PUSHBUTTON 40(14) TEXT-002 USER-COMMAND sm302.
SELECTION-SCREEN END OF BLOCK blk01.

AT SELECTION-SCREEN.
  PERFORM frm_button ."屏幕按钮


*&---------------------------------------------------------------------*
*& Form FRM_BUTTON
*&---------------------------------------------------------------------*
*& 屏幕按钮
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM frm_button .
  DATA: view_name TYPE dd02v-tabname.

  CASE sscrfields-ucomm.
    WHEN 'SM300'.
      CALL TRANSACTION 'CORD'.
      RETURN.
    WHEN 'SM301'.
      view_name = 'V_T001W'.
    WHEN 'SM302'.
      view_name = 'V_T004'.
    WHEN OTHERS.
  ENDCASE.

  IF view_name IS NOT INITIAL.
    CALL FUNCTION 'VIEW_MAINTENANCE_CALL'
      EXPORTING
        action                       = 'U'
        view_name                    = view_name
        no_warning_for_clientindep   = 'X'
      EXCEPTIONS
        client_reference             = 1
        foreign_lock                 = 2
        invalid_action               = 3
        no_clientindependent_auth    = 4
        no_database_function         = 5
        no_editor_function           = 6
        no_show_auth                 = 7
        no_tvdir_entry               = 8
        no_upd_auth                  = 9
        only_show_allowed            = 10
        system_failure               = 11
        unknown_field_in_dba_sellist = 12
        view_not_found               = 13
        OTHERS                       = 14.
  ENDIF.


ENDFORM.

