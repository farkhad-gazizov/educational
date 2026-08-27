--=============== МОДУЛЬ 5. РАБОТА С POSTGRESQL =======================================
--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Сделайте запрос к таблице payment и с помощью оконных функций добавьте вычисляемые колонки согласно условиям:
--1.1 Пронумеруйте все платежи от 1 до N по дате платежа
--1.2 Пронумеруйте платежи для каждого покупателя, сортировка платежей должна быть по дате платежа
--1.3 Посчитайте нарастающим итогом сумму всех платежей для каждого покупателя, сортировка должна быть 
--сперва по дате платежа, а затем по размеру платежа от наименьшей к большей
--1.4 Пронумеруйте платежи для каждого покупателя по размеру платежа от наибольшего к меньшему так, 
--чтобы платежи с одинаковым значением имели одинаковое значение номера.
--В результирующей таблице должны быть следующие столбцы: Идентификатор платежа, дата платежа, 
--идентификатор пользователя, размер платежа, 4 столбца с результатами оконных функций.
select 
	payment_id,
	payment_date,
	customer_id,
	amount,
	row_number() over (order by payment_date),
	row_number() over (
		partition by customer_id 
		order by payment_date
		),
	sum(amount) over (
		partition by customer_id
		order by payment_date, amount
		rows unbounded preceding
		),
	dense_rank() over (
		partition by customer_id
		order by amount desc
		) 
from payment 
order by customer_id, payment_date ;

--ЗАДАНИЕ №2
--С помощью оконной функции выведите для каждого покупателя стоимость платежа и стоимость 
--платежа из предыдущей строки со значением по умолчанию 0.0 с сортировкой по дате платежа.
--В результирующей таблице должны быть следующие столбцы: Идентификатор платежа, дата платежа, 
--идентификатор пользователя, текущий размер платежа, размер платежа из предыдущей строки.
select
	payment_id,
	payment_date,
	customer_id,
	amount,
	lag(amount, 1, 0) over (partition by customer_id order by payment_date)
from payment ;

--ЗАДАНИЕ №3
--С помощью оконной функции определите, на сколько каждый следующий платеж покупателя больше или меньше текущего.
--В результирующей таблице должны быть следующие столбцы: Идентификатор платежа, дата платежа, идентификатор пользователя, 
--текущий размер платежа, следующий размер платежа, разница между текущим и следующим платежами.
select 
	payment_id,
	payment_date,
	customer_id,
	amount,
	coalesce(
		lead(amount) over (
		partition by customer_id
		order by payment_date), 0
		),
	coalesce((lead(amount) over (
		partition by customer_id
		order by payment_date) - amount), 0
		) as diff
from payment ;

--ЗАДАНИЕ №4
--С помощью оконной функции для каждого покупателя выведите данные о его последней оплате аренды.
--В результирующей таблице должны быть следующие столбцы: Все столбцы из таблицы с платежами.
select *
from (
	select *, row_number() over (partition by customer_id order by payment_date desc)
	from payment
	)
where row_number = 1 ;

--ЗАДАНИЕ №5
--Одним запросом ответить на два вопроса: в какой из месяцев было получено платежей на наибольшую сумму? 
--На какую сумму по отношению к предыдущему месяцу было сдано в аренду больше/меньше фильмов.
--Обязательное условие для выполнения задания: Таблица payment должна быть использована строго один раз. Если в топ 1 попадает несколько месяцев, 
--в результате должны быть все месяцы попавшие в топ 1. Топ 1 месяц получать через оконную функцию.
--В результирующей таблице должны быть следующие столбцы: Значение месяца, сумма за месяц, сумма за предыдущий месяц, разница между суммами.
with cte1 as (
	select 
        date_trunc('month', payment_date)::date as month,
        sum(amount) as total_month
    from payment
    group by month
),
cte2 as (
    select 
        month,
        total_month,
        lag(total_month) over (order by month) as total_prev_month,
        dense_rank() over (order by total_month desc) as rank_by_amount
    from cte1
)
select 
    month,
    total_month,
    coalesce(total_prev_month, 0) as total_prev_month,   
    coalesce(total_month - total_prev_month, total_month) as  diff
from cte2
where rank_by_amount = 1
order by month ;

--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--С помощью оконной функции выведите для каждого сотрудника сумму продаж за август 2005 года 
--с нарастающим итогом по каждому сотруднику и по каждой дате продажи (без учёта времени) 
--с сортировкой по дате.
--В результирующей таблице должны быть следующие столбцы: Фамилия и имя сотрудника в виде 
--одного значения, сумма продаж на каждый день, накопительный итог.
with cte1 as (
	select 
		concat(s.last_name, ' ', s.first_name) as staff_name,
		p.payment_date::date as pay_date, 
		sum(p.amount) as daily_amount
	from staff s
	join payment p on s.staff_id = p.staff_id
	where p.payment_date::date between '2005-08-01' and '2005-08-31'
	group by s.staff_id, p.payment_date
)
select 
	staff_name,
	daily_amount,
	sum(daily_amount) over (
		partition by staff_name
		order by pay_date
		rows unbounded preceding) -- ОШИБКА, см. записи и вебинар!!!
from cte1
order by staff_name, pay_date ;

--ЗАДАНИЕ №2
--20 августа 2005 года в магазинах проходила акция: покупатель каждого сотого платежа получал
--дополнительную скидку на следующую аренду. С помощью оконной функции выведите всех покупателей,
--которые в день проведения акции получили скидку
--В результирующей таблице должны быть следующие столбцы: Идентификатор пользователя, 
--фамилия и имя пользователя в виде одного значения.
with cte1 as (
	select
		p.customer_id as customer_id,
		concat(c.last_name, ' ', c.first_name) as customer_name,
		p.payment_date,
		row_number() over (partition by p.customer_id order by p.payment_date) as pay_number
	from payment p
	join customer c on p.customer_id = c.customer_id
),
cte2 as (
	select 
		customer_id,
		customer_name
	from cte1
	where payment_date::date = '2005-08-20' and pay_number = 100
)
select
	c1.customer_id,
	c1.customer_name
from cte1 c1
join cte2 c2 on c1.customer_id = c2.customer_id
where pay_number = 101 ;

--ЗАДАНИЕ №3
--Для каждой страны определите и выведите одним SQL-запросом покупателей, которые попадают под условия:
-- 1. покупатель, арендовавший наибольшее количество фильмов
-- 2. покупатель, арендовавший фильмов на самую большую сумму
-- 3. покупатель, который последним арендовал фильм
--В результирующей таблице должны быть следующие столбцы: Название страны, фамилия и имя пользователя в 
--виде одного значения лучшего по количеству, фамилия и имя пользователя в виде одного значения лучшего 
--по сумме платежей, фамилия и имя пользователя в виде одного значения последним арендовавшим фильм.
--Есть два варианта решения: получать одного случайного, если в топ 1 попадает несколько пользователей, 
--выводить всех пользователей, попавших в топ 1. Выбор варианта остается за вами.

with recursive r as (
    select '2022-02-01'::date as x
    union
    select x + 1
    from r
    where x < '2022-02-28')
select *
from r