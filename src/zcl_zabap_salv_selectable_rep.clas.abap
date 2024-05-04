CLASS zcl_zabap_salv_selectable_rep DEFINITION
  PUBLIC
  INHERITING FROM zcl_zabap_salv_report
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    "! @parameter report_id | <p class="shorttext synchronized" lang="en">Needed for key for saving layouts</p>
    "! @parameter handle | <p class="shorttext synchronized" lang="en">Needed if you need more than one table inside single report</p>
    "! @parameter container | <p class="shorttext synchronized" lang="en">Usually instance of CL_GUI_CUSTOM_CONTAINER if needed.</p>
    METHODS constructor IMPORTING report_id TYPE sy-repid handle TYPE slis_handl OPTIONAL container TYPE REF TO cl_gui_container OPTIONAL RAISING cx_salv_msg.
    METHODS display_data_as_selectable IMPORTING popup_position TYPE t_popup_position OPTIONAL layout_name TYPE slis_vari OPTIONAL
                                                 select_row_on_double_click TYPE abap_bool DEFAULT abap_true
                                                 selection_mode TYPE i DEFAULT if_salv_c_selection_mode=>single
                                       EXPORTING selected_rows TYPE salv_t_row did_user_confirm TYPE abap_bool.
  PROTECTED SECTION.
    DATA select_row_on_double_click TYPE abap_bool.
    DATA did_user_confirm TYPE abap_bool.

    METHODS confirm_or_cancel FOR EVENT added_function OF cl_salv_events_table IMPORTING !e_salv_function.
    METHODS exit_on_double_click FOR EVENT double_click OF cl_salv_events_table IMPORTING !row !column.
  PRIVATE SECTION.
ENDCLASS.


CLASS zcl_zabap_salv_selectable_rep IMPLEMENTATION.
  METHOD constructor.
    super->constructor( container = container report_id = report_id handle = handle ).

    DATA(event) = alv_table->get_event( ).
    SET HANDLER me->confirm_or_cancel FOR event.
    SET HANDLER me->exit_on_double_click FOR event.

    alv_table->set_screen_status( pfstatus = 'POPUP' report = 'SAPLZABAP_SALV_SCREEN_STATUSES' ).
  ENDMETHOD.

  METHOD display_data_as_selectable.
    me->select_row_on_double_click = select_row_on_double_click.
    alv_table->get_selections( )->set_selection_mode( selection_mode ).
    format_alv_table( layout_name ).
    IF popup_position IS SUPPLIED.
      alv_table->set_screen_popup( start_column = popup_position-start_column end_column = popup_position-end_column
                                   start_line = popup_position-start_line end_line = popup_position-end_line ).
    ENDIF.
    alv_table->display( ).
    selected_rows = alv_table->get_selections( )->get_selected_rows( ).
    did_user_confirm = me->did_user_confirm.
  ENDMETHOD.

  METHOD exit_on_double_click.
    IF select_row_on_double_click = abap_false. RETURN. ENDIF.

    DATA(sel) = alv_table->get_selections( ).
    sel->set_selected_rows( value = VALUE #( ( row ) ) ).
    me->did_user_confirm = abap_true.
    alv_table->close_screen( ).
  ENDMETHOD.

  METHOD confirm_or_cancel.
    CASE e_salv_function.
      WHEN '&CONFIRM'.
        me->did_user_confirm = abap_true.
        alv_table->close_screen( ).

      WHEN '&CANCEL'.
        me->did_user_confirm = abap_false.
        alv_table->close_screen( ).

    ENDCASE.
  ENDMETHOD.
ENDCLASS.
