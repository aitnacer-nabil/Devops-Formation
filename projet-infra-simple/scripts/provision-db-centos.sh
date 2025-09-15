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

# Récupération du mot de passe temporaire root (s'il existe)
TEMP_PASSWORD=$(grep 'temporary password' /var/log/mysqld.log 2>/dev/null | tail -1 | awk '{print $NF}' || echo "")

if [ ! -z "$TEMP_PASSWORD" ]; then
    echo "Mot de passe temporaire trouvé, configuration sécurisée..."
    
    # Configuration avec le mot de passe temporaire
    mysql -u root -p"$TEMP_PASSWORD" --connect-expired-password << 'EOF'
ALTER USER 'root'@'localhost' IDENTIFIED BY 'Root123!';
FLUSH PRIVILEGES;
EOF
else
    echo "Pas de mot de passe temporaire, configuration directe..."
    
    # Configuration directe si pas de mot de passe
    mysql -u root << 'EOF'
ALTER USER 'root'@'localhost' IDENTIFIED BY 'Root123!';
FLUSH PRIVILEGES;
EOF
fi

# Configuration de la base de données et utilisateur
echo "Création de la base de données et utilisateur..."
mysql -u root -pRoot123! << 'EOF'
-- Création de la base de données
CREATE DATABASE IF NOT EXISTS demo_db;

-- Création de l'utilisateur vagrant
CREATE USER IF NOT EXISTS 'vagrant'@'%' IDENTIFIED BY 'vagrant123';
CREATE USER IF NOT EXISTS 'vagrant'@'localhost' IDENTIFIED BY 'vagrant123';
CREATE USER IF NOT EXISTS 'vagrant'@'192.168.56.%' IDENTIFIED BY 'vagrant123';

-- Attribution des privilèges
GRANT ALL PRIVILEGES ON demo_db.* TO 'vagrant'@'%';
GRANT ALL PRIVILEGES ON demo_db.* TO 'vagrant'@'localhost';
GRANT ALL PRIVILEGES ON demo_db.* TO 'vagrant'@'192.168.56.%';
GRANT ALL PRIVILEGES ON *.* TO 'vagrant'@'%';
GRANT ALL PRIVILEGES ON *.* TO 'vagrant'@'localhost';
GRANT ALL PRIVILEGES ON *.* TO 'vagrant'@'192.168.56.%';

FLUSH PRIVILEGES;
EOF

# Création de la table et insertion des données
echo "Création de la table users..."
mysql -u vagrant -pvagrant123 << 'EOF'
USE demo_db;

CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nom VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT IGNORE INTO users (nom, email) VALUES
('Alice Martin', 'alice.martin@example.com'),
('Bob Dupont', 'bob.dupont@example.com'),
('Clara Leblanc', 'clara.leblanc@example.com'),
('David Moreau', 'david.moreau@example.com'),
('Emma Rousseau', 'emma.rousseau@example.com'),
('François Simon', 'francois.simon@example.com'),
('Gabrielle Dubois', 'gabrielle.dubois@example.com'),
('Hugo Petit', 'hugo.petit@example.com'),
('Isabelle Leroy', 'isabelle.leroy@example.com'),
('Julien Bernard', 'julien.bernard@example.com');
EOF

# Configuration MySQL pour accepter les connexions externes
echo "Configuration MySQL pour connexions externes..."
sed -i 's/bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf 2>/dev/null || echo "Configuration bind-address non trouvée"

# Pour CentOS, la configuration est différente
cat > /etc/my.cnf.d/mysql-server.cnf << 'EOF'
[mysqld]
bind-address = 0.0.0.0
port = 3306
max_connections = 200

# Logs
log-error = /var/log/mysqld.log
slow_query_log = 1
slow_query_log_file = /var/log/mysql-slow.log
long_query_time = 2
EOF

# Redémarrage de MySQL
systemctl restart mysqld

# Vérification du statut
echo "Vérification des services..."
systemctl status mysqld --no-pager

# Test de la base de données
echo "Test de la base de données..."
mysql -u vagrant -pvagrant123 -e "USE demo_db; SELECT COUNT(*) as nb_users FROM users;"

# Affichage des informations réseau
echo "=== Informations réseau ==="
ip addr show
echo ""
echo "=== Ports d'écoute ==="
netstat -tlnp | grep :3306

# Création d'un script de test pour l'utilisateur vagrant
cat > /home/vagrant/test-mysql.sh << 'EOF'
#!/bin/bash
echo "=== Test MySQL ==="
mysql -u vagrant -pvagrant123 -e "SHOW DATABASES;"
echo ""
echo "=== Données de test ==="
mysql -u vagrant -pvagrant123 -e "USE demo_db; SELECT * FROM users;"
EOF
chmod +x /home/vagrant/test-mysql.sh

# Instructions finales
echo ""
echo "=== Database Server CentOS provisionné avec succès ==="
echo "- MySQL 8.0 installé et configuré"
echo "- Base de données: demo_db"
echo "- Utilisateur: vagrant / mot de passe: vagrant123"
echo "- IP privée: 192.168.56.20"
echo "- Port forwarding: 3306 -> 3307 sur l'hôte"
echo ""
echo "Tests disponibles:"
echo "- Depuis l'hôte: mysql -h localhost -P 3307 -u vagrant -pvagrant123"
echo "- Depuis la VM: /home/vagrant/test-mysql.sh"
echo ""

echo "=== Fin du provisioning Database Server ==="