


DROP TABLE IF EXISTS OLYMPICS_HISTORY;


CREATE TABLE IF NOT EXISTS OLYMPICS_HISTORY (
    id INT,
    name VARCHAR,
    sex VARCHAR,
    age VARCHAR,
    height VARCHAR,
    weight VARCHAR,
    team VARCHAR,
    noc VARCHAR,
    games VARCHAR,
    YEAR INT,
    season VARCHAR,
    city VARCHAR,
    sport VARCHAR,
    event VARCHAR,
    medal VARCHAR
);


DROP TABLE IF EXISTS OLYMPICS_HISTORY_NOC_REGIONS;


CREATE TABLE IF NOT EXISTS OLYMPICS_HISTORY_NOC_REGIONS (noc VARCHAR, region VARCHAR, notes VARCHAR);


SELECT
    *
FROM
    OLYMPICS_HISTORY;


SELECT
    *
FROM
    OLYMPICS_HISTORY_NOC_REGIONS;


SELECT
    COUNT(*)
FROM
    OLYMPICS_HISTORY;


SELECT
    COUNT(*)
FROM
    OLYMPICS_HISTORY_NOC_REGIONS;


-------------------------------------------------- Questions --------------------------------------------------


-- (1) How many Olympic Games have been held?

SELECT
    COUNT(DISTINCT games) AS total_olympic_games
FROM
    olympics_history;


-- (2) List all Olympic Games held so far.

SELECT
    DISTINCT oh.year,
    oh.season,
    oh.city
FROM
    olympics_history oh
ORDER BY
    YEAR;


-- (3) Mention the total number of nations that participated in each Olympic Games."

WITH all_countries AS (
    SELECT
        games,
        nr.region
    FROM
        olympics_history oh
        JOIN olympics_history_noc_regions nr ON nr.noc = oh.noc
    GROUP BY
        games,
        nr.region
)
SELECT
    games,
    COUNT(1) AS total_countries
FROM
    all_countries
GROUP BY
    games
ORDER BY
    games;
	

-- (4) Which year saw the highest and lowest number of countries participating in the Olympics?

WITH all_countries AS (
    SELECT
        games,
        nr.region
    FROM
        olympics_history oh
        JOIN olympics_history_noc_regions nr ON nr.noc = oh.noc
    GROUP BY
        games,
        nr.region
),
tot_countries AS (
    SELECT
        games,
        COUNT(1) AS total_countries
    FROM
        all_countries
    GROUP BY
        games
)
SELECT
    DISTINCT concat(
        first_value(games) OVER(
            ORDER BY
                total_countries
        ),
        ' - ',
        first_value(total_countries) OVER(
            ORDER BY
                total_countries
        )
    ) AS Lowest_Countries,
    concat(
        first_value(games) OVER(
            ORDER BY
                total_countries desc
        ),
        ' - ',
        first_value(total_countries) OVER(
            ORDER BY
                total_countries desc
        )
    ) AS Highest_Countries
FROM
    tot_countries
ORDER BY
    1;

	  
-- (5) Which nation has participated in all of the Olympic Games?
     
WITH tot_games AS (
    SELECT
        COUNT(DISTINCT games) AS total_games
    FROM
        olympics_history
),
countries AS (
    SELECT
        games,
        nr.region AS country
    FROM
        olympics_history oh
        JOIN olympics_history_noc_regions nr ON nr.noc = oh.noc
    GROUP BY
        games,
        nr.region
),
countries_participated AS (
    SELECT
        country,
        COUNT(1) AS total_participated_games
    FROM
        countries
    GROUP BY
        country
)
SELECT
    cp.*
FROM
    countries_participated cp
    JOIN tot_games tg ON tg.total_games = cp.total_participated_games
ORDER BY
    1;
	  
	  
-- (6) Identify the sport that has been played in all Summer Olympics.
    
WITH t1 AS (
    SELECT
        COUNT(DISTINCT games) AS total_games
    FROM
        olympics_history
    WHERE
        season = 'Summer'
),
t2 AS (
    SELECT
        DISTINCT games,
        sport
    FROM
        olympics_history
    WHERE
        season = 'Summer'
),
t3 AS (
    SELECT
        sport,
        COUNT(1) AS no_of_games
    FROM
        t2
    GROUP BY
        sport
)
SELECT
    *
FROM
    t3
    JOIN t1 ON t1.total_games = t3.no_of_games;
	  
	  
-- (7) Which sports were played only once in the Olympics?
     
WITH t1 AS (
    SELECT
        DISTINCT games,
        sport
    FROM
        olympics_history
),
t2 AS (
    SELECT
        sport,
        COUNT(1) AS no_of_games
    FROM
        t1
    GROUP BY
        sport
)
SELECT
    t2.*,
    t1.games
