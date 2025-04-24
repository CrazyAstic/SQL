/* 1. Найдите количество вопросов, которые набрали больше 300 очков или как минимум 100 раз были добавлены в «Закладки».*/

SELECT COUNT(*)
FROM stackoverflow.posts
WHERE post_type_id = 1
AND score > 300;

/* 2. Сколько в среднем в день задавали вопросов с 1 по 18 ноября 2008 включительно? Результат округлите до целого числа.*/

WITH res AS
    (SELECT 
           CAST(creation_date AS date),
           COUNT(*) AS questions
    FROM stackoverflow.posts
    WHERE CAST(creation_date AS date) BETWEEN '2008-11-01' AND '2008-11-18'
    AND post_type_id = 1
    GROUP BY CAST(creation_date AS date)
    ORDER BY creation_date)

SELECT ROUND(AVG(questions))
FROM res;

/*3. Сколько пользователей получили значки сразу в день регистрации? Выведите количество уникальных пользователей.*/

SELECT COUNT(DISTINCT(u.id))
FROM stackoverflow.badges b
JOIN stackoverflow.users u ON b.user_id = u.id
WHERE CAST(u.creation_date AS date) = CAST(b.creation_date AS date)

/*4. Сколько уникальных постов пользователя с именем Joel Coehoorn получили хотя бы один голос?*/

SELECT COUNT(DISTINCT(p.id))
FROM stackoverflow.posts p
JOIN stackoverflow.users u ON u.id = p.user_id
JOIN stackoverflow.votes v ON p.id = v.post_id
WHERE display_name LIKE 'Joel Coehoorn'

/*5. Выгрузите все поля таблицы vote_types. Добавьте к таблице поле rank, в которое войдут номера записей в обратном порядке. Таблица должна быть отсортирована по полю id.*/

SELECT *,
       ROW_NUMBER() OVER (ORDER BY id DESC) AS rank
FROM stackoverflow.vote_types v
ORDER BY v.id

/*6. Отберите 10 пользователей, которые поставили больше всего голосов типа Close. Отобразите таблицу из двух полей: идентификатором пользователя и количеством голосов. Отсортируйте данные сначала по убыванию количества голосов, потом по убыванию значения идентификатора пользователя.*/

SELECT user_id,
       COUNT(*) amt
FROM stackoverflow.votes v
WHERE v.vote_type_id IN (SELECT id FROM stackoverflow.vote_types vt WHERE vt.name LIKE 'Close')
GROUP BY user_id
ORDER BY amt DESC, user_id DESC
LIMIT 10

/*7. Отберите 10 пользователей по количеству значков, полученных в период с 15 ноября по 15 декабря 2008 года включительно.
Отобразите несколько полей:
идентификатор пользователя;
число значков;
место в рейтинге — чем больше значков, тем выше рейтинг.
Пользователям, которые набрали одинаковое количество значков, присвойте одно и то же место в рейтинге.
Отсортируйте записи по количеству значков по убыванию, а затем по возрастанию значения идентификатора пользователя.*/

WITH res AS
    (SELECT
           user_id,
           COUNT(id) amt
FROM stackoverflow.badges b
WHERE CAST(creation_date AS date) BETWEEN '2008-11-15' AND '2008-12-15'
GROUP BY user_id
ORDER BY amt DESC, user_id ASC
LIMIT 10)

SELECT *,
       DENSE_RANK() OVER (ORDER BY amt DESC)
FROM res

/*8. Сколько в среднем очков получает пост каждого пользователя?
Сформируйте таблицу из следующих полей:
заголовок поста;
идентификатор пользователя;
число очков поста;
среднее число очков пользователя за пост, округлённое до целого числа.
Не учитывайте посты без заголовка, а также те, что набрали ноль очков.*/

SELECT p.title,
       p.user_id,
       p.score,
       ROUND(AVG(p.score) OVER (PARTITION BY user_id))
