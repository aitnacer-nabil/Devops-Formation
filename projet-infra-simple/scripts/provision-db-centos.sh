#!/bin/bash

# Script de provisioning pour Database Server CentOS
# provision-db-centos.sh

echo "=== Début du provisioning Database Server CentOS ==="

# Mise à jour du système
echo "Mise à jour du système..."
dnf update -y

# Installation des paquets nécessaires
echo "Installation des paquets..."
dnf install -y wget curl net-tools

# Installation de MySQL 8.0
echo "Installation de MySQL 8.0..."
dnf install -y mysql-server mysql

# Création et configuration des fichiers de log MySQL
echo "Configuration des fichiers de log MySQL..."
touch /var/log/mysqld.log
chown mysql:mysql /var/log/mysqld.log
chmod 640 /var/log/mysqld.log

# Création du répertoire de données MySQL s'il n'existe pas
mkdir -p /var/lib/mysql
chown mysql:mysql /var/lib/mysql

# Configuration SELinux pour MySQL (si activé)
setsebool -P mysql_connect_any 1 2>/dev/null || echo "SELinux non configuré ou désactivé"

# Démarrage et activation de MySQL
echo "Démarrage de MySQL..."
systemctl start mysqld
systemctl enable mysqld

# Configuration du firewall
echo "Configuration du firewall..."
firewall-cmd --permanent --add-service=mysql
firewall-cmd --permanent --add-port=3306/tcp
firewall-cmd --reload

# Configuration initiale de MySQL
echo "Configuration de MySQL..."

# Attempt to set a known root password, handling the temporary password flow if present
DEFAULT_ROOT_PASSWORD="Root123!"
VAGRANT_DB_USER="vagrant"
VAGRANT_DB_PASS="vagrant123"

# Get temporary password if MySQL produced one
TEMP_PASSWORD=$(grep 'temporary password' /var/log/mysqld.log 2>/dev/null | tail -1 | awk '{print $NF}' || echo "")

if [ ! -z "$TEMP_PASSWORD" ]; then
	echo "Temporary MySQL root password found; applying known root password..."
	mysql -u root -p"$TEMP_PASSWORD" --connect-expired-password <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DEFAULT_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF
else
	# Try socket auth first then fallback to setting password without temporary password
	if mysql --protocol=socket -u root -e "SELECT 1;" >/dev/null 2>&1; then
		echo "Root socket auth available; setting root password via SQL..."
		mysql -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DEFAULT_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF
	else
		echo "No temporary password and socket auth failed; attempting to set root password directly (may fail if not allowed)..."
		mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${DEFAULT_ROOT_PASSWORD}'; FLUSH PRIVILEGES;" >/dev/null 2>&1 || echo "Warning: Could not set root password automatically."
	fi
fi

# Ensure root can connect from localhost (plugin/mysql_native_password if needed)
echo "Ensure root uses mysql_native_password auth plugin (best-effort)..."
mysql -u root -p"${DEFAULT_ROOT_PASSWORD}" -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${DEFAULT_ROOT_PASSWORD}'; FLUSH PRIVILEGES;" >/dev/null 2>&1 || echo "Warning: Could not set auth plugin for root."

# Create vagrant user and grant privileges
echo "Creating '${VAGRANT_DB_USER}' user with remote access and granting privileges..."
mysql -u root -p"${DEFAULT_ROOT_PASSWORD}" <<EOF
CREATE DATABASE IF NOT EXISTS demo_db;
CREATE USER IF NOT EXISTS '${VAGRANT_DB_USER}'@'%' IDENTIFIED BY '${VAGRANT_DB_PASS}';
CREATE USER IF NOT EXISTS '${VAGRANT_DB_USER}'@'localhost' IDENTIFIED BY '${VAGRANT_DB_PASS}';
GRANT ALL PRIVILEGES ON demo_db.* TO '${VAGRANT_DB_USER}'@'%';
GRANT ALL PRIVILEGES ON demo_db.* TO '${VAGRANT_DB_USER}'@'localhost';
# Also grant global privileges so the vagrant user can manage the DB during development
GRANT ALL PRIVILEGES ON *.* TO '${VAGRANT_DB_USER}'@'%' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON *.* TO '${VAGRANT_DB_USER}'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

# Configure MySQL to accept external connections by setting bind-address
echo "Configuring MySQL bind-address to 0.0.0.0..."
# For CentOS MySQL/MariaDB the configuration file may be /etc/my.cnf or /etc/my.cnf.d/*.cnf
if [ -f /etc/my.cnf.d/mysql-server.cnf ]; then
	sed -i '/^bind-address/ s/.*/bind-address = 0.0.0.0/' /etc/my.cnf.d/mysql-server.cnf 2>/dev/null || echo '[mysqld]\nbind-address = 0.0.0.0' > /etc/my.cnf.d/mysql-server.cnf
else
	# Fallback to /etc/my.cnf
	if grep -q '\[mysqld\]' /etc/my.cnf 2>/dev/null; then
		sed -i '/\[mysqld\]/, /\[/{/bind-address/ s/.*/bind-address = 0.0.0.0/; t;}' /etc/my.cnf 2>/dev/null || echo -e "\n[mysqld]\nbind-address = 0.0.0.0" >> /etc/my.cnf
	else
		echo -e "[mysqld]\nbind-address = 0.0.0.0" >> /etc/my.cnf
	fi
fi

# Restart MySQL to apply changes
echo "Restarting MySQL to apply configuration..."
systemctl restart mysqld || systemctl restart mysql || echo "Warning: could not restart MySQL service"

# Import SQL files if present
if [ -d "/tmp/database" ]; then
	echo "Importing SQL files from /tmp/database..."
	if [ -f "/tmp/database/create-table.sql" ]; then
		echo "Importing create-table.sql as root..."
		mysql -u root -p"${DEFAULT_ROOT_PASSWORD}" < /tmp/database/create-table.sql || echo "Warning: Failed to import create-table.sql"
	fi
	if [ -f "/tmp/database/insert-demo-data.sql" ]; then
		echo "Importing insert-demo-data.sql as ${VAGRANT_DB_USER} (fallback to root if needed)..."
		if mysql -u ${VAGRANT_DB_USER} -p${VAGRANT_DB_PASS} -e "SELECT 1;" >/dev/null 2>&1; then
			mysql -u ${VAGRANT_DB_USER} -p${VAGRANT_DB_PASS} < /tmp/database/insert-demo-data.sql || echo "Warning: Failed to import insert-demo-data.sql as ${VAGRANT_DB_USER}"
		else
			mysql -u root -p"${DEFAULT_ROOT_PASSWORD}" < /tmp/database/insert-demo-data.sql || echo "Warning: Failed to import insert-demo-data.sql as root"
		fi
	fi
else
	echo "No /tmp/database folder found; skipping SQL import step."
fi

# Create a small test script for vagrant to verify DB access
cat > /home/vagrant/test-mysql.sh <<EOF
#!/bin/bash
echo "=== Test MySQL Connection (vagrant user) ==="
mysql -h 127.0.0.1 -u ${VAGRANT_DB_USER} -p${VAGRANT_DB_PASS} -e "SHOW DATABASES;"
echo "\n=== Demo data (count) ==="
mysql -h 127.0.0.1 -u ${VAGRANT_DB_USER} -p${VAGRANT_DB_PASS} -e "USE demo_db; SELECT COUNT(*) as total FROM users;"
EOF
chmod +x /home/vagrant/test-mysql.sh || echo "Could not make /home/vagrant/test-mysql.sh executable"
chown vagrant:vagrant /home/vagrant/test-mysql.sh || echo "Could not chown test script to vagrant"



