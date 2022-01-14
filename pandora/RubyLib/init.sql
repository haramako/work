CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    session_key TEXT,
    last_commit INTEGER NOT NULL
);

CREATE TABLE commits (
    user_id INTEGER NOT NULL,
    num INTEGER NOT NULL,
    commit_type INTEGER NOT NULL, -- 0: commit, 1: dump
    mtime TEXT NOT NULL,
    body BLOB NOT NULL,
    PRIMARY KEY (user_id, num)
);
