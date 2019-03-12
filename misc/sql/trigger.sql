    CREATE OR REPLACE TRIGGER ${API_SCHEMA}.validate_prediction
    AFTER INSERT ON predictions
    REFERENCING OLD AS o NEW AS n
    FOR EACH ROW
    BEGIN
      UPDATE predictions
      SET correct = (p.date = r.date AND ABS(p.billing - r.billing) <= 10)
    END;
