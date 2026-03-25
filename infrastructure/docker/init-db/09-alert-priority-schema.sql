-- Alert Priority System Schema
-- 3 levels: FLASH (urgent), PRIORITY (important), ROUTINE (batched digest)

CREATE TABLE IF NOT EXISTS alert_log (
    id SERIAL PRIMARY KEY,
    level VARCHAR(10) NOT NULL CHECK (level IN ('FLASH', 'PRIORITY', 'ROUTINE')),
    source VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT,
    acknowledged BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    acknowledged_at TIMESTAMP
);

-- Index for querying unacknowledged FLASH alerts (repeat mechanism)
CREATE INDEX IF NOT EXISTS idx_alert_flash_unack
    ON alert_log (level, acknowledged)
    WHERE level = 'FLASH' AND acknowledged = false;

-- Index for collecting ROUTINE alerts for digest
CREATE INDEX IF NOT EXISTS idx_alert_routine_pending
    ON alert_log (level, created_at)
    WHERE level = 'ROUTINE';

-- Index for querying alerts by source
CREATE INDEX IF NOT EXISTS idx_alert_source
    ON alert_log (source, created_at DESC);

-- Index for general time-based queries
CREATE INDEX IF NOT EXISTS idx_alert_created_at
    ON alert_log (created_at DESC);
