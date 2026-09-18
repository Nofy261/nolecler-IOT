# Inception of Things (IoT)

## Description

Inception of Things est un projet axé sur la mise en place et la gestion d'une infrastructure permettant de déployer et d'exécuter des applications de manière automatisée. Il permet d'aborder les principes de la virtualisation, de la conteneurisation, de l'orchestration et de la gestion des services, à travers la création d'un environnement complet et reproductible.

## Structure

- `p1/` — 2 VM Vagrant, K3s en mode server + agent
- `p2/` — 1 VM Vagrant, K3s + 3 applications + Ingress
- `p3/` — K3d (K3s dans Docker) + Argo CD, GitOps depuis GitHub
- `bonus/` — GitLab local dans le cluster, remplace GitHub comme source Argo CD

## Outils nécessaires

- Une VM
- Docker
- Vagrant + VirtualBox
- K3d
- kubectl
- Helm (pour le bonus)
- Le CLI Argo CD

Chaque dossier possède son propre `scripts/install.sh` qui installe les outils nécessaires à cette partie précise.

## Différentes parties

### p1 — K3s et Vagrant

Deux VM créées par Vagrant : `loginS` (K3s en mode server, IP `192.168.56.110`) et `loginSW` (K3s en mode agent, IP `192.168.56.111`). Le worker rejoint le cluster grâce à un token partagé via le dossier synchronisé Vagrant.

**Lancement :**
```bash
cd p1
sudo bash scripts/install.sh   # installe Vagrant + VirtualBox
vagrant up                     # crée les 2 VM et installe K3s
```

**Vérification :**
```bash
vagrant ssh loginS
```
```BASH
kubectl get nodes -o wide      # doit afficher 2 nœuds Ready
```

**Nettoyage :**
```bash
bash scripts/clean.sh
```

### p2 — K3s et 3 applications

Une seule VM (`loginS`, K3s en mode server) qui héberge 3 applications et un Ingress. Le routage se fait selon le header `Host` de la requête : `app1.com` → app1, `app2.com` → app2, tout le reste → app3 (règle par défaut). L'application 2 tourne en 3 replicas.

**Lancement :**
```bash
cd p2
vagrant up                     # crée la VM, installe K3s et applique les manifests
bash scripts/hosts.sh          # ajoute app1.com/app2.com/app3.com à /etc/hosts
```

**Vérification :**
```bash
curl -H "Host: app1.com" http://192.168.56.110
curl -H "Host: app2.com" http://192.168.56.110
curl http://192.168.56.110      # host inconnu → app3 par défaut
```

Ou directement dans le navigateur (après `hosts.sh`) : `http://app1.com`, `http://app2.com`, et `http://192.168.56.110` pour app3 (règle par défaut)

**Nettoyage :**
```bash
bash scripts/clean.sh
```

### p3 — K3d et Argo CD

Ici K3d fait tourner K3s directement dans des conteneurs Docker, sur la machine actuelle. Le cluster contient 2 namespaces (`argocd`, `dev`), et Argo CD déploie automatiquement une application depuis un dépôt GitHub — c'est le principe du GitOps : Git est la source de vérité, Argo CD synchronise le cluster dessus.

**Lancement :**
```bash
cd p3
sudo bash scripts/install.sh   # installe Docker, K3d, kubectl, argocd
bash scripts/start.sh          # crée le cluster, installe Argo CD, déploie l'app
```

**Accéder à Argo CD :**
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
```
Puis ouvrir `https://localhost:8080` (login `admin` + le mot de passe ci-dessus).

**Vérification :**
```bash
kubectl get nodes
kubectl get pods -n dev
curl http://localhost:8888/    # {"status":"ok", "message": "v1"}
```

**Mise à jour v1 → v2 :** modifier `p3/confs/deployment.yaml` (changer le tag de l'image), commit + push sur GitHub. Argo CD synchronise automatiquement (ou forcer avec `argocd app sync wil-playground`).

**Nettoyage :**
```bash
bash scripts/clean.sh
```

### Bonus — GitLab local

GitLab est installé dans le cluster (namespace `gitlab`), connecté à 3 services externes légers (Valkey, CloudNativePG, Garage) au lieu de ses composants internes lourds. Il remplace GitHub comme source surveillée par Argo CD (`update.sh` copie directement les manifests de `p3/confs`, en local, sans passer par GitHub), via une deuxième application (`wil-playground2`).

**Lancement :**
```bash
cd bonus
sudo bash scripts/install.sh   # installe Helm, Valkey, CloudNativePG, Garage
bash scripts/start.sh          # installe GitLab, ouvre le tunnel (port 80)
```

**Créer le dépôt GitLab :**
1. Récupérer le mot de passe : `cat gitlab_password.txt`
2. Ouvrir `http://gitlab.k3d.gitlab.com`, se connecter en `root`
3. Créer un projet vierge nommé `test`, namespace `root`, visibilité **Public**

**Copier les manifests de p3 vers GitLab (en local) :**
```bash
bash scripts/update.sh
```

**Vérification :**
```bash
curl http://localhost:8889/    # {"status":"ok", "message": "v1"}
```

**Mise à jour v1 → v2 :** modifier `confs/deployment.yaml` directement dans l'interface GitLab (Edit → Commit changes).

**Nettoyage :**
```bash
k3d cluster delete iot
```

