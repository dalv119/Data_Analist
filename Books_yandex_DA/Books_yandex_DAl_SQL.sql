-- Расчёт метрик в SQL
-----------------------------------
-- Этот проект состоит из нескольких частей. Сначала вы поработаете с данными сервиса Яндекс Книги, рассчитаете несколько метрик и 
-- проверите гипотезу. Затем, уже на других данных, вы будете анализировать результаты A/B-тестирования.
-- В этом и следующих трёх уроках вы будете работать с данными о чтении и прослушивании контента в сервисе Яндекс Книги. 
-- Вам предстоит рассчитать несколько метрик с помощью SQL и интерпретировать полученные результаты. 
-- Затем вы проверите гипотезу с помощью Python и составите аналитическую записку.

-- Описание данных
    -- Таблицы этого проекта содержат данные о чтении и прослушивании контента в сервисе Яндекс Книги, которые включают информацию о пользователях, 
    -- платформах, времени, длительности сессий и типах контента. Данные представлены за период с 1 сентября по 11 декабря 2024 года. 
    -- В вашем распоряжении будет несколько таблиц.

-- Таблица bookmate.audition содержит данные об активности пользователей и состоит из следующих полей:
    -- audition_id — уникальный идентификатор сессии чтения или прослушивания;
    -- puid — идентификатор пользователя;
    -- usage_platform_ru — название платформы, с помощью которой пользователь слушал контент;
    -- msk_business_dt_str — дата события в формате строки (московское время);
    -- app_version — версия приложения, которая использовалась для чтения или прослушивания;
    -- adult_content_flg — был ли это контент для взрослых: True или False;
    -- hours — длительность чтения или прослушивания в часах;
    -- hours_sessions_long — продолжительность длинных сессий чтения или прослушивания в часах;
    -- kids_content_flg — был ли это детский контент: True или False;
    -- main_content_id — идентификатор основного контента;
    -- usage_geo_id — идентификатор географического местоположения.

-- Таблица bookmate.content содержит данные о контенте и состоит из следующих полей:
    -- main_content_id — идентификатор основного контента;
    -- main_author_id — идентификатор основного автора контента;
    -- main_content_type — тип контента;
    -- main_content_name— название контента;
    -- main_content_duration_hours — длительность контента в часах;
    -- published_topic_title_list — список жанров контента.
-- Таблица bookmate.author содержит данные об авторах контента и состоит из следующих полей:
    -- main_author_id — идентификатор основного автора контента;
    -- main_author_name — имя основного автора контента.
-- Таблица bookmate.geo содержит данные о местоположении и состоит из следующих полей:
    -- usage_geo_id — идентификатор географического положения;
    -- usage_geo_id_name — город или регион географического положения;
    -- usage_country_name — страна географического положения.

-- 1. Расчёт MAU авторов

-- Проведем анализ и рассчитаем ключевые метрики активности пользователей сервиса Яндекс Книги. Цель — глубже понять поведение пользователей 
-- и найти примечательные закономерности. Эти расчёты помогут понять, как пользователи взаимодействуют с платформой, какие виды контента 
-- наиболее популярны, а также выявить особенности поведения пользователей.
-- Первая задача — расчёт MAU. Здесь MAU будет определяться как количество уникальных пользователей в месяц, которые читали или 
-- слушали конкретного автора. Выведем имена топ-3 авторов с наибольшим MAU в ноябре и сами значения MAU.
-- В результат должны войти следующие поля:
-- main_author_name — имя автора контента;
-- mau — значение MAU.
-- Отсортируем  результат по значению MAU в порядке убывания.

SELECT main_author_name
       ,MAX(count_user) AS mau
FROM (SELECT main_author_name
             ,COUNT(DISTINCT puid) AS count_user
             ,EXTRACT(MONTH FROM msk_business_dt_str) AS month
      FROM bookmate.author AS ba
         JOIN bookmate.content AS bc USING(main_author_id)
        JOIN bookmate.audition AS b_aud USING(main_content_id)
      GROUP BY main_author_name, EXTRACT(MONTH FROM msk_business_dt_str)
     ) AS gr_data
WHERE month = '11'
GROUP BY main_author_name
ORDER BY mau DESC
LIMIT 3


-- 2. Расчёт MAU произведений

-- Рассчитаем MAU произведений. Выведем имена топ-3 произведений с наибольшим MAU в ноябре, а также списки жанров этих произведений, 
-- их авторов и сами значения MAU.
-- В результат должны войти следующие поля:
-- main_content_name — название произведения, или контента;
-- published_topic_title_list — список жанров контента;
-- main_author_name — имя автора контента;
-- mau — значение MAU.
-- Отсортируем результат по значению MAU в порядке убывания.

SELECT main_content_name,
       published_topic_title_list,
       main_author_name,
       MAX(count_user) AS mau
FROM (SELECT main_author_name,
             main_content_name,
             published_topic_title_list,
             COUNT(DISTINCT puid) AS count_user,
             EXTRACT(MONTH FROM msk_business_dt_str) AS month
      FROM bookmate.author AS ba
         JOIN bookmate.content AS bc USING(main_author_id)
        JOIN bookmate.audition AS b_aud USING(main_content_id)
      GROUP BY main_author_name, EXTRACT(MONTH FROM msk_business_dt_str), main_content_name, published_topic_title_list
     ) AS gr_data
