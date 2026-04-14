-- The objects have been on sale for more than 90 days and with a price above the estimate
SELECT p.home_type, n.city, a.street, l.days_on_listing, l.price, l.zestimate
FROM listings l
JOIN properties p  USING (property_id)
JOIN addresses a   USING (address_id)
JOIN neighborhoods n USING (neighborhood_id)
WHERE l.status = 'For sale'
  AND l.days_on_listing > 90
  AND l.price > l.zestimate;

-- Agents who have more than 1 active sale listings
SELECT a.name, COUNT(*) AS active_listings
FROM agents a
JOIN listings l USING (agent_id)
WHERE l.status = 'For sale'
GROUP BY a.agent_id, a.name
HAVING COUNT(*) > 1;

-- The average selling price for each type of housing
SELECT p.home_type, ROUND(AVG(l.price), 2) AS average_price
FROM listings l
JOIN properties p USING (property_id)
WHERE l.status = 'For sale'
GROUP BY p.home_type;

-- Number of properties by number of bedrooms and pool availability
SELECT bedrooms, has_pool, COUNT(*) as property_count
FROM properties
GROUP BY bedrooms, has_pool
ORDER BY bedrooms, has_pool DESC;

-- Percentage of properties with a swimming pool and garage for each type of housing
SELECT home_type,
    COUNT(*) AS total_count,
    ROUND(AVG(living_area_sqft), 0) AS avg_sqft,
    ROUND(AVG(has_pool::int) * 100, 2) AS with_pool,
    ROUND(AVG(has_garage::int) * 100, 2) AS with_garage
FROM properties
GROUP BY home_type;

-- Average percentage drop in price in each district
SELECT p.home_type, 
    ROUND(AVG((ph.old_price - ph.new_price) / ph.old_price * 100), 2) AS avg_drop_percent
FROM price_history ph
JOIN listings l USING (listing_id)
JOIN properties p USING (property_id)
WHERE ph.new_price < ph.old_price
GROUP BY p.home_type;

-- Listings with a price change above the average percentage change for all listings
WITH latest_changes AS (
    SELECT DISTINCT ON (listing_id)
        listing_id,
        old_price,
        new_price,
        (100.0 * (new_price - old_price) / old_price) as change_percent
    FROM price_history
    ORDER BY listing_id, date DESC
)
SELECT *
FROM latest_changes
WHERE change_percent > (
    SELECT AVG(change_percent)
    FROM latest_changes
);

-- Average age of buildings in each district
SELECT n.zipcode, ROUND(AVG(extract(year FROM CURRENT_DATE) - p.year_built), 0) AS avg_building_age
FROM neighborhoods n
JOIN addresses a USING (neighborhood_id)
JOIN properties p USING (address_id)
GROUP BY n.zipcode;

-- The total tax base for each city
SELECT n.city, SUM(p.tax_assessed_value) AS total_tax_base
FROM neighborhoods n
JOIN addresses a USING (neighborhood_id)
JOIN properties p USING (address_id)
GROUP BY n.city
ORDER BY total_tax_base DESC;

-- The largest land area in each city
SELECT DISTINCT ON (n.city) 
    n.city, a.street, p.lot_area_value, p.lot_area_unit
FROM properties p
JOIN addresses a USING (address_id)
JOIN neighborhoods n USING (neighborhood_id)
ORDER BY n.city, p.lot_area_value DESC;

-- The minimum rental price for each type of housing and the corresponding address
SELECT DISTINCT ON (p.home_type)
    p.home_type,
    l.price AS min_price,
    n.city,
    a.street
FROM properties p
JOIN addresses a USING (address_id)
JOIN neighborhoods n USING (neighborhood_id)
JOIN listings l USING (property_id)
WHERE l.status = 'For rent'
ORDER BY p.home_type, l.price ASC;