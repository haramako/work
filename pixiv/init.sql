BEGIN;

CREATE TABLE urls (
	url VARCHAR(255) PRIMARY KEY,
	expire_at DATETIME NOT NULL DEFAULT 0,
	status VARCHAR(1) NOT NULL DEFAULT '',
	updated_at TIMESTAMP
);

-- CREATE INDEX urls_status_expire_at ON urls ( status, expire_at );


CREATE TABLE images (
	id INT PRIMARY KEY,
	title VARCHAR(255) NOT NULL,
	author VARCHAR(100) NOT NULL,
	updated_at TIMESTAMP
);

COMMIT;
