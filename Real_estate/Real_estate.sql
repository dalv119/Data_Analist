-- ИССЛЕДОВАНИЕ ДАННЫХ

--1. Временной интервал
	--Подсчитаем, за какой период представлены объявления о продаже недвижимости. 
	--Если понадобится изучить годовую динамику параметров, выбираем только полные годы: 2015, 2016, 2017, 2018.

SELECT MIN(a.first_day_exposition),
	   MAX(a.first_day_exposition)
FROM real_estate.advertisement a
;

--2. Типы населённых пунктов
	--Населённые пункты варьируются по типу — от крупных городов до сёл и небольших деревень. 
	-- Каждый тип населённого пункта обладает своими особенностями рынка недвижимости, 
	-- поэтому перед исследованием данных всегда смотрим, как распределяются объявления по типам населённых пунктов.

SELECT t."type",
	   COUNT(f.id) AS count_adv,
	   COUNT(DISTINCT f.city_id) AS count_city
FROM real_estate.flats f
LEFT JOIN real_estate.type t USING(type_id)
GROUP BY t."type"
ORDER BY count_adv
;

-- 3. Время активности объявления
	-- Подсчитаем основные статистики по полю со временем активности объявлений. 

SELECT MIN(a.days_exposition ),
	   MAX(a.days_exposition ),
	   ROUND(AVG(a.days_exposition )::NUMERIC, 2),
	   PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY a.days_exposition )
FROM real_estate.advertisement a
;

-- 4. Доля снятых с публикации объявлений
	-- подсчитаем процент таких объявленй

SELECT ROUND((SELECT COUNT(a.days_exposition )
		FROM real_estate.advertisement a)/COUNT(a.id)::NUMERIC*100, 2)
FROM real_estate.advertisement a
;

-- 5. Объявления Санкт-Петербурга
	-- Какой процент квартир продаётся в Санкт-Петербурге и Ленинградской области.

SELECT ROUND(
    (SELECT COUNT(f.id )
	FROM real_estate.flats f
	LEFT JOIN real_estate.city c USING(city_id)
	WHERE c.city = 'Санкт-Петербург'
    )/COUNT(f.id )::NUMERIC*100,
    2)
FROM real_estate.flats f
;

-- 6. Стоимость квадратного метра

SELECT ROUND(MIN(a.last_price/f.total_area::NUMERIC)::NUMERIC, 2) AS min_price,
	   ROUND(MAX(a.last_price/f.total_area::NUMERIC)::NUMERIC, 2) AS max_price,
	   ROUND(AVG(a.last_price/f.total_area::NUMERIC)::NUMERIC, 2) AS avg_price,
	   ROUND(PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY a.last_price::NUMERIC/f.total_area::NUMERIC ), 2) AS median_price
FROM real_estate.flats f 
INNER JOIN real_estate.advertisement a USING(id)
;

-- 7. Статистические показатели
	-- Подсчитаем статистические показатели — минимальное и максимальное значения, 
	-- среднее значение, медиану и 99 перцентиль по следующим количественным данным: общая площадь недвижимости, 
	-- количество комнат и балконов, высота потолков, этаж. 

SELECT ROUND(MIN(f.total_area)::NUMERIC, 2) AS min_total_area,
	   ROUND(MAX(f.total_area)::NUMERIC, 2) AS max_total_area,
	   ROUND(AVG(f.total_area)::NUMERIC, 2) AS avg_total_area,
	   PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY f.total_area) AS median_total_area,
	   PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY f.total_area ) AS perc_99_total_area,
	   PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY f.total_area ) AS perc_1_total_area
FROM real_estate.flats f 
;

SELECT ROUND(MIN(f.rooms)::NUMERIC, 2) AS min_rooms,
	   ROUND(MAX(f.rooms)::NUMERIC, 2) AS max_rooms,
	   ROUND(AVG(f.rooms)::NUMERIC, 2) AS avg_rooms,
	   PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY f.rooms) AS median_rooms,
	   PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY f.rooms) AS perc99_rooms
FROM real_estate.flats f 
;

SELECT ROUND(MIN(f.balcony)::NUMERIC, 2) AS min_balcony,
	   ROUND(MAX(f.balcony)::NUMERIC, 2) AS max_balcony,
	   ROUND(AVG(f.balcony)::NUMERIC, 2) AS avg_balcony,
	   PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY f.balcony) AS median_balcony,
	   PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY f.balcony) AS perc99_balcony
FROM real_estate.flats f 
;

