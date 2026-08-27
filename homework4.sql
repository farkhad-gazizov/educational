--=============== МОДУЛЬ 4. УГЛУБЛЕНИЕ В SQL =======================================
--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--База данных: если подключение к облачной базе, то создаёте новую схему с префиксом в 
--виде фамилии, название должно быть на латинице в нижнем регистре и таблицы создаете 
--в этой новой схеме, если подключение к локальному серверу, то создаёте новую схему и 
--в ней создаёте таблицы.

--Спроектируйте базу данных, содержащую три справочника:
--· язык (английский, французский и т. п.);
--· народность (славяне, англосаксы и т. п.);
--· страны (Россия, Германия и т. п.).
--Две таблицы со связями: язык-народность и народность-страна, отношения многие ко многим. 
-- Пример таблицы со связями — film_actor.
--Требования к таблицам-справочникам:
--· наличие ограничений первичных ключей.
--· идентификатору сущности должен присваиваться автоинкрементом;
--· наименования сущностей не должны содержать null-значения, не должны допускаться --дубликаты в названиях сущностей.
--Требования к таблицам со связями:
--· наличие ограничений первичных и внешних ключей.

--В качестве ответа на задание пришлите запросы создания таблиц и запросы по 
--добавлению в каждую таблицу по 5 строк с данными.
 -- 1. СПРАВОЧНИК ЯЗЫКОВ

--СОЗДАНИЕ ТАБЛИЦЫ ЯЗЫКИ
create table languages (
	languages_id serial2 primary key,
	languages_name varchar(50) not null unique) ; 

--ВНЕСЕНИЕ ДАННЫХ В ТАБЛИЦУ ЯЗЫКИ
insert into languages (languages_name)
values ('Русский'),('Английский'),('Испанский'),('Немецкий'),('Турецкий') ;

--СОЗДАНИЕ ТАБЛИЦЫ НАРОДНОСТИ
create table ethnicgroup (
	ethnicgroup_id serial2 primary key,
	ethnicgroup_name varchar(50) not null unique) ;
	
--ВНЕСЕНИЕ ДАННЫХ В ТАБЛИЦУ НАРОДНОСТИ
insert into ethnicgroup (ethnicgroup_name)
values ('славяне'),('англосаксы'),('романцы'),('германцы'),('тюрки') ;

--СОЗДАНИЕ ТАБЛИЦЫ СТРАНЫ
create table country (
	country_id serial2 primary key,
	country_name varchar(100) not null unique) ;


--ВНЕСЕНИЕ ДАННЫХ В ТАБЛИЦУ СТРАНЫ
insert into country (country_name)
values ('Россия'),('Великобритания'),('Испания'),('Германия'),('Турция') ;


--СОЗДАНИЕ ПЕРВОЙ ТАБЛИЦЫ СО СВЯЗЯМИ (язык-народность)
create table languages_ethnicgroup (
	languages_id int2 references languages(languages_id),
	ethnicgroup_id int2 references ethnicgroup(ethnicgroup_id),
	primary key (languages_id, ethnicgroup_id)) ;

--ВНЕСЕНИЕ ДАННЫХ В ТАБЛИЦУ СО СВЯЗЯМИ 
insert into languages_ethnicgroup (languages_id, ethnicgroup_id)
values (1,1),(2,2),(3,3),(4,4),(5,5) ;

--СОЗДАНИЕ ВТОРОЙ ТАБЛИЦЫ СО СВЯЗЯМИ (народность-страна)
create table ethnicgroup_country (
	ethnicgroup_id int2 references ethnicgroup(ethnicgroup_id),
	country_id int2 references country(country_id),
	primary key (ethnicgroup_id, country_id)) ;

--ВНЕСЕНИЕ ДАННЫХ В ТАБЛИЦУ СО СВЯЗЯМИ 
insert into ethnicgroup_country (ethnicgroup_id, country_id)
values (1,1),(2,2),(3,3),(4,4),(5,5) ;


--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============


--ЗАДАНИЕ №1 
--Создайте новую таблицу film_new со следующими полями:
--·   	film_name - название фильма - тип данных varchar(255) и ограничение not null
--·   	film_year - год выпуска фильма - тип данных integer, условие, что значение должно быть больше 0
--·   	film_rental_rate - стоимость аренды фильма - тип данных numeric(4,2), значение по умолчанию 0.99
--·   	film_duration - длительность фильма в минутах - тип данных integer, ограничение not null и условие, что значение должно быть больше 0
--Если работаете в облачной базе, то перед названием таблицы задайте наименование вашей схемы.
create table film_new (
	film_id serial2 primary key,
	film_name varchar (255) not null,
	film_year int check (film_year > 0),
	film_rental_rate numeric(4,2) default 0.99,
	film_duration int not null check ((film_duration) > 0)) ;


--ЗАДАНИЕ №2 
--Заполните таблицу film_new данными с помощью SQL-запроса, где колонкам соответствуют массивы данных:
--·       film_name - array['The Shawshank Redemption', 'The Green Mile', 'Back to the Future', 'Forrest Gump', 'Schindlers List']
--·       film_year - array[1994, 1999, 1985, 1994, 1993]
--·       film_rental_rate - array[2.99, 0.99, 1.99, 2.99, 3.99]
--·   	  film_duration - array[142, 189, 116, 142, 195]
insert into film_new (film_name, film_year, film_rental_rate, film_duration)
select
	unnest(array['The Shawshank Redemption', 'The Green Mile', 'Back to the Future', 'Forrest Gump', 'Schindlers List']),
	unnest(array[1994, 1999, 1985, 1994, 1993]),
	unnest(array[2.99, 0.99, 1.99, 2.99, 3.99]),
	unnest(array[142, 189, 116, 142, 195]) ;

--ЗАДАНИЕ №3
--Обновите стоимость аренды фильмов в таблице film_new с учетом информации, 
--что стоимость аренды всех фильмов поднялась на 1.41
update film_new 
set film_rental_rate = film_rental_rate + 1.41 ;

--ЗАДАНИЕ №4
--Фильм с названием "Back to the Future" был снят с аренды, 
--удалите строку с этим фильмом из таблицы film_new
delete from film_new
where film_name = 'Back to the Future' ; -- ЭТО ОШИБКА, НАДО УДАЛЯТЬ ЧЕРЕЗ АЙДИ ФИЛЬМА

--ЗАДАНИЕ №5
--Добавьте в таблицу film_new запись о любом другом новом фильме
insert into film_new (film_name, film_year, film_rental_rate, film_duration)
values ('Interstellar', 2014, 6.4, 169) ;

--ЗАДАНИЕ №6
--Напишите SQL-запрос, который выведет все колонки из таблицы film_new, 
--а также новую вычисляемую колонку "длительность фильма в часах", округлённую до десятых
select 
	film_name,
	film_year, 
	film_rental_rate, 
	film_duration,
	round(film_duration/60.0, 1) as film_duration_in_hour
from film_new ;

--ЗАДАНИЕ №7 
--Удалите таблицу film_new
drop table film_new ;