FROM
    t2
    JOIN t1 ON t1.sport = t2.sport
WHERE
    t2.no_of_games = 1
ORDER BY
    t1.sport;
	  
	  
-- (8) Fetch the total number of sports played in each Olympic Games.
     
WITH t1 AS (
    SELECT
        DISTINCT games,
        sport
    FROM
        olympics_history
),
t2 AS (
    SELECT
        games,
        COUNT(1) AS no_of_sports
    FROM
        t1
    GROUP BY
        games
)
SELECT
    *
FROM
    t2
ORDER BY
    no_of_sports desc;
	  
	  
-- (9) Fetch the oldest athletes to win a gold medal.
   
WITH temp AS (
    SELECT
        name,
        sex,
        CAST(
            CASE
                WHEN age = 'NA' THEN '0'
                ELSE age
            END AS INT
        ) AS age,
        team,
        games,
        city,
        sport,
        event,
        medal
    FROM
        olympics_history
),
ranking AS (
    SELECT
        *,
        RANK() OVER(
            ORDER BY
                age desc
        ) AS rnk
    FROM
        temp
    WHERE
        medal = 'Gold'
)
SELECT
    *
FROM
    ranking
WHERE
    rnk = 1;
	
	
-- (10) Find the ratio of male to female athletes who participated in all Olympic Games.
   
WITH t1 AS (
    SELECT
        sex,
        COUNT(1) AS cnt
    FROM
        olympics_history
    GROUP BY
        sex
),
t2 AS (
    SELECT
        *,
        ROW_NUMBER() OVER(
            ORDER BY
                cnt
        ) AS rn
    FROM
        t1
),
min_cnt AS (
    SELECT
        cnt
    FROM
        t2
    WHERE
        rn = 1
),
max_cnt AS (
    SELECT
        cnt
    FROM
        t2
    WHERE
        rn = 2
)
SELECT
    concat('1 : ', round(max_cnt.cnt:: DECIMAL / min_cnt.cnt, 2)) AS ratio
FROM
    min_cnt,
    max_cnt;

	
-- (11) List the top 5 athletes who have won the most gold medals.
   
WITH t1 AS (
    SELECT
        name,
        team,
        COUNT(1) AS total_gold_medals
    FROM
        olympics_history
    WHERE
        medal = 'Gold'
    GROUP BY
        name,
        team
    ORDER BY
        total_gold_medals desc
),
t2 AS (
    SELECT
        *,
        DENSE_RANK() OVER (
            ORDER BY
                total_gold_medals desc
        ) AS rnk
    FROM
        t1
)
SELECT
    name,
    team,
    total_gold_medals
FROM
    t2
WHERE
    rnk <= 5;
	
	
-- (12) List the top 5 athletes who have won the most medals (gold/silver/bronze).
   
WITH t1 AS (
    SELECT
        name,
        team,
        COUNT(1) AS total_medals
    FROM
        olympics_history
    WHERE
        medal IN ('Gold', 'Silver', 'Bronze')
    GROUP BY
        name,
        team
    ORDER BY
        total_medals desc
),
t2 AS (
    SELECT
        *,
        DENSE_RANK() OVER (
            ORDER BY
                total_medals desc
        ) AS rnk
    FROM
        t1
)
SELECT
    name,
    team,
    total_medals
FROM
    t2
WHERE
    rnk <= 5;
	
	
-- (13) List the top 5 most successful countries in the Olympics, where success is defined by the number of medals won.
   
WITH t1 AS (
    SELECT
        nr.region,
        COUNT(1) AS total_medals
    FROM
        olympics_history oh
        JOIN olympics_history_noc_regions nr ON nr.noc = oh.noc
    WHERE
        medal <> 'NA'
    GROUP BY
        nr.region
    ORDER BY
        total_medals desc
),
t2 AS (
    SELECT
        *,
        DENSE_RANK() OVER(
            ORDER BY
                total_medals desc
        ) AS rnk
    FROM
        t1
)
SELECT
    *
FROM
    t2
WHERE
    rnk <= 5;
	

-- PIVOT
-- In Postgresql, we can use crosstab function to create pivot table.
-- crosstab function is part of a PostgreSQL extension called tablefunc.
-- To call the crosstab function, you must first enable the tablefunc extension by executing the following SQL command:

CREATE EXTENSION TABLEFUNC;

-- (14) List the total number of gold, silver, and bronze medals won by each country.

SELECT
    country,
    COALESCE(gold, 0) AS gold,
    COALESCE(silver, 0) AS silver,
    COALESCE(bronze, 0) AS bronze