SELECT ROUND(MIN(f.ceiling_height)::NUMERIC, 2) AS min_ceiling_height,
	   ROUND(MAX(f.ceiling_height)::NUMERIC, 2) AS max_ceiling_height,
	   ROUND(AVG(f.ceiling_height)::NUMERIC, 2) AS avg_ceiling_height,
	   PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY f.ceiling_height) AS median_ceiling_height,
	   PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY f.ceiling_height) AS perc99_ceiling_height
FROM real_estate.flats f 
;

SELECT ROUND(MIN(f.floor)::NUMERIC, 2) AS min_floor,
	   ROUND(MAX(f.floor)::NUMERIC, 2) AS max_floor,
	   ROUND(AVG(f.floor)::NUMERIC, 2) AS avg_floor,
	   PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY f.floor) AS median_floor,
	   PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY f.floor) AS perc99_floor
FROM real_estate.flats f
;
--------------------------------------------------------------------------------------

-- РЕШАЕМ ad hoc ЗАДАЧИ

-- 1. Время активности объявлений
	-- определим — по времени активности объявления — самые привлекательные для работы сегменты недвижимости 
	-- Санкт-Петербурга и городов Ленинградской области

-- Определим аномальные значения (выбросы) по значению перцентилей:
WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
),
-- Найдём id объявлений, которые не содержат выбросы:
filtered_id AS(
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
),
-- объединяем города в регионы и категории по времени активности (экспозиции квартиры)
price_gr AS (
SELECT id,
	   CASE WHEN city = 'Санкт-Петербург' 
	        THEN 'Санкт-Петербург'
	        ELSE 'ЛенОбл' 
	   END AS region , -- объединяем города в регионы
	   CASE WHEN a.days_exposition BETWEEN 1 AND 30 
	        THEN 'до месяца'
	        WHEN a.days_exposition < 90
	        THEN 'до трёх месяцев'
	        WHEN a.days_exposition < 180
	        THEN 'до полугода'
	        WHEN a.days_exposition > 180
	        THEN 'более полугода' 
	   END AS activity_segment , -- категории по времени активности (экспозиции квартиры)
	   f.total_area,
	   a.last_price,
	   f.rooms,
	   f.balcony
FROM real_estate.flats f
INNER JOIN real_estate.advertisement a USING(id)
LEFT JOIN real_estate.city c USING(city_id)
LEFT JOIN real_estate.type t USING(type_id)
WHERE id IN (SELECT * FROM filtered_id) -- Выведем объявления без выбросов
	  AND f.is_apartment = 0 -- исключаем аппаратенты
	  AND t.type = 'город' -- анализируем только города
)
-- итоговая сводная таблица
SELECT region,
	   activity_segment, -- сегмент активности
	   COUNT(pg.id) AS count_ads, -- количество объявлений
	   ROUND(COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS share_total,
	   ROUND(COUNT(*) / SUM(COUNT(*)) OVER(PARTITION BY region), 2) AS share_region, -- Доля объявлений в регионе
	   ROUND(AVG(pg.last_price/pg.total_area)::NUMERIC, 0) AS avg_price_per_sq_m, -- Средняя цена за кв.м.
	   ROUND(AVG(pg.total_area)::NUMERIC, 0) AS avg_total_area, --Средняя площадь квартир
	   PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY pg.rooms) AS median_count_room, -- Медиана кол-во комнат
	   PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY pg.balcony) AS median_count_balcony -- Медиана кол-во балконов
FROM price_gr pg 
--WHERE activity_segment IS NOT NULL -- исключаем не не снятые объявления
GROUP BY region, activity_segment
ORDER BY region DESC, count_ads
;
-----------------------------------------------------------------------

-- 2. Сезонность объявлений
	-- Заказчику важно понять сезонные тенденции на рынке недвижимости 
	-- Санкт-Петербурга и Ленинградской области — то есть для всего региона, 
	-- чтобы выявить периоды с повышенной активностью продавцов и покупателей недвижимости. 

