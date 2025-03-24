#set text(
  font: "Times New Roman",
  size: 14pt
)
#set quote(block: true)

#align(center)[Министерство науки и высшего образования Российской Федерации]
#align(center)[Федеральное государственное автономное образовательное учреждение]
#align(center)[Высшего образования]
#align(center)[_Факультет Программной Инженерии и Компьютерной Техники_]

#v(8em)

#align(center)[*Лабораторная работа 2 по РСХД*]
#align(center)[Кластер PostgreSQL]
#align(center)[Вариант 39455]

#v(8em)

#align(right)[Группа: P3316]
#align(right)[Выполнили:]
#align(right)[Сиразетдинов, Шпинева]
#align(right)[Проверил:]
#align(right)[Николаев В.В.]

#v(8em)

#align(center)[г. Санкт-Петербург]
#align(center)[2025]

#pagebreak()

= Задание

== Цель работы

Цель работы - на выделенном узле создать и сконфигурировать новый кластер БД Postgres, саму БД,
табличные пространства и новую роль, а также произвести наполнение базы в соответствии с заданием.

Отчёт по работе должен содержать все команды по настройке, скрипты, а также измененные строки конфигурационных файлов.

Способ подключения к узлу из сети Интернет через helios:
```sh
ssh -J sXXXXXX\@helios.cs.ifmo.ru:2222 postgresY\@pgZZZ
```
== Способ подключения к узлу из сети факультета:

```sh
ssh postgresY\@pgZZZ
```
Номер выделенного узла pgZZZ, а также логин и пароль для подключения Вам выдаст преподаватель.

== Этап 1. Инициализация кластера БД

- Директория кластера: ```\$HOME/djs10```
- Кодировка: ANSI1251
- Локаль: русская

Параметры инициализации задать через переменные окружения

== Этап 2. Конфигурация и запуск сервера БД

Способы подключения:

+ Unix-domain сокет в режиме peer;

+ сокет TCP/IP, принимать подключения к любому IP-адресу узла

Номер порта: 9455

Способ аутентификации TCP/IP клиентов: по паролю в открытом виде

Остальные способы подключений запретить.

Настроить следующие параметры сервера БД:
```
max_connections
shared_buffers
temp_buffers
work_mem
checkpoint_timeout
effective_cache_size
fsync
commit_delay
```

Параметры должны быть подобраны в соответствии со сценарием OLTP:

1500 транзакций в секунду размером 16КБ; обеспечить высокую доступность (High Availability) данных.

Директория WAL файлов: \$HOME/zkw63

Формат лог-файлов: .csv

Уровень сообщений лога: ERROR

Дополнительно логировать: завершение сессий и продолжительность выполнения команд

== Этап 3. Дополнительные табличные пространства и наполнение базы

- Создать новые табличные пространства для временных объектов: \$HOME/cje38, \$HOME/qdx64
- На основе template0 создать новую базу: leftbrownmom
- Создать новую роль, предоставить необходимые права, разрешить подключение к базе.
- От имени новой роли (не администратора) произвести наполнение ВСЕХ созданных баз тестовыми наборами данных. ВСЕ табличные пространства должны использоваться по назначению.
- Вывести список всех табличных пространств кластера и содержащиеся в них объекты

#pagebreak()

= Выполнение

== Этап 1. Инициализация кластера

```sh
PGDATA=$HOME/u08/djs10
PGLOCALE=ru_RU.CP1251
PGENCODE=WIN1251
PGUSERNAME=postgres0
PGHOST=pg109
export PGDATA PGLOCALE PGENCODE PGUSERNAME PGHOST

mkdir -p $PGDATA

initdb --locale=$PGLOCALE --encoding=$PGENCODE --username=$PGUSERNAME
```

#image("imgs/init.png")

```sh
pg_ctl -D /var/db/postgres0/u08/djs10 -l logfile start
```

#image("imgs/init2.png")

== Этап 2. Конфигурация и запуск сервера БД

=== Конфигурация pg_hba.conf
+ Способы подключения
    - Unix-domain сокет в режиме peer;

    - сокет TCP/IP, принимать подключения к любому IP-адресу узла

+ Способ аутентификации TCP/IP клиентов: по паролю в открытом виде

+ Остальные способы подключений запретить.
```conf
# "local" is for Unix domain socket connections only
local   all             all                                     peer
# IPv4 local connections:
host    all             all             0.0.0.0/0            password
```

=== Конфигурация posrgresql.conf

- Номер порта: 9455

```conf
port = 9455
```

- Настроить следующие параметры сервера БД:
    - max_connections
    - shared_buffers
    - temp_buffers
    - work_mem
    - checkpoint_timeout
    - effective_cache_size
    - fsync
    - commit_delay

Параметры должны быть подобраны в соответствии со сценарием OLTP:
  1500 транзакций в секунду размером 16КБ; обеспечить высокую доступность (High Availability) данных

- max_connections
```conf
max_connections = 2000
```

