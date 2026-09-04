
Concrètement, On va :
-Fabriquer des ordinateurs virtuels (avec Vagrant) et les faire travailler en équipe grâce à un outil appelé K3s — un "chef" qui organise le travail entre plusieurs machines.
-Faire tourner plusieurs sites web en même temps sur une seule machine, et apprendre à afficher le bon site selon le nom tapé dans le navigateur.
-Automatiser tout ça encore plus : au lieu de taper des commandes à la main pour mettre à jour un site, tu écris juste tes changements sur GitHub, et un robot (Argo CD) va les récupérer et mettre à jour ton site tout seul.
-(Bonus) faire pareil mais avec ton propre GitHub "maison" (GitLab).


L'histoire, en mots simples:
Tu veux ouvrir un site web. Mais un site web tout seul, si l'ordinateur qui le fait tourner tombe en panne, tout s'arrête. Alors des gens ont inventé des outils pour gérer plein de "copies" d'un site, sur plein de machines, automatiquement, sans que t'aies à surveiller 24h/24.

Le conteneur (Docker) — c'est comme une boîte à repas toute prête : dedans il y a le programme + tout ce qu'il faut pour qu'il marche, peu importe l'ordinateur sur lequel tu l'ouvres. Tu peux la copier-coller partout, elle marchera pareil.

Kubernetes — c'est le chef d'équipe qui gère plein de boîtes à repas sur plusieurs tables (machines). Il vérifie qu'il y a toujours assez de boîtes ouvertes, il en rajoute si besoin, il en remplace une si elle tombe par terre (crash). C'est puissant mais très compliqué à apprendre d'un coup.

K3s — c'est Kubernetes en version simplifiée, pour des petites machines, plus facile à installer. C'est celui qu'on utilise dans ce projet.

Vagrant — c'est une machine à fabriquer des ordinateurs virtuels à partir d'une recette écrite (le Vagrantfile). Tu écris "je veux un ordi avec telle IP, tel nom", tu appuies sur un bouton, et Vagrant le construit tout seul, toujours pareil. Pratique pour ne pas devoir tout recliquer à la main.

K3d — comme K3s, mais au lieu de tourner dans un vrai ordinateur virtuel, il tourne directement dans des boîtes Docker. C'est plus léger et plus rapide à lancer.

Argo CD — c'est un livreur automatique. Tu écris tes instructions ("je veux la version 2 de mon site") dans un endroit sur Internet (GitHub), et Argo CD va vérifier régulièrement, voit que t'as changé un truc, et met à jour ton site tout seul, sans que tu doives taper une seule commande sur ta machine.