-- Определим аномальные значения (выбросы) по значению перцентилей:
WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
),
-- Найдём id объявлений, которые не содержат выбросы:
filtered_id AS(
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
),
-- определим месяц публикации и месяц продажи квартир
month_gr AS (
	SELECT id,
		   a.first_day_exposition,
		   EXTRACT(MONTH FROM a.first_day_exposition)  AS month_publication, -- Месяц публикации
		   TO_CHAR(a.first_day_exposition::DATE 
		           + (a.days_exposition ||' day')::INTERVAL, 'Month'
		           ) AS month_sale, -- Месяц продажи
		   f.total_area,
		   a.last_price,
		   f.rooms,
		   f.balcony
	FROM real_estate.flats f
	INNER JOIN real_estate.advertisement a USING(id)
	LEFT JOIN real_estate.city c USING(city_id)
	LEFT JOIN real_estate.type t USING(type_id)
	WHERE id IN (SELECT * FROM filtered_id) -- Выведем объявления без выбросов
		  AND f.is_apartment = 0 -- исключаем аппаратенты
	      AND t.type = 'город' -- анализируем только города		  
		  AND first_day_exposition BETWEEN '2015-01-01' AND '2018-12-31' -- ограничиваем период анализа полными годами
),
-- количество публикаций по месяцам
exp_month AS (
	SELECT ROW_NUMBER() OVER(ORDER BY COUNT(id)DESC) AS row_num,
	       COUNT(id) AS count_publication, -- Кол-во публикаций
	       ROUND(COUNT(id)/SUM(COUNT(id)) OVER(), 2) AS share_count_publication, -- доля кол-ва объявлений
	       month_publication, -- Месяц публикации
	       ROUND(AVG(last_price/total_area)::NUMERIC, 0) AS ads_avg_price_per_sq_m, -- Средняя цена (объявления) за кв.м.
	       ROUND(AVG(total_area)::NUMERIC, 0) AS ads_avg_total_area -- Средняя площадь (объявления) кв.м.    	       
	FROM month_gr
	GROUP BY month_publication
),
-- количество продаж по месяцам
sale_month AS (
	SELECT ROW_NUMBER() OVER(ORDER BY COUNT(id)DESC) AS row_num,
	       COUNT(id) AS count_sale, -- Кол-во продаж
	       ROUND(COUNT(id)/SUM(COUNT(id)) OVER(), 2) AS share_count_sale, -- доля количества продаж
	       month_sale, -- Месяц продаж
	       ROUND(AVG(last_price/total_area)::NUMERIC, 0) AS sale_avg_price_per_sq_m, -- Средняя цена за кв.м.
	       ROUND(AVG(total_area)::NUMERIC, 0) AS sale_avg_total_area -- Средняя площадь кв.м.    
	FROM month_gr 
	WHERE first_day_exposition IS NOT NULL
	GROUP BY month_sale
)
-- итоговая сводная таблица
SELECT month_sale, -- месяц продаж
	   count_sale, -- Кол-во продаж
	   share_count_sale, -- доля количества продаж
	   sm.sale_avg_price_per_sq_m, -- Средняя цена продажи за кв.м.
	   sm.sale_avg_total_area, -- Средняя площадь кв.м.	   
	   month_publication, -- Месяц публикации
	   count_publication, -- Кол-во публикаций
	   share_count_publication, -- доля кол-ва объявлений
	   em.ads_avg_price_per_sq_m, -- Средняя цена (объявления) за кв.м.
	   em.ads_avg_total_area -- Средняя площадь (объявления) кв.м.
FROM sale_month AS sm 
FULL JOIN exp_month AS em USING(row_num)
ORDER BY count_sale DESC

--------------------------------------------------------------------------------

-- 3. Анализ рынка недвижимости Ленобласти
	-- Заказчик хочет определить, в каких населённых пунктах Ленинградской области 
	-- активнее всего продаётся недвижимость и какая именно. 

-- Определим аномальные значения (выбросы) по значению перцентилей:
WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
),
-- Найдём id объявлений, которые не содержат выбросы:
filtered_id AS(
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
),
-- объединяем города в регионы и категории по времени активности (экспозиции квартиры)
price_gr AS (
SELECT id,
	   city,
	   a.days_exposition, 
	   f.total_area,
	   a.last_price,
	   f.rooms,
	   f.balcony
FROM real_estate.flats f
INNER JOIN real_estate.advertisement a USING(id)
LEFT JOIN real_estate.city c USING(city_id)
WHERE id IN (SELECT * FROM filtered_id) -- Выведем объявления без выбросов
	  AND f.is_apartment = 0 -- исключаем аппаратенты
	  AND city != 'Санкт-Петербург'
)
-- итоговая сводная таблица
SELECT city,
	   COUNT(pg.id) AS count_ads, -- Кол-во объявлений
	   ROUND(COUNT(pg.days_exposition ) / COUNT(pg.id)::NUMERIC*100) AS share_count_sale, -- Доля снятых с публикации %
	   ROUND(AVG(days_exposition)) AS avg_days_exposition, -- Ср кол-во дней экспозиции квартиры	   
	   ROUND(AVG(pg.total_area)::NUMERIC) AS avg_total_area, -- Средняя площадь кв.м.
	   PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY pg.rooms) AS median_count_rooms, -- Медиана кол-во комнат
	   ROUND(AVG(pg.last_price/pg.total_area)::NUMERIC) AS avg_price_per_sq_m -- Средняя цена за кв.м.
FROM price_gr pg 
GROUP BY city
ORDER BY count_ads DESC
LIMIT 15 -- определяем топ-15 по количеству размещенных объявлений
;
