K3s:
K3s est un logiciel, une version allégée de Kubernetes, qui sert à créer un cluster. Un cluster est composé de nœuds : un nœud server qui gère le cluster, et des nœuds worker qui exécutent les conteneurs (les pods).

Vagrant:
Vagrant est un logiciel qui sert a creer une VM. 
vagrant up -> Vagrant creer la VM via vagrantfile-> script lancer -> k3s installer a l'interieur de la VM -> connexion du worker au serveur -> naissance du cluster.

K3d:
K3s in docker.
K3d est un logiciel qui permet de faire tourner K3s dans des conteneurs Docker. Pour lancer un cluster, on installe Docker puis K3d, et la commande "k3d cluster create ..." demande à Docker de créer les conteneurs et d'y installer K3s dedans.

Part 1 - Configuration

CI et argocd:
L'integration continue(CI) automatise ce qui se passe apres un changement de code.
ArgoCD est l'outil qui fait du Gitops: il surveille un depot Git et des qu'un commit change les manifests. Il applique automatiquement la difference via l'API Kubernetes, qui recreer les pods concernes.

-----------------

Part 1 - Configuration

Derniere version de debian 13 trixie
https://www.debian.org/releases/ 

install.sh:
apt ne connaît par défaut que les paquets officiels Debian, qui n'incluent pas Vagrant ni VirtualBox ; le script ajoute donc 3 dépôts externes (HashiCorp, Debian backports, Debian fasttrack) avec leurs clés de sécurité, pour pouvoir les installer. 

Les headers sont installés avant VirtualBox car virtualbox-dkms en a besoin pour compiler les modules noyau (vboxdrv...) qui permettent la virtualisation. Sans eux, l'installation de VirtualBox échouerait.

Le script installe VirtualBox (le moteur de virtualisation) et virtualbox-dkms (qui reconstruit automatiquement ses modules noyau à chaque mise à jour du noyau, grâce aux headers installés juste avant). 

Le processeur a un pouvoir spécial pour la virtualisation, mais un seul outil peut l'utiliser à la fois. Le script désactive KVM pour laisser ce pouvoir entièrement à VirtualBox. 

Le fichier blacklist empêche KVM de redémarrer au prochain boot ; les modprobe -r l'éteignent immédiatement s'il tournait déjà, pour libérer tout de suite le pouvoir de virtualisation pour VirtualBox. 

vboxdrv → la pièce principale, donne accès au pouvoir de virtualisation. Sans elle, aucune VM.
vboxnetadp → crée les cartes réseau virtuelles (le réseau privé 192.168.56.x entre les VM).
vboxnetflt → route le trafic réseau entre la VM et l'extérieur (accès Internet).

Ces 3 modules(vboxdrv, vboxnetadp, vboxnetflt) ont été construits grâce au plan technique du noyau (les headers), puis insérés dans le noyau lui-même, pour que VirtualBox (et donc les VM) puissent fonctionner correctement. 

Exemple:
modprobe vboxdrv → « insère cette pièce dans le noyau maintenant »
modprobe -r kvm → « retire cette pièce du noyau maintenant »

Résumé de toute la chaîne, dans l'ordre :
- On installe les headers (le plan du noyau)
- virtualbox-dkms construit les 3 modules (vboxdrv, vboxnetadp, vboxnetflt) grâce à ce plan
- Ces modules sont insérés dans le noyau (chargés avec modprobe)
- VirtualBox peut alors créer et faire fonctionner des VM correctement

Part 1 - Usage

-Utiliser Vagrant pour se connecter en SSH aux deux machines virtuelles, avec l'aide du groupe évalué:
vagrant ssh noleclerS
vagrant ssh noleclerSW

-Ensure that the primary network interface has the required IP addresses by using the following command: For macOS: "ifconfig en0" For the latest Linux distributions: "ip a show $(ip route | grep default | awk '{print $5}')" (to dynamically detect the primary interface):
La commande du sujet trouve l'interface de la route par défaut, qui est toujours le NAT dans Vagrant. L'IP demandée par le sujet est sur la deuxième interface, eth1 => ip a show eth1

-Ensure both machines have the hostname required by the subject:
hostname

-Then, check that both virtual machines use K3s:
Pour le server: systemctl status k3s
Pour le worker: systemctl status k3s-agent

