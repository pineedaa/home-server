#!/bin/bash
set -e

# Convertir las cadenas de usuarios, contraseñas y bases de datos en arrays
IFS=',' read -r -a users <<< "$USERS"
IFS=',' read -r -a passwords <<< "$PASSWORDS"
IFS=',' read -r -a databases <<< "$DATABASES"

# Comprobar que las tres variables tienen el mismo número de elementos
if [ "${#users[@]}" -ne "${#passwords[@]}" ] || [ "${#users[@]}" -ne "${#databases[@]}" ]; then
    echo "Error: Las variables de entorno USERS, PASSWORDS y DATABASES deben tener el mismo número de elementos." >&2
    exit 1
fi

# Crear usuarios y bases de datos
for i in "${!users[@]}"; do
    user="${users[$i]}"
    password="${passwords[$i]}"
    database="${databases[$i]}"

    # Crear el usuario si no existe
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
        DO \$\$
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '$user') THEN
                CREATE USER $user WITH PASSWORD '$password';
            END IF;
        END
        \$\$;
EOSQL

    # Verificar si la base de datos existe
    if ! psql -t -c "SELECT 1 FROM pg_database WHERE datname = '$database'" | grep -q 1; then
        # Crear la base de datos si no existe
        psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
            CREATE DATABASE $database;
            GRANT ALL PRIVILEGES ON DATABASE $database TO $user;
EOSQL
    fi

    # Otorgar permisos en el esquema public
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$database" <<-EOSQL
        GRANT ALL PRIVILEGES ON SCHEMA public TO $user;
        GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $user;
        ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON TABLES TO $user;
EOSQL
done
