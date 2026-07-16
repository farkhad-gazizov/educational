/*
Задание
Вопросы по заданию
Вы получили SQLite3 базу данных со случайной выборкой из free-to-play игры «Мир Кораблей». Выполните задания ниже, используя любые инструменты для анализа и визуализации данных на ваше усмотрение.

Исходные данные
Таблица arenas
Характеристики боя (режим, карта, длительность и т.п.)

Таблица arena_members
Данные по пользователям в сыгранных боях: техника игрока, успехи в бою и т.п. Отрицательные значения ID игроков соответствуют ботам.

Таблица glossary_ships
Словарь для расшифровки техники.

Таблица catalog_items
Словарь для расшифровки других игровых сущностей (например, игрового режима).

Задание 1
Определите топ 5% игроков по суммарному урону за все бои. Запрос должен возвращать таблицу

Задание 2
Для каждого игрока из задания 1 определите корабль, на котором он нанес больше всего урона за все бои. Ограничьте выгрузку 10-ю лучшими результатами. Запрос должен возвращать таблицу
*/

Задание 1.

with player_damage as (
    select
        account_db_id,
        sum(damage) as total_damage
    from arena_members
    where account_db_id > 0
    group by account_db_id
),
ranked as (
    select
        account_db_id,
        total_damage,
        row_number() over (order by total_damage desc) as rn,
	count(distinct account_db_id) as total_players
    from player_damage
)
select
    account_db_id,
    total_damage
from ranked
where rn <= cast(0.05 * total_players as integer)
order by total_damage desc;


Задание 2.

with player_damage as (
    select
        account_db_id,
        sum(damage) as total_damage
    from arena_members
    where account_db_id > 0
    group by account_db_id
),
ranked_players as (
    select
        account_db_id,
        total_damage,
        row_number() over (order by total_damage desc) as rn,
	count(distinct account_db_id) as total_players
    from player_damage
),
top_players as (
    select
        account_db_id
    from ranked_players 
    where rn <= cast(0.05 * total_players as integer)
    order by total_damage desc
),
player_ship_damage as (
    select
        am.account_db_id,
        gs.ship_name,
        sum(am.damage) as dealt_damage
    from arena_members am
    join glossary_ships gs on am.vehicle_type_id = gs.vehicle_type_id
    where am.account_db_id in (select account_db_id from top_players)
    group by am.account_db_id, gs.ship_name
),
best_ship_per_player as (
    select
        account_db_id,
        ship_name,
        dealt_damage,
        row_number() over (partition by account_db_id order by dealt_damage desc) as ship_rank
    from player_ship_damage
)
select
    account_db_id,
    ship_name,
    dealt_damage
from best_ship_per_player
where ship_rank = 1
order by dealt_damage desc
limit 10;
