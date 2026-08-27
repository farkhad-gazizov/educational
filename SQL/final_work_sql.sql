--Итоговый модуль по курсу «SQL и получение данных» 
--ЗАДАНИЯ
--1. Получите количество проектов, подписанных в 2023 году.
--В результат вывести одно значение количества.
select count(sign_date) 
from project
where sign_date >= date '2023-01-01'
	and sign_date < date '2024-01-01';

--2. Получите общий возраст сотрудников, нанятых в 2022 году.
--Результат вывести одним значением в виде "... years ... months ... days"
--Использование более 2х функций для работы с типом данных дата и время будет являться ошибкой.
select sum(age(current_date, p.birthdate))
from person p
join employee e on p.person_id = e.person_id 
where e.hire_date >= '2022-01-01'
	and e.hire_date < '2023-01-01' ;

--3. Получите сотрудников, у которого фамилия начинается на М, всего в фамилии 8 букв и который работает дольше других.
--Если таких сотрудников несколько, выведите одного случайного.
--В результат выведите два столбца, в первом должны быть имя и фамилия через пробел, во втором дата найма.
select 
	concat(p.first_name, ' ', p.last_name), 
	e.hire_date
from person p 
join employee e on p.person_id = e.person_id 
where
	p.last_name ilike 'М%'
	and length(p.last_name) = 8
	and e.dismissal_date is null
order by e.hire_date
limit 1 ;

--4. Получите среднее значение полных лет сотрудников, которые уволены и не задействованы на проектах.
--В результат вывести одно среднее значение. Если получаете null, то в результат нужно вывести 0.
select 
	coalesce(avg(extract(year from age(current_date, p.birthdate))), 0)
from employee e 
join person p on e.person_id = p.person_id
where e.dismissal_date is not null
	and not exists (
		select 1
		from project p2
		where e.employee_id = any(p2.employees_id)
			or e.employee_id = p2.project_manager_id
	) ;

--5. Чему равна сумма полученных платежей от контрагентов из Жуковский, Россия.
--В результат вывести одно значение суммы.
select sum(pp.amount)
from project_payment pp 
join project p on pp.project_id = p.project_id 
join customer c on p.customer_id = c.customer_id 
join address a on c.address_id = a.address_id 
join city c2 on a.city_id = c2.city_id 
join country c3 on c2.country_id = c3.country_id 
where 
	c3.country_name = 'Россия'
	and c2.city_name = 'Жуковский'
	and pp.fact_transaction_timestamp is not null ;

--6. Пусть руководитель проекта получает премию в 1% от стоимости завершенных проектов.
--Если взять завершенные проекты, какой руководитель проекта получит самый большой бонус?
--В результат нужно вывести идентификатор руководителя проекта, его ФИО и размер бонуса.
--Если таких руководителей несколько, предусмотреть вывод всех.
with cte as (
	select 
		project_manager_id, 
		sum(project_cost)*0.01 as bonus
	from project
	where status = 'Завершен'
	group by project_manager_id
)
select 
	c.project_manager_id, 
	p.full_fio, 
	c.bonus
from cte c
join employee e on c.project_manager_id = e.employee_id
join person p on e.person_id = p.person_id
where c.bonus = (
	select max(bonus)
	from cte
) ;

--7. Получите накопительный итог планируемых авансовых платежей на каждый месяц в отдельности.
--Выведите в результат те даты планируемых платежей, которые идут после преодаления накопительной суммой значения в 30 000 000
--Пример:
--дата		накопление
--2022-06-14	28362946.20
--2022-06-20	29633316.30
--2022-06-23	34237017.30
--2022-06-24	46248120.30
--В результат должна попасть дата 2022-06-23
with cte1 as (
	select 
		plan_payment_date,
		date_trunc('month', plan_payment_date) as months,
		sum(amount) over (
		partition by date_trunc('month', plan_payment_date)
		order by plan_payment_date
		) as cumul_total
	from project_payment
	where "payment_type" = 'Авансовый'
),
cte2 as (
	select 
		plan_payment_date,
		row_number() over (
		partition by months
		order by plan_payment_date
		) as rn
	from cte1 c1
	where c1.cumul_total > 30000000
)
select c2.plan_payment_date
from cte2 c2
where c2.rn = 1 ;