Для поддержки 1500 TPS нам нужно как минимум 1500 открытых соединений. Я взял с запасом в 500 соединений, чтобы
был запас для открытых транзакций в пуле соединения

- shared_buffers

```conf
shared_buffers = 2GB
```

#quote(attribution: [Документация])[Если вы используете выделенный сервер с объёмом ОЗУ 1 ГБ и более, разумным начальным значением shared_buffers
будет 25% от объёма памяти. Существуют варианты нагрузки, при которых эффективны будут и ещё большие значения
shared_buffers, но так как PostgreSQL использует и кеш операционной системы, выделять для shared_buffers более 40% ОЗУ
вряд ли будет полезно. При увеличении shared_buffers обычно требуется соответственно увеличить max_wal_size,
чтобы растянуть процесс записи большого объёма новых или изменённых данных на более продолжительное время.]

Для значения shared_buffers возьмем 25% от доступной памяти

- temp_buffers

```conf
temp_buffers = 8MB
```
В нашем сервисе транзакции имеют небольшой размер - так что стандартного значения будет достаточно

#quote(attribution: [Документация])[Задаёт максимальное число временных буферов для каждого сеанса, По умолчанию
объём временных буферов составляет
восемь мегабайт (1024 буфера). Этот параметр можно изменить в отдельном сеансе, но только до первого обращения к
временным таблицам; после этого изменить его значение для текущего сеанса не удастся.]

- work_mem

Если мы предположим что у нас 1500 TPS размером 16КБ, которые будут созданы в одном соединении то
16КБ \* 1500 = 24Мб

округлив получим
```conf
work_mem = 32MB
```

- checkpoint_timeout

#quote(attribution: [Документация])[Уменьшение значений checkpoint_timeout и/или max_wal_size приводит к учащению
контрольных точек. Это позволяет ускорить восстановление после краха (поскольку для воспроизведения нужно меньше данных),
но с другой стороны нужно учитывать дополнительную нагрузку, возникающую вследствие более частого сброса «грязных»
страниц данных на диск]

Для высокой доступности уменьшим число в 2 раза до 2 минут

```conf
checkpoint_timeout = 2min
```

- effective_cache_size

#quote(attribution: [Документация])[Определяет представление планировщика об эффективном размере дискового кеша,
доступном для одного запроса. Это представление влияет на оценку стоимости использования индекса; чем выше это значение,
тем больше вероятность, что будет применяться сканирование по индексу, чем ниже, тем более вероятно, что будет выбрано
последовательное сканирование.]

Для высокой доступности надо увеличить кеш чтобы больше операций использовали индекс

```conf
effective_cache_size = 8GB
```

- fsync
#quote(attribution: [Документация])[Если этот параметр установлен, сервер PostgreSQL старается добиться, чтобы изменения
были записаны на диск физически, выполняя системные вызовы fsync() или другими подобными методами (см. wal_sync_method).
Это даёт гарантию, что кластер баз данных сможет вернуться в согласованное состояние после сбоя оборудования или
операционной системы.]

Для повышения надежности нам следует оставить значение - true

```conf
fsync = on
```

- commit_delay

#quote(attribution: [Документация])[Параметр commit_delay добавляет паузу (в микросекундах) перед собственно
выполнением сохранения WAL. Эта задержка может увеличить быстродействие при фиксировании множества транзакций,
позволяя зафиксировать большее число транзакций за одну операцию сохранения WAL, если система нагружена достаточно
сильно и за заданное время успевают зафиксироваться другие транзакции.]

Чтобы увеличить доступность установим значение в 10 мс

```conf
commit_delay = 10
```

- Формат лог-файлов: .csv

```conf
log_destination = 'csvlog'
```
#quote(attribution: [Документация])[В качестве значения log_destination указывается один или несколько методов
протоколирования, разделённых запятыми. По умолчанию используется stderr. Если в log_destination включено значение
csvlog, то протоколирование ведётся в формате CSV (разделённые запятыми значения).]

```conf
logging_collector = on
```
#quote(attribution: [Документация])[Параметр включает сборщик сообщений. Это фоновый процесс, который собирает
отправленные в stderr сообщения и перенаправляет их в журнальные файлы. Такой подход зачастую более полезен чем запись
в syslog, поскольку некоторые сообщения в syslog могут не попасть. (Типичный пример с сообщениями об ошибках
динамического связывания, другой пример — ошибки в скриптах типа archive_command.)]

```conf
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
```
#quote(attribution: [Документация])[При включённом logging_collector задаёт имена журнальных файлов. Значение по
умолчанию postgresql-%Y-%m-%d\_%H%M%S.log. Если в log_destination включён вывод в формате CSV, то к имени журнального
файла будет добавлено расширение .csv. (Если log_filename заканчивается на .log, то это расширение заменится на .csv.)]

- Уровень сообщений лога: ERROR

