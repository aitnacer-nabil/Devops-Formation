# Projet Infrastructure Multi-Machines avec Vagrant

## 🎯 Description du projet

Ce projet implémente une infrastructure automatisée avec deux machines virtuelles :
- **Web Server** : Ubuntu 22.04 avec Nginx
- **Database Server** : CentOS 9 avec MySQL 8.0
# Projet d'infrastructure Vagrant (Web + BDD)

## 🇫🇷 Description (version professionnelle)

Ce dépôt fournit une infrastructure de démonstration entièrement automatisée avec Vagrant et VirtualBox. Elle contient deux machines virtuelles :

- `web-server` (Ubuntu 22.04) : serveur web (Nginx) qui sert un site statique depuis le dossier partagé `./website`.
- `db-server` (CentOS 9) : serveur de base de données MySQL 8.0 qui fournit la base `demo_db` et un utilisateur `vagrant` pour les tests.

Les scripts de provisioning fournis (shell) automatisent l'installation et la configuration :

- `scripts/provision-web-ubuntu.sh` : installe Nginx, déploie le contenu du dossier `website`, installe le client MySQL et crée `/home/vagrant/test-db.sh` pour tests simples.
- `scripts/provision-db-centos.sh` : installe MySQL, gère le mot de passe root (prend en charge le mot de passe temporaire produit par MySQL), crée l'utilisateur `vagrant`, accorde les privilèges, configure `bind-address` pour les connexions privées, importe les fichiers SQL depuis `/tmp/database` (synced folder) et crée `/home/vagrant/test-mysql.sh`.

> Remarque importante : pour que les fichiers SQL soient importés automatiquement, placez `create-table.sql` et `insert-demo-data.sql` dans le dossier `./database` avant d'exécuter `vagrant up`.

---

## Structure du projet

```
projet-infra-simple/
├── Vagrantfile
├── scripts/
│   ├── provision-web-ubuntu.sh
│   └── provision-db-centos.sh
├── website/
│   └── assets/ (images et CSS/JS du site)
└── database/
		├── create-table.sql
		└── insert-demo-data.sql
```

---

## Démarrage rapide

1) Prérequis :

- Vagrant
- VirtualBox

2) Démarrage des machines :

```powershell
# Depuis le répertoire du projet
vagrant up
# Pour démarrer une machine seule
vagrant up web-server
vagrant up db-server
```

3) Re-provisionner si besoin :

```powershell
vagrant provision db-server
vagrant provision web-server
```

---

## Détails des scripts de provisioning

