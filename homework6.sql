--=============== МОДУЛЬ 6. POSTGRESQL =======================================
--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1.1
--Выведите для каждого сотрудника сведения о самой первой продаже этого сотрудника.
--Решение должно быть через оконную функцию.
--В результирующей таблице должны быть следующие столбцы:Все столбцы из таблицы с платежами.
select *
from (
	select *,
		row_number() over (partition by staff_id order by payment_date)
	from payment)
where row_number = 1 ;

--ЗАДАНИЕ №1.2
--Выведите для каждого сотрудника сведения о самой первой продаже этого сотрудника.
--Решение должно быть через агрегацию.
--В результирующей таблице должны быть следующие столбцы:Все столбцы из таблицы с платежами.
select *
from payment
where (staff_id, payment_date) in (
	select staff_id, min(payment_date)
	from payment
	group by staff_id) ;

--ЗАДАНИЕ №1.3
--Выведите для каждого сотрудника сведения о самой первой продаже этого сотрудника.
--Решение должно быть через distinct on.
--В результирующей таблице должны быть следующие столбцы:Все столбцы из таблицы с платежами.
select distinct on (staff_id) *
from payment 
order by staff_id, payment_date ;

--ЗАДАНИЕ №2
--Для каждого покупателя посчитайте сколько он брал в аренду фильмов 
--со специальным атрибутом "Behind the Scenes.
--Обязательное условие для выполнения задания: Должно быть использовано СТЕ в котором получаете нужные фильмы. В сте должна быть использована строго одна таблица.
--В результирующей таблице должны быть следующие столбцы: Фамилия и имя пользователя в виде одного значения, 
--количество арендованных фильмов.
with cte1 as (
	select film_id
	from film
	where 'Behind the Scenes' = any(special_features) -- вариант с any выбрал потому, что с ним тратится меньше ресурсов из 3х вариантов 2й домашки
)
select 
	concat(c.last_name, ' ', c.first_name),
	count(r.rental_id) 
from customer c 
join rental r on c.customer_id = r.customer_id 
join inventory i on r.inventory_id = i.inventory_id 
join cte1 c1 on i.film_id = c1.film_id
group by c.customer_id ;

--ЗАДАНИЕ №3
--Для каждого покупателя посчитайте сколько он брал в аренду фильмов
-- со специальным атрибутом "Behind the Scenes".
--Обязательное условие для выполнения задания: Должен быть использован подзапрос в котором получаете нужные фильмы. В подзапросе должна быть использована строго одна таблица.
--В результирующей таблице должны быть следующие столбцы: Фамилия и имя пользователя в виде одного значения, 
--количество арендованных фильмов.
select 
	concat(c.last_name, ' ', c.first_name),
	count(r.rental_id) 
from customer c 
join rental r on c.customer_id = r.customer_id 
join inventory i on r.inventory_id = i.inventory_id 
join (
	select film_id
	from film
	where 'Behind the Scenes' = any(special_features)
	) c1 on i.film_id = c1.film_id
group by c.customer_id ;

--ЗАДАНИЕ №4
--Создайте материализованное представление с запросом из задания №3
--и напишите запрос для обновления материализованного представления
create materialized view task1 as (
	select 
		concat(c.last_name, ' ', c.first_name),
		count(r.rental_id) 
	from customer c 
	join rental r on c.customer_id = r.customer_id 
	join inventory i on r.inventory_id = i.inventory_id 
	join (
		select film_id
		from film
		where 'Behind the Scenes' = any(special_features)
		) c1 on i.film_id = c1.film_id
	group by c.customer_id ) ;

select * -- проверка создания мат.представления
from task1

refresh materialized view task1 ;

--ЗАДАНИЕ №5
--С помощью explain analyze проведите анализ стоимости выполнения запросов из всех предыдущих заданий и ответьте на вопросы:
--1. какой вариант вычислений затрачивает меньше ресурсов системы: из задания 1.1, 1.2 или 1.3.
--2. какой вариант вычислений затрачивает меньше ресурсов системы: 
--с использованием CTE из 2 задания или с использованием подзапроса из 3 задания.
explain analyze -- 1922 / 8.5
select *
from (
	select *,
		row_number() over (partition by staff_id order by payment_date)
	from payment)
where row_number = 1 ;

explain analyze -- 724 / 4.8
select *
from payment
where (staff_id, payment_date) in (
	select staff_id, min(payment_date)
	from payment
	group by staff_id) ;

explain analyze -- 1481 / 13.8
select distinct on (staff_id) *
from payment 
order by staff_id, payment_date ;

explain analyze -- 380 / 1.9
with cte1 as (
	select film_id
	from film
	where 'Behind the Scenes' = any(special_features) -- вариант с any выбрал потому, что с ним тратится меньше ресурсов из 3х вариантов 2й домашки
)
select 
	concat(c.last_name, ' ', c.first_name),
	count(r.rental_id) 
from customer c 
join rental r on c.customer_id = r.customer_id 
join inventory i on r.inventory_id = i.inventory_id 
join cte1 c1 on i.film_id = c1.film_id
group by c.customer_id ;

explain analyze -- 380 / 2.0
select 
	concat(c.last_name, ' ', c.first_name),
	count(r.rental_id) 
from customer c 
join rental r on c.customer_id = r.customer_id 
join inventory i on r.inventory_id = i.inventory_id 
join (
	select film_id
	from film
	where 'Behind the Scenes' = any(special_features)
	) c1 on i.film_id = c1.film_id
group by c.customer_id ;


Ответ на вопрос №1: вариант с использованием агрегации через функцию min затрачивает меньше ресурсов системы
Ответ на вопрос №2: оба вариант затрачивают примерно равное количество ресурсов системы

--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Откройте по ссылке SQL-запрос: https://letsdocode.ru/sql-main/sql-hw5.sql
--Сделайте explain analyze этого запроса.
--Основываясь на описании запроса, найдите узкие места и опишите их.
--Сравните с вашим решением из 3 задания.
--Сделайте построчное описание explain analyze на русском языке оптимизированного запроса. 
--Описание строк в explain можно посмотреть по ссылке: https://use-the-index-luke.com/sql/explain-plan/postgresql/operations



--ЗАДАНИЕ №2
--Для каждого магазина определите и выведите одним SQL-запросом следующие аналитические показатели:
-- 1. день, в который арендовали больше всего фильмов (день в формате год-месяц-день)
-- 2. количество фильмов взятых в аренду в этот день
-- 3. день, в который продали фильмов на наименьшую сумму (день в формате год-месяц-день)
-- 4. сумму продажи в этот день
--В результирующей таблице должны быть следующие столбцы: Идентификатор магазина, день аренды, количество фильмов, день продажи, сумма продаж.



--ЗАДАНИЕ №3
--Создайте не наполненное материализованное представление, которое будет хранить отчёт следующей структуры:
--идентификатор сотрудника
--ФИО сотрудника в виде одной строки
--город проживания сотрудника
--идентификатор магазина
--город магазина
--дата последнего платежа, принятого сотрудником
--размер последнего платежа, принятого сотрудником
--общая сумма продаж
