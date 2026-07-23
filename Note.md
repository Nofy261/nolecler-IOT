But du projet:
Apprendre à faire tourner des sites web sur plusieurs ordinateurs qui travaillent en équipe, et faire en sorte que tout se mette à jour tout seul.

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
vagrant ssh noleclerS -c "sudo systemctl status k3s --no-pager"
vagrant ssh noleclerSW -c "sudo systemctl status k3s-agent --no-pager"

vagrant ssh noleclerS puis kubectl get nodes -o wide



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

En tout -> P2 -> 3 applis soit 5 pods car appli 2 = 3 replicas donc 3 pods

"1 appli = autant de Pods que de réplicas précisés" (1 par défaut, ou plus si demandé).

On teste avec curl -H "Host: appX.com" 192.168.56.110
→ Ingress lit le Host → appelle le bon Service → Service choisit un Pod disponible → le Pod répond "Hello from appX"

---------

hashicorp/http-echo — une image publique conçue spécifiquement pour ce genre de cas : elle affiche juste le texte que tu lui donnes, sans bricolage de commande shell.


image: hashicorp/http-echo
args: ["-text=Hello from app1"]
La plus simple de toutes — pas de command/echo/&& à écrire, juste un argument direct
Image minuscule, démarre très vite

------------

Ingress -> Service -> Pod -> Reponse

Commande a appliquer 
kubectl apply -f confs/

K3s = une version allégée de Kubernetes, qui sert à créer, faire tourner, et maintenir en vie automatiquement des applications, réparties dans des "pods".
------------


Resume notions P2:

K3s = version allégée de Kubernetes, qui crée et gère automatiquement des applications

Pod = une copie en cours d'exécution d'une application (adresse IP instable, recréé si besoin)

Deployment = tes instructions à K3s pour dire combien de copies (réplicas) créer, et à quoi elles doivent ressembler

Service = point d'accès stable, qui retrouve ses pods grâce à un système d'étiquettes (labels), et transmet les requêtes vers l'un d'eux

Ingress = le "réceptionniste", qui lit le Host de la requête et route vers le bon Service

kubectl = l'outil en ligne de commande pour envoyer tes instructions (fichiers YAML) à K3s (kubectl apply -f ...)


VM (la maison)
  └── K3s (le gestionnaire de l'immeuble, qui tourne dans la maison)
        └── Pods/Applications (les locataires, gérés par K3s)

-----
Test P2
Aller dans p2/
vagrant up
vagrant status
vagrant ssh noleclerS -c "hostname"
vagrant ssh noleclerS -c "ip a"
vagrant ssh noleclerS -c "sudo systemctl status k3s --no-pager" (verifie que k3s tourne)
vagrant ssh noleclerS -c "kubectl get nodes -o wide" (verif que le noeud est pret)
vagrant ssh noleclerS -c "kubectl get all" (verif que tous les Pods sont bien crees)
vagrant ssh noleclerS -c "kubectl get ingress"
Exécuter hosts.sh sur la machine hôte (pas dans la VM !) 
-> bash ~/Bureau/IOT/p2/scripts/hosts.sh
Tester le routage pour chaque application (depuis la machine hôte)
-> curl http://app1.com
-> curl http://app2.com
-> curl http://192.168.56.110