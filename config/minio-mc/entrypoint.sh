#!/bin/sh
set -e

# Esperar a que MinIO esté listo
until /usr/bin/mc alias set local http://minio:9000 "${MINIO_ROOT_USER}" "${MINIO_ROOT_PASSWORD}"; do
    echo "Esperando a que MinIO esté listo..."
    sleep 2
done

# Convertir las cadenas de usuarios, contraseñas y buckets en arrays
IFS=',' read -r -a users <<< "${USERS}"
IFS=',' read -r -a passwords <<< "${PASSWORDS}"
IFS=',' read -r -a buckets <<< "${BUCKETS}"

# Comprobar que las tres variables tienen el mismo número de elementos
if [ "${#users[@]}" -ne "${#passwords[@]}" ] || [ "${#users[@]}" -ne "${#buckets[@]}" ]; then
    echo "Error: Las variables de entorno USERS, PASSWORDS y BUCKETS deben tener el mismo número de elementos." >&2
    exit 1
fi

# Crear usuarios y buckets
for i in "${!users[@]}"; do
    user="${users[$i]}"
    password="${passwords[$i]}"
    bucket="${buckets[$i]}"

    # Crear el usuario si no existe
    if ! /usr/bin/mc admin user info local "$user" >/dev/null 2>&1; then
        echo "Creando usuario: $user"
        /usr/bin/mc admin user add local "$user" "$password"
    fi

    # Crear el bucket si no existe
    if ! /usr/bin/mc ls local/"$bucket" >/dev/null 2>&1; then
        echo "Creando bucket: $bucket"
        /usr/bin/mc mb local/"$bucket"
    fi

    # Crear una política que permita acceso total al bucket para el usuario
    policy_name="${bucket}-policy"
    policy_json="{
        \"Version\": \"2012-10-17\",
        \"Statement\": [
            {
                \"Effect\": \"Allow\",
                \"Action\": [
                    \"s3:GetObject\",
                    \"s3:PutObject\",
                    \"s3:DeleteObject\",
                    \"s3:ListBucket\"
                ],
                \"Resource\": [
                    \"arn:aws:s3:::${bucket}\",
                    \"arn:aws:s3:::${bucket}/*\"
                ]
            }
        ]
    }"

    # Crear un archivo temporal para la política
    temp_policy_file=$(mktemp)
    echo "$policy_json" > "$temp_policy_file"

    # Crear la política
    echo "Creando política: $policy_name"
    /usr/bin/mc admin policy create local "$policy_name" "$temp_policy_file"

    # Verificar el usuario antes de asignar la política
    echo "Verificando si el usuario existe: $user"
    if /usr/bin/mc admin user info local "$user" >/dev/null 2>&1; then
        /usr/bin/mc admin policy attach local "$policy_name" --user "$user"
    fi

    # Eliminar el archivo temporal
    rm "$temp_policy_file"
done

# Mantener el contenedor en ejecución
tail -f /dev/null