FROM stackoverflow.posts p
WHERE p.title IS NOT NULL
AND p.score != 0

/*9. Отобразите заголовки постов, которые были написаны пользователями, получившими более 1000 значков. Посты без заголовков не должны попасть в список.*/

WITH res AS
    (SELECT
           user_id, 
           COUNT(b.id)
FROM stackoverflow.badges b
GROUP BY user_id
HAVING COUNT(b.id) > 1000)

SELECT p.title
FROM stackoverflow.posts p
WHERE p.user_id in (SELECT user_id FROM res)
AND p.title IS NOT NULL

/*10. Напишите запрос, который выгрузит данные о пользователях из Канады (англ. Canada). Разделите пользователей на три группы в зависимости от количества просмотров их профилей:
пользователям с числом просмотров больше либо равным 350 присвойте группу 1;
пользователям с числом просмотров меньше 350, но больше либо равно 100 — группу 2;
пользователям с числом просмотров меньше 100 — группу 3.
Отобразите в итоговой таблице идентификатор пользователя, количество просмотров профиля и группу. Пользователи с количеством просмотров меньше либо равным нулю не должны войти в итоговую таблицу.*/

SELECT id,
       views,
       CASE
           WHEN views >= 350 THEN 1
           WHEN views < 350 AND views>= 100 THEN 2
           WHEN views < 100 THEN 3
       END AS group_num
FROM stackoverflow.users
WHERE location LIKE '%Canada%'
AND views > 0

/*11. Дополните предыдущий запрос. Отобразите лидеров каждой группы — пользователей, которые набрали максимальное число просмотров в своей группе. Выведите поля с идентификатором пользователя, группой и количеством просмотров. Отсортируйте таблицу по убыванию просмотров, а затем по возрастанию значения идентификатора.*/

WITH res1 AS
    (SELECT id,
            views,
            CASE
                WHEN views >= 350 THEN 1
                WHEN views < 350 AND views>= 100 THEN 2
                WHEN views < 100 THEN 3
            END AS group_num
FROM stackoverflow.users
WHERE location LIKE '%Canada%'
AND views > 0),

res2 AS
    (SELECT 
           DISTINCT(r.group_num),
           MAX(r.views) OVER (PARTITION BY r.group_num) group_max_views
     FROM res1 r)

SELECT id,
       r1.group_num,
       views
FROM res1 r1
JOIN res2 r2 ON r1.group_num = r2.group_num
WHERE r1.group_num = r2.group_num AND r1.views = r2.group_max_views
ORDER BY views DESC, id ASC

/*12. Посчитайте ежедневный прирост новых пользователей в ноябре 2008 года. Сформируйте таблицу с полями:
номер дня;
число пользователей, зарегистрированных в этот день;
сумму пользователей с накоплением.*/

WITH res AS
    (SELECT EXTRACT(DAY FROM CAST(u.creation_date AS date)) AS day_of_period,
            COUNT(u.id) AS count_users
     FROM stackoverflow.users u
     WHERE DATE_TRUNC('month', CAST(u.creation_date AS date)) = '2008-11-01'
     GROUP BY EXTRACT(DAY FROM CAST(u.creation_date AS date))
     ORDER BY day_of_period)

SELECT *,
       SUM(count_users) OVER (ORDER BY day_of_period)
FROM res

/*13. Для каждого пользователя, который написал хотя бы один пост, найдите интервал между регистрацией и временем создания первого поста. Отобразите:
идентификатор пользователя;
разницу во времени между регистрацией и первым постом.*/

WITH res1 AS
    (SELECT u.id,
            u.creation_date
     FROM stackoverflow.users u),

res2 AS
    (SELECT p.user_id,
            MIN(p.creation_date)
     FROM stackoverflow.posts p
     GROUP BY p.user_id)

SELECT 
       r1.id AS user_id,
       r2.min - r1.creation_date AS date_range
FROM res1 r1
JOIN res2 r2 ON r1.id = r2.user_id
