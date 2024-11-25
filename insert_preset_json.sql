create function demo.insert_preset_json_1(p_preset_json jsonb, p_chage_preset_id integer, p_new_preset_name text,
                                          OUT p_changed_preset_json jsonb) returns jsonb
    language plpgsql
as
$$
DECLARE
    v_preset_list         JSONB;
    v_preset              JSONB;
    v_changed_preset_list JSONB;
    v_retval              numeric;
    v_row_count           numeric;
    v_message             text;
    v_error_message       text;
BEGIN
    --     {
    --       "preset": [
    --         {
    --           "preset_id": 1,
    --           "preset_name": "Sl_Cricket_SL_Master",
    --           "created_date": "2024-11-12T05:51:49.915303"
    --         },
    --         {
    --           "preset_id": 2,
    --           "preset_name": "IPL_T20_Cricket_SL_Fantasy",
    --           "created_date": "2024-11-12T05:51:49.915303"
    --         }
    --       ]
    --     }

    v_preset_list := p_preset_json -> 'preset';
    BEGIN
        IF p_chage_preset_id IS NULL OR p_new_preset_name IS NULL THEN
            v_retval := -1;
            v_error_message := 'preset_id or preset_name are null';
            RAISE EXCEPTION 'PRESET_ID_NAME_NULL';
        END IF;

        FOR v_preset IN SELECT * FROM jsonb_array_elements(v_preset_list)
            LOOP
                INSERT INTO demo.preset_json (preset_id, preset_json)
                VALUES ((v_preset ->> 'preset_id')::INT, v_preset);
            END LOOP;

        UPDATE demo.preset_json
        SET preset_json = jsonb_set(preset_json, '{preset_name}', to_jsonb(p_new_preset_name))
        WHERE preset_id = p_chage_preset_id;

        v_changed_preset_list := jsonb_agg(preset_json) FROM demo.preset_json;

        GET DIAGNOSTICS v_row_count = ROW_COUNT;
        IF v_row_count = 0 THEN
            v_retval := -1;
            v_error_message := 'No rows inserted';
            RAISE EXCEPTION 'NO_ROWS_INSERTED';
        END IF;

        v_retval := 1;
        v_message := 'Success - ' || v_row_count || ' rows inserted';

        p_changed_preset_json := jsonb_build_object(
                'preset', v_changed_preset_list,
                'message', v_message,
                'retval', v_retval,
                'error_message', v_error_message
                                 );

    EXCEPTION
        WHEN OTHERS THEN
            v_retval := -1;
            v_error_message := 'ERROR: ' || SQLSTATE || ', ' || SQLERRM;


            p_changed_preset_json := jsonb_build_object(
                    'preset', v_changed_preset_list,
                    'message', v_message,
                    'retval', v_retval,
                    'error_message', v_error_message
                                     );

    END;
END;
$$;