```conf
log_min_messages = error
```
#quote(attribution: [Документация])[Управляет минимальным уровнем сообщений, записываемых в журнал сервера. Допустимые
значения DEBUG5, DEBUG4, DEBUG3, DEBUG2, DEBUG1, INFO, NOTICE, WARNING, ERROR, LOG, FATAL и PANIC. Каждый из
перечисленных уровней включает все идущие после него. Чем дальше в этом списке уровень сообщения, тем меньше сообщений
будет записано в журнал сервера. По умолчанию используется WARNING.]

- Дополнительно логировать: завершение сессий и продолжительность выполнения команд

```conf
log_disconnections = on
log_duration = on
```

Включаем протоколирование завершения сеанса и продолжительность каждой завершённой команды.

== Этап 3. Дополнительные табличные пространства и наполнение базы

- Создать новые табличные пространства для временных объектов: \$HOME/cje38, \$HOME/qdx64
```sh
mkdir -p $HOME/cje38
mkdir -p $HOME/qdx64

psql -h localhost -p 9455 -U postgres0 -d postgres
```
```sql
CREATE TABLESPACE cje38 LOCATION '/var/db/postgres0/cje38';
CREATE TABLESPACE qdx64 LOCATION '/var/db/postgres0/qdx64';
```
#image("imgs/img.png")
- На основе template0 создать новую базу: leftbrownmom

```sql
CREATE DATABASE leftbrownmom WITH TEMPLATE=template0;
```
#image("imgs/img_1.png")

- Создать новую роль, предоставить необходимые права, разрешить подключение к базе.
```sql
CREATE ROLE new_user WITH LOGIN PASSWORD 'password123!';
GRANT CONNECT ON DATABASE leftbrownmom TO new_user;
```

- От имени новой роли (не администратора) произвести наполнение ВСЕХ созданных баз тестовыми наборами данных. ВСЕ т
абличные пространства должны использоваться по назначению.
Созданная роль без выданных прав:
#image("imgs/img_2.png")

```sh
psql -h localhost -p 9455 -U postgres0 -d leftbrownmom
```
```sql
GRANT ALL PRIVILEGES ON SCHEMA public TO new_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO new_user;
GRANT CREATE ON TABLESPACE cje38, qdx64 TO new_user;
```
```sh
psql -h localhost -p 9455 -U new_user -d leftbrownmom
```

Срипт наполнения данными:
```sql
CREATE TABLE test_table1 (
    id SERIAL PRIMARY KEY,
    data TEXT
) TABLESPACE cje38;

CREATE TABLE test_table2 (
    id SERIAL PRIMARY KEY,
    data TEXT
) TABLESPACE qdx64;

INSERT INTO test_table1 (data) VALUES ('Test data 1'), ('Test data 2');
INSERT INTO test_table2 (data) VALUES ('Test data 3'), ('Test data 4');

CREATE TEMP TABLE test_temp_table1 (
                             id SERIAL PRIMARY KEY,
                             data TEXT
) TABLESPACE cje38;

CREATE TEMP TABLE test_temp_table2 (
                             id SERIAL PRIMARY KEY,
                             data TEXT
) TABLESPACE qdx64;

INSERT INTO test_temp_table1 (data) VALUES ('Test data 1'), ('Test data 2');
INSERT INTO test_temp_table2 (data) VALUES ('Test data 3'), ('Test data 4');
```
Расположение таблиц по схемам:
```sql
SELECT
    n.nspname AS schema_name,
    c.relname AS table_name
FROM
    pg_class c
JOIN
    pg_namespace n ON c.relnamespace = n.oid
WHERE
    c.relkind = 'r'
    AND n.nspname != 'pg_catalog'
    AND n.nspname != 'information_schema'
ORDER BY
    schema_name, table_name;
```
#image("imgs/img_6.png")

- Вывести список всех табличных пространств кластера и содержащиеся в них объекты
Список табличных простарнств:
```sql
SELECT spcname AS tablespace_name, pg_tablespace_location(oid) AS location
FROM pg_tablespace;
```
#image("imgs/img_3.png")

```sql
SELECT relname AS table_name, spcname AS tablespace_name
FROM pg_class
JOIN pg_tablespace ON pg_class.reltablespace = pg_tablespace.oid
WHERE relkind = 'r';
```
Только таблицы:
#image("imgs/img_7.png")

Все объекты:
#image("imgs/img_4.png")
#image("imgs/img_8.png")

```sql
WITH space AS (
SELECT
    COALESCE(t.spcname, 'pg_default') AS spcname,
    c.relname,
    ROW_NUMBER() OVER (PARTITION BY COALESCE(t.spcname, 'pg_default') ORDER BY c.relname) AS rn
  FROM pg_tablespace t
  FULL JOIN pg_class c ON c.reltablespace = t.oid
  ORDER BY spcname, c.relname
)
SELECT
  CASE WHEN rn = 1 THEN spcname ELSE NULL END AS spcname,
  relname
FROM space;
```
#image("imgs/img_10.png")
#image("imgs/img_11.png")
== Вывод
В ходе выполнения лабораторной работы был создан и сконфигурирован кластер БД на выделенном узле, мы познакомились с
различными вариантами конфигурации. Также была создана БД, новая роль, табличные пространства и заполнение тестовыми
данными.
