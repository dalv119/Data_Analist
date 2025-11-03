

-- Часть 1: Анализ данных с помощью SQL и создание дашборда в DataLens. Вычисление ключевых метрик продукта
-----------------------------------------------------------------------------------------------------------
-- Представлены данными сервиса Яндекс Афиша. С его помощью пользователи могут узнавать информацию о мероприятиях 
-- в разных городах и покупать на них билеты. Сервис сотрудничает с партнёрами — организаторами мероприятий и билетными операторами, 
-- которые предоставляют информацию о событиях и выставляют билеты на продажу.
-- Необходимо выяснить в предверии праздников причины изменения цены на различные мероприятия в ноябре 2024 года
-- Может, сработал фактор сезонности, и пользователи поменяли предпочтения? Или изменилась аудитория? 
-- Стоит также разобраться, какие события стали привлекать больше зрителей, а какие организаторы и площадки выбились в лидеры. 
-- А также понять, отличаются ли своей активностью пользователи мобильных устройств от клиентов, которые бронируют билеты 
-- со стационарного компьютера.
-- Близится период распродаж и новогодних акций, и сервис должен основательно к нему подготовиться. 
-- Чтобы принимать взвешенные решения, нужна детальная аналитика и убедительные инсайты.
-- Необходимо разработать аналитический дашборд в Yandex DataLens. С его помощью команда сможет отслеживать динамику ключевых бизнес-показателей, 
-- анализировать популярность мероприятий и структуру выручки в разрезе категорий событий и устройств.

-- 1. Получение общих данных

-- Вычислим общие значения ключевых показателей сервиса за весь период:
    -- общая выручка с заказов total_revenue;
    -- количество заказов total_orders;
    -- средняя стоимость заказа avg_revenue_per_order;
    -- общее число уникальных клиентов total_users.
-- Поскольку данные представлены в российских рублях и казахстанских тенге, то значения посчитаем в разрезе каждой валюты (поле currency_code). 
-- Результат отсортируем по убыванию значения в поле total_revenue.

SELECT currency_code,
       SUM(revenue) AS total_revenue,
       COUNT(DISTINCT order_id) AS total_orders,
       AVG(revenue) AS avg_revenue_per_order,
       COUNT(DISTINCT user_id) AS total_users
FROM afisha.purchases
GROUP BY currency_code
ORDER BY total_revenue DESC;

-- 2. Изучим распределения выручки в разрезе устройств
-- Для заказов в рублях вычислим распределение выручки и количества заказов по типу устройства device_type_canonical. 
-- Результат будет включать поля:
    -- тип устройства device_type_canonical;
    -- общая выручка с заказов total_revenue;
    -- количество заказов total_orders;
    -- средняя стоимость заказа avg_revenue_per_order;
    -- доля выручки для каждого устройства от общего значения revenue_share, округлённая до трёх знаков после точки.
-- Результат отсортируем по убыванию значения в поле revenue_share.


SELECT device_type_canonical,
       sum(revenue) AS total_revenue,
       count(order_id) AS total_orders,
       avg(revenue) AS avg_revenue_per_order,
       ROUND(sum(revenue)::NUMERIC/(SELECT SUM(revenue)FROM afisha.purchases WHERE currency_code = 'rub')::NUMERIC, 3) AS revenue_share
FROM afisha.purchases
WHERE currency_code = 'rub'
GROUP BY device_type_canonical
ORDER BY revenue_share DESC;

-- 3. Изучение распределения выручки в разрезе типа мероприятий

-- Для заказов в рублях вычислим распределение количества заказов и их выручку в зависимости от типа мероприятия event_type_main. 
-- Результат будет включать поля:
    -- тип мероприятия event_type_main;
    -- общая выручка с заказов total_revenue;
    -- количество заказов total_orders;
    -- средняя стоимость заказа avg_revenue_per_order;
    -- уникальное число событий total_event_name (по их коду event_name_code);
    -- среднее число билетов в заказе avg_tickets;
    -- средняя выручка с одного билета avg_ticket_revenue;
    -- доля выручки от общего значения revenue_share, округлённая до трёх знаков после точки.
-- Результат отсортируем по убыванию значения в поле total_orders.

SELECT event_type_main,
       SUM(revenue) AS total_revenue,
       COUNT(order_id) AS total_orders,
       AVG(revenue) AS avg_revenue_per_order,
       COUNT(DISTINCT event_name_code) AS total_event_name,
       AVG(tickets_count) AS avg_tickets,
       SUM(revenue)/SUM(tickets_count) AS avg_ticket_revenue,
       ROUND(SUM(revenue)::NUMERIC/(SELECT SUM(revenue) FROM afisha.purchases WHERE currency_code='rub')::NUMERIC, 3) AS revenue_share
FROM afisha.purchases
JOIN afisha.events USING(event_id)
WHERE currency_code='rub'
GROUP BY event_type_main
ORDER BY total_orders DESC;

-- 4. Динамика изменения значений

-- На дашборде понадобится показать динамику изменения ключевых метрик и параметров. Для заказов в рублях вычислим изменение выручки, 
-- количества заказов, уникальных клиентов и средней стоимости одного заказа в недельной динамике. 
-- Результат будет включать поля:
    -- неделя week;
    -- суммарная выручка total_revenue;
    -- число заказов total_orders;
    -- уникальное число клиентов total_users;
    -- средняя стоимость одного заказа revenue_per_order.
-- Результат отсортируем по возрастанию значения в поле week.

SELECT DATE_TRUNC('week', created_dt_msk)::date AS week,
       SUM(revenue) AS total_revenue,
       COUNT(order_id) AS total_orders,
       COUNT(DISTINCT user_id) AS total_users,
       SUM(revenue)/COUNT(order_id) AS revenue_per_order
FROM afisha.purchases
WHERE currency_code='rub'
GROUP BY week
ORDER BY week;

-- 5.Выделение топ-сегментов

-- Выведем топ-7 регионов по значению общей выручки, включив только заказы за рубли. 
-- Результат будет включать поля:
    -- название региона region_name;
    -- суммарная выручка total_revenue;
    -- число заказов total_orders;
    -- уникальное число клиентов total_users;
    -- количество проданных билетов total_tickets;
    -- средняя выручка одного билета one_ticket_cost.
-- Результат отсортируем по убыванию значения в поле total_revenue.

SELECT region_name,
       SUM(revenue) AS total_revenue,
       COUNT(order_id) AS total_orders,
       COUNT(DISTINCT user_id) AS total_users,
       SUM(tickets_count) AS total_tickets,
       SUM(revenue)/SUM(tickets_count) AS one_ticket_cost
FROM afisha.purchases p
JOIN afisha.events USING(event_id)
JOIN afisha.city USING(city_id)
JOIN afisha.regions USING(region_id)
WHERE currency_code='rub'
GROUP BY region_name
ORDER BY total_revenue DESC
LIMIT 7;

