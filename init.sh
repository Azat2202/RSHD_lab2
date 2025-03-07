PGDATA=$HOME/u08/djs10
PGLOCALE=ru_RU.CP1251
PGENCODE=WIN1251
PGUSERNAME=postgres0
PGHOST=pg109
export PGDATA PGLOCALE PGENCODE PGUSERNAME PGHOST

mkdir -p $PGDATA

initdb --locale=$PGLOCALE --encoding=$PGENCODE --username=$PGUSERNAME

pg_ctl -D /var/db/postgres0/u08/djs10 -l logfile start