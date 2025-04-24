/*1. Выведите общую сумму просмотров у постов, опубликованных в каждый месяц 2008 года. Если данных за какой-либо месяц в базе нет, такой месяц можно пропустить. Результат отсортируйте по убыванию общего количества просмотров.*/

SELECT DATE_TRUNC('month', p.creation_date)::date AS post_month,
       SUM(p.views_count) AS sum_views
FROM stackoverflow.posts p
GROUP BY DATE_TRUNC('month', p.creation_date)::date
ORDER BY sum_views DESC

/*2. Выведите имена самых активных пользователей, которые в первый месяц после регистрации (включая день регистрации) дали больше 100 ответов. Вопросы, которые задавали пользователи, не учитывайте. Для каждого имени пользователя выведите количество уникальных значений user_id. Отсортируйте результат по полю с именами в лексикографическом порядке.*/

SELECT
       u.display_name,
       COUNT(DISTINCT p.user_id)
FROM stackoverflow.users u
JOIN stackoverflow.posts p ON u.id = p.user_id
JOIN stackoverflow.post_types vt ON p.post_type_id = vt.id
WHERE vt.type = 'Answer'
AND CAST(p.creation_date AS date) BETWEEN CAST(u.creation_date AS date) AND (CAST(u.creation_date AS date) + INTERVAL '1 month')
GROUP BY u.display_name
HAVING COUNT(DISTINCT p.id) > 100
ORDER BY u.display_name ASC

/*3. Выведите количество постов за 2008 год по месяцам. Отберите посты от пользователей, которые зарегистрировались в сентябре 2008 года и сделали хотя бы один пост в декабре того же года. Отсортируйте таблицу по значению месяца по убыванию.*/

WITH res AS
    (SELECT u.id
     FROM stackoverflow.users u
     JOIN stackoverflow.posts p ON u.id = p.user_id
     WHERE DATE_TRUNC('month', u.creation_date) = '2008-09-01'
     AND DATE_TRUNC('month', p.creation_date) BETWEEN '2008-12-01' AND '2008-12-31')

SELECT 
      CAST(DATE_TRUNC('month', p.creation_date) as date),
      COUNT(p.id)
FROM stackoverflow.posts p
WHERE EXTRACT(YEAR FROM p.creation_date::date) = 2008
AND p.user_id in (SELECT * FROM res)
GROUP BY CAST(DATE_TRUNC('month', p.creation_date) AS date)
ORDER BY CAST(DATE_TRUNC('month', p.creation_date) AS date) DESC

/*4. Используя данные о постах, выведите несколько полей:
идентификатор пользователя, который написал пост;
дата создания поста;
количество просмотров у текущего поста;
сумма просмотров постов автора с накоплением.
Данные в таблице должны быть отсортированы по возрастанию идентификаторов пользователей, а данные об одном и том же пользователе — по возрастанию даты создания поста.*/

SELECT p.user_id,
       p.creation_date,
       p.views_count,
       SUM(p.views_count) OVER (PARTITION BY p.user_id ORDER BY p.creation_date)
FROM stackoverflow.posts p
ORDER BY p.user_id ASC, p.creation_date ASC

/*5. Сколько в среднем дней в период с 1 по 7 декабря 2008 года включительно пользователи взаимодействовали с платформой? Для каждого пользователя отберите дни, в которые он или она опубликовали хотя бы один пост. Нужно получить одно целое число — не забудьте округлить результат.*/

WITH res AS
    (SELECT p.user_id,
            COUNT(DISTINCT(EXTRACT(DAY FROM p.creation_date))) AS activity_days
     FROM stackoverflow.posts p
     WHERE p.creation_date BETWEEN '2008-12-01' AND '2008-12-07'
     GROUP BY p.user_id)

SELECT ROUND(AVG(activity_days))
FROM res

/*6. На сколько процентов менялось количество постов ежемесячно с 1 сентября по 31 декабря 2008 года? Отобразите таблицу со следующими полями:
Номер месяца.
Количество постов за месяц.
Процент, который показывает, насколько изменилось количество постов в текущем месяце по сравнению с предыдущим.
Если постов стало меньше, значение процента должно быть отрицательным, если больше — положительным. Округлите значение процента до двух знаков после запятой.
Напомним, что при делении одного целого числа на другое в PostgreSQL в результате получится целое число, округлённое до ближайшего целого вниз. Чтобы этого избежать, переведите делимое в тип numeric.*/

WITH res AS
    (SELECT
            EXTRACT(MONTH FROM p.creation_date) AS posts_month,
            COUNT(id) AS posts_count
     FROM stackoverflow.posts p
     WHERE p.creation_date BETWEEN '2008-09-01' AND '2008-12-31'
     GROUP BY EXTRACT(MONTH FROM p.creation_date)
     ORDER BY EXTRACT(MONTH FROM p.creation_date))

SELECT
       posts_month,
       posts_count,
       ROUND(posts_count/(LAG(posts_count) OVER ())::numeric*100-100,2)
FROM res

/*7. Найдите пользователя, который опубликовал больше всего постов за всё время с момента регистрации. Выведите данные его активности за октябрь 2008 года в таком виде:
номер недели;
дата и время последнего поста, опубликованного на этой неделе.*/

WITH res AS
    (SELECT p.user_id,
            SUM(p.id) AS post_count
     FROM stackoverflow.posts p
     GROUP BY p.user_id
     ORDER BY post_count DESC
     LIMIT 1),

res2 AS
    (SELECT p.creation_date, 
            EXTRACT(WEEK FROM p.creation_date) AS num_week
     FROM stackoverflow.posts p
     WHERE p.user_id IN (SELECT user_id FROM res)
     AND DATE_TRUNC('month', p.creation_date) = '2008-10-01')

SELECT DISTINCT(r2.num_week),
       MAX(r2.creation_date) OVER (PARTITION BY num_week)
FROM res2 r2

