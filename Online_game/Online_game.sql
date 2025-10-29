/* Проект «Секреты Тёмнолесья»
 * Цель проекта: изучить влияние характеристик игроков и их игровых персонажей 
 * на покупку внутриигровой валюты «райские лепестки», а также оценить 
 * активность игроков при совершении внутриигровых покупок
 * 
 * Автор: Владимир Добров 
 * Дата: 15.02.2025
*/

-- Часть 1. Исследовательский анализ данных
-- Задача 1. Исследование доли платящих игроков

-- 1.1. Доля платящих пользователей по всем данным:

SELECT COUNT(id) AS all_players, --общее количество игроков, зарегистрированных в игре
	   SUM(payer) AS pay_players, --количество платящих игроков
	   ROUND(SUM(payer)/COUNT(id)::NUMERIC, 2) AS share_pay_players --доля платящих игроков от общего количества пользователей, зарегистрированных в игре
FROM fantasy.users
;

-- 1.2. Доля платящих пользователей в разрезе расы персонажа:

SELECT race,
	   COUNT(id) AS all_players, --общее количество игроков, зарегистрированных в игре
	   SUM(payer) AS pay_players, --количество платящих игроков
	   ROUND(SUM(payer)/COUNT(id)::NUMERIC, 2) AS share_pay_players --доля платящих игроков от общего количества пользователей, зарегистрированных в игре
FROM fantasy.users AS u
LEFT JOIN fantasy.race AS r USING(race_id)
GROUP BY race
ORDER BY pay_players DESC
;

-- Задача 2. Исследование внутриигровых покупок
-- 2.1. Статистические показатели по полю amount:

SELECT COUNT(DISTINCT transaction_id ) AS count_purchese, --общее количество покупок;
	   SUM(amount) AS total_amount, --суммарную стоимость всех покупок;
	   MIN(amount) AS min_cost, --минимальную стоимость покупки;
	   ROUND(MAX(amount)) AS max_cost, --максимальную стоимость покупки;
	   ROUND(AVG(amount)) AS avg_cost, --среднее значение, 
	   ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY amount)) AS median_cost, --медиану и 
	   ROUND(STDDEV(amount)) AS stand_dev_cost --стандартное отклонение стоимости покупки.
FROM fantasy.events

-- 2.2: Аномальные нулевые покупки:

SELECT COUNT(transaction_id) AS count_no_cost,-- количество нулевых покупок 
	   (SELECT COUNT(transaction_id) FROM fantasy.events) AS count_all_purchase,-- общее каличество покупок
	   COUNT(transaction_id) / (SELECT COUNT(transaction_id) FROM fantasy.events) AS share_no_cost -- доля нулевых рокупок
FROM fantasy.events 
WHERE amount = 0
;
-- или
SELECT COUNT(transaction_id) FILTER (WHERE amount = 0) AS zero_amounts, -- количество нулевых покупок 
 	   COUNT(transaction_id) AS total_amounts, -- общее каличество покупок
 	   COUNT(transaction_id) FILTER (WHERE amount = 0)::NUMERIC / COUNT(transaction_id) AS zero_share -- доля нулевых рокупок
FROM fantasy.events;


-- 2.3: Сравнительный анализ активности платящих и неплатящих игроков:

WITH gr_events AS (
	SELECT id,
		   payer, 
	       COUNT(transaction_id) AS count_purchese,
	       SUM(amount) AS sum_cost
	FROM fantasy.events AS e
	LEFT JOIN fantasy.users AS u USING(id)
	WHERE amount <> 0
	GROUP BY id, payer
)
SELECT payer,
	   COUNT(id) AS all_players, --общее количество игроков,
	   ROUND(AVG(count_purchese), 2) AS avg_purchese, --среднее количество покупок
	   ROUND(AVG(sum_cost)::NUMERIC, 2) AS avg_cost_for_player --среднюю суммарную стоимость покупок на одного игрока
FROM gr_events
GROUP BY payer

-- 2.4: Популярные эпические предметы:

WITH gr_events AS (
	SELECT id,
	   i.game_items,
	   COUNT(transaction_id) OVER(PARTITION BY item_code) AS total_sale, 
	   ROUND(COUNT(transaction_id) OVER(PARTITION BY item_code)
	   /COUNT(transaction_id) OVER()::NUMERIC, 3) AS share_sale_item   
	FROM fantasy.events AS e
	LEFT JOIN fantasy.items AS i USING(item_code)
	LEFT JOIN fantasy.users AS u USING(id)
WHERE e.amount <> 0
)
SELECT game_items,
	   total_sale, --общее количество внутриигровых продаж в абсолютном значени
	   share_sale_item, --доля продажи каждого предмета от всех продаж
	   ROUND(COUNT(DISTINCT id)
	   	   /(SELECT COUNT(DISTINCT id) 
	   	     FROM fantasy.events)::NUMERIC, 2) AS share_player_sale_item --доля игроков, которые хотя бы раз покупали этот предмет
FROM gr_events
GROUP BY game_items,
	   total_sale,
	   share_sale_item
ORDER BY share_player_sale_item DESC

-- Часть 2. Решение ad hoc-задач
-- Задача 1. Зависимость активности игроков от расы персонажа:

