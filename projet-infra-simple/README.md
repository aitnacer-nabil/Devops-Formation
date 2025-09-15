# Projet Infrastructure Multi-Machines avec Vagrant

## 🎯 Description du projet

Ce projet implémente une infrastructure automatisée avec deux machines virtuelles :
- **Web Server** : Ubuntu 22.04 avec Nginx
- **Database Server** : CentOS 9 avec MySQL 8.0

## 📁 Structure du projet

```
projet-infra-simple/
├── Vagrantfile                    # Configuration principale Vagrant
├── scripts/
│   ├── provision-web-ubuntu.sh    # Script de provisioning web server
│   └── provision-db-centos.sh     # Script de provisioning database server
├── website/                       # Dossier synchronisé avec le web server
├── database/
│   ├── create-table.sql           # Création de la base de données
│   └── insert-demo-data.sql       # Données de démonstration
└── README.md                      # Ce fichier
```

## ⚡ Démarrage rapide

### 1. Prérequis

```bash
# Vérifier les installations
vagrant --version
VBoxManage --version
```

### 2. Cloner et préparer le projet

```bash
# Créer la structure
mkdir projet-infra-simple
cd projet-infra-simple

# Créer les dossiers nécessaires
mkdir -p scripts website database
```

### 3. Déployer l'infrastructure

```bash
# Démarrer toutes les machines
vagrant up

# Ou démarrer une machine spécifique
vagrant up web-server
vagrant up db-server
```

## 🔧 Configuration des machines

### Web Server (Ubuntu 22.04)
- **Hostname** : web-server
- **IP Privée** : 192.168.56.10
- **IP Publique** : Automatique (bridge)
- **Services** : Nginx, SSH
- **Dossier synchronisé** : `./website` → `/var/www/html`

### Database Server (CentOS 9)
- **Hostname** : db-server  
- **IP Privée** : 192.168.56.20
- **Port Forwarding** : 3306 → 3307
- **Services** : MySQL 8.0, SSH
- **Base de données** : demo_db
- **Utilisateur** : vagrant / vagrant123

## 🌐 Accès aux services

### Site Web
```bash
# Trouver l'IP publique de la machine web
vagrant ssh web-server -c "hostname -I"

# Accéder au site web
# http://[IP_PUBLIQUE]
```

### Base de Données

#### Depuis la machine physique (hôte)
```bash
# Connexion MySQL via port forwarding
mysql -h localhost -P 3307 -u vagrant -pvagrant123

# Test rapide
mysql -h localhost -P 3307 -u vagrant -pvagrant123 -e "USE demo_db; SELECT * FROM users;"
```

#### Depuis la machine web
```bash
# Se connecter à la machine web
vagrant ssh web-server

# Tester la connexion à la DB
mysql -h 192.168.56.20 -u vagrant -pvagrant123 -e "SHOW DATABASES;"
```

#### Ping de la base de données
```bash
# Depuis la machine physique - ping vers l'IP privée
ping 192.168.56.20

# Depuis la machine web
vagrant ssh web-server
ping 192.168.56.20
```

## 🧪 Tests et vérifications

### Vérifier les services
```bash
# Status des machines
vagrant status

# Vérifier Nginx
vagrant ssh web-server -c "sudo systemctl status nginx"

# Vérifier MySQL
vagrant ssh db-server -c "sudo systemctl status mysqld"
```

### Tests de connectivité réseau
```bash
# Test du site web
curl http://192.168.56.10

# Test ping entre machines
vagrant ssh web-server -c "ping -c 3 192.168.56.20"

# Test des ports
nmap -p 3307 localhost  # Depuis l'hôte
```

### Tests de la base de données
```bash
# Test depuis l'hôte
mysql -h localhost -P 3307 -u vagrant -pvagrant123 -e "SELECT COUNT(*) FROM demo_db.users;"

# Test depuis la machine DB
vagrant ssh db-server
/home/vagrant/test-mysql.sh

# Test depuis la machine Web
vagrant ssh web-server
/home/vagrant/test-db.sh
```

## 🔄 Commandes de gestion

### Gestion des machines
```bash
# Démarrer
vagrant up [nom-machine]

# Arrêter
vagrant halt [nom-machine]

# Redémarrer
vagrant reload [nom-machine]

# Reprovisioner
vagrant provision [nom-machine]

# Détruire
vagrant destroy [nom-machine]
```

### Connexions SSH
```bash
# SSH vers web server
vagrant ssh web-server

# SSH vers database server
vagrant ssh db-server

# Exécuter une commande sans se connecter
vagrant ssh web-server -c "sudo nginx -t"
```

## 🐛 Dépannage

### Problèmes courants

#### La machine ne démarre pas
```bash
# Vérifier VirtualBox
VBoxManage list vms

# Voir les logs détaillés
vagrant up --debug
```

#### Problème de réseau
```bash
# Vérifier les interfaces réseau
vagrant ssh web-server -c "ip addr show"

# Redémarrer le réseau
vagrant reload
```

#### MySQL inaccessible
```bash
# Vérifier MySQL
vagrant ssh db-server -c "sudo systemctl status mysqld"

# Voir les logs MySQL
vagrant ssh db-server -c "sudo tail -f /var/log/mysqld.log"

# Redémarrer MySQL
vagrant ssh db-server -c "sudo systemctl restart mysqld"
```

#### Port forwarding ne fonctionne pas
```bash
# Vérifier les ports
netstat -tlnp | grep 3307

# Tester la connectivité
telnet localhost 3307
```

### Réinitialisation complète
```bash
# Détruire et recréer
vagrant destroy -f
vagrant up
```

## 📊 Informations techniques

### Ressources allouées
- **Web Server** : 1GB RAM, 1 vCPU
- **Database Server** : 1GB RAM, 1 vCPU
- **Disques** : 20GB allocation dynamique

### Ports utilisés
- **80** : HTTP (web server)
- **22** : SSH (les deux machines)
- **3306** : MySQL (internal)
- **3307** : MySQL forwarded (hôte → db-server:3306)

### Utilisateurs et mots de passe
- **SSH** : vagrant/vagrant (clé automatique)
- **MySQL root** : root/Root123!
- **MySQL user** : vagrant/vagrant123

## 🎯 Objectifs validés

- ✅ Infrastructure multi-machines automatisée
- ✅ Réseaux public et privé configurés
- ✅ Web server accessible publiquement
- ✅ Base de données accessible depuis l'hôte (port 3307)
- ✅ Communication inter-machines fonctionnelle
- ✅ Ping possible vers la base de données
- ✅ Provisioning automatique
- ✅ Synchronisation des dossiers

## 📚 Ressources

- [Documentation Vagrant](https://www.vagrantup.com/docs)
- [VirtualBox Manual](https://www.virtualbox.org/manual/)
- [MySQL 8.0 Documentation](https://dev.mysql.com/doc/refman/8.0/en/)

## 🤝 Support

En cas de problème, vérifiez :
1. Les prérequis sont installés
2. La virtualisation est activée dans le BIOS
3. Les logs avec `vagrant up --debug`
4. Les services avec `systemctl status`