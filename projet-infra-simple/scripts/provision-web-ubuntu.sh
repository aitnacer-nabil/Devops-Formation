#!/bin/bash

# Script de provisioning pour Web Server Ubuntu
# provision-web-ubuntu.sh

echo "=== Début du provisioning Web Server Ubuntu ==="

# Mise à jour du système
echo "Mise à jour du système..."
apt-get update -y
apt-get upgrade -y

# Installation des paquets nécessaires
echo "Installation des paquets..."
apt-get install -y nginx git curl wget unzip rsync

# Installation de MySQL client pour tester la connexion DB
apt-get install -y mysql-client

# Démarrage et activation de Nginx
echo "Configuration de Nginx..."
systemctl start nginx
systemctl enable nginx

# Configuration du firewall
echo "Configuration du firewall..."
ufw allow 'Nginx Full'
ufw allow ssh
ufw --force enable

# Création du dossier website s'il n'existe pas
mkdir -p /var/www/html

# Supprimer d'abord le contenu par défaut de Nginx
echo "Suppression du contenu par défaut de Nginx..."
rm -rf /var/www/html/*

# Clonage d'un repository GitHub exemple (site statique) et déploiement
echo "Clonage du repository GitHub..."
cd /tmp
rm -rf website-repo
git clone https://github.com/startbootstrap/startbootstrap-landing-page.git website-repo

# Deploy only the built 'dist' contents into /var/www/html
if [ -d website-repo/dist ]; then
    echo "Déploiement de website-repo/dist -> /var/www/html"
    rsync -a --delete website-repo/dist/ /var/www/html/
else
    echo "Aucun dossier 'dist' trouvé dans le repo, déploiement du contenu du repo -> /var/www/html"
    rsync -a --delete website-repo/ /var/www/html/
fi

# Fix ownership and permissions
chown -R www-data:www-data /var/www/html/
chmod -R 755 /var/www/html/

# Configuration Nginx personnalisée
echo "Configuration personnalisée de Nginx..."
cat > /etc/nginx/sites-available/default << 'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/html;
    index index.html index.htm index.nginx-debian.html;

    server_name _;

    location / {
        try_files $uri $uri/ =404;
    }

    # Logs
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;
}
EOF

# Test de la configuration Nginx
nginx -t

# Redémarrage de Nginx
systemctl restart nginx

# Vérification du statut des services
echo "Vérification des services..."
systemctl status nginx --no-pager
systemctl status ssh --no-pager

# Affichage des informations réseau
echo "=== Informations réseau ==="
ip addr show
echo ""
echo "=== Routes ==="
ip route show

# Test de connectivité vers la base de données
echo "Test de connectivité vers la base de données..."
ping -c 3 192.168.56.20 || echo "Base de données pas encore accessible"

# Création d'un script de test DB
cat > /home/vagrant/test-db.sh << 'EOF'
#!/bin/bash
echo "Test de connexion à MySQL..."
mysql -h 192.168.56.20 -u vagrant -pvagrant123 -e "SHOW DATABASES;" 2>/dev/null && echo "Connexion DB OK" || echo "Connexion DB échouée"
EOF
chmod +x /home/vagrant/test-db.sh

# Affichage des instructions
echo ""
echo "=== Web Server Ubuntu provisionné avec succès ==="
echo "- Nginx installé et configuré"
echo "- Site web disponible dans /var/www/html"
echo "- Accès web via l'IP publique de la machine"
echo "- Test DB disponible avec: /home/vagrant/test-db.sh"
echo "- IP privée: 192.168.56.10"
echo ""

# Affichage de l'IP publique
PUBLIC_IP=$(ip route get 8.8.8.8 | sed -n '/src/{s/.*src *\([^ ]*\).*/\1/p;q}')
echo "IP publique pour accès web: http://$PUBLIC_IP"

echo "=== Fin du provisioning Web Server ==="