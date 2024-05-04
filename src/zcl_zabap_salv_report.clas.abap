CLASS zcl_zabap_salv_report DEFINITION
 PUBLIC
 CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF t_popup_position,
        start_column TYPE i,
        end_column   TYPE i,
        start_line   TYPE i,
        end_line     TYPE i,
      END OF t_popup_position.

    CONSTANTS:
      "! Can be used in <em>DISPLAY_DATA</em> function
      BEGIN OF c_default_popup_position,
        start_column TYPE i VALUE 1,
        end_column   TYPE i VALUE 192,
        start_line   TYPE i VALUE 1,
        end_line     TYPE i VALUE 32,
      END OF c_default_popup_position.

    DATA alv_table TYPE REF TO cl_salv_table READ-ONLY.

    "! @parameter layout_key | <p class="shorttext synchronized" lang="en">Needed for saving/displaying layouts</p>
    "! @parameter container | <p class="shorttext synchronized" lang="en">Usually instance of CL_GUI_CUSTOM_CONTAINER if needed</p>
    "! @parameter report_id | <p class="shorttext synchronized" lang="en">Left for backwards compatibility. Use layout_key parameter.</p>
    "! @parameter handle | <p class="shorttext synchronized" lang="en">Left for backwards compatibility. Use layout_key parameter.</p>
    METHODS constructor IMPORTING layout_key TYPE salv_s_layout_key OPTIONAL container TYPE REF TO cl_gui_container OPTIONAL
                                  report_id TYPE sy-repid OPTIONAL handle TYPE slis_handl OPTIONAL RAISING cx_salv_msg.
    "! @parameter text | <p class="shorttext synchronized" lang="en">If left empty last text is displayed</p>
    "! @parameter records_count | <p class="shorttext synchronized" lang="en">Leave 0 to not display progress circle</p>
    METHODS set_progress_bar IMPORTING text TYPE string DEFAULT '' current_record TYPE i DEFAULT 0 records_count TYPE i DEFAULT 0.
    "! <p class="shorttext synchronized" lang="en">Table with data must be assigned before calling display_data</p>
    "! @parameter create_table_copy | <p class="shorttext synchronized" lang="en">Set abap_true if table is freed from memory after this...</p>
    "! ...function. E.g. you had <em>DATA(data_table) = ...</em> inside method/form before calling this function with data_table and not calling <em>display_data</em> before exiting method/form.
    "! @parameter data_table | <p class="shorttext synchronized" lang="en">Table with data to display</p>
    METHODS set_data IMPORTING create_table_copy TYPE abap_bool DEFAULT 'X' CHANGING data_table TYPE STANDARD TABLE RAISING cx_salv_no_new_data_allowed.
    "! <p class="shorttext synchronized" lang="en">Data must be assigned with <em>SET_DATA</em> before display</p>
    "! @parameter popup_position | <p class="shorttext synchronized" lang="en">Can't be used with container. Fill to display table as popup</p>
    METHODS display_data IMPORTING popup_position TYPE t_popup_position OPTIONAL layout_name TYPE slis_vari OPTIONAL.
    METHODS get_layout_from_f4_selection RETURNING VALUE(retval) TYPE slis_vari.
    METHODS set_fixed_column_text IMPORTING column TYPE lvc_fname text TYPE scrtext_l output_length TYPE lvc_outlen OPTIONAL.
    METHODS set_column_ddic_ref IMPORTING column TYPE lvc_fname table TYPE lvc_tname field TYPE lvc_fname.
    METHODS hide_column IMPORTING column TYPE lvc_fname.
    METHODS set_column_as_icon IMPORTING column TYPE lvc_fname.
    METHODS set_header IMPORTING header TYPE lvc_title.
    METHODS set_edit_mask IMPORTING column TYPE lvc_fname mask TYPE lvc_edtmsk OPTIONAL.
    METHODS set_column_as_hotspot IMPORTING column TYPE lvc_fname.

  PROTECTED SECTION.
    DATA layout_key TYPE salv_s_layout_key.
    DATA progress_text TYPE string.
    DATA data_table_ref TYPE REF TO data.

    METHODS get_ref_to_cell_value IMPORTING row TYPE salv_de_row column TYPE salv_de_column RETURNING VALUE(retval) TYPE REF TO data RAISING cx_sy_tab_range_out_of_bounds.
    METHODS initialise_alv IMPORTING container TYPE REF TO cl_gui_container OPTIONAL RAISING cx_salv_msg.
    METHODS enable_layouts.
    METHODS set_handlers.
    METHODS format_alv_table IMPORTING layout_name TYPE slis_vari OPTIONAL.

    "EVENT HANDLERS
    "! <p class="shorttext synchronized" lang="en">Redefine when inheriting from <em>zcl_zabap_salv_report</em></p>
    METHODS on_before_salv_function FOR EVENT before_salv_function OF cl_salv_events_table IMPORTING e_salv_function.
    "! <p class="shorttext synchronized" lang="en">Redefine when inheriting from <em>zcl_zabap_salv_report</em></p>
    METHODS on_after_salv_function FOR EVENT before_salv_function OF cl_salv_events_table IMPORTING e_salv_function.
    "! <p class="shorttext synchronized" lang="en">Redefine when inheriting from <em>zcl_zabap_salv_report</em></p>
    METHODS on_added_function FOR EVENT added_function OF cl_salv_events_table IMPORTING e_salv_function.
    "! <p class="shorttext synchronized" lang="en">Redefine when inheriting from <em>zcl_zabap_salv_report</em></p>
    METHODS on_top_of_page FOR EVENT top_of_page OF cl_salv_events_table IMPORTING r_top_of_page page table_index.
    "! <p class="shorttext synchronized" lang="en">Redefine when inheriting from <em>zcl_zabap_salv_report</em></p>
    METHODS on_end_of_page FOR EVENT end_of_page OF cl_salv_events_table IMPORTING r_end_of_page page.
    "! <p class="shorttext synchronized" lang="en">Redefine when inheriting from <em>zcl_zabap_salv_report</em></p>
    METHODS on_double_click FOR EVENT double_click OF cl_salv_events_table IMPORTING row column.
    "! <p class="shorttext synchronized" lang="en">Redefine when inheriting from <em>zcl_zabap_salv_report</em></p>
    METHODS on_link_click FOR EVENT link_click OF cl_salv_events_table IMPORTING row column.
    "EVENTS HANDLERS END

  PRIVATE SECTION.
