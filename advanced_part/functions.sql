CREATE OR REPLACE PROCEDURE pr_update_listing_price(
    p_listing_id INTEGER,
    p_new_price NUMERIC
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_old_price NUMERIC;
BEGIN
    SELECT price INTO v_old_price
    FROM listings
    WHERE listing_id = p_listing_id;

    IF v_old_price IS NULL THEN
        RAISE EXCEPTION 'Listing % not found', p_listing_id;
    END IF;

    IF v_old_price = p_new_price THEN
        RAISE NOTICE 'New price matches the old price. Update not required.';
        RETURN;
    END IF;

    UPDATE listings
    SET price = p_new_price
    WHERE listing_id = p_listing_id;

    INSERT INTO price_history (listing_id, old_price, new_price)
    VALUES (p_listing_id, v_old_price, p_new_price);
END;
$$;

-- for example, to update the price of listing with ID 7:
-- CALL pr_update_listing_price(7, 350000.00)


CREATE OR REPLACE PROCEDURE pr_close_sale(
    p_listing_id INTEGER,
    p_buyer_name VARCHAR,
    p_buyer_email VARCHAR,
    p_final_price NUMERIC
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_status VARCHAR;
BEGIN
    SELECT status INTO v_status
    FROM listings
    WHERE listing_id = p_listing_id;

    IF v_status IS NULL THEN
        RAISE EXCEPTION 'Listing % not found', p_listing_id;
    END IF;

    IF v_status != 'For sale' THEN
        RAISE EXCEPTION 'Deal not possible! Current listing status: %', v_status;
    END IF;

    UPDATE listings
    SET status = 'Sold',
        last_sold_date = CURRENT_DATE
    WHERE listing_id = p_listing_id;

    INSERT INTO transactions (listing_id, buyer_name, buyer_email, price, date)
    VALUES (p_listing_id, p_buyer_name, p_buyer_email, p_final_price, CURRENT_DATE);

    RAISE NOTICE 'Deal for listing % successfully closed!', p_listing_id;
END;
$$;

-- for example, to close a sale for listing with ID 9:
-- CALL pr_close_sale(9, 'Test User', 'test-user@email.com', 300000.00);


CREATE OR REPLACE FUNCTION fn_get_comparables(
    p_target_listing_id INTEGER
)
RETURNS TABLE (
    comp_listing_id INTEGER,
    street VARCHAR(200),
    price NUMERIC(12,2),
    bedrooms NUMERIC(3,1),
    living_area_sqft INTEGER,
    price_difference NUMERIC(12,2)
)
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_city VARCHAR(100);
    v_home_type VARCHAR(30);
    v_bedrooms NUMERIC;
    v_price NUMERIC;
    v_status VARCHAR(20);
BEGIN
    SELECT n.city, p.home_type, p.bedrooms, l.price, l.status
    INTO v_city, v_home_type, v_bedrooms, v_price, v_status
    FROM listings l
    JOIN properties p USING (property_id)
    JOIN addresses a USING (address_id)
    JOIN neighborhoods n USING (neighborhood_id)
    WHERE l.listing_id = p_target_listing_id;

    IF v_city IS NULL THEN
        RAISE EXCEPTION 'Listing % not found', p_target_listing_id;
    END IF;

    RETURN QUERY
    SELECT 
        l.listing_id, 
        n.city, 
        l.price, 
        p.bedrooms,
        p.living_area_sqft,
        (l.price - v_price) AS price_difference
    FROM listings l
    JOIN properties p USING (property_id)
    JOIN addresses a USING (address_id)
    JOIN neighborhoods n USING (neighborhood_id)
    WHERE l.listing_id != p_target_listing_id
        AND n.city = v_city
        AND p.home_type = v_home_type
        AND l.status = v_status
        AND p.bedrooms BETWEEN (v_bedrooms - 1) AND (v_bedrooms + 1)
    ORDER BY ABS(l.price - v_price) ASC
    LIMIT 5;
END;
$$;

-- for example, to get comparables for listing with ID 43:
-- SELECT * FROM fn_get_comparables(43);