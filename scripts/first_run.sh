#!/bin/bash
USER=${POSTGRES_USERNAME:-pgadmin}
PASS=${POSTGRES_PASSWORD:-$(pwgen -s -1 16)}
DB=${POSTGRES_DBNAME:-}
EXTENSIONS=${POSTGRES_EXTENSIONS:-}
DATA_DIR=/data/postgres

cd /var/lib/postgresql
# Start PostgreSQL service
sudo -u postgres /usr/lib/postgresql/9.4/bin/postgres -D $DATA_DIR &

while ! sudo -u postgres psql -q -c "select true;"; do sleep 1; done

# Create user
echo "Creating user: \"$USER\"..."
sudo -u postgres psql -q -c "DROP ROLE IF EXISTS \"$USER\";"
sudo -u postgres psql -q <<-EOF
    CREATE ROLE "$USER" WITH ENCRYPTED PASSWORD '$PASS';
    ALTER ROLE "$USER" WITH ENCRYPTED PASSWORD '$PASS';
    ALTER ROLE "$USER" WITH LOGIN;
EOF

sudo -u postgres psql -q -c "ALTER USER \"$USER\" WITH NOSUPERUSER;"

# Create dabatase
if [ ! -z "$DB" ]; then
    echo "Creating database: \"$DB\"..."
    sudo -u postgres psql -q <<-EOF
    CREATE DATABASE "$DB" WITH OWNER="$USER" ENCODING='UTF8';
    GRANT ALL ON DATABASE "$DB" TO "$USER"
EOF

    if [[ ! -z "$EXTENSIONS" ]]; then
        for extension in $EXTENSIONS; do
            echo "Installing extension \"$extension\" for database \"$DB\"..."
            sudo -u postgres psql -q "$DB" -c "CREATE EXTENSION \"$extension\";"
        done
    fi
fi

# Stop PostgreSQL service
sudo -u postgres /usr/lib/postgresql/9.4/bin/pg_ctl stop -m fast -w -D $DATA_DIR

echo "========================================================================"
echo "PostgreSQL User: \"$USER\""
echo "PostgreSQL Password: \"$PASS\""
if [ ! -z $DB ]; then
    echo "PostgreSQL Database: \"$DB\""
    if [[ ! -z "$EXTENSIONS" ]]; then
        echo "PostgreSQL Extensions: \"$EXTENSIONS\""
    fi
fi
echo "========================================================================"

rm -f /.firstrun
