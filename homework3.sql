--Практическое задание по теме «Соединения таблиц и подзапросы»
--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Выведите для каждого покупателя его адрес проживания, город и страну проживания.
--В результирующей таблице должны быть следующие столбцы: Имя пользователя, фамилия пользователя, адрес, город, страна.
select 
	first_name, 
	last_name, 
	address, 
	city, 
	country
from customer c
join address a on c.address_id = a.address_id 
join city c2 on a.city_id = c2.city_id 
join country c3 on c2.country_id = c3.country_id ;

--ЗАДАНИЕ №2.1
--С помощью SQL-запроса посчитайте для каждого магазина количество его покупателей.
--В результирующей таблице должны быть следующие столбцы: Идентификатор магазина, количество прикрепленных пользователей.
select 
	s.store_id,
	count(customer_id)
from store s 
join customer c on s.store_id = c.store_id -- дипсик говорит лефт джойн, чтоб гарантированно вывести даже те магазины, у кот нет покупателей
group by s.store_id ;

--ЗАДАНИЕ №2.2
--Доработайте запрос и выведите только те магазины, 
--у которых количество покупателей больше 300-от.
--Для решения используйте фильтрацию по сгруппированным строкам с использованием функции агрегации.
--В результирующей таблице должны быть следующие столбцы: Идентификатор магазина, количество прикрепленных пользователей.
select 
	s.store_id, 
	count(customer_id)
from store s 
join customer c on s.store_id = c.store_id
group by s.store_id 
having count(customer_id) > 300 ;

--ЗАДАНИЕ №2.3
-- Доработайте запрос, добавив в него информацию о городе магазина, 
--а также фамилию и имя продавца, который работает в этом магазине.
--В результирующей таблице должны быть следующие столбцы: Фамилия и имя сотрудника в виде одного значения, идентификатор магазина, 
--город нахождения магазина, количество прикрепленных пользователей.
select 
	concat(s2.last_name, ' ', s2.first_name),
	s.store_id,
	c2.city,
	count(customer_id)
from store s 
join customer c on s.store_id = c.store_id
join address a on s.address_id = a.address_id 
join city c2 on a.city_id = c2.city_id 
join staff s2 on s.store_id = s2.store_id 
group by s2.staff_id, s.store_id, c2.city_id 
having count(customer_id) > 300 ;

--ЗАДАНИЕ №3
--Для каждого фильма посчитайте сколько раз его брали в прокат, при этом работать нужно только с теми фильмами, в которых снимались актрисы с именем Julia.
--В результирующей таблице должны быть следующие столбцы: Название фильма, количество аренд.
select 
	f.title, 
	count(distinct r.rental_id)
from film f
join inventory i on f.film_id = i.film_id 
join rental r on i.inventory_id = r.inventory_id 
where f.film_id in 
	(
	select distinct fa.film_id
	from film_actor fa
	join actor a on fa.actor_id = a.actor_id
	where a.first_name = 'JULIA'
	)
group by f.film_id ;

--ЗАДАНИЕ №4
--Посчитайте для каждого покупателя 4 аналитических показателя:
--  1. количество фильмов, которые он взял в аренду
--  2. общую стоимость платежей за аренду всех фильмов (значение округлите до целого числа)
--  3. минимальное значение платежа за аренду фильма
--  4. максимальное значение платежа за аренду фильма
--В результирующей таблице должны быть следующие столбцы: Фамилия и имя пользователя в виде одного значения, 
--количество арендованных фильмов, округленная сумма платежей, минимальный и максимальный платеж.
select
	concat(c.last_name, ' ', c.first_name),
	count(r.rental_id),
	round(sum(p.amount),0),
	concat(min(p.amount), ' - ', max(p.amount))	
from customer c
join rental r on c.customer_id = r.customer_id 
join payment p on r.rental_id = p.rental_id
group by c.customer_id, concat(c.first_name, ' ', c.last_name)
order by c.customer_id ;

--ЗАДАНИЕ №5
--Используя данные из таблицы городов, составьте все возможные пары городов так, чтобы 
--в результате не было пар с одинаковыми названиями городов. Решение должно быть через Декартово произведение.
--В результирующей таблице должны быть следующие столбцы: два столбца с названиями городов.

