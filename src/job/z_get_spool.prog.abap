*&---------------------------------------------------------------------*
*& Report Z_GET_SPOOL
*&---------------------------------------------------------------------*
*&  本程序来自【老白的ABAP博客】，在此致谢！
*&  地址：http://blog.chinaunix.net/uid-8527621-id-2029790.html
*&---------------------------------------------------------------------*
REPORT z_get_spool NO STANDARD PAGE HEADING MESSAGE-ID so LINE-SIZE 255  .

DATA: objcont TYPE soli OCCURS 0 WITH HEADER LINE.
DATA: owner    LIKE soud-usrnam,
      rcode(4) .

START-OF-SELECTION.
  owner = sy-uname.
  PERFORM read_spool  TABLES objcont
                      USING  owner
                             rcode.
  LOOP AT objcont.
    WRITE objcont-line.
  ENDLOOP.

*&---------------------------------------------------------------------*
*&      Form  read_spool
*&---------------------------------------------------------------------*
FORM read_spool TABLES objcont STRUCTURE soli
                USING  owner rcode.
  DATA h_objcont     LIKE tline OCCURS 0 WITH HEADER LINE.
  DATA spool_number  LIKE rspotype-rqnumber.
  DATA desired_type  LIKE sood-objtp.
  DATA real_type     LIKE sood-objtp.
  DATA f_stop_loop   LIKE sonv-flag.
  DATA is_otf.
  CLEAR: f_stop_loop.
  WHILE f_stop_loop EQ ' '.
    CALL FUNCTION 'SO_WIND_SPOOL_LIST'
      EXPORTING
        owner        = owner
      IMPORTING
        spool_number = spool_number.
    IF spool_number IS INITIAL.
      MOVE '9000' TO rcode.
      MOVE 'X' TO f_stop_loop.
      EXIT.
    ENDIF.
    CALL FUNCTION 'RSPO_GET_TYPE_SPOOLJOB'
      EXPORTING
        rqident        = spool_number
      IMPORTING
        is_otf         = is_otf
      EXCEPTIONS
        can_not_access = 1.
    IF NOT is_otf IS INITIAL.
      MOVE 'OTF' TO desired_type.
    ELSE.
      MOVE 'RAW' TO desired_type.
    ENDIF.
    CALL FUNCTION 'RSPO_RETURN_SPOOLJOB'
      EXPORTING
        rqident              = spool_number
        desired_type         = desired_type
      IMPORTING
        real_type            = real_type
      TABLES
        buffer               = objcont
      EXCEPTIONS
        no_such_job          = 1
        type_no_match        = 2
        job_contains_no_data = 3
        no_permission        = 4
        can_not_access       = 4
        read_error           = 5.
    CASE sy-subrc.
      WHEN '00'.
        MOVE '00' TO rcode.
        MOVE 'X' TO f_stop_loop.
        IF real_type EQ 'OTF'.
          CALL FUNCTION 'CONVERT_OTF'
            TABLES
              otf    = objcont
              lines  = h_objcont
            EXCEPTIONS
              OTHERS = 1.
          IF sy-subrc EQ '00'.
            CLEAR objcont.
            REFRESH objcont.
            LOOP AT h_objcont.
              APPEND h_objcont-tdline TO objcont.
            ENDLOOP.
          ENDIF.
        ENDIF.
      WHEN 1.
        MESSAGE i753 WITH spool_number.
      WHEN 2.
        MESSAGE i100.
      WHEN 4.
        MESSAGE i015.
        MOVE '9000' TO rcode.
        MOVE 'X'  TO f_stop_loop.
      WHEN 5.
        MESSAGE i752 WITH spool_number.
        MOVE '9000' TO rcode.
        MOVE 'X'  TO f_stop_loop.
    ENDCASE.
  ENDWHILE.
ENDFORM.                    "READ_SPOOL
