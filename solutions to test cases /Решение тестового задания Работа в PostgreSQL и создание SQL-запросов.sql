/*
Задача 1.
Необходимо получить список сотрудников в формате: «Иванова — Наталья – Юрьевна». ФИО должно быть прописано в одном столбике, разделение —.
Вывести: новое поле, назовем его fio, birth_dt.
*/

-- Решение Задачи 1.

select
    concat(last_nm, '—', first_nm, '—', middle_nm) as fio
    birth_dt
from employees
order by last_nm;

/*
Задача 2
Вывести %% дозвона для каждого дня. Период с 01.10.2020 по текущий день (%% дозвона – это доля принятых звонков (dozv_flg=1) от всех поступивших звонков (dozv_flg = 1 or dozv_flg = 0)).
Вывести: date, sla (%% дозвона)
*/

-- Решение Задачи 2.

select
    date(start_dttm) as date,
    (count(*) filter (where dozv_flg=1)) :: numeric / (count(*) filter (where dozv_flg in (0,1)) as sla
from calls
where date >= '2020-10-01' and dozv_flg is not null
group by date
order by date;

/*
Задача 3.
Дана таблица clients:
id клиента
calendar_at - дата входа в мобильное приложение
Нужно написать запрос для расчета MAU.
*/

-- Решение Задачи 3.

with cte as (
    select
        date_trunc('month', calendar_at),
        count(distinct id) as cnt
    from clients
    group by date_trunc('month', calendar_at)
)
select avg(cnt)
from cte;

