CREATE OR REPLACE FUNCTION fn_auto_mark_listing_sold()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE listings
    SET status = 'Sold',
        last_sold_date = NEW.date
    WHERE listing_id = NEW.listing_id;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_sync_transaction_sale
AFTER INSERT ON transactions
FOR EACH ROW
EXECUTE FUNCTION fn_auto_mark_listing_sold();


CREATE OR REPLACE FUNCTION fn_prevent_duplicate_active_listings()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.status IN ('For sale', 'For rent', 'Under contract') THEN
        IF EXISTS (
            SELECT 1
            FROM listings
            WHERE property_id = NEW.property_id
              AND status IN ('For sale', 'For rent', 'Under contract')
              AND (TG_OP = 'INSERT' OR listing_id != NEW.listing_id)
        ) THEN
            RAISE EXCEPTION 'Estate % already has an active listing. Close it first.', NEW.property_id;
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_check_active_listings
BEFORE INSERT OR UPDATE ON listings
FOR EACH ROW
EXECUTE FUNCTION fn_prevent_duplicate_active_listings();