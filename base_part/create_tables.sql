DROP TABLE IF EXISTS transactions;
DROP TABLE IF EXISTS price_history;
DROP TABLE IF EXISTS listings;
DROP TABLE IF EXISTS properties;
DROP TABLE IF EXISTS agents;
DROP TABLE IF EXISTS addresses;
DROP TABLE IF EXISTS neighborhoods;

CREATE TABLE neighborhoods (
    neighborhood_id SERIAL PRIMARY KEY,
    zipcode VARCHAR(10) NOT NULL UNIQUE,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(2),
    latitude NUMERIC(10,7) CHECK (latitude BETWEEN -90.0 AND 90.0),
    longitude NUMERIC(10,7) CHECK (longitude BETWEEN -180.0 AND 180.0),
    population INTEGER CHECK (population > 0),
    median_income NUMERIC(12,2) CHECK (median_income > 0),
    crime_index NUMERIC(4,2) CHECK (crime_index >= 0)
);

CREATE TABLE addresses (
    address_id SERIAL PRIMARY KEY,
    neighborhood_id INTEGER NOT NULL,
    street VARCHAR(200) NOT NULL,
    latitude NUMERIC(10,7) CHECK (latitude BETWEEN -90.0 AND 90.0),
    longitude NUMERIC(10,7) CHECK (longitude BETWEEN -180.0 AND 180.0),
    CONSTRAINT fk_address_neighborhood 
        FOREIGN KEY (neighborhood_id) 
        REFERENCES neighborhoods (neighborhood_id) 
        ON DELETE CASCADE
);

CREATE TABLE agents (
    agent_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    license VARCHAR(20) UNIQUE,
    phone VARCHAR(20) CHECK (phone ~ '^[0-9\+\-\(\)\s]+$'),
    email VARCHAR(100) NOT NULL UNIQUE CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

CREATE TABLE properties (
    property_id SERIAL PRIMARY KEY,
    address_id INTEGER NOT NULL,
    home_type VARCHAR(30) NOT NULL CHECK (home_type IN ('Single Family', 'Condo', 'Townhouse', 'Apartment', 'Multi Family', 'Land')),
    bedrooms NUMERIC(3,1) CHECK (bedrooms >= 0),
    bathrooms NUMERIC(3,1) CHECK (bathrooms >= 0),
    living_area_sqft INTEGER CHECK (living_area_sqft > 0),
    lot_area_value NUMERIC(10,2) CHECK (lot_area_value > 0),
    lot_area_unit VARCHAR(10) DEFAULT 'sqft',
    year_built INTEGER CHECK (year_built > 0),
    tax_assessed_value NUMERIC(12,2) CHECK (tax_assessed_value > 0),
    has_pool BOOLEAN DEFAULT FALSE,
    has_garage BOOLEAN DEFAULT FALSE,
    has_basement BOOLEAN DEFAULT FALSE,
    is_non_owner_occupied BOOLEAN,
    is_premier_builder BOOLEAN,
    CONSTRAINT fk_property_address 
        FOREIGN KEY (address_id) 
        REFERENCES addresses (address_id) 
        ON DELETE CASCADE
);

CREATE TABLE listings (
    listing_id SERIAL PRIMARY KEY,
    property_id INTEGER NOT NULL,
    agent_id INTEGER NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('For sale', 'For rent', 'Under contract', 'Rented', 'Sold', 'Off market')),
    price NUMERIC(12,2) NOT NULL CHECK (price > 0),
    zestimate NUMERIC(12,2) CHECK (zestimate > 0),
    rent_zestimate NUMERIC(10,2) CHECK (rent_zestimate > 0),
    days_on_listing INTEGER CHECK (days_on_listing >= 0),
    listing_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_sold_date DATE,
    is_showcase_listing BOOLEAN DEFAULT FALSE,
    CONSTRAINT fk_listing_property 
        FOREIGN KEY (property_id) 
        REFERENCES properties (property_id) 
        ON DELETE CASCADE,
    CONSTRAINT fk_listing_agent 
        FOREIGN KEY (agent_id) 
        REFERENCES agents (agent_id) 
        ON DELETE CASCADE
);

CREATE TABLE price_history (
    history_id SERIAL PRIMARY KEY,
    listing_id INTEGER NOT NULL,
    old_price NUMERIC(12,2) CHECK (old_price > 0),
    new_price NUMERIC(12,2) CHECK (new_price > 0),
    date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_history_listing 
        FOREIGN KEY (listing_id) 
        REFERENCES listings (listing_id) 
        ON DELETE CASCADE
);

CREATE TABLE transactions (
    transaction_id SERIAL PRIMARY KEY,
    listing_id INTEGER NOT NULL UNIQUE,
    buyer_name VARCHAR(100) NOT NULL,
    buyer_email VARCHAR(100) CHECK (buyer_email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    price NUMERIC(12,2) NOT NULL CHECK (price > 0),
    date DATE NOT NULL,
    CONSTRAINT fk_transaction_listing 
        FOREIGN KEY (listing_id) 
        REFERENCES listings (listing_id) 
        ON DELETE CASCADE
);