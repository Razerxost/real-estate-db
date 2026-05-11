-- DROP INDEX IF EXISTS 
--     idx_listings_active_sales, 
--     idx_price_history_latest_change, 
--     idx_listings_property_id;


-- type: btree
--description: Index to optimize queries filtering active listings by days on listing and price
CREATE INDEX idx_listings_active_sales 
ON listings(days_on_listing, price) 
WHERE status = 'For sale';


-- type: btree
-- description: Index to optimize queries filtering price history by listing_id and date
CREATE INDEX idx_price_history_latest_change 
ON price_history(listing_id, date DESC);


-- type: btree
-- description: Index to optimize queries filtering listings by property_id
CREATE INDEX idx_listings_property_id 
ON listings(property_id);