-Finally, verify that the Server machine and the Agent machine are in the same cluster by running this command on the Server machine: "kubectl get nodes -o wide":
kubectl get nodes -o wide liste les nœuds du cluster. NAME = leurs noms, STATUS = Ready s'ils sont opérationnels, ROLES = control-plane pour le server qui gère le cluster (vide pour le worker qui exécute), VERSION prouve que c'est K3s, INTERNAL-IP montre l'IP privée de chaque nœud.

------------

Part 2 - Configuration
- Reponse dans le code


Part 2 - Usage

-Use Vagrant to SSH into the virtual machine:
vagrant ssh noleclerS

-Ensure that the primary network interface has the required IP addresses by using the following command: For macOS: "ifconfig en0" For the latest Linux distributions: "ip a show $(ip route | grep default | awk '{print $5}')" (to dynamically detect the primary interface): 
Cette commande générique cherche l'interface de la route par défaut. Sur ma VM Vagrant, il y a 2 interfaces : eth0 (NAT, avec passerelle, choisi par défaut) et eth1 (réseau privé, sans passerelle). La commande tombe donc toujours sur eth0, pas sur l'IP 192.168.56.x demandée par le sujet. Pour vérifier la bonne IP => ip a show eth1 

-Ensure the machine has the hostname required by the subject:
hostname

-Then, check that the virtual machine uses K3s:
systemctl status k3s

-Verify that the virtual machine meets the subject's requirements...:
kubectl get nodes -o wide
(NAME + IP)

kubectl get all

Ingress est le pont entre l'extérieur et l'intérieur du cluster. Il lit le header Host de la requête HTTP reçue et route vers le bon Service selon des règles définies.

kubectl get ingress
kubectl describe ingress apps-ingress
→ ça affiche les règles : app1.com → app1, app2.com → app2, et une règle sans host → app3 (défaut).

-Now, check that the 3 applications can be accessed depending on the HOST header that is used...:
curl -H "Host: app1.com" http://192.168.56.110
curl -H "Host: app2.com" http://192.168.56.110
curl -H "Host: app3.com" http://192.168.56.110
curl http://192.168.56.110

OU directement dans le navigateur (une fois hosts.sh lancé) :
http://app1.com
http://app2.com

--------

Part 3 - Configuration

-Expliquer les fichiers dans confs

