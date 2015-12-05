#!/bin/bash
psql -d postgres -a -f 00_drop_wisdb.sql
psql -d postgres -a -f 01_create_db.sql
psql -d wisdb -a -f 02_create_schema.sql
psql -d wisdb -a -f 03_insert_data.sql
psql -d wisdb -a -f 04a_set_data_for_2013.sql
psql -d wisdb -a -f 05_create_bt_calculate_tables_views.sql
psql -d wisdb -a -f 06_fill_factorstable.sql
psql -d wisdb -a -f 07_create_views_for_UI.sql