FROM
    CROSSTAB(
        'SELECT nr.region as country
    			, medal
    			, count(1) as total_medals
    			FROM olympics_history oh
    			JOIN olympics_history_noc_regions nr ON nr.noc = oh.noc
    			where medal <> ''NA''
    			GROUP BY nr.region,medal
    			order BY nr.region,medal',
        'values (''Bronze''), (''Gold''), (''Silver'')'
    ) AS FINAL_RESULT(
        country VARCHAR,
        bronze BIGINT,
        gold BIGINT,
        silver BIGINT
    )
ORDER BY
    gold desc,
    silver desc,
    bronze desc;

		
-- PIVOT
-- In Postgresql, we can use crosstab function to create pivot table.
-- crosstab function is part of a PostgreSQL extension called tablefunc.
-- To call the crosstab function, you must first enable the tablefunc extension by executing the following SQL command:

CREATE EXTENSION TABLEFUNC;

-- (15) List the total number of gold, silver, and bronze medals won by each country corresponding to each Olympic Games.

SELECT
    SUBSTRING(games, 1, POSITION(' - ' IN games) - 1) AS games,
    SUBSTRING(games, POSITION(' - ' IN games) + 3) AS country,
    COALESCE(gold, 0) AS gold,
    COALESCE(silver, 0) AS silver,
    COALESCE(bronze, 0) AS bronze
FROM
    CROSSTAB(
        'SELECT concat(games, '' - '', nr.region) as games
                , medal
                , count(1) as total_medals
                FROM olympics_history oh
                JOIN olympics_history_noc_regions nr ON nr.noc = oh.noc
                where medal <> ''NA''
                GROUP BY games,nr.region,medal
                order BY games,medal',
        'values (''Bronze''), (''Gold''), (''Silver'')'
    ) AS FINAL_RESULT(games text, bronze BIGINT, gold BIGINT, silver BIGINT);
	
	
-- PIVOT
-- In Postgresql, we can use crosstab function to create pivot table.
-- crosstab function is part of a PostgreSQL extension called tablefunc.
-- To call the crosstab function, you must first enable the tablefunc extension by executing the following SQL command:

CREATE EXTENSION TABLEFUNC;

-- (16) Identify the country that won the most gold, most silver, and most bronze medals in each Olympic Games.

WITH temp AS (
    SELECT
        SUBSTRING(games, 1, POSITION(' - ' IN games) - 1) AS games,
        SUBSTRING(games, POSITION(' - ' IN games) + 3) AS country,
        COALESCE(gold, 0) AS gold,
        COALESCE(silver, 0) AS silver,
        COALESCE(bronze, 0) AS bronze
    FROM
        CROSSTAB(
            'SELECT concat(games, '' - '', nr.region) as games
    					, medal
    				  	, count(1) as total_medals
    				  FROM olympics_history oh
    				  JOIN olympics_history_noc_regions nr ON nr.noc = oh.noc
    				  where medal <> ''NA''
    				  GROUP BY games,nr.region,medal
    				  order BY games,medal',
            'values (''Bronze''), (''Gold''), (''Silver'')'
        ) AS FINAL_RESULT(games text, bronze BIGINT, gold BIGINT, silver BIGINT)
)
SELECT
    DISTINCT games,
    concat(
        first_value(country) OVER(
            PARTITION BY games
            ORDER BY
                gold desc
        ),
        ' - ',
        first_value(gold) OVER(
            PARTITION BY games
            ORDER BY
                gold desc
        )
    ) AS Max_Gold,
    concat(
        first_value(country) OVER(
            PARTITION BY games
            ORDER BY
                silver desc
        ),
        ' - ',
        first_value(silver) OVER(
            PARTITION BY games
            ORDER BY
                silver desc
        )
    ) AS Max_Silver,
    concat(
        first_value(country) OVER(
            PARTITION BY games
            ORDER BY
                bronze desc
        ),
        ' - ',
        first_value(bronze) OVER(
            PARTITION BY games
            ORDER BY
                bronze desc
        )
    ) AS Max_Bronze
FROM
    temp
ORDER BY
    games;
	
	
-- PIVOT
-- In Postgresql, we can use crosstab function to create pivot table.
-- crosstab function is part of a PostgreSQL extension called tablefunc.
-- To call the crosstab function, you must first enable the tablefunc extension by executing the following SQL command:

CREATE EXTENSION TABLEFUNC;

-- (17) Identify the country that won the most gold, silver, bronze medals, and the most overall medals in each Olympic Games.

