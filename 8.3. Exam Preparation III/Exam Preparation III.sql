-- 1. 1. Database Design

DROP TABLE IF EXISTS categories CASCADE;

CREATE TABLE categories (
	id SERIAL PRIMARY KEY,
	name VARCHAR(50) NOT NULL
);

DROP TABLE IF EXISTS addresses CASCADE;

CREATE TABLE addresses (
	id SERIAL PRIMARY KEY,
	street_name VARCHAR(100) NOT NULL,
	street_number INT NOT NULL,
	town VARCHAR(30) NOT NULL,
	country VARCHAR(50) NOT NULL,
	zip_code INT NOT NULL,
	CONSTRAINT
		ck_street_number
	CHECK
		(street_number > 0),
	CONSTRAINT
		ck_zip_code
	CHECK
		(zip_code > 0)
);

DROP TABLE IF EXISTS publishers CASCADE;

CREATE TABLE publishers (
	id SERIAL PRIMARY KEY,
	name VARCHAR(30) NOT NULL,
	address_id INT NOT NULL,
	website VARCHAR(40),
	phone VARCHAR(20),
	CONSTRAINT
		fk_publishers_addresses
	FOREIGN KEY
		(address_id)
	REFERENCES
		addresses(id)
	ON UPDATE CASCADE
	ON DELETE CASCADE
);

DROP TABLE IF EXISTS players_ranges CASCADE;

CREATE TABLE players_ranges (
	id SERIAL PRIMARY KEY,
	min_players INT NOT NULL,
	max_players INT NOT NULL,
	CONSTRAINT
		ck_min_players
	CHECK 
		(min_players > 0),
	CONSTRAINT
		ck_max_players
	CHECK
		(max_players > 0)
);

DROP TABLE IF EXISTS creators CASCADE;

CREATE TABLE creators (
	id SERIAL PRIMARY KEY,
	first_name VARCHAR(30) NOT NULL,
	last_name VARCHAR(30) NOT NULL,
	email VARCHAR(30) NOT NULL
);

DROP TABLE IF EXISTS board_games CASCADE;

CREATE TABLE board_games (
	id SERIAL PRIMARY KEY,
	name VARCHAR(30) NOT NULL,
	release_year INT NOT NULL,
	rating NUMERIC(10, 2) NOT NULL,
	category_id INT NOT NULL,
	publisher_id INT NOT NULL,
	players_range_id INT NOT NULL,
	CONSTRAINT
		ck_release_year
	CHECK
		(release_year > 0),
	CONSTRAINT
		fk_board_games_categories
	FOREIGN KEY
		(category_id)
	REFERENCES
		categories(id)
	ON UPDATE CASCADE
	ON DELETE CASCADE,
	CONSTRAINT
		fk_board_games_publishers
	FOREIGN KEY
		(publisher_id)
	REFERENCES
		publishers(id)
	ON UPDATE CASCADE
	ON DELETE CASCADE,
	CONSTRAINT
		fk_board_games_players_ranges
	FOREIGN KEY
		(players_range_id)
	REFERENCES
		players_ranges(id)
	ON UPDATE CASCADE
	ON DELETE CASCADE
);

DROP TABLE IF EXISTS creators_board_games CASCADE;

CREATE TABLE creators_board_games (
	creator_id INT NOT NULL,
	board_game_id INT NOT NULL,
	CONSTRAINT
		fk_creators_board_games_creators
	FOREIGN KEY
		(creator_id)
	REFERENCES
		creators(id)
	ON UPDATE CASCADE
	ON DELETE CASCADE,
	CONSTRAINT
		fk_creators_board_games_board_games
	FOREIGN KEY
		(board_game_id)
	REFERENCES
		board_games(id)
	ON UPDATE CASCADE
	ON DELETE CASCADE
);

-- 2.2. Insert

INSERT INTO
	board_games(name, release_year, rating, category_id, publisher_id, players_range_id)
VALUES
	('Deep Blue', 2019,	5.67, 1, 15, 7),
	('Paris', 2016, 9.78, 7, 1, 5),
	('Catan: Starfarers', 2021, 9.87, 7, 13, 6),
	('Bleeding Kansas',	2020, 3.25,	3, 7, 4),
	('One Small Step', 2019, 5.75, 5, 9, 2);
	
INSERT INTO
	publishers(name, address_id, website, phone)
VALUES
	('Agman Games',	5, 'www.agmangames.com', '+16546135542'),
	('Amethyst Games',	7,	'www.amethystgames.com', '+15558889992'),
	('BattleBooks',	13,	'www.battlebooks.com', '+12345678907');

-- 2. 3. Update

UPDATE
	players_ranges
SET
	max_players = max_players + 1
WHERE
	min_players = 2
		AND
	max_players = 2;
	
UPDATE
	board_games
SET
	name = name || ' V2'
WHERE
	release_year >= 2020;