Le projet étape par étape:
Partie 1 : tu fabriques 2 ordinateurs virtuels avec Vagrant (un "chef" et un "assistant"), et tu installes K3s dessus pour qu'ils travaillent en équipe.
Partie 2 : sur un seul ordinateur, tu fais tourner 3 mini sites web. Un "aiguilleur" (l'Ingress) regarde le nom que tu tapes dans ton navigateur et t'affiche le bon site.
Partie 3 : tu changes d'outil (K3d au lieu de Vagrant), et tu branches le "livreur automatique" (Argo CD) qui va chercher les instructions sur GitHub tout seul.
Bonus : pareil, mais avec ton propre GitHub "fait maison" (GitLab), hébergé chez toi.

------------------

    PARTIE 1:

En mots simples : tu construis les fondations. Tu fabriques deux ordinateurs virtuels qui vont apprendre à travailler ensemble en équipe.

Un ordinateur = le chef (Server) → il donne les ordres, organise le travail
L'autre ordinateur = l'assistant (ServerWorker) → il exécute le travail que le chef lui donne
Ces deux machines, une fois connectées, forment ce qu'on appelle un cluster : littéralement "un groupe de machines qui agissent comme une seule grosse machine".

Le but de cette partie n'est pas encore de faire tourner des sites web utiles. C'est juste de prouver que :
-> tu sais fabriquer des machines automatiquement (avec Vagrant)
-> tu sais installer l'outil K3s dessus
-> le chef et l'assistant arrivent bien à se parler et former une équipe

------------------

résumé de la Partie 1 :

Créer 2 VM avec Vagrant
L'une est chef (installe K3s en mode serveur), l'autre est assistant (installe K3s en mode agent, en se connectant au chef via son IP + le token)
La connexion des deux forme un cluster
Il faut le prouver : une seule commande (kubectl get nodes) lancée sur le chef doit montrer les 2 machines, chacune avec son rôle (control-plane,master pour le chef, vide/worker pour l'assistant), toutes les deux Ready


GUIDE DETAILLE - PARTIE 1 

Objectif final : avoir 2 VMs (un chef + un assistant), formant un cluster K3s, et pouvoir le prouver avec une seule commande.

ETAPE 1 - Créer le Vagrantfile
- Un seul fichier Vagrantfile (dans p1/) qui définit les 2 VMs
- Dans ce fichier, pour chaque VM (avec config.vm.define) :
  - box = distribution Linux au choix (dernière version stable)
  - hostname = login + "S" pour le chef, login + "SW" pour l'assistant
  - IP fixe sur réseau privé : 192.168.56.110 (chef) / 192.168.56.111 (assistant)
  - provider (ex: virtualbox) limité à 1 CPU et 512 Mo (ou 1024 Mo) de RAM
  - SSH doit fonctionner sans mot de passe (comportement par défaut de Vagrant, à vérifier)
  - une ligne de provisioning qui pointe vers un script shell (un par machine)

ETAPE 2 - Créer le script d'installation du chef (server)
- Script shell exécuté automatiquement au démarrage de la VM chef
- Contenu : installer K3s en mode serveur (commande d'install officielle, mode par défaut = serveur)
- Résultat attendu : K3s tourne en mode "controller", et génère un token dans un fichier sur cette machine
- Installer aussi kubectl sur cette machine si besoin

ETAPE 3 - Créer le script d'installation de l'assistant (agent)
- Script shell exécuté automatiquement au démarrage de la VM assistant
(script de l'assistant → installe K3s en mode agent, en se connectant au chef (IP + token))
- Doit récupérer automatiquement (sans copier-coller à la main) :
  - l'IP du chef (192.168.56.110) -> fixe, connue à l'avance
  - le token généré par le chef -> à récupérer via un dossier partagé entre les VMs ou via SSH
- Contenu : installer K3s en mode agent, en précisant l'IP du chef + le token dans la commande d'install
- Résultat attendu : la VM rejoint automatiquement le cluster en tant qu'agent

ETAPE 4 - Lancer et vérifier
- Commande : vagrant up -> doit créer et démarrer les 2 VMs sans erreur
- Vérifier le SSH sans mot de passe : vagrant ssh <loginS> et vagrant ssh <loginSW>
- Vérifier le hostname (commande hostname) et l'IP (commande ip a) sur chaque VM

ETAPE 5 - Preuve que le cluster est formé (la démonstration finale)
- Depuis le chef, lancer : kubectl get nodes -o wide 
- Résultat attendu : 2 lignes affichées, une par machine
  - loginS -> STATUS Ready, ROLES control-plane,master
  - loginSW -> STATUS Ready, ROLES (vide / worker)
- Si une seule ligne apparaît (juste le chef) -> l'assistant n'a pas rejoint, donc pas connecté, à corriger

Points de vigilance :
- Modernes distributions Linux -> interfaces réseau nommées enp0sX (pas eth0), vérifier avec ip a
- Respecter le nommage exact : login+S et login+SW
- IPs imposées : 192.168.56.110 et .111
- Le token ne doit jamais être écrit "en dur" à la main, il doit être récupéré automatiquement par le script

-------------------

Vagrant = le câble → il crée le réseau, donne les IP fixes, permet aux deux VM de se joindre physiquement. Sans lui, pas de route entre les deux machines.
K3s = celui qui utilise le câble → il s'en sert pour établir la relation chef/assistant (avec le token comme preuve d'autorisation), et pour faire vivre le cluster ensuite (surveiller que tout va bien, distribuer le travail, etc.)

Vagrant fournit le réseau (la route entre les deux machines), et K3s l'utilise pour établir et maintenir la relation "chef ↔ assistant" qui forme le cluster. Sans Vagrant → pas de route possible. Sans K3s → une route qui ne sert à rien, aucune organisation du travail.

Vagrant
"Vagrant est un outil qui permet de créer et configurer des machines virtuelles automatiquement à partir d'un seul fichier de configuration (le Vagrantfile). Au lieu d'installer une VM à la main en cliquant dans une interface, on décrit dans ce fichier ce qu'on veut (l'OS, l'IP, les ressources, les scripts à exécuter au démarrage), et Vagrant se charge de tout créer de façon identique et reproductible à chaque fois."

K3s
"K3s est une distribution légère de Kubernetes, l'outil qui orchestre des conteneurs sur plusieurs machines. Il permet de faire tourner un cluster : un nœud en mode serveur qui pilote et prend les décisions, et un ou plusieurs nœuds en mode agent qui exécutent le travail. K3s est plus simple et plus léger que Kubernetes classique, pensé pour des environnements avec peu de ressources."

Différence entre Vagrant et K3s:
Vagrant crée les machines et le réseau qui les relie. K3s, lui, tourne à l'intérieur de ces machines et les fait fonctionner ensemble comme un cluster. Vagrant s'arrête une fois la VM créée ; K3s continue de tourner en permanence pour faire vivre le cluster.

------------------
*****Résumé des notions clés de la Partie 1
Le but : prouver qu'on sait créer un mini-cluster de 2 machines qui travaillent en équipe.

Les 4 notions essentielles :

Vagrant = l'outil qui crée les VM automatiquement à partir d'un fichier de config (le Vagrantfile). Il gère aussi tout le cycle de vie ensuite (up, ssh, halt, destroy...). Il fournit également le réseau privé entre les VM (les IP fixes).

K3s = la version légère de Kubernetes qui tourne en permanence à l'intérieur des VM. Il a deux modes :

serveur/controller (sur le chef) → pilote le cluster, expose l'API
agent (sur l'assistant) → exécute le travail, reste connecté au serveur
Le token = la preuve d'autorisation que l'agent doit présenter pour rejoindre le cluster du serveur. Il est généré automatiquement par K3s côté serveur, et il faut le récupérer automatiquement (pas de copier-coller à la main).

Le dossier partagé /vagrant = le mécanisme qui permet à l'assistant de récupérer ce token sans intervention humaine — les deux VM voient le même dossier p1/ de ton PC, monté à l'identique chez elles.

La preuve finale : kubectl get nodes -o wide lancé depuis le chef doit montrer les 2 machines, Ready, avec les bons rôles.

----------------------------------------------------------------------------------------

TEST POUR P1:

vagrant up
→ vérifie que les deux VMs se créent et démarrent sans erreur.


vagrant up
vagrant status
vagrant ssh noleclerS -c "hostname"
vagrant ssh noleclerSW -c "hostname"
vagrant ssh noleclerS -c "ip a"
vagrant ssh noleclerSW -c "ip a"
vagrant ssh noleclerS -c "ls -la /vagrant"

-> Verfier que les deux VMs utlise k3s
vagrant ssh noleclerS -c "sudo systemctl status k3s --no-pager"
vagrant ssh noleclerSW -c "sudo systemctl status k3s-agent --no-pager"

vagrant ssh noleclerS puis kubectl get nodes -o wide
ip a show $(ip route | grep default | awk '{print $5}')



vagrant ssh noleclerS
vagrant ssh noleclerSW
→ vérifie la connexion SSH sans mot de passe sur les deux machines.


vagrant ssh noleclerS -c "nproc; free -h"
→ vérifie que les ressources (1 CPU / 1024MB) sont bien appliquées.

vagrant ssh noleclerS -c "sudo systemctl status k3s"
→ vérifie que K3s tourne en mode serveur sur la première VM.

vagrant ssh noleclerSW -c "sudo systemctl status k3s-agent"  (--no-pager)
→ vérifie que K3s tourne en mode agent sur la deuxième VM.

--> Se connecter au serveur vagrant ssh noleclerS puis kubectl get nodes -o wide 
vagrant ssh noleclerS -c "kubectl get nodes -o wide"
→ le test le plus important : vérifie que les deux nœuds apparaissent bien ensemble et en Ready, preuve que le cluster est formé (server + worker liés).

vagrant ssh noleclerS -c "kubectl get nodes"
(sans sudo devant, en te connectant normalement avec vagrant ssh noleclerS puis en tapant kubectl get nodes toi-même)
→ vérifie que kubectl fonctionne pour l'utilisateur vagrant sans besoin de sudo.

------------

Config:
dasn la premiere vm apres : vagrant ssh noleclerS 
Fait : echo 'export KUBECONFIG=/home/vagrant/.kube/config' >> ~/.bashrc
Puis: source ~/.bashrc

--------------------------------------------------

    PARTIE 2

En mots simples : tu n'as plus besoin de deux VM ici — une seule suffit, avec K3s installé en mode serveur (comme le chef de la Partie 1). Mais cette fois, l'objectif n'est plus de connecter des machines entre elles : c'est de faire tourner PLUSIEURS sites web différents sur cette même VM, et d'apprendre à afficher le bon site selon le nom que tu tapes dans ton navigateur.

Le problème concret : normalement une IP = un site. Ici, tu veux qu'une seule IP (192.168.56.110) affiche 3 sites différents, selon ce que tu demandes. Comment faire la différence si c'est toujours la même IP ? Grâce au "Host" — un champ caché dans chaque requête HTTP (le nom de domaine tapé), même si l'IP de destination reste la même. C'est ce champ que l'Ingress va lire pour savoir quel site te montrer.

Ingress = "l'aiguilleur" : un composant de Kubernetes qui reçoit toutes les requêtes arrivant sur la VM, regarde le Host demandé, et redirige vers le bon site (le bon Service/Pod) en conséquence. Sans Ingress, K3s ne saurait pas quoi faire de 3 sites différents partageant la même IP.

------------------

résumé de la Partie 2 :

Une seule VM avec K3s en mode serveur (pas d'agent cette fois)
3 apps web déployées dedans (app1, app2, app3), chacune dans son propre Deployment
app2 doit avoir 3 réplicas (3 copies du même Pod)
Chaque app est exposée via un Service (adresse interne stable pour la joindre)
Un Ingress fait le tri entre les 3 selon le Host demandé :
  - app1.com -> app1
  - app2.com -> app2
  - tout le reste (par défaut) -> app3
Preuve : une requête sur 192.168.56.110 avec des Host différents affiche le bon site à chaque fois

------------------

GUIDE DETAILLE - PARTIE 2

Objectif final : une seule VM K3s qui fait tourner 3 apps web, avec un Ingress qui choisit la bonne app selon le nom (Host) demandé.

ETAPE 1 - Préparer la VM
- Une seule VM cette fois (nommée login+S), avec K3s installé en mode serveur uniquement
- Peut réutiliser le même principe de script shell que le chef de la Partie 1 (sans la partie agent/token)

ETAPE 2 - Créer les 3 applications (Deployments)
- Des fichiers de configuration Kubernetes (YAML) qui décrivent, pour chaque app :
  - quelle image Docker utiliser (une appli web simple qui répond par exemple "Hello from appX")
  - combien de réplicas (1 pour app1 et app3, 3 pour app2)
- Chaque Deployment crée les Pods correspondants automatiquement

ETAPE 3 - Exposer chaque application (Services)
- Un Service par application (type ClusterIP), qui donne une adresse stable à l'intérieur du cluster pour joindre les Pods de ce Deployment
- Nécessaire car les Pods ont des IP internes qui changent ; l'Ingress a besoin d'une cible stable (le Service) pour rediriger le trafic

ETAPE 4 - Créer l'Ingress (l'aiguilleur)
- Un objet Ingress qui définit des règles de routage basées sur le Host de la requête :
  - Host: app1.com -> Service app1
  - Host: app2.com -> Service app2
  - règle par défaut (aucun Host reconnu) -> Service app3
- K3s installe déjà un Ingress controller (Traefik) par défaut -> pas besoin de l'installer soi-même

ETAPE 5 - Vérifier et prouver
- `k get all` -> vérifier 3 Deployments, 5 Pods au total (1+3+1), 3 Services, tous Running
- Tester avec curl en simulant différents Host :
  curl -H "Host: app1.com" 192.168.56.110 -> doit afficher app1
  curl -H "Host: app2.com" 192.168.56.110 -> doit afficher app2
  curl -H "Host: n-importe-quoi.com" 192.168.56.110 -> doit afficher app3 (par défaut)

Points de vigilance :
- Une seule VM ici, pas deux (ne pas confondre avec la Partie 1)
- Le hostname de la VM = login + S
- app2 doit précisément avoir 3 réplicas -> vérifiable avec `k get deployments`
- Il faut une règle "par défaut" dans l'Ingress pour app3 (le sujet dit "otherwise, app3 sera sélectionné par défaut")
- L'IP reste 192.168.56.110 dans tous les cas, seul le Host change selon l'app demandée

------------------

Ce qui est nouveau (les vraies notions clés de la Partie 2) :

Deployment → le fichier de config qui dit "je veux faire tourner telle appli, avec tant de réplicas". C'est lui qui crée les Pods automatiquement.

Pod → l'unité de base qui fait réellement tourner ton appli (le "conteneur en action"). Un Deployment avec 3 réplicas = 3 Pods identiques.

Réplicas → le nombre de copies d'une même appli qu'on fait tourner en parallèle (app2 en a 3).

Service → l'adresse stable à l'intérieur du cluster pour joindre les Pods d'un Deployment (utile car les Pods eux-mêmes ont des IP qui changent).

Ingress → "l'aiguilleur" qui reçoit toutes les requêtes et les redirige vers le bon Service selon le nom demandé.

Host → le nom (ex: app1.com) tapé/envoyé dans la requête, qui permet de distinguer plusieurs sites même s'ils partagent la même IP.

En résumé : la Partie 1 = notions d'infrastructure (créer des machines, les relier). La Partie 2 = notions Kubernetes pures (comment on décrit et route des applications à l'intérieur d'un cluster déjà existant).
--------------------

curl/navigateur → Ingress (lit le Host) → Service (de la bonne appli) → Pod (de cette appli)

Un Deployment (décrit l'appli à faire tourner)
Un Service (donne une adresse stable pour la joindre)

Requête (Host: app1.com)
   → Ingress lit le Host de la requete
      → redirige vers Service-app1 (et lui seul)
         → Service-app1 choisit un Pod parmi ceux d'app1
            → réponse : "Hello from app1"

Requête (Host: app2.com) --> a 3 replicas donc 3 pods
   → Ingress → Service-app2
      → Service-app2 a 3 Pods disponibles, en choisit un (tour à tour)
         → réponse : "Hello from app2" (peu importe lequel des 3 a répondu, le résultat est identique)

--------

image: hashicorp/http-echo
args: ["-text=Hello from app1"]
La plus simple de toutes — pas de command/echo/&& à écrire, juste un argument direct
Image minuscule, démarre très vite

-------------

Partie 2:

OBJECTIF:
Déployer 3 applications web différentes sur une seule instance K3s, accessibles depuis une unique IP mais routées vers le bon site grâce au nom d'hôte (Host) demandé, avec l'une d'elles répliquée sur 3 instances.

BUT PEDAGOGIQUE:
Apprendre les briques de base de Kubernetes pour décrire et exposer des applications (Deployment, Service, Ingress) et comprendre comment un cluster peut héberger plusieurs services distincts derrière un seul point d'entrée réseau.

NOTIONS CLES:
1. Deployment
Décrit une application à faire tourner : quelle image utiliser, combien de copies (réplicas). Kubernetes lit cette description(voir fichier deployment.yaml) et crée automatiquement les Pods correspondants — un par réplica demandé.

deployment.yaml: decrit l'application app1(et autres) : crée 1 Pod, étiqueté app: app1, faisant tourner un conteneur basé sur l'image hashicorp/http-echo, configuré pour répondre Hello from app1.

2. Pod
L'instance réellement active de l'application, celle qui tourne et répond aux requêtes. Un Deployment avec 3 replicas génère 3 Pods identiques.
*Ce qu'il contient : un conteneur, créé automatiquement à partir de l'image référencée dans le Deployment (ici, hashicorp/http-echo) — c'est Kubernetes (via K3s et son container runtime, containerd) qui transforme cette image en conteneur actif, sans intervention manuelle.
*Ce qu'il possède : sa propre adresse IP interne (accessible uniquement à l'intérieur du cluster, jamais directement depuis l'extérieur).
*Son rôle : c'est le Pod (plus précisément, le conteneur qu'il fait tourner) qui répond réellement aux requêtes — le Deployment ne fait que décrire, le Service ne fait que rediriger, mais c'est le Pod qui exécute et génère la réponse.
*Sa relation avec les réplicas : un Deployment avec replicas: 3 (comme app2) crée 3 Pods identiques, chacun une instance indépendante de la même application.

3. Service
Le pont entre l'Ingress et les Pods : il reçoit le trafic redirigé par l'Ingress et le transmet à un Pod disponible parmi ceux qu'il cible (via une étiquette partagée). Il fournit une adresse stable, indépendante des IP changeantes des Pods, et répartit la charge entre plusieurs Pods si l'application a plusieurs réplicas.

service.yaml : décrit une adresse stable (nommée app1 etc...) qui cible tous les Pods portant l'étiquette app: app1, et fait la traduction entre le port 80 (utilisé pour la contacter) et le port 5678 (celui réellement écouté par le conteneur).

4. Ingress
Le point d'entrée qui reçoit toutes les requêtes externes, lit le Host demandé, et redirige vers le bon Service. Si aucun Host connu n'est reconnu, une règle par défaut redirige automatiquement vers app3.

ingress.yaml: le fichier qui contient les règles de routage qui décident vers quel Service envoyer chaque requête, selon le Host demandé.

5. Host
Le Host est un champ de la requête HTTP qui précise le nom de domaine demandé (app1.com, app2.com...), indépendamment de l'IP de destination. C'est ce champ que l'Ingress utilise pour distinguer les 3 applications, qui partagent pourtant la même IP.
Ex: curl -H "Host: app1.com" 192.168.56.110


Test P2

Aller dans p2/
vagrant up

vagrant status

vagrant ssh noleclerS -c "hostname"

vagrant ssh noleclerS -c "ip a"

vagrant ssh noleclerS -c "sudo systemctl status k3s --no-pager" (verifie que k3s tourne)

vagrant ssh noleclerS -c "kubectl get nodes -o wide" (verif que le La vm noleclerS est en mode ready)

vagrant ssh noleclerS -c "kubectl get all" (verif que tous les Pods sont bien crees)

vagrant ssh noleclerS -c "kubectl get ingress" A VERIFIER 

Exécuter hosts.sh sur la machine hôte (pas dans la VM !) 
-> bash ~/Bureau/IOT/p2/scripts/hosts.sh

Tester le routage pour chaque application (depuis la machine hôte)
-> curl http://app1.com

-> curl http://app2.com

-> curl http://192.168.56.110

Ouvrir un navigateur -> http://app1.com

kubectl get ingress
kubectl describe ingress apps-ingress

--------------------
Ingress -> Service -> Pod -> Reponse

K3s = version allégée de Kubernetes, qui crée et gère automatiquement des applications
K3s = une version allégée de Kubernetes, qui sert à créer, faire tourner, et maintenir en vie automatiquement des applications, réparties dans des "pods".

kubectl = l'outil en ligne de commande pour envoyer tes instructions (fichiers YAML) à K3s (kubectl apply -f ...)

la notion clé ici est de montrer comment Kubernetes permet d'exposer plusieurs applications différentes derrière une seule adresse IP, en utilisant un système de routage intelligent (l'Ingress) basé sur le Host demandé, tout en gérant la résilience et la répartition de charge via les Deployments et Services.

VM (la maison)
  └── K3s (le gestionnaire de l'immeuble, qui tourne dans la maison)
        └── Pods/Applications (les locataires, gérés par K3s)

-----------------------------------------------

PARTIE 3

Objectif : Déployer une application dans un cluster K3d, avec Argo CD qui synchronise automatiquement le cluster dès qu'un changement est poussé sur GitHub.(mettre en place une chaîne GitOps)

But pédagogique : Apprendre le GitOps (Git = source de vérité) et K3d (alternative à Vagrant+K3s, plus légère). (comment automatiser le déploiement d'applications dans Kubernetes grâce à des outils modernes comme Argo CD et K3d.)


Notions clés:
Argo CD : 
Argo CD (dans son namespace) surveille GitHub
   → et déploie/met à jour le Pod de l'appli (dans le namespace dev)

Argo CD, qui vit dans le namespace argocd, gère et met à jour l'application, qui elle vit dans le namespace dev — ce sont deux Pods séparés, dans deux 'boîtes' séparées, mais Argo CD a le droit d'agir sur ce qui se passe dans dev.

Argo cd: est l'outil qui automatise le deploiment, il surveille un dossier/fichier précis sur Github, compare avec ce qui tourne dans le cluster, et met a jour l'application tout seul des qu'une difference est detectée, sans commande manuelle de notre part.

Namespace: Outil qui permet d'heberger Argo Cd et l'application
Namespace 1 = Argo CD : va heberger Argo CD
Namespace 2 = dev : va heberger l'application à deployer.

K3d = "K3s in Docker" , outil qui fait tourner K3s a l'intérieur de conteneurs Docker plutot que sur une VM, rendant la création de clusters Kubernetes beaucoup plus rapide et légere.

Partie 1 : Vagrant crée une VM → K3s s'installe directement sur le système de cette VM
Partie 3 : K3d demande a Docker de créer des conteneurs Docker → K3s tourne à l'intérieur de ces conteneurs, eux-mêmes hébergés dans la VM de travail.

Docker = le logiciel (l'outil) qui sait créer et faire tourner des conteneurs
Image Docker (ex: hashicorp/http-echo) = le modèle figé, pas encore actif — comme l'ISO d'Ubuntu
Conteneur = l'image démarrée, en train de tourner réellement — comme la VM une fois Ubuntu installé et lancé


1. Installer Docker dans IOT
2. Installer K3d dans IOT
3. K3d demande à Docker de créer un conteneur, à partir d'une image contenant K3s
4. Docker crée et démarre ce conteneur — pas nous manuellement
5. K3s tourne alors à l'intérieur



┌──────────────────────────────────────────────────┐
│ La vraie machine (l'ordi physique)               │
│                                                  │
│  ┌────────────────────────────────────────────┐  │
│  │ IOT (la VM)                                │  │
│  │                                            │  │
│  │  Docker tourne ici (installé sur IOT)      │  │
│  │                                            │  │
│  │  ┌──────────────┐      ┌───────────────────┐│ │
│  │  │Conteneur     │◄────►│  Conteneur        ││ │
│  │  │load balancer │      │  "serveur"        ││ │
│  │  │  (le pont)   │      │  (contient K3s)   ││ │
│  │  └──────┬───────┘      │          |         ││ │
│  │         │              │  ┌───────────────┐││ │
│  │   accessible           │  │Namespace argocd ││
│  │   depuis IOT           │ └─ Pod Argo CD │ ││
│  │   (terminal, kubectl)  │└───────────────┘ ││
│  │                        │ ┌───────────────┐ ││
│  │                        │ │Namespace dev   │ │
│  │                        │ │ └─ Pod ton appli││
│  │                        │ └───────────────┘ ││
│  │                        └───────────────────┘│
│  └────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────┘


Docker creer deux conteneurs (a partir d'une image donnée par K3d contenant k3s dedans) dont un par defaut:
-> K3s le conteneur serveur 
-> Le load balancer : conteneur creer par defaut = pont entre l'exterieur et le cluster K3s

K3s creer le pod avec la'ppli wil42. K3d n'intervient plus une fois le cluster créé — son travail s'arrête là.
C'est ensuite K3s qui reçoit le Deployment (via Argo CD qui l'applique) et qui crée réellement le Pod.

-----------------------------------------------
résumé de la Partie 3 :

Installer Docker + K3d dans IOT2 (script d'installation obligatoire, exigé par le sujet)
K3d crée un cluster K3s à l'intérieur de conteneurs Docker 
Créer 2 namespaces : argocd (héberge Argo CD) et dev (héberge notre application)
Créer un repo GitHub public contenant le fichier Deployment de l'application (wil42/playground ou notre propre appli), taguée v1
Configurer Argo CD pour surveiller ce repo et synchroniser automatiquement le namespace dev
Preuve : changer le tag v1 → v2 dans le fichier sur GitHub, push, et voir l'appli se mettre à jour toute seule sans commande kubectl manuelle

------------------

GUIDE DETAILLE - PARTIE 3

Objectif final : un cluster K3d avec Argo CD qui déploie et met à jour automatiquement une application depuis un repo GitHub public.

ETAPE 1 - Créer le script d'installation
- Script shell qui installe Docker, puis K3d (obligatoire selon le sujet : "you must write a script to install all the necessary packages and tools")
- S'exécute sur IOT2 (pas de VM imbriquée cette fois, contrairement à p1/p2)

ETAPE 2 - Créer le cluster K3d
- Une commande crée le(s) conteneur(s) : au minimum un conteneur "serveur" (contient K3s) + un conteneur "load balancer" (pont réseau vers l'extérieur du réseau Docker)
- K3d configure automatiquement kubectl pour parler à ce nouveau cluster (pas besoin de bricoler ~/.kube/config comme en p1)

ETAPE 3 - Créer les 2 namespaces
- kubectl create namespace argocd
- kubectl create namespace dev

ETAPE 4 - Installer Argo CD dans le namespace argocd
- Argo CD lui-même tourne sous forme de Pods, à l'intérieur du cluster qu'il va gérer

ETAPE 5 - Préparer le repo GitHub public
- Créer un repo public (login d'un membre du groupe dans le nom, exigé par le sujet)
- Contient au minimum un fichier deployment.yaml décrivant l'application (wil42/playground:v1, port 8888, ou une appli perso avec 2 tags différents sur Docker Hub)

ETAPE 6 - Configurer Argo CD pour surveiller ce repo
- Dire à Argo CD : quel repo GitHub, quel dossier/chemin précis, quel namespace cible (dev)
- Dès cette config faite, Argo CD applique automatiquement le deployment.yaml trouvé → crée le Pod dans dev

ETAPE 7 - Vérifier et prouver (preuve exacte du sujet)
- curl http://localhost:8888/ → doit répondre {"status":"ok","message":"v1"}
- Modifier deployment.yaml sur GitHub : v1 → v2, git push
- Attendre qu'Argo CD détecte le changement et resynchronise (automatique, sans kubectl apply manuel)
- curl http://localhost:8888/ → doit maintenant répondre "v2"

Points de vigilance :
- Le script d'installation (Docker + K3d) est explicitement obligatoire pour cette partie, contrairement à p1
- comprendre la différence K3s vs K3d 
- Le repo GitHub DOIT être public (Argo CD doit pouvoir le lire depuis Internet)
- Ne jamais oublier de git push après une modification — sans ça, Argo CD ne voit rien
- Argo CD remplace seulement l'étape kubectl apply côté cluster , pas le push sur Github

------------------

NOTIONS CLES

1. K3d
"K3s in Docker" — outil qui fait tourner K3s à l'intérieur de conteneurs Docker plutôt que sur une VM complète, rendant la création de clusters Kubernetes beaucoup plus rapide et légère.

Comparaison directe avec la Partie 1 :
| Rôle |                         Partie 1 (VM) |                            Partie 3 (Docker) |
| L'orchestrateur |                 Vagrant |                                    K3d |
| Le moteur |                       VirtualBox |                                 Docker |
| Le résultat créé |                   la VM |                                   le conteneur |
| Ce qui tourne dedans |      K3s (installé via notre script) |        K3s (déjà intégré dans l'image utilisée) |

2. Docker / Image / Conteneur
Docker = le logiciel (l'outil) qui sait créer et faire tourner des conteneurs.
Image Docker (ex: hashicorp/http-echo, wil42/playground) = le modèle figé, pas encore actif — équivalent d'un ISO ou d'une box Vagrant, mais pour les conteneurs.
Conteneur = l'image démarrée, en train de tourner réellement — équivalent d'une VM une fois son OS installé et lancé.

Différence fondamentale VM vs Conteneur :
- VM : VirtualBox simule du matériel complet, un OS entier et indépendant tourne dessus, avec son propre noyau
- Conteneur : Docker utilise le noyau déjà existant de la machine hôte (IOT) et isole juste un programme — pas de nouveau système à démarrer, donc beaucoup plus rapide et léger
- Avantage VM : isolation plus forte, peut faire tourner un OS différent de l'hôte
- Avantage conteneur : ultra léger, démarrage quasi instantané, très économe en RAM/CPU/disque
- Le réseau : Docker crée un réseau privé logiciel entre ses conteneurs, mais en utilisant toujours le réseau de la machine hôte (IOT) comme base

3. Les rôles de Docker liés au conteneur
Télécharger l'image si besoin, créer le conteneur à partir de cette image, le démarrer/arrêter, l'isoler des autres programmes de la machine, lui donner accès aux ressources (CPU/RAM).

4. Ce qui se passe entre la création du cluster et K3s qui tourne
   1. On lance la commande de création K3d
   2. K3d vérifie/télécharge l'image spéciale contenant K3s
   3. K3d crée un réseau Docker dédié
   4. K3d demande à Docker de créer le conteneur "serveur" → dès son démarrage, K3s se lance automatiquement dedans (pas de script d'installation à écrire, contrairement à p1)
   5. K3d crée aussi un conteneur "load balancer" séparé
   6. K3d configure automatiquement kubectl sur IOT

5. Le conteneur "load balancer"
Un conteneur séparé (pas imbriqué dans le conteneur serveur, un voisin côte à côte), dont le seul rôle est de faire le pont entre l'extérieur du réseau Docker (IOT, notre terminal/kubectl) et le conteneur serveur qui contient K3s, cachés dans le réseau privé de Docker.
Comparable à l'Ingress de la Partie 2 dans l'idée (un point d'entrée qui redirige), même si techniquement à un niveau différent (Docker vs Kubernetes).

6. Namespace
Une façon de cloisonner des ressources à l'intérieur d'un même cluster — comme des appartements séparés dans un même immeuble.
Namespace "argocd" → héberge les Pods d'Argo CD lui-même (son propre fonctionnement interne)
Namespace "dev" → héberge le Pod de notre application déployée (celle qu'Argo CD surveille et met à jour)

7. Argo CD
Outil de déploiement continu (GitOps) : surveille en permanence un dossier/fichier précis sur GitHub (le deployment.yaml de notre appli), compare avec ce qui tourne dans le cluster, et synchronise automatiquement dès qu'une différence est détectée — sans commande manuelle de notre part.
Argo CD remplace seulement l'étape kubectl apply.
Tourne lui-même sous forme de Pods, à l'intérieur du namespace argocd du cluster qu'il gère.
Pas un composant natif de Kubernetes — un projet séparé (hébergé par la CNCF, comme Kubernetes), mais conçu spécifiquement pour piloter des clusters Kubernetes.

Sans Argo CD, ce qui se passerait dans le même scénario :
- Push sur GitHub → rien ne se passe automatiquement dans le cluster
- Il faudrait taper soi-même kubectl apply -f deployment.yaml à CHAQUE changement, à la main, à chaque fois
- Argo CD supprime exactement ce geste manuel répétitif

8. La chaîne complète GitOps
Toi : tu modifies deployment.yaml (ex: v1 → v2) → git add/commit/push (TOUJOURS manuel)
   → le fichier est maintenant sur GitHub
      → Argo CD (qui surveille en permanence) voit que le repo a changé
         → Argo CD applique AUTOMATIQUEMENT ce changement au cluster (équivalent de kubectl apply, mais automatique et répété)
            → K3s crée/met à jour le Pod dans le namespace dev


------------------

TEST P3 (à faire une fois l'implémentation terminée)

k3d cluster list
→ vérifie que le cluster existe

kubectl get nodes
→ vérifie que le(s) nœud(s) du cluster K3d sont Ready

kubectl get ns
→ doit afficher argocd et dev dans la liste

kubectl get pods -n argocd
→ vérifie que les Pods d'Argo CD tournent

kubectl get pods -n dev
→ vérifie que le Pod de l'application tourne

cat deployment.yaml | grep v1
curl http://localhost:8888/
→ doit répondre {"status":"ok","message":"v1"}

# modifier deployment.yaml sur GitHub : v1 → v2, puis git push
curl http://localhost:8888/
→ doit maintenant répondre {"status":"ok","message":"v2"}, sans commande kubectl manuelle entre les deux

------------------

Partie 3:

OBJECTIF:
Déployer une application dans un cluster K3d (Kubernetes dans des conteneurs Docker), avec Argo CD qui synchronise automatiquement le cluster dès qu'un changement est poussé sur GitHub (chaîne GitOps).

BUT PEDAGOGIQUE:
Apprendre le GitOps (Git = source de vérité) et K3d (alternative à Vagrant+K3s, plus légère et plus rapide), et comprendre comment automatiser le déploiement d'applications dans Kubernetes.

NOTIONS CLES:
1. K3d
"K3s in Docker" — outil qui fait tourner K3s à l'intérieur de conteneurs Docker plutôt que sur une VM complète. K3d demande à Docker de créer un conteneur "serveur" à partir d'une image contenant déjà K3s, qui se lance automatiquement dès le démarrage du conteneur — pas de script d'installation à écrire, contrairement à p1.

2. Docker / Image / Conteneur
Docker = l'outil qui crée et gère les conteneurs. Image (ex: hashicorp/http-echo, wil42/playground) = le modèle figé, équivalent d'un ISO/box Vagrant mais pour les conteneurs. Conteneur = l'image démarrée, en train de tourner. Contrairement à une VM (qui a son propre OS complet), un conteneur partage le noyau de la machine hôte (IOT2) — plus léger, démarrage quasi instantané.

3. Conteneur load balancer
Un conteneur séparé, créé par défaut par K3d en plus du conteneur serveur, dont le seul rôle est de faire le pont entre l'extérieur du réseau Docker (IOT2, notre terminal/kubectl) et le conteneur serveur qui contient K3s. Comparable à l'Ingress de la Partie 2 dans l'idée (point d'entrée qui redirige).

4. Namespace
Une façon de cloisonner des ressources à l'intérieur d'un même cluster. Namespace "argocd" → héberge les Pods d'Argo CD. Namespace "dev" → héberge le Pod de notre application déployée.

5. Argo CD
Outil de déploiement continu (GitOps) : surveille en permanence un fichier précis sur GitHub (deployment.yaml), compare avec ce qui tourne dans le cluster, et synchronise automatiquement dès qu'une différence est détectée. Ne remplace jamais git add/commit/push (toujours manuel) — remplace seulement l'étape kubectl apply côté cluster.
Sans Argo CD : chaque changement resterait sans effet sur le cluster tant qu'on n'a pas retapé kubectl apply -f à la main, à chaque fois.

deployment.yaml: le fichier que Argo CD surveille sur GitHub — contient l'image et sa version (ex: wil42/playground:v1). C'est en changeant cette ligne (v1 → v2) et en la poussant sur GitHub que la mise à jour automatique se déclenche.


Test P3

k3d cluster list
→ vérifie que le cluster existe

kubectl get nodes
→ vérifie que le(s) nœud(s) K3d sont Ready

kubectl get ns
→ doit afficher argocd et dev

kubectl get pods -n argocd
→ vérifie que les Pods d'Argo CD tournent

kubectl get pods -n dev
→ vérifie que le Pod de l'application tourne

curl http://localhost:8888/
→ doit répondre {"status":"ok","message":"v1"}

# modifier deployment.yaml sur GitHub (v1 → v2), git push

curl http://localhost:8888/
→ doit répondre {"status":"ok","message":"v2"}, sans commande kubectl manuelle entre les deux
--------------------

1. Créer le cluster K3d
2. Créer les namespaces
3. Installer Argo CD, le configurer pour déployer l'appli
4. Argo CD déploie l'appli → le Service "wil-playground" existe maintenant
5. → LANCER le port-forward (une seule fois, il tourne en arrière-plan)
6. curl http://localhost:8888/  → teste v1
7. (plus tard) modifier v1→v2, push, attendre la synchro
8. curl http://localhost:8888/  → teste v2 (pas besoin de relancer le port-forward, il tourne toujours)
----------------

kubectl : l'outil en ligne de commande qui permet de parler a un cluster Kubernetes.
Le fichier ~/.kube/config = contient l'adresse du cluster, et l'identifiant admin (un code secret qui prouve que tu as le droit de l'appeler).

Quand k3s demarre -> un identifiant admin(certificat) est generer automatiquement par k3s.
K3d copie cet identifiant admin dans le fichier ~/.kube/config
kubectl consulte ce fichier 

Une image Docker peut avoir plusieurs "tags" — ce sont des versions différentes, nommées, d'une même appli. 


K3s démarre → génère son identifiant admin (certificat)
   → K3d récupère (adresse + identifiant) → crée ~/.kube/config (déjà rempli)

Toi : kubectl get nodes
   → kubectl lit ~/.kube/config (adresse + identifiant)
      → kubectl envoie la requête réelle au cluster, avec le certificat joint
         → K3s vérifie le certificat, traite la demande, répond
            → kubectl affiche la réponse



Image complète	      Organisation	      Nom (famille)	   Tag (version)
wil42/playground:v1	    wil42	             playground	         v1
wil42/playground:v2	    wil42	             playground	         v2
hashicorp/http-echo	   hashicorp	         http-echo	     (rien précisé)

kubectl parle à l'API de Kubernetes/K3s en général ; argocd (le binaire CLI) parle spécifiquement à l'API d'Argo CD — deux outils différents, pour parler à deux "interlocuteurs" différents.

argocd login ...        → se connecter à Argo CD (avec le mot de passe admin)
argocd repo add ...     → dire à Argo CD "voici un repo GitHub que tu as le droit de lire"
argocd app create ...   → LA commande clé : dit à Argo CD précisément quoi surveiller (quel repo, quel dossier, quel namespace cible) et de synchroniser automatiquement


dès que K3d crée le cluster, il fait automatiquement télécharger et démarrer l'image contenant K3s, en une seule commande.
-------

install.sh: script qui prepare tous les outils en ligne de commnade necessaire : installe
-> Docker (pour faire tourner des conteneurs)
-> argocd(le binaire CLI, la commande argocd pour parler a Argo CD(le pod qui tourne reellement))
-> K3d (pour creer le cluster)
-> kubectl (pour parler au cluster)


start.sh : utiliser ces outils pour créer/configurer tout :
-> creer le cluster k3d (conteneur serveur + load balancer, créés automatiquement)(k3d cluster create)
-> creer les deux namespaces : argocd et dev (kubectl create namespace)
-> installe reellement Argo CD dans le cluster (kubectl apply -f .../install.yaml)
-> Attendre qu'Argo CD soit prêt
-> Récupérer le mot de passe admin d'Argo CD depuis le Secret
-> Creer le tunnel vers Argo CD (kubectl port-forward svc/argocd-server ... 8080:443 &)
   puis attendre que le tunnel soit vraiment actif (nc -z localhost 8080)
-> Se connecter (argocd login, rendu possible grâce à ce tunnel qui vient d'être créé)
-> Configurer Argo CD pour surveiller notre repo/dossier (argocd app create ,Crée l'"Application" Argo CD — la        commande la plus importante, celle qui dit précisément quoi surveiller)

Le certificat du kubeconfig → pour parler à Kubernetes/K3s (via kubectl) se trouve dans un vrai fichier standard (~/.kube/config), automatiquement maintenu.

Le mot de passe admin d'Argo CD → pour parler à Argo CD lui-même (via argocd ou son interface web) est stocké dans le cluster (comme Secret), pas un fichier standard local — c'est à récupérer manuellement si besoin
---> Par Ex: Juste au moment de se connecter (argocd login) 

Le deployment.yaml est la description complète (quelle image, combien de copies) de ce qu'on veut faire tourner. K3s le lit et crée le(s) Pod(s) correspondant(s) 

fichier deployment.yaml : decrit une appli à faire tourner cad quelle image utiliser(le programme),et combien de copies en creer(replicas). C'est la description que Kubernetes lit pour savoir exactement quoi creer comme pods.

A faire un dossier manifest puis dedans un dossier app et dans app le fichier deployment.yaml


Tableau récapitulatif

Ressource	                      Groupe	               apiVersion complet
Pod, Service, Namespace	         core (sans nom)	            v1
Deployment	                     apps	                      apps/v1
Ingress	                         networking.k8s.io	      networking.k8s.io/v1


Le groupe dit QUELLE catégorie de ressource on décrit (apps pour Deployment, networking.k8s.io pour Ingress...), et v1 dit QUELLE version stable de ce format on utilise — les deux sont fixes, à copier tels quels, jamais liés à notre propre application.
----------

Difference entre K3s et K3d:
-Kubernetes = tout un système qui permet de gérer un cluster (créer/maintenir des applications réparties sur plusieurs machines)
-K3s = une version allégée de ce système, plus simple à installer
-K3d = pas un Kubernetes lui-même, mais un outil qui installe et fait tourner K3s dans un conteneur Docker, plutôt que sur une VM

On parle a K3s via kubectl.
K3d creer le fichier kube-config et y copie (IP + certificat) que k3s a generé.
Argo CD utilise un mot d passe admin(stocké dans un secret Kubernetes, et non un fichier automatique).

Le Pod n'existe PAS encore, nulle part, tant qu'on n'a pas écrit et appliqué le deployment.yaml. C'est cette action précise (écrire le fichier + l'appliquer via Argo CD) qui fait naître le Pod pour la première fois — en utilisant l'image de Wil comme "ingrédient". C'est K3s qui le lit le fichier .yaml et creer reellement le Pod.

Dans  fichier deployment.yaml:
image: wil42/playground:v1    ← "utilise CE kit précis (celui de Wil, version v1)"
replicas: 1                    ← "fais-en cuire 1 exemplaire"
containerPort: 8888             ← "sers-le sur ce port"

La chaîne GitOps va d'un simple changement de texte dans un fichier sur GitHub, jusqu'à la mise à jour automatique et réelle de l'appli qui tourne dans le cluster — sans intervention manuelle entre les deux.

CHAINE GITOPS:
1. TOI : tu écris/modifies deployment.yaml (image: wil42/playground:v1)
2. TOI : git add, commit, push → le fichier est sur GitHub
3. Argo CD (déjà configuré pour surveiller ce chemin) détecte que le fichier existe/a changé
4. Argo CD applique automatiquement ce fichier au cluster (équivalent de kubectl apply, mais automatique)
5. K3s lit le fichier, crée le Pod (image wil42/playground:v1) dans le namespace "dev"
6. TOI : tu testes avec curl → tu vois "v1"

--- plus tard, pour tester le changement de version ---

7. TOI : tu modifies deployment.yaml (v1 → v2), tu push à nouveau
8. Argo CD détecte CE nouveau changement
9. Argo CD applique automatiquement la mise à jour
10. K3s remplace le Pod par une version utilisant l'image v2
11. TOI : tu testes à nouveau avec curl → tu vois maintenant "v2", sans avoir tapé aucune commande kubectl toi-même

------
namespace argocd heberge le logiciel Argo CD lui meme
namespace dev heberge l'appli de Wil

p3/
├── scripts/
│   └── (nos scripts .sh)
└── confs/
    └── deployment.yaml
    └── service.yaml


Le tunnel (port-forward):
Le problème de base : Argo CD tourne à l'intérieur du cluster (comme un Pod, avec un Service qui lui donne une adresse) — mais cette adresse est interne, seulement joignable depuis l'intérieur du cluster. Depuis ton terminal IOT2, tu ne peux pas l'atteindre directement.

Ce que fait le tunnel : kubectl port-forward crée un pont temporaire entre un port de ta machine (localhost:8080) et le Service d'Argo CD, à l'intérieur du cluster. Tout ce que tu envoies à localhost:8080 est automatiquement redirigé jusqu'à Argo CD, et sa réponse revient par le même chemin.

Pourquoi on en a besoin, précisément ici : parce qu'on veut utiliser la commande argocd login (et potentiellement l'interface web) depuis le terminal d'IOT2 pour configurer Argo CD — sans ce tunnel, argocd login localhost:8080 échouerait, puisqu'il n'y aurait littéralement rien qui écoute sur ce port depuis l'extérieur du cluster.

Analogie, reprise : Argo CD est dans un quartier fermé (le réseau interne du cluster), sans porte donnant sur la rue. Le port-forward, c'est un tuyau temporaire qu'on installe depuis la rue (IOT2) directement jusqu'à la porte d'Argo CD — le temps qu'on en ait besoin, pas une installation permanente.

Point important à retenir : c'est temporaire et manuel — dès que tu arrêtes ce tunnel (ou éteins la VM), il faut le relancer si tu veux à nouveau parler à Argo CD depuis l'extérieur.
---------

Le tunnel connecte toujours la machine à un Service (l'adresse stable), jamais directement à un Pod.
------------
Notions sur les Ports:

curl → port du Service → le Service redirige en interne → targetPort du Pod

ports:
  - port: 80          ← le port du SERVICE (ce qu'on contacte)
    targetPort: 5678  ← le port RÉEL du Pod (imposé par le programme lui-même)
-------------

Chapitre 1 — Préparer les outils

Tout commence sur IOT2, avec un script install.sh. Ce script installe 4 outils, un par un : Docker (le moteur qui saura créer et gérer des conteneurs), K3d (l'outil qui va orchestrer la création d'un cluster K3s dans ces conteneurs), kubectl (pour pouvoir parler au futur cluster), et le binaire argocd (la télécommande pour parler à Argo CD plus tard). Rien n'est encore créé à ce stade — on prépare juste la boîte à outils.

Chapitre 2 — Le cluster naît

Le script start.sh prend le relais. Première commande : k3d cluster create. K3d demande alors à Docker de créer deux conteneurs côte à côte : un conteneur "serveur", dans lequel K3s démarre immédiatement et automatiquement, et un conteneur "load balancer", qui sert de pont entre l'extérieur du réseau Docker (IOT2) et ce cluster caché à l'intérieur.

Au moment même où K3s démarre dans son conteneur, il génère lui-même son propre certificat admin — une preuve d'identité qui donnera les pleins pouvoirs sur le cluster. K3d va aussitôt récupérer ce certificat et l'écrire dans le fichier ~/.kube/config sur IOT2, accompagné de l'adresse du cluster. Résultat : kubectl peut immédiatement parler au cluster, sans aucune configuration manuelle — contrairement à toute la galère qu'on avait eue en Partie 1.

Chapitre 3 — Les deux namespaces

Avec kubectl, on crée deux "compartiments" séparés à l'intérieur de ce cluster tout neuf : le namespace argocd, qui va bientôt héberger le logiciel Argo CD lui-même, et le namespace dev, qui accueillera plus tard l'application qu'on veut déployer.

Chapitre 4 — Argo CD s'installe réellement

kubectl apply applique le fichier YAML officiel d'Argo CD, publié par ses propres créateurs, dans le namespace argocd. C'est cette commande précise qui fait naître les vrais Pods d'Argo CD à l'intérieur du cluster — jusque-là, on n'avait que le binaire CLI (la télécommande), maintenant on a le "téléviseur" qui tourne réellement.

Le script attend patiemment que ces Pods soient bien démarrés et en bonne santé (kubectl wait), puis attend encore qu'Argo CD génère, de son côté, son propre mot de passe admin — stocké non pas dans un fichier automatique comme pour K3s, mais dans un Secret Kubernetes, à l'intérieur du cluster. Le script va le chercher manuellement et le récupère.

Chapitre 5 — Configurer Argo CD

Pour pouvoir parler à Argo CD depuis le terminal d'IOT2, il faut d'abord construire un tunnel temporaire (kubectl port-forward svc/argocd-server ... 8080:443) — un pont entre localhost:8080 sur IOT2 et le Service d'Argo CD, caché à l'intérieur du cluster.

Une fois ce tunnel actif, argocd login s'y connecte avec le mot de passe récupéré. Puis, toujours à travers ce même tunnel, deux commandes essentielles : argocd repo add (dire à Argo CD "voici un repo GitHub que tu as le droit de lire"), puis argocd app create, la commande la plus importante de toute la partie — celle qui précise exactement quel repo, quel dossier précis à l'intérieur (p3/confs/), et quel namespace cible (dev) surveiller, avec une synchronisation automatique.

Chapitre 6 — Le fichier qui manquait

Mais attention : à ce stade, Argo CD sait où regarder — encore faut-il que quelque chose existe réellement à cet endroit. C'est là que nous entrons en jeu, séparément des scripts : on écrit un fichier deployment.yaml, qui décrit précisément l'application qu'on veut faire tourner — l'image wil42/playground:v1 (le "kit-repas" préparé par Wil, jamais encore cuisiné), avec 1 réplica, écoutant sur le port 8888. On commit, on push ce fichier sur notre repo GitHub public.

Chapitre 7 — La première synchronisation

Argo CD, qui surveille en permanence ce dossier précis, détecte que le fichier existe désormais. Automatiquement, sans qu'on tape la moindre commande kubectl apply, il applique ce Deployment au cluster. K3s le lit, et fait naître pour la première fois un Pod réel, dans le namespace dev, faisant tourner l'appli de Wil en version v1.

Pour vérifier, on ouvre un deuxième tunnel séparé — cette fois vers le Service de l'appli elle-même (kubectl port-forward svc/wil-playground -n dev 8888:8888), rien à voir avec Argo CD, juste pour nous permettre de tester. curl http://localhost:8888/ répond : {"status":"ok", "message": "v1"}.

Chapitre 8 — La preuve finale

On modifie une seule ligne dans notre fichier deployment.yaml : v1 devient v2. On push ce changement sur GitHub.

Argo CD, toujours en surveillance, détecte cette différence. Il applique automatiquement la mise à jour. Kubernetes fait alors une mise à jour progressive : un nouveau Pod naît, avec l'image v2, et une fois prêt, l'ancien Pod (v1) est supprimé.

On relance curl http://localhost:8888/ — la réponse est maintenant {"status":"ok", "message": "v2"}. Sans jamais avoir tapé une seule commande Kubernetes manuelle pour cette mise à jour — juste un changement de texte et un git push. La boucle GitOps est bouclée, et prouvée.


Docker Hub est le catalogue public en ligne pour les images Docker 
Dans notre projet, notre deployment.yaml référence directement une image hébergée sur Docker Hub — c'est ça qui permet à Kubernetes de la télécharger et de créer le Pod automatiquement.

---------------
start.sh:

ArgoCD demarre -> genere lui-meme son MDP -> creer lui meme le secret pour le stocker -> Le sscript(via kubectl) va chercher ce MDP danc ce secret.

Reuperer le MDP de argoCd -> creer le tunnel vers argocd-server port 8080(sert a se connecter a l'interface web d'ArgoCD, on garde ce tunnel ouvert expres) -> attendre qu'il soit actif (boucle) -> puis utilser les commandes argocd login , argocd repo add, argocd app create  

Un 2eme tunnel est creer pour tester l'appli elle meme 

Tunnel 1:
Ta machine locale (port 8080)
    ↓ tunnel kubectl port-forward
Service argocd-server (namespace argocd, port 443)
    ↓
Pod(s) Argo CD

Tunnel 2:
Ta machine locale (port 8888)
    ↓ tunnel kubectl port-forward
Service wil-playground (namespace dev, port 8888)
    ↓ (le Service utilise le système de labels/selector, comme en P2)
Pod wil-playground-7796fcdb67-j7nss

Donc:
TOI (curl http://localhost:8888)
    ↓
kubectl port-forward (le tunnel)
    ↓
Service "wil-playground" (dans le namespace dev)
    ↓ (grâce au selector/labels)
Pod "wil-playground-7796fcdb67-j7nss" (qui fait vraiment tourner l'application)
    ↓
Réponse : {"status":"ok", "message": "v1"}
--------------

Test P3:

Aller dasn p3 puis -> sudo bash scripts/install.sh

Verifier que l'installation a bien fonctionne:
docker --version
k3d --version
kubectl version --client
argocd version --client

bash scripts/start.sh 
-> Creer le cluster K3d
-> Creer les namespaces
-> Installer Argo CD
-> Se connecter à Argo CD, ajouter le repo GitHub
-> Créer l'Application Argo CD qui va déployer automatiquement wil-playground dans dev

k3d cluster list
kubectl get nodes -o wide -> les noeuds du cluster sont prets
kubectl get ns  -> verifier les namespaces argo cd et dev
kubectl get pods -n argocd  -> les pods dans chaque ns concernee
kubectl get pods -n dev 
kubectl get all -n dev -> Vue complète des ressources dans dev
ps aux | grep "port-forward"  -> Les tunnels (port-forward) actifs
curl -k https://localhost:8080
curl http://localhost:8888/
argocd app get wil-playground
argocd repo list


----------
sudo usermod -aG docker $USER
exit

k3d cluster stop iot 

Vérifier quels port-forwards sont actuellement actifs (Argo CD + App) :
ps aux | grep "port-forward"

Activer le port-forward vers Argo CD (API/interface web, port 8080) :
kubectl port-forward svc/argocd-server -n argocd 8080:443 &

Activer le port-forward vers l'application wil-playground (port 8888) :
kubectl port-forward svc/wil-playground -n dev 8888:8888 &

Test:
curl http://localhost:8888/          # Test app, tunnel vers l'appli de Wil
curl -k https://localhost:8080/      # Test Argo CD , tunnel vers ArgoCD(le -k ignore le certificat auto-signé)
(-k = c'est juste pour dire à curl de faire confiance au certificat HTTPS "maison" généré par Argo CD, plutôt que d'exiger un vrai certificat officiel.)

--revision nofy

commande pour forcer la synchornisation si attente trop long
argocd app sync wil-playground
---------------

arrêter les tunnels port-forward:
pkill -f "kubectl port-forward"

verfier que cela a fonctionne: ps aux | grep "port-forward"

détruire le cluster K3d:
k3d cluster delete iot

k3d cluster list
docker ps
---------

apres start.sh il faut verifier -> argocd app get wil-playground
-----------

SUJET DE CORRECTION P3

1 - Montrer le script d'installation en fonctionnement
-> sudo bash scripts/install.sh

Verif si cela a bien fonctionnee:
docker --version
k3d --version
kubectl version --client
argocd version --client

2 - Démarrer l'infrastructure
-> Verification avant de lancer le script : k3d cluster list
-> k3d cluster delete iot (supprimer un cluster existant)
-> bash scripts/start.sh

Verifier que l'USER est bien dans groupe docker
-> groups

3 - Vérifier la présence et comprendre le contenu des fichiers de config
-> p3/scripts/install.sh (script qui Installe tous les outils nécessaires — Docker, K3d, kubectl, et le CLI argocd — avant de pouvoir monter l'infrastructure)

-> p3/scripts/start.sh (Ce script crée le cluster K3d, les namespaces argocd et dev, installe Argo CD, s'y connecte, puis crée une Application Argo CD qui va automatiquement déployer mon app depuis mon repo GitHub)

-> p3/confs/deployment.yaml (C'est le manifest Kubernetes qui décrit comment déployer l'application wil-playground — quelle image Docker utiliser (wil42/playground:v1), combien de replicas, et sur quel port elle écoute.)

-> p3/confs/service.yaml (Service Kubernetes c'est ce qui permet de contacter mon application via un nom fixe (wil-playground) et un port fixe (8888), sans avoir à connaître l'adresse exacte du pod — qui peut changer à chaque redéploiement)

4 - Vérifier les 2 namespaces ("at least 2 namespaces in K3d: 'argocd' and 'dev'")
-> kubectl get ns 
(montrer argocd et dev, les autres sont créés automatiquement par Kubernetes à chaque cluster, ils gèrent le fonctionnement interne du système)

5 - Vérifier au moins 1 pod dans dev ("at least 1 pod in the 'dev' namespace")
-> kubectl get pods -n dev
(l'appli de Wil doit y etre et visible)

6 - Expliquer la différence entre namespace et pod
Namespace : un contenant de pod (ou plusieurs pods)
Pod : c'est l'enveloppe Kubernetes qui contient un ou plusieurs conteneurs Docker , là où tourne l'application (Wil).
Ici chaque pod wil-playground contient exactement 1 conteneur Docker, celui qui fait tourner l'application."

7 - Vérifier que les services nécessaires tournent
-> kubectl get pods -n argocd (Optionnel: vérifie que les pods d'Argo CD tournent bien (Running)) (A tester -> kubectl get svc)

-> kubectl get svc -n argocd
*** argocd-server -> Le service argocd-server est celui qui expose l'interface web et l'API d'Argo CD, sur le port 443 (HTTPS) en interne. C'est via ce service que je crée mon tunnel port-forward, pour accéder à l'interface depuis mon navigateur sur localhost:8080. (permet d'accéder à l'interface web et de piloter Argo CD)
*** argocd-repo-server : celui qui va chercher les fichiers sur mon repo GitHub

-> kubectl get svc -n dev -> Le service wil-playground expose mon application sur le port 8888 à l'intérieur du cluster. C'est via ce service que j'accède à l'app depuis l'extérieur, grâce au port-forward

8 - Argo CD installé, accessible en navigateur avec login/mot de passe ("You can access it in your web browser. You will need a login and a password")
-> On recupere le MDP generer par ArgoCd ( a utiliser pour la connexion a l interface web de argocd)
-> kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d (on recupere le MDP admin. Ex: NY4ujjZbE530n4Ed)
-> ouvrir https://localhost:8080
-> Username = admin
-> mot de passe = celui qu'on vient de recuperer 
-> Une fois a l'interieur de ArgoCd, Expliquer le schema (Question 11)

9 - Vérifier le login dans le nom du repo GitHub
-> nolecler-IOT 

10 - Vérifier l'image Docker utilisée ("Check that a Docker image is used in the Github repository")
-> cat p3/confs/deployment.yaml | grep image
-> image: wil42/playground:v1
-> On peut verifier directement aussi via l'interface de argoCd

11 - Naviguer dans Argo CD, comprendre son fonctionnement ("try to understand how it basically works... navigate through the application")
->  une fois connecté dans le navigateur (point 8), cliquer sur l'application wil-playground dans l'interface, et regarder le graphique visuel qui apparaît (Deployment → Pod → Service, avec leur statut Synced/Healthy) — et être capable d'expliquer ce qu'on voit.

12 - Vérifier l'accès à l'appli en v1 ("Check that the v1 application can be accessed")
-> Ouvrir un 2eme terminal 
-> curl http://localhost:8888/
-> Le resultat affichee doit etre:  {"status":"ok", "message": "v1"}

13 - Vérifier que Docker Hub est utilisé ("Verify that Dockerhub is used. This part is important")
-> montrer https://hub.docker.com/r/wil42/playground 
Ici montrer que c'est bien le meme qu'on utlise dans le projet 
Dans deployment.yaml -> image: wil42/playground:v1 
Dans dockerHub c'est aussi -> wil42/playground Et Montrer le Tags dans dockerHub


14 - Modifier, commit, push ("you must commit and push a modification")
-> Modifier l'image dans deployment.yaml en v2
-> git add p3/confs/deployment.yaml
-> git commit -m "update to v2"
-> git push

SI PROBLEME ICI : "Empty reply from server" après un changement de version (v1→v2)
Explication:

Quand Argo CD déploie une nouvelle version de l'application (v1 → v2), Kubernetes ne modifie pas le pod existant — il supprime l'ancien pod et en crée un tout nouveau, avec un nom différent.

Le tunnel qu'on a créé avec kubectl port-forward est connecté à un pod précis, pas à l'application en général. Donc quand l'ancien pod disparaît, le tunnel devient cassé — même s'il continue parfois d'apparaître comme "actif" dans la liste des processus.

Résultat visible : curl http://localhost:8888/ renvoie Empty reply from server, alors que la nouvelle version (v2) tourne bien dans le cluster.

Point important à retenir : ce n'est pas un bug de notre projet — c'est le fonctionnement normal de Kubernetes à chaque redéploiement. Il faut donc relancer le tunnel après chaque changement de version.

16 - Vérifier la synchro avec l'opération donnée en exemple ("Ensure that the application was successfully synchronized using operation given as an example in the subject") -> curl http://localhost:8888/ -> Le resulat doit etre -> {"status":"ok", "message": "v2"}

-> Si erreur = "Empty reply from server"

Le déploiement vers v2 a supprimé l'ancien pod (v1) et en a créé un nouveau (v2) — donc le tunnel port-forward, qui pointait vers l'ancien pod, est maintenant cassé.
Solution :

    Tuer l'ancien tunnel cassé: -> pkill -f "kubectl port-forward svc/wil-playground"

    Vérifier que le nouveau pod (v2) tourne bien -> kubectl get pods -n dev

    Relancer un tunnel frais qui va automatiquement se connecter au pod actuel (v2) -> kubectl port-forward svc/wil-playground -n dev 8888:8888 &

    Retester -> curl http://localhost:8888/


======================================================================
             BONUS : GITLAB LOCAL
======================================================================

OBJECTIF DU BONUS

Le bonus reprend toute la Partie 3, mais remplace le dépôt GitHub public
par un dépôt GitLab hébergé localement dans le cluster. GitLab doit donc :

- tourner dans le namespace Kubernetes "gitlab" ;
- être accessible depuis la machine avec gitlab.k3d.gitlab.com ;
- contenir le dépôt Git utilisé par Argo CD ;
- permettre à Argo CD de déployer puis de mettre à jour l'application ;
- conserver les deux versions de l'application Wil (v1 et v2).

Le dépôt GitLab utilisé par les scripts est par défaut :

  root/test

Il doit être créé une première fois dans l'interface GitLab avec le compte
root. Le nom du projet peut être changé avec la variable GITLAB_PROJECT.

ARCHITECTURE DU BONUS

  Machine locale
     |
     | port-forward 80
     v
  GitLab dans le namespace gitlab
     |
     | dépôt root/test
     v
  Argo CD dans le namespace argocd
     |
     | synchronisation automatique
     v
  wil-playground dans le namespace dev
     |
     | port-forward 8888
     v
  http://localhost:8888

Le dépôt GitHub du projet reste la source de départ. Le script
bonus/scripts/update.sh clone ce dépôt, prend le dossier p3/confs et le
copie dans manifest/app du dépôt GitLab. Argo CD surveille ensuite
manifest/app dans GitLab, et non plus p3/confs sur GitHub.

FICHIERS DU BONUS

1. bonus/values-minikube-minimum.yaml

Ce fichier réduit les ressources demandées par GitLab afin qu'il puisse
fonctionner dans un environnement Minikube/K3d limité. Prometheus et le
GitLab Runner sont désactivés, et les composants GitLab sont limités à une
réplique. Les réglages de domaine et d'accès HTTP sont complétés par
bonus/scripts/start.sh.

2. bonus/scripts/install.sh

Ce script installe Helm, le gestionnaire utilisé pour installer GitLab avec
le chart officiel gitlab/gitlab. Les outils Docker, K3d, kubectl et le CLI
Argo CD sont installés par p3/scripts/install.sh, qui doit être exécuté
avant le bonus.

Commandes d'installation :

  cd p3
  sudo bash scripts/install.sh
  cd ../bonus
  sudo bash scripts/install.sh

3. bonus/scripts/start.sh

Ce script réalise toute la mise en place :

- vérifie que docker, k3d, kubectl, helm, argocd et curl existent ;
- vérifie que l'utilisateur courant peut utiliser Docker ;
- ajoute gitlab.k3d.gitlab.com à /etc/hosts ;
- crée le cluster K3d "iot" s'il n'existe pas ;
- crée les namespaces argocd, dev et gitlab ;
- installe ou met à jour GitLab avec Helm ;
- attend que le webservice GitLab soit prêt ;
- installe ou met à jour Argo CD dans argocd ;
- récupère les mots de passe initiaux GitLab et Argo CD depuis les Secrets ;
- ouvre le port-forward GitLab sur http://gitlab.k3d.gitlab.com ;
- lance update.sh pour publier les manifests dans GitLab ;
- ajoute le dépôt GitLab interne à Argo CD ;
- crée ou met à jour l'application wil-playground ;
- attend le Deployment dans dev et ouvre localhost:8888.

Lancer le bonus :

  cd bonus
  bash scripts/start.sh

Le dépôt GitLab doit déjà exister avant cette commande. Pour utiliser un
autre projet ou un autre hôte :

  GITLAB_PROJECT=root/mon-projet bash scripts/start.sh

4. bonus/scripts/update.sh

Ce script est le pont entre GitHub et GitLab. Il :

- récupère le mot de passe root GitLab depuis le Secret Kubernetes ;
- crée un fichier ~/.netrc avec des permissions privées ;
- clone la version actuelle du dépôt GitHub ;
- vérifie que p3/confs existe ;
- clone le dépôt GitLab ou met à jour une copie locale existante ;
- remplace manifest/app par les manifests de p3/confs ;
- crée un commit uniquement si le contenu a changé ;
- pousse le commit vers GitLab.

La commande peut être relancée sans créer de commit vide. Les paramètres
principaux sont configurables :

  GITLAB_PROJECT=root/test
  GITLAB_REPO_DIR="$PWD/gitlab_repo"
  GITHUB_REPOSITORY=https://github.com/Nofy261/nolecler-IOT.git

PREUVE DE FONCTIONNEMENT DU BONUS

1. Vérifier que les outils sont disponibles :

  docker --version
  k3d --version
  kubectl version --client
  helm version
  argocd version --client

2. Vérifier le cluster et les namespaces :

  k3d cluster list
  kubectl get nodes
  kubectl get ns

La sortie doit contenir les namespaces argocd, dev et gitlab, ainsi qu'un
nœud K3d en état Ready.

3. Vérifier les composants :

  kubectl get pods -n gitlab
  kubectl get pods -n argocd
  kubectl get pods -n dev
  argocd app get wil-playground

GitLab et Argo CD peuvent mettre plusieurs minutes à devenir disponibles.
L'application doit finir avec un état Synced/Healthy dans Argo CD.

4. Vérifier GitLab dans un navigateur :

  http://gitlab.k3d.gitlab.com

Le port-forward GitLab créé par start.sh doit rester actif. Se connecter avec
root et le mot de passe récupéré avec :

  sudo kubectl get secret gitlab-gitlab-initial-root-password \
    -n gitlab -o jsonpath="{.data.password}" | base64 -d

5. Vérifier la version v1 :

  curl http://localhost:8888/

La réponse attendue est une réponse JSON contenant le message v1.

6. Vérifier la mise à jour GitOps vers v2 :

- modifier manifest/app/deployment.yaml dans le dépôt GitLab ;
- remplacer wil42/playground:v1 par wil42/playground:v2 ;
- faire git add, git commit et git push ;
- attendre la synchronisation automatique d'Argo CD ;
- relancer curl http://localhost:8888/.

La réponse doit maintenant contenir le message v2. Aucune commande
kubectl apply ne doit être exécutée entre le git push et la mise à jour.
Argo CD détecte le commit GitLab, compare l'état désiré avec le cluster et
met à jour le Deployment dans dev.

MISE A JOUR DEPUIS GITHUB

Pour republier les manifests actuels de GitHub vers GitLab sans relancer
toute l'infrastructure :

  cd bonus
  bash scripts/update.sh

Après le push, Argo CD doit détecter le nouveau commit GitLab et synchroniser
automatiquement l'application. Le dépôt GitLab est la source observée par
Argo CD ; GitHub ne sert ici que de dépôt source pour update.sh.

DEPANNAGE RAPIDE

- GitLab ne répond pas : vérifier kubectl get pods -n gitlab et le fichier
  ~/.gitlab-port-forward.log.
- Argo CD ne répond pas : vérifier kubectl get pods -n argocd et le fichier
  ~/.argocd-port-forward.log.
- Le dépôt GitLab est introuvable : créer root/test dans GitLab ou définir
  GITLAB_PROJECT avec le bon chemin.
- L'application n'est pas synchronisée : lancer argocd app get
  wil-playground puis, uniquement pour diagnostiquer, argocd app sync
  wil-playground.
- Le port 8888 est déjà utilisé : arrêter l'ancien port-forward avant de
  relancer start.sh.

ARRET ET NETTOYAGE

  pkill -f "kubectl port-forward"
  k3d cluster delete iot

La suppression du cluster supprime les pods et GitLab locaux, mais pas le
dépôt GitLab lui-même si celui-ci utilise un stockage persistant externe.

15 - Attendre puis Synchro manuelle si besoin ("if synchronizing didn't happen, do it manually in Argo CD")
-> Reteste si la synchro a fonctionne: curl http://localhost:8888/
-> Sinon -> argocd app sync wil-playground (commande si l'attente de la synchro est trop long)

SI PROBLEME ICI :
Problème connu : "Empty reply from server" après un changement de version (v1→v2)
Le problème en mots simples

Quand Argo CD déploie une nouvelle version de l'application (v1 → v2), Kubernetes ne modifie pas le pod existant — il supprime l'ancien pod et en crée un tout nouveau, avec un nom différent.

Le tunnel qu'on a créé avec kubectl port-forward est connecté à un pod précis, pas à l'application en général. Donc quand l'ancien pod disparaît, le tunnel devient cassé — même s'il continue parfois d'apparaître comme "actif" dans la liste des processus.

Résultat visible : curl http://localhost:8888/ renvoie Empty reply from server, alors que la nouvelle version (v2) tourne bien dans le cluster.

Point important à retenir : ce n'est pas un bug de notre projet — c'est le fonctionnement normal de Kubernetes à chaque redéploiement. Il faut donc relancer le tunnel après chaque changement de version.

16 - Vérifier la synchro avec l'opération donnée en exemple ("Ensure that the application was successfully synchronized using operation given as an example in the subject")
-> curl http://localhost:8888/
-> Le resulat doit etre -> {"status":"ok", "message": "v2"}

-> Si erreur = "Empty reply from server"

Le déploiement vers v2 a supprimé l'ancien pod (v1) et en a créé un nouveau (v2) — donc le tunnel port-forward, qui pointait vers l'ancien pod, est maintenant cassé.
Solution :
1. Tuer l'ancien tunnel cassé:
-> pkill -f "kubectl port-forward svc/wil-playground"

2. Vérifier que le nouveau pod (v2) tourne bien
-> kubectl get pods -n dev

3. Relancer un tunnel frais qui va automatiquement se connecter au pod actuel (v2)
-> kubectl port-forward svc/wil-playground -n dev 8888:8888 &

4. Retester
-> curl http://localhost:8888/



----****----

Commande en plus:

k3d cluster list -> état du cluster
kubectl get nodes -> nœud(s) Ready
docker ps -> voir les conteneurs Docker réels (serveur K3s + load balancer)
jobs -> liste les tunnels actifs dans ta session
sudo lsof -i :8080 -> vérifie si le tunnel Argo CD est bien ouvert
sudo lsof -i :8888 -> vérifie si le tunnel de l'appli est bien ouvert
argocd app get wil-playground  -> statut détaillé de la synchro, vu par Argo CD
kubectl get deployment wil-playground -n dev -o jsonpath='{.spec.template.spec.containers[0].image}' -> quelle version d'image tourne réellement

arrêter les tunnels port-forward -> pkill -f "kubectl port-forward"
verifier que cela a fonctionne -> ps aux | grep "port-forward"

kubectl get pods -A -> voir les pods de tous les namespaces en même temps
---------

kubectl = l'outil universel pour parler à N'IMPORTE QUEL cluster Kubernetes (K3s, K3d....)
K3d = l'outil qui crée des clusters K3s dans des conteneurs Docker
K3s = la distribution Kubernetes légère elle-même, qui tourne à l'intérieur


Explication:
ARGOCD_PASS=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

argocd login localhost:8080 --username admin --password "$ARGOCD_PASS" --insecure

"On a récupéré le mot de passe qu'on a mis dans une variable" ✅ Exact — ARGOCD_PASS contient le mot de passe généré automatiquement par Argo CD lors de son installation, stocké dans un Secret Kubernetes.
"Pour se connecter/parler à Argo CD, il faut un compte admin" ✅ Exact — Argo CD, comme n'importe quel système sécurisé, exige une authentification avant de pouvoir agir dessus (créer des apps, forcer des syncs, etc.).
"Ce compte admin doit donner le mot de passe récupéré" ✅ Exact — c'est exactement ce que fait la commande argocd login localhost:8080 --username admin --password "$ARGOCD_PASS".
"Argo CD va vérifier, il voit l'admin et le bon mot de passe, et accepte la connexion" ✅ Exact — Argo CD compare ce qu'on lui envoie avec ce qu'il a en interne, et valide l'authentification.
"Admin, c'est l'username par défaut pour le compte qui va se connecter à Argo CD" ✅ Exactement ça — admin est le compte administrateur créé automatiquement à l'installation d'Argo CD, avec tous les droits sur cette instance Argo CD précise (pas sur le système Linux, ni sur GitHub — juste sur Argo CD lui-même).

Cluster Kubernetes
    └── Namespace (ex: dev)
            └── Pod (ex: wil-playground-xxx)
                    └── Conteneur(s) Docker (ex: le conteneur qui fait tourner l'app wil42/playground)


TOI (navigateur)
    ↓ tu tapes https://localhost:8080
    ↓
LE TUNNEL kubectl port-forward
    (c'est UN SEUL processus qui fait le pont)
    ↓ redirige vers
Service argocd-server, port 443 (dans le cluster)
    ↓
Pod argocd-server (le vrai programme qui répond)

8080 EST le port sur lequel le tunnel écoute, sur ma machine locale. Le tunnel lui-même redirige ensuite directement vers le port 443 d'Argo CD, dans le cluster.
en résumé : il n'y a que 2 ports — 8080 (ta machine) et 443 (Argo CD dans le cluster) — reliés directement par UN SEUL tunnel, sans étape intermédiaire supplémentaire.
-------------------------------------------------

CORRECTION P1

1 - Vérifier la présence et comprendre le contenu du Vagrantfile 
-> fichier qui decrit et creer automatquement 2 VM avec Vagrant: noleclerS en mode serveur K3s et noleclerSW en mode agent, avec leurs IP fixes, ressources, et un script de provisionning propre a chacune, pour former former un cluster K3s a 2noeuds. 

-> p1/scripts/server.sh (script exécuté automatiquement sur noleclerS : installe K3s en mode serveur, avec une IP fixe et l'interface réseau détectée automatiquement, puis copie le token généré dans le dossier partagé /vagrant pour que l'assistant puisse le récupérer)

-> p1/scripts/worker.sh (script exécuté automatiquement sur noleclerSW : attend que le token du chef apparaisse dans /vagrant, le récupère, puis installe K3s en mode agent en utilisant l'IP du chef + ce token pour rejoindre automatiquement le cluster)

2 - Vérifier qu'il y a bien 2 VM dans le Vagrantfile

3 - Vérifier la dernière version stable de la distribution
-> onlyoffice/base-debian13 (Debian 13,la box officielle Debian n'a pas les Guest Additions nécessaires au partage de dossier, celle-ci si)

4 - Vérifier l'IP sur l'interface principale, imposée par le sujet 
-> 192.168.56.110 (noleclerS) 
-> 192.168.56.111 (noleclerSW)

5 - Vérifier les noms des VM (login + S / SW)

6 - Démarrer et se connecter aux VM
-> aller dans p1
-> vagrant up
-> vagrant ssh noleclerS
-> vagrant ssh noleclerSW

7 - Vérifier l'IP réelle sur l'interface, avec la commande  ("ip a show $(ip route | grep default | awk '{print $5}')")
-> vagrant ssh noleclerS -c "ip a show \$(ip route | grep default | awk '{print \$5}')"
-> vagrant ssh noleclerSW -c "ip a show \$(ip route | grep default | awk '{print \$5}')"

8 - Vérifier le hostname 
-> vagrant ssh noleclerS -c "hostname"
-> vagrant ssh noleclerSW -c "hostname"

9 - Vérifier que les deux VM utilisent K3s
-> vagrant ssh noleclerS -c "sudo systemctl status k3s --no-pager"
-> vagrant ssh noleclerSW -c "sudo systemctl status k3s-agent --no-pager"

10 - Vérifier que les deux machines forment le même cluster
-> vagrant ssh noleclerS -c "kubectl get nodes -o wide"
Explication: le token généré par le server (chef), récupéré automatiquement par worker (l'assistant) via le dossier partagé /vagrant, prouve son droit de rejoindre — c'est cette connexion qui forme le cluster à 2 nœuds.

COMMANDES UTILES EN PLUS 
vagrant status -> état des 2 VM
vagrant ssh noleclerS -c "nproc; free -h" -> vérifie 1 CPU / 1024 Mo respectés
vagrant ssh noleclerS -c "ls -la /vagrant" -> vérifie le dossier partagé (token visible)
vagrant ssh noleclerS -c "k3s -v" -> version de K3s installée

-----------

CORRECTION P2

1 - Éteindre les autres VM d'abord ("you can of course shut down every other running virtual machines")
-> cd p1 && vagrant halt
-> cd ../p2

2 - Vérifier la présence et comprendre le contenu du Vagrantfile 

3 - Vérifier qu'il n'y a qu'1 seule VM

4 - Vérifier la dernière version stable de la distribution
-> onlyoffice/base-debian13 

5 - Vérifier l'IP sur l'interface principale -> 192.168.56.110

6 - Vérifier le nom de la VM (login + S) 

7 - Fichiers supplémentaires présents, à expliquer

8 - Se connecter à la VM ("Use Vagrant to SSH into the virtual machine")
-> cd p2
-> vagrant up
-> vagrant ssh noleclerS

9 - Vérifier l'IP réelle, avec la commande précise de l'évaluateur
-> vagrant ssh noleclerS -c "ip a show \$(ip route | grep default | awk '{print \$5}')"

10 - Vérifier le hostname
-> vagrant ssh noleclerS -c "hostname"

12 - kubectl get nodes -o wide ("It should display the name of the controller and the internal IP address")
-> vagrant ssh noleclerS -c "kubectl get all"

13 - kubectl get all ("It should display 3 applications")
-> vagrant ssh noleclerS -c "kubectl get all"
→ 3 Deployments, 5 Pods (1+3+1), 3 Services — expliquer pourquoi app2 a 3 Pods (réplicas)

14 - Montrer comment fonctionne l'Ingress
-> kubectl get ingress
-> kubectl describe ingress apps-ingress

15 - Tester les 3 apps selon le HOST 
-> curl -H "Host: app1.com" 192.168.56.110
-> curl -H "Host: app2.com" 192.168.56.110
-> curl -H "Host: n-importe-quoi.com" 192.168.56.110   # doit tomber sur app3, par défaut
-> ou via navigateur, après avoir lancé bash scripts/hosts.sh sur IOT


COMMANDES UTILES EN PLUS
vagrant status
vagrant ssh noleclerS -c "kubectl get deployments"    # vérifier précisément les réplicas d'app2
vagrant ssh noleclerS -c "kubectl get pods -o wide"    # voir quel pod répond à quelle requête

======================================================================
          FIN DU BONUS : PARCOURS RAPIDE
======================================================================

Le bonus remplace la source GitHub de la Partie 3 par un GitLab local.
GitLab tourne dans le namespace gitlab, Argo CD dans argocd et
wil-playground dans dev. Le dépôt root/test est synchronisé vers le chemin
manifest/app, puis Argo CD déploie ce chemin dans dev.

Pour refaire le parcours complet :

  cd p3 && sudo bash scripts/install.sh
  cd ../bonus && sudo bash scripts/install.sh
  # créer une fois le projet root/test dans GitLab
  bash scripts/start.sh
  kubectl get ns
  kubectl get pods -n gitlab
  kubectl get pods -n argocd
  kubectl get pods -n dev
  argocd app get wil-playground
  curl http://localhost:8888/

La première réponse doit être v1. Après modification de
manifest/app/deployment.yaml dans GitLab, avec commit et push vers v2,
Argo CD doit synchroniser automatiquement le Deployment. La seconde
requête curl doit alors retourner v2, sans kubectl apply manuel.

Pour republier les manifests du dépôt GitHub vers GitLab :

  cd bonus
  bash scripts/update.sh

Les erreurs de prérequis, de secret, de dépôt absent et de synchronisation
sont arrêtées explicitement par les scripts grâce à set -euo pipefail.


------------

Bonus -> script start.sh :
-> rajouter une verif si le cluster dans lequel on va ajouter gitlab existe est en train de tourner
P3 : start.sh
-> Resoudre le probleme de "sg" 


Ce qu'il faut nettoyer, dans l'ordre

1. Helm releases installées par le bonus (namespace gitlab)

bash
helm uninstall gitlab -n gitlab
helm uninstall dev-valkey -n gitlab
helm uninstall dev-cnpg -n gitlab
helm uninstall dev-garage -n gitlab

2. Le namespace gitlab lui-même (supprime tout ce qui reste dedans, y compris volumes/secrets/pods)

bash
kubectl delete namespace gitlab

3. Les CRD installées par CloudNativePG (elles restent même après le helm uninstall, car les CRD sont globales, pas liées à un namespace)


kubectl get crd | grep postgresql

Puis supprime celles trouvées (probablement clusters.postgresql.cnpg.io, etc.) :


kubectl delete crd -l app.kubernetes.io/name=cloudnative-pg 2>/dev/null || true

4. Le dossier gitlab cloné par install.sh (le repo git cloné dans bonus/scripts/)


rm -rf ~/Bureau/nolecler-IOT/bonus/scripts/gitlab

5. La ligne dans /etc/hosts (optionnel, mais propre)


sudo sed -i '/gitlab.k3d.gitlab.com/d' /etc/hosts

6. Les tunnels port-forward encore actifs
ps aux | grep "port-forward" -> pour verifier

pkill -f "kubectl port-forward.*gitlab"
Vérification finale

kubectl get ns
kubectl get pods -A | grep gitlab
helm list -A

---------

Vendredi 4/09 Debian
Erreur P1/scripts/install.sh : Virtualbox ne s'installe pas

le paquet VirtualBox n'est pas fourni dans les dépôts officiels de Debian 13.

VirtualBox
Sur Debian 13 (Trixie), le paquet virtualbox n’est pas disponible directement dans les dépôts Debian standards.
On utilise donc Debian Fast Track pour obtenir VirtualBox.
Fast Track
Fast Track nécessite que le dépôt trixie-backports soit activé.
On a donc ajouté trixie-backports avant Fast Track.

Donc le chemin est :

Debian 13 (Trixie)
→ trixie-backports
→ Fast Track
→ VirtualBox
→ Vagrant + VirtualBox prêts pour créer les 2 VM

VirtualBox est installé ✅
les linux-headers sont installés ✅
vboxdrv est le module qui permet à VirtualBox de communiquer avec le noyau Linux.
modprobe vboxdrv → active ce module.

vagrant --version
VBoxManage --version
dpkg -l | grep linux-headers -> Tester les headers Linux
lsmod | grep vbox -> Tester le module VirtualBox