ENDCLASS.


CLASS zcl_zabap_salv_report IMPLEMENTATION.
  METHOD constructor.
    me->layout_key = COND #( WHEN layout_key IS SUPPLIED THEN layout_key ELSE VALUE #( report = report_id handle = handle ) ).
    initialise_alv( container ).
    enable_layouts( ).
    set_handlers( ).
  ENDMETHOD.

  METHOD display_data.
    format_alv_table( layout_name ).
    IF popup_position IS SUPPLIED.
      alv_table->set_screen_popup( start_column = popup_position-start_column end_column = popup_position-end_column
                                   start_line = popup_position-start_line end_line = popup_position-end_line  ).
    ENDIF.
    alv_table->display( ).
  ENDMETHOD.

  METHOD enable_layouts.
    alv_table->get_layout( )->set_key( layout_key ).
    alv_table->get_layout( )->set_save_restriction( if_salv_c_layout=>restrict_none ).
    alv_table->get_layout( )->set_default( abap_true ). "Enables to save layout as default
  ENDMETHOD.

  METHOD format_alv_table.
    IF NOT layout_name IS INITIAL.
      alv_table->get_layout( )->set_initial_layout( layout_name ).
    ENDIF.
    alv_table->get_functions( )->set_all( ).
  ENDMETHOD.

  METHOD get_layout_from_f4_selection.
    retval = cl_salv_layout_service=>f4_layouts( s_key = layout_key restrict = if_salv_c_layout=>restrict_none )-layout.
  ENDMETHOD.

  METHOD get_ref_to_cell_value.
    FIELD-SYMBOLS <data_table> TYPE STANDARD TABLE.

    ASSIGN me->data_table_ref->* TO <data_table>.

    IF row < 0 OR row > lines( <data_table> ).
      RAISE EXCEPTION TYPE cx_sy_tab_range_out_of_bounds.
    ENDIF.

    READ TABLE <data_table> ASSIGNING FIELD-SYMBOL(<table_row>) INDEX row.
    ASSIGN COMPONENT column OF STRUCTURE <table_row> TO FIELD-SYMBOL(<cell_value>).

    GET REFERENCE OF <cell_value> INTO retval.
  ENDMETHOD.

  METHOD hide_column.
    alv_table->get_columns( )->get_column( column )->set_technical( abap_true ).
  ENDMETHOD.

  METHOD initialise_alv.
    "Need empty table for cl_salv_table factory so you can use f4 layout selection
    "Table must be of structured type, throws error otherwise
    TYPES:
      BEGIN OF t_dummy,
        dummy TYPE i,
      END OF t_dummy.

    CREATE DATA data_table_ref TYPE TABLE OF t_dummy.
    FIELD-SYMBOLS <data_table> TYPE STANDARD TABLE.
    ASSIGN data_table_ref->* TO <data_table>.

    "The code inside factory checks whether container was supplied (even if emtpy) and blocks popup in such case
    IF container IS BOUND.
      cl_salv_table=>factory( EXPORTING r_container = container IMPORTING r_salv_table = alv_table CHANGING t_table = <data_table> ).
    ELSE.
      cl_salv_table=>factory( IMPORTING r_salv_table = alv_table CHANGING t_table = <data_table> ).
    ENDIF.
  ENDMETHOD.

  METHOD on_added_function.
  ENDMETHOD.

  METHOD on_after_salv_function.
  ENDMETHOD.

  METHOD on_before_salv_function.
  ENDMETHOD.

  METHOD on_double_click.
  ENDMETHOD.

  METHOD on_end_of_page.
  ENDMETHOD.

  METHOD on_link_click.
  ENDMETHOD.

  METHOD on_top_of_page.
  ENDMETHOD.

  METHOD set_column_ddic_ref.
    alv_table->get_columns( )->get_column( column )->set_ddic_reference( VALUE salv_s_ddic_reference( table = table field = field ) ).
  ENDMETHOD.

  METHOD set_column_as_icon.
    DATA(col) = CAST cl_salv_column_table( me->alv_table->get_columns( )->get_column( column ) ).
    col->set_icon( if_salv_c_bool_sap=>true ).
  ENDMETHOD.

  METHOD set_data.
    IF create_table_copy = abap_true.
      "COPY DATA TO LOCAL REFERENCE, NEEDED IF IT'S FREED AFTER METHOD FINISHES PROGRAM WILL SHORT DUMP.
      CREATE DATA me->data_table_ref LIKE data_table.
      FIELD-SYMBOLS <data_table> LIKE data_table.
      ASSIGN data_table_ref->* TO <data_table>.
      APPEND LINES OF data_table TO <data_table>.

      alv_table->set_data( CHANGING t_table = <data_table> ).
    ELSE.
      data_table_ref = REF #( data_table ).
      alv_table->set_data( CHANGING t_table = data_table ).
    ENDIF.
  ENDMETHOD.

  METHOD set_fixed_column_text.
    DATA(col) = alv_table->get_columns( )->get_column( column ).
    IF strlen( text ) > 20.
      col->set_long_text( text ).
      col->set_fixed_header_text( 'L' ).
    ELSEIF strlen( text ) > 10.
      col->set_long_text( text ).
      col->set_medium_text( CONV #( text ) ).
      col->set_fixed_header_text( 'M' ).
    ELSE.
      col->set_long_text( text ).
      col->set_medium_text( CONV #( text ) ).
      col->set_short_text( CONV #( text ) ).
      col->set_fixed_header_text( 'S' ).
    ENDIF.

    IF NOT output_length IS INITIAL.
      col->set_output_length( output_length ).
    ENDIF.
  ENDMETHOD.

  METHOD set_handlers.
    DATA(event) = alv_table->get_event( ).
    SET HANDLER me->on_before_salv_function FOR event.
    SET HANDLER me->on_after_salv_function FOR event.
    SET HANDLER me->on_added_function FOR event.
    SET HANDLER me->on_top_of_page FOR event.
    SET HANDLER me->on_end_of_page FOR event.
    SET HANDLER me->on_double_click FOR event.
    SET HANDLER me->on_link_click FOR event.
  ENDMETHOD.

  METHOD set_progress_bar.
    IF NOT text IS INITIAL.
      progress_text = text.
    ENDIF.

    IF records_count > 0.
      cl_progress_indicator=>progress_indicate( i_text = progress_text i_processed = current_record i_total = records_count i_output_immediately = 'X' ).
    ELSE.
      cl_progress_indicator=>progress_indicate( i_text = progress_text i_output_immediately = 'X' ).
    ENDIF.
  ENDMETHOD.

  METHOD set_header.
    alv_table->get_display_settings( )->set_list_header( value = header ).
  ENDMETHOD.

  METHOD set_edit_mask.
    alv_table->get_columns( )->get_column( column )->set_edit_mask( mask ).
  ENDMETHOD.

  METHOD set_column_as_hotspot.
    DATA(col) = alv_table->get_columns( )->get_column( column ).
    CALL METHOD col->('SET_CELL_TYPE') EXPORTING value = if_salv_c_cell_type=>hotspot.
  ENDMETHOD.
ENDCLASS.