WITH temp AS (
    SELECT
        SUBSTRING(games, 1, POSITION(' - ' IN games) - 1) AS games,
        SUBSTRING(games, POSITION(' - ' IN games) + 3) AS country,
        COALESCE(gold, 0) AS gold,
        COALESCE(silver, 0) AS silver,
        COALESCE(bronze, 0) AS bronze
    FROM
        CROSSTAB(
            'SELECT concat(games, '' - '', nr.region) as games
    					, medal
    					, count(1) as total_medals
    				  FROM olympics_history oh
    				  JOIN olympics_history_noc_regions nr ON nr.noc = oh.noc
    				  where medal <> ''NA''
    				  GROUP BY games,nr.region,medal
    				  order BY games,medal',
            'values (''Bronze''), (''Gold''), (''Silver'')'
        ) AS FINAL_RESULT(games text, bronze BIGINT, gold BIGINT, silver BIGINT)
),
tot_medals AS (
    SELECT
        games,
        nr.region AS country,
        COUNT(1) AS total_medals
    FROM
        olympics_history oh
        JOIN olympics_history_noc_regions nr ON nr.noc = oh.noc
    WHERE
        medal <> 'NA'
    GROUP BY
        games,
        nr.region
    ORDER BY
        1,
        2
)
SELECT
    DISTINCT t.games,
    concat(
        first_value(t.country) OVER(
            PARTITION BY t.games
            ORDER BY
                gold desc
        ),
        ' - ',
        first_value(t.gold) OVER(
            PARTITION BY t.games
            ORDER BY
                gold desc
        )
    ) AS Max_Gold,
    concat(
        first_value(t.country) OVER(
            PARTITION BY t.games
            ORDER BY
                silver desc
        ),
        ' - ',
        first_value(t.silver) OVER(
            PARTITION BY t.games
            ORDER BY
                silver desc
        )
    ) AS Max_Silver,
    concat(
        first_value(t.country) OVER(
            PARTITION BY t.games
            ORDER BY
                bronze desc
        ),
        ' - ',
        first_value(t.bronze) OVER(
            PARTITION BY t.games
            ORDER BY
                bronze desc
        )
    ) AS Max_Bronze,
    concat(
        first_value(tm.country) OVER (
            PARTITION BY tm.games
            ORDER BY
                total_medals desc nulls last
        ),
        ' - ',
        first_value(tm.total_medals) OVER(
            PARTITION BY tm.games
            ORDER BY
                total_medals desc nulls last
        )
    ) AS Max_Medals
FROM
    temp t
    JOIN tot_medals tm ON tm.games = t.games
    AND tm.country = t.country
ORDER BY
    games;


-- PIVOT
-- In Postgresql, we can use crosstab function to create pivot table.
-- crosstab function is part of a PostgreSQL extension called tablefunc.
-- To call the crosstab function, you must first enable the tablefunc extension by executing the following SQL command:

CREATE EXTENSION TABLEFUNC;

-- (18) Which countries have won silver or bronze medals but have never won a gold medal?
    
SELECT
    *
FROM
    (
        SELECT
            country,
            COALESCE(gold, 0) AS gold,
            COALESCE(silver, 0) AS silver,
            COALESCE(bronze, 0) AS bronze
        FROM
            CROSSTAB(
                'SELECT nr.region as country
    					, medal, count(1) as total_medals
    					FROM OLYMPICS_HISTORY oh
    					JOIN OLYMPICS_HISTORY_NOC_REGIONS nr ON nr.noc=oh.noc
    					where medal <> ''NA''
    					GROUP BY nr.region,medal order BY nr.region,medal',
                'values (''Bronze''), (''Gold''), (''Silver'')'
            ) AS FINAL_RESULT(
                country VARCHAR,
                bronze BIGINT,
                gold BIGINT,
                silver BIGINT
            )
    ) x
WHERE
    gold = 0
    AND (
        silver > 0
        OR bronze > 0
    )
ORDER BY
    gold desc nulls last,
    silver desc nulls last,
    bronze desc nulls last;


-- (19) In which sport or event has India won the highest number of medals?
   
WITH t1 AS (
    SELECT
        sport,
        COUNT(1) AS total_medals
    FROM
        olympics_history
    WHERE
        medal <> 'NA'
        AND team = 'India'
    GROUP BY
        sport
    ORDER BY
        total_medals desc
),
t2 AS (
    SELECT
        *,
        RANK() OVER(
            ORDER BY
                total_medals desc
        ) AS rnk
    FROM
        t1
)
SELECT
    sport,
    total_medals
FROM
    t2
WHERE
    rnk = 1;


-- (20) Break down all Olympic Games where India won medals for hockey and specify how many medals were won in each Olympic Games.
   
SELECT
    team,
    sport,
    games,
    COUNT(1) AS total_medals
FROM
    olympics_history
WHERE
    medal <> 'NA'
    AND team = 'India'
    AND sport = 'Hockey'
GROUP BY
    team,
    sport,
    games
ORDER BY
    total_medals desc;


