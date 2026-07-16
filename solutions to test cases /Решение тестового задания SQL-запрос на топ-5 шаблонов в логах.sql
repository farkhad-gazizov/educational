/*
Задание
Вопросы по заданию
Вы — аналитик данных. Руководитель дал вам задание поработать с таблицей logs действий пользователей (user_id, event, event_time, value). Действия пользователей поделены на сессии - последовательности событий, в которых между соседними по времени событиями промежуток не более 5 минут. Т.е. длина всей сессии может быть гораздо больше 5 минут, но между каждыми последовательными событиями не должно быть более 5 минут.
Поле event может принимать разные значения, в том числе ’template_selected’ (пользователь выбрал некий шаблон). В случае, если event=’template_selected’, то в value записано название этого шаблона (например, ’pop_art_style’).

Задача
Напишите SQL-запрос, выводящий 5 шаблонов, которые чаще всего применяются юзерами 2 и более раза подряд в течение одной сессии.
*/


with session_starts as (
    select
        user_id,
        event_time,
        event,          -- <-- нужно для фильтрации
        value,          -- <-- нужно для определения шаблона
        case 
            when lag(event_time) over (partition by user_id order by event_time) is null 
                 or strftime('%s', event_time) - strftime('%s', lag(event_time) over (partition by user_id order by event_time)) > 300
            then 1
            else 0
        end as is_new_session
    from logs
),
sessionized as (
    select
        user_id,
        event_time,
        event,
        value,
        sum(is_new_session) over (partition by user_id order by event_time) as session_id
    from session_starts
),
numbered_events as (
    select
        user_id,
        session_id,
        event_time,
        event,
        value,
        row_number() over (partition by user_id, session_id order by event_time) as event_number
    from sessionized
),
groups as (
    select
        user_id,
        session_id,
        event_time,
        event,
        value,
        case
            -- Начало новой группы, если:
            when event_number = 1  -- первое событие в сессии
                 or event != 'template_selected'  -- текущее событие не template_selected
                 or lag(event) over (partition by user_id, session_id order by event_number) != 'template_selected'  -- предыдущее было не template_selected
                 or lag(value) over (partition by user_id, session_id order by event_number) != value  -- изменился шаблон
            then 1
            else 0
        end as is_new_group
    from numbered_events
),
grouped as (
    select
        user_id,
        session_id,
        event_number,
        event,
        value,
        sum(is_new_group) over (partition by user_id, session_id order by event_number) as group_id
    from groups
),
valid_groups as (
    select
        user_id,
        session_id,
        group_id,
        value,
        count(*) as events_in_group
    from grouped
    where event = 'template_selected'
    group by user_id, session_id, group_id, value
    having count(*) >= 2
)
select
    value as template_name,
    count(*) as usage_count
from valid_groups
group by value
order by usage_count desc
limit 5;
