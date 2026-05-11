-- DROP VIEW IF EXISTS v_sale_catalog;
-- DROP MATERIALIZED VIEW IF EXISTS mv_neighborhood_sale_stats;


CREATE VIEW v_sale_catalog AS
SELECT 
    l.listing_id,
    l.price,
    p.home_type,
    p.bedrooms,
    p.bathrooms,
    p.living_area_sqft,
    a.street,
    n.city,
    n.zipcode,
    ag.name AS agent_name,
    ag.phone AS agent_phone,
    l.days_on_listing
FROM listings l
JOIN properties p USING(property_id)
JOIN addresses a USING(address_id)
JOIN neighborhoods n USING(neighborhood_id)
JOIN agents ag USING(agent_id)
WHERE l.status = 'For sale';


CREATE MATERIALIZED VIEW mv_neighborhood_sale_stats AS
SELECT 
    n.neighborhood_id,
    n.city,
    n.zipcode,
    COUNT(l.listing_id) AS total_active_listings,
    ROUND(AVG(l.price), 2) AS avg_listing_price,
    ROUND(AVG(l.price / NULLIF(p.living_area_sqft, 0)), 2) AS avg_price_per_sqft,
    ROUND(AVG(l.days_on_listing), 0) AS avg_days_on_market
FROM neighborhoods n
JOIN addresses a USING(neighborhood_id)
JOIN properties p USING(address_id)
JOIN listings l USING(property_id)
WHERE l.status ='For sale'
GROUP BY n.neighborhood_id, n.city, n.zipcode;