Le Deployment gère et supervise les Pods (le nombre de copies, l'image utilisée), le Pod exécute réellement le conteneur. On attend que le Deployment existe puis soit disponible avant d'ouvrir le tunnel, sinon il n'y aurait rien à contacter.

Le Service donne une adresse stable et fixe pour joindre des Pods qui, eux, changent tout le temps d'IP. Il trouve les bons Pods grâce au selector (par étiquette/label), et fait le lien entre le port d'entrée (port) et le port réel du conteneur (targetPort).

(Le namespace argocd contient tous les composants d'Argo CD lui-même : le serveur qui répond à mes commandes, le repo-server qui lit le dépôt Git, et le controller qui compare l'état du cluster à Git et déclenche la synchronisation.)

Make sure there are at least 2 namespaces in K3d:
kubectl get ns
-> il doit y avoir argocd et dev

Verify that there is at least 1 pod in the "dev" namespace: 
kubectl get pods -n dev
-> On doit voir 1 pod wil-playground-xxxx en Running

-The differences between a namespace and a pod:
Un namespace est une subdivision logique à l'intérieur d'un cluster, qui permet d'organiser et d'isoler des ressources (ici, argocd d'un côté, dev de l'autre).
Un pod est l'enveloppe qui contient un ou plusieurs conteneurs, et qui tourne à l'intérieur d'un namespace précis.

-Check that all the required services are running with the help of the evaluated group:
--> kubectl get all -n dev
Dans le namespace dev, on a 1 pod wil-playground en Running — il exécute réellement l'application. Le service expose ce pod sur le port 8888, avec une IP interne stable. Le deployment est 1/1, ce qui veut dire que le nombre de copies voulues correspond au nombre de copies réellement disponibles. Et le replicaset confirme la même chose : 1 désiré, 1 actuel, 1 prêt. Tout est sain, sans erreur. 

--> kubectl get all -n argocd
Dans le namespace argocd, on retrouve tous les composants d'Argo CD lui-même. Les 3 essentiels : argocd-server (le cœur, répond à mes commandes et à l'interface web), argocd-repo-server (va lire le dépôt Git), et argocd-application-controller (compare l'état réel du cluster à Git, et déclenche la synchro). Les autres (redis, dex-server, notifications-controller, applicationset-controller) sont des composants secondaires — cache, authentification, notifications, gestion groupée d'apps — pas essentiels au fonctionnement du projet.
Les services exposent chacun de ces composants en interne au cluster. Les deployments/replicasets montrent 1 copie de chaque, tous Ready.
argocd-application-controller : c'est le seul qui apparaît comme un StatefulSet (pas un Deployment) dans la sortie — parce qu'il doit garder une identité stable (il gère l'état du cluster en continu, contrairement aux autres qui sont plus "sans état").

-Check that Argo CD is installed and configured...:
--> Dans le navigateur https://localhost:8080
--> username: admin 
--> commande pour recuperer le mot de passe: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
(Le mot de passe admin initial est stocké dans le secret Kubernetes argocd-initial-admin-secret, encodé en base64. Onle récupère avec kubectl get secret puis on le décode)

-Check that a Docker image is used in the Github repository...:

https://hub.docker.com/r/wil42/playground 

Dans deployment.yaml -> image 
On utilise l'image pré-faite de Wil, wil42/playground, disponible publiquement sur DockerHub avec les tags v1 et v2 déjà fournis.

Partie 3 - Usage

-Naviguer dans argocd et savoir expliquer son fonctionnement:
Synced veut dire que le cluster correspond exactement au commit affiché. Comme l'app(argocd) suit le dernier commit (HEAD), Synced = à jour avec Git. Si un nouveau commit arrive, ça passerait brièvement à OutOfSync avant que la synchro automatique ne rattrape.
Argo CD compare en permanence l'état du cluster à ce qui est déclaré dans Git. S'il détecte une différence, il synchronise automatiquement le cluster pour qu'il corresponde à Git — c'est le principe même du GitOps : Git est la source de vérité, le cluster s'y adapte.

Le Deployment crée automatiquement un ReplicaSet, qui lui-même crée le Pod — c'est cette chaîne automatique qui garantit qu'il y a toujours exactement le nombre de pods demandé. Le Service, expose une adresse stable vers ce pod. Cet arbre dans Argo CD, c'est juste la représentation visuelle de cette hiérarchie, avec l'état de santé de chaque élément affiché en direct.

Changer de version déclenche la création d'un nouveau ReplicaSet et d'un nouveau Pod par le Deployment. L'ancien pod est détruit, ce qui casse un éventuel tunnel pointant dessus — il faut le relancer vers le nouveau pod. 

-Check that the v1 application can be accessed from this machine. You can use curl (there is an example usage in the subject):
curl http://localhost:8888/ 
--> attendu : {"status":"ok", "message": "v1"}

-Verify that Dockerhub is used...:
Voici le lien DockerHub public de l'image utilisée, wil42/playground, avec les 2 tags v1 et v2 disponibles — c'est de là que Kubernetes télécharge l'image quand il crée le pod.
https://hub.docker.com/r/wil42/playground
OU montrer cette commande mais optionnel:
kubectl describe pod -n dev -l app=wil-playground | grep Image
    OU  
kubectl get pods -n dev -l app=wil-playground -o jsonpath='{.items[0].spec.containers[0].image}'; echo


-Since you can see the v1 application, you must be able to update it with the help of the evaluated group...:
Dans deployment.yaml changer l'image en v2 puis push sur github. L'app argocd attend quelques minutes le temps de faire la synchronisation puis devra etre a jour.
Sinon si cela prend trop de temps , la commande pour forcer c'est : argocd app sync wil-playground 
OU Sinon dans argocd on Refresh 
Puis reteste :
-> curl http://localhost:8888/ 
--> attendu : {"status":"ok", "message": "v2"}
Si erreur: curl: (52) Empty reply from server
Le déploiement vers v2 a supprimé l'ancien pod (v1) et en a créé un nouveau (v2) — donc le tunnel port-forward, qui pointait vers l'ancien pod, est maintenant cassé.
Solution :

-Verifier quel pod qui tourne (facultatif)
kubectl get deploy wil-playground -n dev -o jsonpath='{.spec.template.spec.containers[0].image}'; echo

1. Tuer l'ancien tunnel cassé:
-> pkill -f "kubectl port-forward svc/wil-playground"

2. Vérifier que le nouveau pod (v2) tourne bien
-> kubectl get pods -n dev
OU 
kubectl get deploy wil-playground -n dev -o jsonpath='{.spec.template.spec.containers[0].image}'; echo

3. Relancer un tunnel frais qui va automatiquement se connecter au pod actuel (v2)
-> kubectl port-forward svc/wil-playground -n dev 8888:8888 &

4. Retester
-> curl http://localhost:8888/

-> Montrer dans l'interface de Argocd le changement
---------------

BONUS

GitLab n'embarque plus Postgres/Redis/MinIO par défaut pour un usage local léger — il faut fournir ces 3 dépendances soi-même en externe. Le script dev_dependencies.sh, fourni par GitLab, les installe automatiquement : Valkey (cache), CloudNativePG (base de données), Garage (stockage S3).

install.sh: installe l'outil Helm, qui sert à déployer GitLab dans Kubernetes. Il installe aussi util-linux-extra (dépendance système mineure, rôle précis inconnu). Il clone ensuite le dépôt des charts GitLab (protégé contre une relance) et exécute dev_dependencies.sh, qui installe les 3 services nécessaires (Valkey, CloudNativePG, Garage) dans le namespace gitlab. 

start.sh:
Avant d'installer GitLab, on efface d'anciennes règles réseau qui pourraient déjà exister dans le système, pour éviter que GitLab ne se bloque en voulant poser ses propres règles par-dessus des anciennes incompatibles. 
(On supprime d'anciens CRD réseau pour éviter un conflit avec la nouvelle installation de GitLab, qui peut contenir ces mêmes CRD. )

On ajoute une entrée dans le fichier /etc/hosts qui associe une adresse IP (127.0.0.1) à un nom local (gitlab.k3d.gitlab.com).
/etc/hosts est un fichier qui contient des correspondances entre des adresses IP et des noms locaux, utilisées avant d'aller chercher sur Internet. 

values-minikube-minimum.yaml → un fichier copié depuis GitLab (exemple officiel), pour réduire les ressources de GitLab lui-même.
dev_dependencies.sh → un script, récupéré dans le dépôt des charts GitLab, qui installe les 3 services nécessaires.
dev-external.values.yaml → un fichier généré par le script dev_dependencies.sh, qui contient les infos (noms de secrets) pour connecter les 3 services à GitLab.

helm repo add enregistre le dépôt de charts. helm repo update rafraîchit le catalogue de tous les dépôts (pas GitLab lui-même). helm upgrade --install est la seule ligne qui touche réellement à GitLab — elle l'installe ou le met à jour selon son état actuel. 

On désactive la Gateway API pour cette installation, mais d'anciens CRD liés à cette fonctionnalité pourraient traîner d'une fois précédente où elle était activée — donc on les supprime d'abord, pour que le "désactivé maintenant" ne rentre pas en conflit avec un "activé avant" (ligne 57)

On attend que le pod webservice soit prêt, on récupère le mot de passe root (généré automatiquement à l'installation de GitLab), on le décode et le stocke dans un fichier, puis on ouvre un tunnel pour s'y connecter depuis le local.   
Kubernetes stocke les secrets encodés en base64 (pas chiffrés, juste encodés). base64 -d décode cette valeur pour retrouver le vrai mot de passe lisible.

start.sh: installe réellement GitLab (via Helm), connecté aux 3 services préparés par install.sh (Valkey, CNPG, Garage). Il attend que GitLab soit prêt, récupère le mot de passe root, puis ouvre un tunnel (port 80 → 8181) pour y accéder depuis le navigateur. 

Bonus: 
Le lancement de start.sh peut prendre quelques minutes : 
-> commande pour voir l'avancee de creation des pods:
--> watch kubectl get pods -n gitlab

Ensuite tester le tunnel avec gitlab --> 
curl -sI http://gitlab.k3d.gitlab.com/users/sign_in | head -1
---> Reponse attendu ---> HTTP/1.1 200 OK

Ouvrir http://gitlab.k3d.gitlab.com dans le navigateur, se connecter avec root + le mot de passe (cat gitlab_password.txt)
---

update.sh:
On prépare des variables : le namespace, le mot de passe GitLab (récupéré en direct depuis le cluster), et le chemin d'un fichier à créer plus loin.

On écrit les identifiants dans le fichier standard .netrc, que Git lit automatiquement pour s'authentifier sans demander de mot de passe, puis on verrouille ce fichier pour protéger sa confidentialité.

Si la copie locale du dépôt GitLab existe déjà, on la met à jour (pull) ; sinon, on la clone pour la première fois.


On réutilise le clone GitHub fait plus tôt : il remplace le contenu de confs dans la copie locale GitLab par celui de GitHub, renomme l'app en wil-playground2, puis nettoie le dossier GitHub temporaire — il ne reste que la copie GitLab, prête à être commitée et poussée.

argocd app create crée d'abord la fiche de surveillance (l'objet Application) — c'est ensuite, automatiquement, qu'Argo CD utilise cette fiche pour créer réellement le Deployment et le Pod. Les deux se passent vite l'un après l'autre, mais ce sont deux étapes distinctes.

Commande pour tester la deuxieme appli de Wil2: 
curl http://localhost:8889/

argocd app get wil-playground2  -----
kubectl get pods -n dev

A faire avant de tester si le passage de v1 a v2 a reussi 
pkill -f "port-forward.*8889"
kubectl port-forward svc/wil-playground2 -n dev 8889:8888 &
sleep 2
curl http://localhost:8889/

GITLAB_PROJECT=root/test0 ./scripts/update.sh


--------


Bonne question, la vraie solution robuste (comme celles qu'on a déjà ajoutées ailleurs) serait de tuer l'ancien tunnel avant d'en ouvrir un nouveau, systématiquement — pour être sûr d'avoir un tunnel frais et fonctionnel, plutôt que de risquer un conflit.

Correctif proposé pour les 2 lignes de p3/scripts/start.sh :


pkill -f "port-forward.*8080:443" 2>/dev/null || true
kubectl port-forward svc/argocd-server -n argocd 8080:443 &
et pareil pour l'app :


pkill -f "port-forward.*8888:8888" 2>/dev/null || true
kubectl port-forward svc/wil-playground -n dev 8888:8888 2>&1 >/dev/null &
Pourquoi c'est la bonne approche : on ne "devine" pas si l'ancien tunnel marche encore bien — on le tue systématiquement et on en ouvre un garanti neuf, exactement le réflexe qu'on a pratiqué plusieurs fois à la main pendant tes révisions.

------

kubectl get pods -n argocd
-> Les 3 essentiels à retenir (les autres sont secondaires) :
argocd-server → le cœur, répond à nos commandes et à l'interface web    ---
argocd-repo-server → va lire le dépôt Git   ---
argocd-application-controller → compare l'état du cluster à Git et déclenche la synchro ---






























-------

Procédure générale de dépannage tunnel
1. Vérifier que le pod visé est sain : 
kubectl get pods -n <namespace>

→ doit être Running, 1/1 ou 2/2. Si Pending/Error/CrashLoopBackOff, le problème est le pod, pas le tunnel — inutile de toucher au tunnel avant d'avoir réglé ça.

2. Vérifier si un tunnel tourne déjà :
ps aux | grep "port-forward" | grep -v grep


3. Tuer l'ancien tunnel (il pointe probablement vers un pod mort) :
pkill -f "port-forward.*<port_local>"

4. Relancer un tunnel neuf: 
kubectl port-forward svc/<nom-service> -n <namespace> <port_local>:<port_distant> &


5. Laisser une seconde s'établir, puis tester : 
sleep 2
curl <protocole>://localhost:<port_local>/

---------
Application concrète — Argo CD

kubectl get pods -n argocd --------
ps aux | grep "port-forward" | grep -v grep --------
pkill -f "port-forward.*8080" ---------
kubectl port-forward svc/argocd-server -n argocd 8080:443 & -----------
sleep 2 --------
curl -k https://localhost:8080/ -----------

******

Application concrète — App de Wil (p3)

kubectl get pods -n dev ------
ps aux | grep "port-forward" | grep -v grep -------
pkill -f "port-forward.*8888" --------
kubectl port-forward svc/wil-playground -n dev 8888:8888 & --------
sleep 2 ---------
curl http://localhost:8888/


