-- 2.4. Delete

DELETE 
FROM
	board_games
WHERE
	publisher_id IN (SELECT id FROM publishers WHERE address_id IN (SELECT id FROM addresses WHERE town LIKE 

'L%'));
	
DELETE
FROM
	publishers
WHERE
	address_id IN (SELECT id FROM addresses WHERE town LIKE 'L%');

DELETE
FROM
	addresses
WHERE
	town LIKE 'L%';

-- 3.5. Board Games by Release Year

SELECT
	name,
	rating
FROM
	board_games
ORDER BY
	release_year ASC,
	name DESC;

-- 3.6. Board Games by Category

SELECT
	bg.id,
	bg.name,
	release_year,
	c.name
FROM
	board_games AS bg
JOIN
	categories AS c
ON
	bg.category_id = c.id
WHERE
	c.name IN ('Strategy Games', 'Wargames')
ORDER BY
	release_year DESC;

-- 3.7. Creators without Board Games

SELECT
	c.id,
	CONCAT_WS(' ', c.first_name, c.last_name) AS creator_name,
	c.email
FROM
	creators AS c
LEFT JOIN
	creators_board_games AS cbg
ON
	c.id = cbg.creator_id
WHERE
	cbg.creator_id IS NULL
ORDER BY
	creator_name ASC;

-- 3.8. First 5 Board Games

SELECT
	bg.name,
	bg.rating,
	c.name AS category_name
FROM
	board_games AS bg
JOIN
	categories AS c
ON
	bg.category_id = c.id
JOIN
	players_ranges AS pr
ON
	bg.players_range_id = pr.id
WHERE
	(bg.rating > 7.00 AND bg.name ILIKE '%a%')
		OR
	(bg.rating > 7.50 AND pr.min_players >= 2 AND pr.max_players <= 5)
ORDER BY
	bg.name ASC,
	bg.rating DESC
LIMIT 
	5;

-- 3.9. Creators with Emails

SELECT
    CONCAT_WS(' ', c.first_name, c.last_name) AS full_name,
    c.email,
    MAX(bg.rating) AS rating
FROM
    creators c
JOIN
    creators_board_games AS cbg 
ON 
	c.id = cbg.creator_id
JOIN
    board_games AS bg 
ON 
	cbg.board_game_id = bg.id
WHERE
    c.email LIKE '%.com'
GROUP BY
	c.first_name,
	c.last_name,
	c.email
ORDER BY
    full_name ASC;

-- 3.10. Creators by Rating

SELECT
	c.last_name,
	CEIL(AVG(bg.rating)) AS average_rating,
	p.name AS publisher_name
FROM
	creators AS c
JOIN
	creators_board_games AS cbg
ON
	c.id = cbg.creator_id
JOIN
	board_games AS bg
ON
	cbg.board_game_id = bg.id
JOIN
	publishers AS p
ON
	bg.publisher_id = p.id
WHERE
	p.name = 'Stonemaier Games'
GROUP BY
	c.last_name, p.name
ORDER BY
	average_rating DESC;

-- 4.11. Creator of Board Games

CREATE OR REPLACE FUNCTION
	fn_creator_with_board_games(first_name_arg VARCHAR(30))
RETURNS INT AS
$$
	BEGIN
	RETURN
	COUNT(cbg.creator_id) 
FROM
	creators AS c
JOIN
	creators_board_games AS cbg
ON
	c.id = cbg.creator_id
WHERE
	c.first_name = first_name_arg;
	END;
$$
LANGUAGE plpgsql;

-- 4.12. Search for Board Games

CREATE TABLE search_results (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50),
    release_year INT,
    rating FLOAT,
    category_name VARCHAR(50),
    publisher_name VARCHAR(50),
    min_players VARCHAR(50),
    max_players VARCHAR(50)
);

CREATE OR REPLACE PROCEDURE
	usp_search_by_category(
	IN category VARCHAR(50))
AS
$$
	BEGIN
		TRUNCATE TABLE search_results;
		
		INSERT INTO search_results (
			"name",
			release_year,
			rating,
			category_name,
			publisher_name,
			min_players,
			max_players)
		SELECT
			bg.name,
			bg.release_year,
			bg.rating,
			cat.name AS category_name,
			pb.name AS publisher_name,
			pr.min_players || ' people',
			pr.max_players || ' people'
		FROM
			board_games AS bg
		JOIN
			categories AS cat
		ON
			bg.category_id = cat.id
		JOIN
			publishers AS pb
		ON
			bg.publisher_id = pb.id
		JOIN
			players_ranges AS pr
		ON
			bg.players_range_id = pr.id
		WHERE
			cat.name = category
		ORDER BY
			pb.name ASC,
			bg.release_year DESC;
	END;
$$
LANGUAGE plpgsql;

CALL usp_search_by_category('Wargames')

SELECT
	*
FROM
	search_results;