select c.city, c2.city
from city c, city c2
where c.city > c2.city ;

--ЗАДАНИЕ №6
--Выведите наиболее и наименее востребованные категории фильмов (те, которые арендовали наибольшее/наименьшее количество раз), количество аренд и сумму продаж.
--В результирующей таблице должны быть следующие столбцы: Название категории, количество аренд, сумма продаж.

(select 
	c.name, 
	count(r.rental_id), 
	sum(p.amount) 
from category c 
	join film_category fc on c.category_id = fc.category_id 
	join film f on fc.film_id = f.film_id 
	join inventory i on f.film_id = i.film_id 
	join rental r on i.inventory_id = r.inventory_id 
	join payment p on r.rental_id = p.rental_id 
group by c.category_id 
order by count(r.rental_id) desc
fetch first 1 rows with ties
)
union all
(select 
	c.name, 
	count(r.rental_id),
	sum(p.amount) 
from category c 
	join film_category fc on c.category_id = fc.category_id 
	join film f on fc.film_id = f.film_id 
	join inventory i on f.film_id = i.film_id 
	join rental r on i.inventory_id = r.inventory_id 
	join payment p on r.rental_id = p.rental_id 
group by c.category_id 
order by count(r.rental_id) asc
fetch first 1 rows with ties
) ;

--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Посчитайте для каждого фильма сколько раз его брали в аренду и значение общей стоимости аренды фильма за всё время.
--В результирующей таблице должны быть следующие столбцы: Название фильма, рейтинг фильма, язык фильма, категория фильма, 
--количество аренд фильма, общий размер платежей по фильму.
select 
	f.title, 
	f.rating, 
	l.name, 
	c.name, 
	coalesce(f1.rentcount, 0),
	coalesce(f1.paysum, 0)
from film f 
join "language" l on f.language_id = l.language_id 
join film_category fc on f.film_id = fc.film_id 
join category c on fc.category_id = c.category_id 
left join (
    	select 
        i.film_id,
        count (r.rental_id) as rentcount,
        sum (p.amount) as paysum
    	from rental r
    	join inventory i on r.inventory_id = i.inventory_id
    	join payment p on r.rental_id = p.rental_id
    	group by i.film_id
		) f1 on f.film_id = f1.film_id
order by f.film_id ;
		
--ЗАДАНИЕ №2
--Доработайте запрос из предыдущего задания и выведите с помощью него фильмы, которые отсутствуют на dvd дисках.
--В результирующей таблице должны быть следующие столбцы: Название фильма, рейтинг фильма, язык фильма, категория фильма, 
--количество аренд фильма, общий размер платежей по фильму.
select 
	f.title, 
	f.rating, 
	l.name, 
	c.name, 
	coalesce(f1.rentcount, 0),
	coalesce(f1.paysum, 0)
from film f 
join "language" l on f.language_id = l.language_id 
join film_category fc on f.film_id = fc.film_id 
join category c on fc.category_id = c.category_id 
left join (
    	select 
        i.film_id,
        count (r.rental_id) as rentcount,
        sum (p.amount) as paysum
    	from rental r
    	join inventory i on r.inventory_id = i.inventory_id
    	join payment p on r.rental_id = p.rental_id
    	group by i.film_id
		) f1 on f.film_id = f1.film_id
where not exists (
	select 1
	from inventory i
	where i.film_id = f.film_id
	)
order by f.film_id ;


--ЗАДАНИЕ №3
--Нужно сформировать массив из категорий фильмов и для каждого фильма вывести массив с индексами массива соответствующей категории
--В результирующей таблице должны быть следующие столбцы: Идентификатор фильма, название фильма, массив с индексами.


--ЗАДАНИЕ №4 (очень высокий уровень сложности)
--Определите первые две категории фильмов по каждому пользователю, которые они чаще всего берут в аренду. В виде строки выведите названия данных двух категорий по каждому пользователю.
--Использование оконных функций запрещено.
--В результирующей таблице должны быть следующие столбцы: Идентификатор пользователя, строка с названиями категорий.
