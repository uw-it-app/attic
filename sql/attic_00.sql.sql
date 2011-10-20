SELECT standard.create_data_schema('attic', 'Attic related data');

/**********************************************************************************************/

CREATE TABLE attic.store (
    modified_at     timestamptz NOT NULL DEFAULT now(),
    modified_by     varchar     NOT NULL DEFAULT standard.get_uwnetid(),
    id              serial      PRIMARY KEY,
    username        varchar     NOT NULL DEFAULT standard.get_uwnetid(),
    application     varchar     NOT NULL,
    content         xml,
    UNIQUE (username, application)
);

COMMENT ON TABLE attic.store IS 'DR: Stores user application settings (2011-10-20)';

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE attic.store TO PUBLIC;
GRANT SELECT, USAGE ON SEQUENCE attic.store_id_seq TO PUBLIC;

SELECT standard.standardize_table_history_and_trigger('attic', 'store');

/**********************************************************************************************/

CREATE OR REPLACE FUNCTION attic.store_xml(varchar) RETURNS xml
    LANGUAGE sql
    VOLATILE
    SECURITY INVOKER
    AS $_$
/*  Function:     attic.store_xml(varchar)
    Description:  Retrieves the XML stored for the current user and application
    Affects:      nothing
    Arguments:    varchar: application name
    Returns:      xml: stored settings
*/
    SELECT content FROM attic.store WHERE application = $1 AND username = standard.get_uwnetid();
$_$;

COMMENT ON FUNCTION attic.store_xml(varchar) IS 'DR: Retrieves the XML stored for the current user and application (2011-10-20)';

/**********************************************************************************************/

CREATE OR REPLACE FUNCTION attic.store_xml_write(varchar, xml) RETURNS xml
    LANGUAGE plpgsql
    VOLATILE
    SECURITY INVOKER
    AS $_$
/*  Function:     attic.store_xml_write(varchar, xml)
    Description:  Sets application store for the current user
    Affects:      single record in attic.store
    Arguments:    varchar: application name
                  xml: stored settings
    Returns:      xml: stored settings
*/
DECLARE
    v_app       ALIAS FOR $1;
    v_xml       ALIAS FOR $2;
    _updated    integer;
BEGIN
    UPDATE attic.store SET content = v_xml WHERE application = v_app AND username = standard.get_uwnetid();
    GET DIAGNOSTICS _updated = ROW_COUNT;
    IF _updated = 0 THEN
        INSERT INTO attic.store (application, username, content) VALUES (v_app, standard.get_uwnetid(), v_xml);
    END IF;
    RETURN attic.store_xml(v_app);
END;
$_$;

COMMENT ON FUNCTION attic.store_xml_write(varchar, xml) IS 'DR: Sets application store for the current user (2011-10-20)';
