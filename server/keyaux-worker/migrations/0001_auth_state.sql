CREATE TABLE IF NOT EXISTS peki_auth_challenges (
    id TEXT PRIMARY KEY,
    nonce TEXT NOT NULL,
    hwid TEXT NOT NULL,
    license_hash TEXT NOT NULL,
    version TEXT NOT NULL,
    expires_at INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS peki_auth_challenges_expiry ON peki_auth_challenges(expires_at);

CREATE TABLE IF NOT EXISTS peki_auth_rate_limits (
    bucket TEXT PRIMARY KEY,
    attempts INTEGER NOT NULL,
    expires_at INTEGER NOT NULL
);