WHERE month = '11'
GROUP BY main_content_name, published_topic_title_list, main_author_name
ORDER BY mau DESC
LIMIT 3

-- 3. Расчёт Retention Rate

-- Команда сервиса Яндекс Книги провела рекламную кампанию, которая 2 декабря привлекла множество пользователей. 
-- Задача — проанализировать ежедневный Retention Rate всех пользователей, которые были активны 2 декабря. 
-- При этом неважно, новые это пользователи или нет, ведь по имеющимся данным этого всё равно не получится определить.
-- Рассчитаем ежедневный Retention Rate пользователей до конца представленных данных. Выведем следующие поля:
-- day_since_install — срок жизни пользователя в днях;
-- retained_users — количество пользователей, которые вернулись в приложение в конкретный день;
-- retention_rate — коэффициент удержания для вернувшихся пользователей по отношению к общему числу пользователей, 
-- которые установили приложение.Округлите до двух знаков после запятой.
-- Отсортируем результат по сроку жизни в порядке возрастания.

-- Рассчитываем активных пользователей по дате события
WITH active_users AS (
  SELECT DISTINCT puid,
                  msk_business_dt_str AS log_date
  FROM bookmate.audition 
  WHERE msk_business_dt_str = '2024-12-02'
  ),

daily_retention AS (
  SELECT puid, msk_business_dt_str,
         MAX(a.msk_business_dt_str) - log_date  AS day_since_install      
  FROM active_users AS au
  JOIN bookmate.audition as a USING(puid)
  WHERE msk_business_dt_str>=log_date 
  GROUP BY puid, log_date, msk_business_dt_str

)
SELECT day_since_install,
       COUNT(puid) AS retained_users, --msk_business_dt_str,
       ROUND(1.0 * COUNT(puid)/MAX(COUNT(DISTINCT puid)) OVER (ORDER by day_since_install), 2) AS retention_rate
FROM daily_retention
-- WHERE day_since_install < 8
GROUP BY day_since_install
ORDER BY day_since_install;  

-- 4. Расчёт LTV

-- Подписка Яндекс Плюс стоит 399 рублей в месяц. Кроме Яндекс Книг в подписку входят и другие сервисы, однако в рамках этого проекта 
-- будем считать, что пользователь приносит 399 рублей, если хотя бы раз в месяц пользуется Яндекс Книгами. При этом потенциально платящих, 
-- но неактивных пользователей не будем учитывать.
-- Рассчитаем средние LTV для пользователей в Москве и Санкт-Петербурге и сравним их между собой. Для расчёта среднего LTV используем формулу: 
-- общий доход / количество пользователей. Выведем в результате запроса общее количество пользователей в каждом городе и их средний LTV.
-- В результат должны войти следующие поля:
-- city — название города или региона (данные из поля usage_geo_id_name);
-- total_users — суммарное количество пользователей в городе или регионе;
-- ltv — средний LTV пользователей в городе или регионе.Округлите до двух знаков после запятой.


WITH activ_users AS (
  SELECT city,
         puid,
         COUNT(month) AS month_count
  FROM (SELECT DISTINCT puid,
              usage_geo_id_name AS city,
              EXTRACT('month'FROM msk_business_dt_str) AS month
        FROM bookmate.audition AS a
        JOIN bookmate.geo AS g USING(usage_geo_id)
        WHERE usage_geo_id_name IN('Москва', 'Санкт-Петербург')
        ORDER BY puid, month) AS m
  GROUP BY city, puid
  -- HAVING COUNT(month) = )
)
SELECT city,
       COUNT(DISTINCT puid) AS total_users,
       ROUND(1.0*399*SUM(month_count) / COUNT(DISTINCT puid), 2)  AS ltv
FROM activ_users
GROUP BY city


-- 5. Расчёт средней выручки прослушанного часа — аналог среднего чека

-- Предполагается, что в сервисе используется модель монетизации с единой подпиской. По этой причине рассчитывать средний чек транзакций 
-- нецелесообразно, ведь он будет равен стоимости подписки. Тем не менее можно рассчитать ежемесячную среднюю выручку от часа чтения 
-- или прослушивания по такой формуле: выручка (MAU * 399 рублей) / сумма прослушанных часов.
-- Рассчитаем эту метрику вместе с MAU и суммой прослушанных часов с сентября по ноябрь. В результат должны войти следующие поля:
-- month — месяц активности;
-- mau — значение MAU;
-- hours — общее количество прослушанных часов (вычисляется по полю hours). Округлите до двух знаков после запятой;
-- avg_hour_rev — средняя выручка от часа чтения или прослушивания. Округлите до двух знаков после запятой.



SELECT DATE_TRUNC('month', msk_business_dt_str)::date AS month,
       COUNT(DISTINCT puid) AS mau,
       ROUND(SUM(hours::numeric), 2) AS hours,
       ROUND(COUNT(DISTINCT puid) * 399 / SUM(hours::numeric), 2) AS avg_hour_rev
FROM bookmate.audition
WHERE msk_business_dt_str BETWEEN '2024-09-01' AND '2024-11-30'
GROUP BY 1