--8. Используя рекурсию посчитайте сумму фактических окладов сотрудников из структурного подразделения с id равным 17 и всех дочерних подразделений.
--В результат вывести одно значение суммы.
with recursive r as (
	select *, 0 as level
	from company_structure cs
	where unit_id = 17
	union
	select cs.*, level + 1 as level
	from r 
	join company_structure cs on r.unit_id = cs.parent_id 
	)
select sum(ep.salary * ep.rate)
from r
join "position" p on r.unit_id = p.unit_id 
join employee_position ep on p.position_id = ep.position_id ;

--9. Задание выполняется одним запросом.
--Сделайте сквозную нумерацию фактических платежей по проектам на каждый год в отдельности в порядке даты платежей.
--Получите платежи, сквозной номер которых кратен 5.
--Выведите скользящее среднее размеров платежей с шагом 2 строки назад и 2 строки вперед от текущей.
--Получите сумму скользящих средних значений.
--Получите сумму стоимости проектов на каждый год.
--Выведите в результат значение года (годов) и сумму проектов, где сумма проектов меньше, чем сумма скользящих средних значений.
with cte1 as (
	select 
		fact_transaction_timestamp,
		project_payment_id,
		amount,
		row_number() over (
			partition by date_trunc('year', fact_transaction_timestamp)
			order by fact_transaction_timestamp, project_payment_id
			) as rn
	from project_payment
	where fact_transaction_timestamp is not null
),
cte2 as (
	select 
		avg(amount) over (
			order by fact_transaction_timestamp, project_payment_id 
			rows between 2 preceding and 2 following
			) as slid_avg
	from cte1 c1
	where c1.rn % 5 = 0
),
cte3 as (
	select 
		sum(slid_avg) as total_slid_avg
	from cte2 c2
),
cte4 as (
	select 
		date_trunc('year', sign_date) as years,	
		sum(project_cost) as sum_project_cost 
	from project
	group by date_trunc('year', sign_date)
)
select 
	extract('year' from c4.years) as year,
	c4.sum_project_cost
from cte4 c4
cross join cte3 c3
where c4.sum_project_cost < c3.total_slid_avg ;

--10. Создайте материализованное представление, которое будет хранить отчет следующей структуры:
--идентификатор проекта
--название проекта
--дата последней фактической оплаты по проекту
--размер последней фактической оплаты
--ФИО руководителей проектов
--Названия контрагентов
--В виде строки названия типов работ по каждому контрагенту
create materialized view task1 as
select 
	pr.project_id,
	pr.project_name,
	pp.fact_transaction_timestamp,
	pp.amount,
	p.full_fio,
	c.customer_name,
	agg_tow.types_of_work
from project pr
join (
	select distinct on (project_id)
		project_id,
		fact_transaction_timestamp,
		amount
	from project_payment
	where fact_transaction_timestamp is not null
	order by 
		project_id, 
		fact_transaction_timestamp
		desc
) pp on pr.project_id = pp.project_id 
join employee e on pr.project_manager_id = e.employee_id
join person p on e.person_id = p.person_id
join customer c on pr.customer_id = c.customer_id 
join (
	select 
		ctow.customer_id,
		string_agg(distinct tow.type_of_work_name, ', ') as types_of_work
	from customer_type_of_work ctow
	join type_of_work tow on ctow.type_of_work_id = tow.type_of_work_id 
	group by ctow.customer_id 
	) agg_tow on c.customer_id = agg_tow.customer_id
order by pr.project_id ;






