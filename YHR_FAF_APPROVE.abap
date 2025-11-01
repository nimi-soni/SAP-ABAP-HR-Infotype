FORM INFOTYPE_POST.

  DATA:W_9136 TYPE P9136.
  DATA: E_RETURN  TYPE BAPIRETURN1,
        E_RETURN1 TYPE BAPIRETURN1,
        LV_RETURN TYPE BAPIRETURN1,
        GC_KEY    TYPE BAPIPAKEY.
  DATA: GC_STTS(4) TYPE  C VALUE '@08@', "S
        GC_STTA(4) TYPE  C VALUE '@09@', "Already
        GC_STTE(4) TYPE  C VALUE '@0A@', "E
        GC_INFO    TYPE PA9135-SUBTY VALUE '9136',
        GC_OP(20)  TYPE C,
        GC_UPD(20) TYPE C VALUE 'MOD',
        GC_INS(20) TYPE C VALUE 'INS',
        GC_S(1)    TYPE C VALUE 'S',
        GC_E(1)    TYPE C VALUE 'E',
        GC_I(1)    TYPE C VALUE 'I',
        GC_BLANK   TYPE C VALUE ''.
  DATA: EDATE TYPE SY-DATUM VALUE '99991231',
        SDATE TYPE SY-DATUM.

  IF WA_FINAL IS NOT INITIAL.
    SELECT SINGLE * FROM PA9136 WHERE PERNR =  _FINAL-PERNR AND ( CURR_FLAG = '1' OR CURR_FLAG = '2' ) INTO (LS_DATA).

    IF SY-SUBRC = 0.
      LOOP AT IT_FINAL ASSIGNING FIELD-SYMBOL(<LFS_FINAL_2>) WHERE PERNR = WA_FINAL-PERNR.

        DATA(WA_9136_INTYP) = LS_DATA.

        CLEAR:W_9136.
        MOVE-CORRESPONDING WA_9136_INTYP TO W_9136.

        CALL FUNCTION 'BAPI_EMPLOYEE_ENQUEUE'
          EXPORTING
            NUMBER = <LFS_FINAL_2>-PERNR
          IMPORTING
            RETURN = E_RETURN.
        IF E_RETURN-TYPE = GC_E.
          <LFS_FINAL_2>-MSG = E_RETURN-MESSAGE.
          <LFS_FINAL_2>-STATUS = GC_STTE.
        ELSE.
          W_9136-INFTY  = GC_INFO.

          IF VERIFIER = 'FIRST' AND R_VERF = 'X'.
            IF LV_FIELDNAME = 'APPROVE'.
              W_9136-CURR_FLAG = '2'.
              W_9136-CURR_STATUS = 'Approved'.
            ELSEIF LV_FIELDNAME EQ 'REJECT'.
              W_9136-CURR_FLAG = '3'.
              W_9136-CURR_STATUS = 'Rejected'.
            ENDIF.

            <LFS_FINAL_2>-SP_WF_ACTON      = LV_FIELDNAME                .
            <LFS_FINAL_2>-SP_ID             = SY-UNAME                    .
            <LFS_FINAL_2>-SP_NAME           = <LFS_FINAL_2>-VERIFIED_BY   .
            <LFS_FINAL_2>-SP_POS            = <LFS_FINAL_2>-VERIFIED_POS  .
            <LFS_FINAL_2>-SP_ACTON_DATE     = SY-DATUM                    .
            <LFS_FINAL_2>-SP_ACTON_TIME     = SY-UZEIT                    .
            <LFS_FINAL_2>-SP_REMARKS        = <LFS_FINAL_2>-SP_REMARKS    .

            W_9136-SP_WF_ACT         = LV_FIELDNAME                .
            W_9136-SP_ID             = SY-UNAME                    .
            W_9136-SP_NAME           = <LFS_FINAL_2>-VERIFIED_BY   .
            W_9136-SP_POS            = <LFS_FINAL_2>-VERIFIED_POS  .
            W_9136-SP_ACTON_DATE     = SY-DATUM                    .
            W_9136-SP_ACTON_TIME     = SY-UZEIT                    .
            W_9136-SP_REMARKS        = <LFS_FINAL_2>-SP_REMARKS    .
          ENDIF.

          CLEAR :LV_RETURN,GC_KEY.

          CALL FUNCTION 'HR_INFOTYPE_OPERATION'
            EXPORTING
              INFTY         = GC_INFO
              NUMBER        = W_9136-PERNR
              VALIDITYEND   = W_9136-ENDDA
              VALIDITYBEGIN = W_9136-BEGDA
              RECORD        = W_9136
              OPERATION     = GC_UPD
              SUBTYPE       = ''
            IMPORTING
              RETURN        = LV_RETURN
              KEY           = GC_KEY.

          IF LV_RETURN-TYPE = GC_E.
            <LFS_FINAL_2>-MSG = LV_RETURN-MESSAGE.
            <LFS_FINAL_2>-STATUS = GC_STTE.

            CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
          ELSEIF GC_KEY IS NOT INITIAL .
            <LFS_FINAL_2>-MSG = 'WF Verified.'.
            <LFS_FINAL_2>-STATUS = GC_STTS.
            CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
              EXPORTING
                WAIT = 'X'.
            "COMMIT WORK.
            WA_FINAL = <LFS_FINAL_2>.
            PERFORM SEND_MAIL.
          ENDIF.
          CLEAR LV_RETURN.
          CALL FUNCTION 'BAPI_EMPLOYEE_DEQUEUE'
            EXPORTING
              NUMBER = <LFS_FINAL_2>-PERNR
            IMPORTING
              RETURN = E_RETURN1.
        ENDIF.
        CLEAR E_RETURN1.

      ENDLOOP.
    ENDIF.
  ENDIF.
  CLEAR LS_DATA.

ENDFORM.