WITH reg_users AS ( --общее количество зарегистрированных игроков
	SELECT r.race,
		   COUNT(id) AS all_players,
		   SUM(payer) AS total_payer
	FROM fantasy.users AS u
	LEFT JOIN fantasy.race AS r USING(race_id)
	GROUP BY r.race
),
players_pay AS (
	SELECT race,
		   COUNT(DISTINCT id) AS pay_player --количество игроков, которые совершили покупку
	FROM fantasy.users AS u
	INNER JOIN fantasy.events AS e USING(id)
	LEFT JOIN fantasy.race AS r USING(race_id)
	WHERE amount <> 0
	GROUP BY r.race
),
activ_players AS (
	SELECT race,
		   ROUND(AVG(count_pay_player)::NUMERIC, 2) AS avg_pay_for_player,--среднее количество покупок на одного игрока;
	       ROUND(AVG(amount_for_player)::NUMERIC, 2) AS avg_amount_for_player, --средняя стоимость одной покупки на одного игрока;
		   ROUND(AVG(total_amount_for_player)::NUMERIC, 2) AS avg_total_amount_for_player--средняя суммарная стоимость всех покупок на одного игрока
	FROM (SELECT id,
				 race,
				 COUNT(transaction_id) AS count_pay_player, --количество покупок на одного игрока;
				 AVG(amount) AS amount_for_player, --средняя стоимость одной покупки на одного игрока;
				 SUM(amount) AS total_amount_for_player --суммарная стоимость всех покупок на одного игрока
			FROM fantasy.users AS u
			INNER JOIN fantasy.events AS e USING(id)
			LEFT JOIN fantasy.race AS r USING(race_id)
			WHERE amount <> 0
			GROUP BY r.race, u.id, amount
			) AS activ
	GROUP BY race
)
SELECT race,
	   all_players, --общее количество зарегистрированных игроков
	   pay_player, --количество игроков, которые совершили покупку
	   ROUND(total_payer/pay_player::NUMERIC, 2) AS share_paying_player, --доля платящих игроков среди них
	   avg_pay_for_player,--среднее количество покупок на одного игрока;
	   avg_amount_for_player, --средняя стоимость одной покупки на одного игрока;
	   avg_total_amount_for_player --средняя суммарная стоимость всех покупок на одного игрока
FROM reg_users AS ru 
LEFT JOIN players_pay AS pp USING(race)
LEFT JOIN activ_players AS ap USING(race)
ORDER BY pay_player DESC

-- Задача 2: Частота покупок

WITH date_pay AS ( -- определяем дату и время покупки
	SELECT id,
		   transaction_id,
		   date::DATE + time::TIME AS pay_date	   
	FROM fantasy.events
	WHERE amount <> 0
),
time_between_buy AS ( -- определяем интервал времени между покупками 
	SELECT id,
		   transaction_id,
		   EXTRACT(DAY FROM LEAD(pay_date) OVER(PARTITION BY id ORDER BY pay_date) - pay_date) AS pay_interval
	FROM date_pay
),
avg_pay_interval AS ( --общее количество покупок и среднее значение по количеству дней между покупками
	SELECT id,
		   CASE WHEN payer = 1 THEN id ELSE NULL END AS payer_id,
		   COUNT(transaction_id) OVER(PARTITION BY id) AS count_pay_per_user, --общее количество покупок на одного игрока
		   AVG(pay_interval) OVER(PARTITION BY id) AS avg_pay_interval
	FROM time_between_buy
	LEFT JOIN fantasy.users AS u USING(id)
),
split_interval AS ( --разделение всех игроков на три примерно равные группы по частоте покупки
	SELECT id,
		   payer_id,
		   count_pay_per_user,
		   avg_pay_interval,
		   NTILE(3) OVER(ORDER BY avg_pay_interval) AS serm_interval
	FROM avg_pay_interval
	WHERE count_pay_per_user > 25 --учитывать только активных клиентов, которые совершили 25 или более покупок
),	
segment_interval AS ( --присваиваем названия группам по по частоте покупки
	SELECT id,
		   payer_id,
		   count_pay_per_user,
		   avg_pay_interval,
		   CASE WHEN serm_interval = 1 
		   			THEN 'высокая частота'
				WHEN serm_interval = 2 
					THEN 'умеренная частота'
				WHEN serm_interval = 3 
					THEN 'низкая частота'
				END AS gr_interval
	FROM split_interval
)
SELECT gr_interval,
	   COUNT(DISTINCT id) AS count_pay_users, --количество игроков, которые совершили покупки
	   COUNT(DISTINCT payer_id) AS count_paying_users, --количество платящих игроков, совершивших покупки
	   ROUND(COUNT(DISTINCT payer_id)/COUNT(DISTINCT id)::NUMERIC, 2) AS share_paying_users,--их доля от общего количества игроков, совершивших покупку
	   ROUND(AVG(count_pay_per_user)) AS avg_pay_per_user, --среднее количество покупок на одного игрока;
	   ROUND(AVG(avg_pay_interval), 3) AS avg_day_for_pay --среднее количество дней между покупками на одного игрока.	   
FROM segment_interval
GROUP BY gr_interval
ORDER BY count_pay_users DESC
;

