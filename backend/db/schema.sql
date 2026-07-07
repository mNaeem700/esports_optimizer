-- Run this against a real Postgres instance (TimescaleDB extension optional
-- but recommended for the network_metrics hypertable).

CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TYPE plan_type AS ENUM ('free', 'premium', 'pro');
CREATE TYPE sub_status AS ENUM ('active', 'cancelled', 'expired');

CREATE TABLE IF NOT EXISTS subscriptions (
    id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(id) ON DELETE CASCADE,
    plan_type plan_type DEFAULT 'free',
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    payment_method VARCHAR(50),
    status sub_status DEFAULT 'active'
);

CREATE TYPE health_status AS ENUM ('healthy', 'degraded', 'down');

CREATE TABLE IF NOT EXISTS relay_servers (
    id SERIAL PRIMARY KEY,
    server_name VARCHAR(255),
    region VARCHAR(50),
    country VARCHAR(50),
    latitude FLOAT,
    longitude FLOAT,
    ip_address INET,
    capacity INT,
    current_load INT DEFAULT 0,
    health_status health_status DEFAULT 'healthy',
    last_health_check TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS network_metrics (
    time TIMESTAMPTZ NOT NULL DEFAULT now(),
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_id VARCHAR(255) NOT NULL,
    latency_ms INT,
    jitter_ms INT,
    packet_loss_percent FLOAT,
    selected_relay_id INT REFERENCES relay_servers(id),
    wifi_signal_strength INT,
    cellular_signal_strength INT
);

-- Requires the TimescaleDB extension. Skip if using plain Postgres.
-- SELECT create_hypertable('network_metrics', 'time', if_not_exists => TRUE);
CREATE INDEX IF NOT EXISTS idx_user_metrics ON network_metrics (user_id, time DESC);

CREATE TABLE IF NOT EXISTS vpn_sessions (
    id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(id) ON DELETE CASCADE,
    device_id VARCHAR(255),
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMP,
    relay_used INT REFERENCES relay_servers(id),
    avg_latency INT,
    total_data_transferred BIGINT
);

-- Seed a few relays so the app has something to select from out of the box.
INSERT INTO relay_servers (server_name, region, country, latitude, longitude, ip_address, capacity, current_load)
VALUES
  ('US-East-1', 'us-east', 'US', 39.0, -77.5, '203.0.113.10', 1000, 200),
  ('EU-West-1', 'eu-west', 'IE', 53.3, -6.3, '203.0.113.20', 1000, 150),
  ('APAC-South-1', 'apac-south', 'SG', 1.35, 103.8, '203.0.113.30', 1000, 400),
  ('South-Asia-1', 'south-asia', 'PK', 31.5, 74.3, '203.0.113.40', 500, 50)
ON CONFLICT DO NOTHING;
