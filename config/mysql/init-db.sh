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

    # Crear la base de datos si no existe
    mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "CREATE DATABASE IF NOT EXISTS $database;"

    # Crear el usuario si no existe
    mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "CREATE USER IF NOT EXISTS '$user'@'%' IDENTIFIED BY '$password';"

    # Otorgar todos los privilegios en la base de datos al usuario
    if ! mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "USE $database; GRANT ALL PRIVILEGES ON $database.* TO '$user'@'%';"; then
        echo "Error al otorgar privilegios a $user en $database."
    fi
done

# Aplicar cambios de privilegios
mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "FLUSH PRIVILEGES;"