- `provision-web-ubuntu.sh` :
	- installe Nginx et déploie la version statique du site dans `/var/www/html`.
	- installe `mysql-client` (permet au web-server d'exécuter des tests vers la BDD).
	- crée `/home/vagrant/test-db.sh` pour vérifier la connexion à la BDD depuis le web-server.

- `provision-db-centos.sh` :
	- installe MySQL et prend en charge le flux du mot de passe temporaire (si présent).
	- définit un mot de passe root (par défaut `Root123!`, modifiable) et force `mysql_native_password` si nécessaire.
	- crée la base `demo_db` et l'utilisateur `vagrant` (mot de passe par défaut `vagrant123`) et lui accorde les privilèges nécessaires;
	- configure `bind-address = 0.0.0.0` pour accepter les connexions depuis la private network (VMs Vagrant) et redémarre MySQL;
	- importe `create-table.sql` puis `insert-demo-data.sql` depuis `/tmp/database` si ces fichiers existent;
	- crée `/home/vagrant/test-mysql.sh` pour vérification.

> Sécurité : les mots de passe sont codés pour la démonstration. Pour un usage réel, configurez des variables Vagrant ou stockez les secrets de manière sécurisée.

---

## Vérifications et tests

- Vérifier l'état des machines :

```powershell
vagrant status
```

- Tester la connexion MySQL depuis l'hôte (port forward 3307 -> 3306) :

```powershell
mysql -h localhost -P 3307 -u vagrant -pvagrant123 -e "SHOW DATABASES;"
```

- Depuis le web-server :

```bash
vagrant ssh web-server
/home/vagrant/test-db.sh
```

- Depuis le db-server :

```bash
vagrant ssh db-server
/home/vagrant/test-mysql.sh
```

---

## Sortie réseau (extrait du provisioning `web-server`)

Le provisioning du `web-server` affiche des informations réseau utiles pour le débogage de la connectivité entre VMs. Exemple d'extrait :

```
web-server: === Informations réseau ===
		web-server: 1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
		web-server:     link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
		web-server:     inet 127.0.0.1/8 scope host lo
		web-server:        valid_lft forever preferred_lft forever
		web-server:     inet6 ::1/128 scope host
		web-server:        valid_lft forever preferred_lft forever
		web-server: 2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
		web-server:     link/ether 02:29:1e:73:1f:d5 brd ff:ff:ff:ff:ff:ff
		web-server:     inet 10.0.2.15/24 metric 100 brd 10.0.2.255 scope global dynamic enp0s3
		web-server:        valid_lft 86215sec preferred_lft 86215sec
		web-server:     inet6 fd00::29:1eff:fe73:1fd5/64 scope global dynamic mngtmpaddr noprefixroute
		web-server:        valid_lft 86216sec preferred_lft 14216sec
		web-server:     inet6 fe80::29:1eff:fe73:1fd5/64 scope link
		web-server:        valid_lft forever preferred_lft forever
		web-server: 3: enp0s8: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
		web-server:     link/ether 08:00:27:ba:39:65 brd ff:ff:ff:ff:ff:ff
		web-server:     inet 192.168.11.119/24 metric 100 brd 192.168.11.255 scope global dynamic enp0s8
		web-server:        valid_lft 85217sec preferred_lft 85217sec
		web-server:     inet6 fe80::a00:27ff:feba:3965/64 scope link
		web-server:        valid_lft forever preferred_lft forever
		web-server: 4: enp0s9: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
		web-server:     link/ether 08:00:27:69:67:9e brd ff:ff:ff:ff:ff:ff
		web-server:     inet 192.168.56.10/24 brd 192.168.56.255 scope global enp0s9
		web-server:        valid_lft forever preferred_lft forever
		web-server:     inet6 fe80::a00:27ff:fe69:679e/64 scope link
		web-server:        valid_lft forever preferred_lft forever
		web-server:
		web-server: === Routes ===
		web-server: default via 10.0.2.2 dev enp0s3 proto dhcp src 10.0.2.15 metric 100
		web-server: default via 192.168.11.1 dev enp0s8 proto dhcp src 192.168.11.119 metric 100
		web-server: 8.8.8.8 via 192.168.11.1 dev enp0s8 proto dhcp src 192.168.11.119 metric 100
		web-server: 10.0.2.0/24 dev enp0s3 proto kernel scope link src 10.0.2.15 metric 100
		web-server: 10.0.2.2 dev enp0s3 proto dhcp scope link src 10.0.2.15 metric 100
		web-server: 10.0.2.3 dev enp0s3 proto dhcp scope link src 10.0.2.15 metric 100
		web-server: 41.214.140.4 via 192.168.11.1 dev enp0s8 proto dhcp src 192.168.11.119 metric 100
		web-server: 41.214.140.5 via 192.168.11.1 dev enp0s8 proto dhcp src 192.168.11.119 metric 100
		web-server: 192.168.11.0/24 dev enp0s8 proto kernel scope link src 192.168.11.119 metric 100
		web-server: 192.168.11.1 dev enp0s8 proto dhcp scope link src 192.168.11.119 metric 100
		web-server: 192.168.56.0/24 dev enp0s9 proto kernel scope link src 192.168.56.10
		web-server: Test de connectivité vers la base de données...
		web-server: PING 192.168.56.20 (192.168.56.20) 56(84) bytes of data.
		web-server: From 192.168.56.10 icmp_seq=1 Destination Host Unreachable
		web-server: From 192.168.56.10 icmp_seq=2 Destination Host Unreachable
		web-server: From 192.168.56.10 icmp_seq=3 Destination Host Unreachable
		web-server:
		web-server: --- 192.168.56.20 ping statistics ---
		web-server: 3 packets transmitted, 0 received, +3 errors, 100% packet loss, time 2052ms
		web-server: pipe 3
		web-server: Base de données pas encore accessible
		web-server: 
		web-server: === Web Server Ubuntu provisionné avec succès ===
		web-server: - Nginx installé et configuré
		web-server: - Site web disponible dans /var/www/html
		web-server: - Accès web via l'IP publique de la machine
		web-server: - Test DB disponible avec: /home/vagrant/test-db.sh
		web-server: - IP privée: 192.168.56.10
		web-server:
		web-server: IP publique pour accès web: http://192.168.11.119
		web-server: === Fin du provisioning Web Server ===
```

---

## Exemples de commandes utiles

- Démarrer les machines : `vagrant up`
- Re-provisionner : `vagrant provision db-server` ou `vagrant provision web-server`
- Connecter SSH : `vagrant ssh web-server` / `vagrant ssh db-server`

---




vagrant reload

```



#### MySQL inaccessible

```bash
