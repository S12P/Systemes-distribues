# Systeme Distribué


## Pour le fichier ring.erl


Lancer : erl

Compiler : c(ring).

Création anneau : ring :build(N). avec N nombre de nœud. Broadcast : ring :broad(PID).

Ajout d’un nœud : ring :add(PID).

Suppression d’un nœud : ring :kill(PID).

Avoir un message : ring :getvalue(Key, PID).

Supprimer un message : ring :erase(Key, PID).

Envoyer un message : ring :send(Message, UUID, PID).


## Pour le fichier ring2.erl

Lancer : erl -name name@adresse_ip -setcookie nom_cookie

(Par exemple : erl -name stephane@192.167.26.36 -setcookie ens)


Veuillez ensuite connecté tous les noeuds entre eux en faisant : net_adm(’name@ip’).

(Remarque si un noeud est connecté à tous alors il suffit de se connecté une fois a lui et on sera connecté a tout le monde)

Création anneau : ring2 :start().

Broadcast : ring2 :broad(PID).

Ajout d’un nœud : ring2 :add(PID, Noeud).

Suppression d’un nœud : ring2 :kill(PID).

Avoir un message : ring2 :getvalue(Key, PID). Supprimer un message : ring2 :erase(Key, PID).

Envoyer un message : ring2 :send(Message, UUID, PID).