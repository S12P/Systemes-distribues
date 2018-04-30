# Systeme Distribué


## Compiler : c(ring).

Création anneau : ring:build(N). avec N nombre de noeud.

Broadcast : ring:broad(PID).

Ajout d'un noeud : ring:add(PID).

Suppresion d'un noeud : ring:kill(PID).

Avoir un message : ring:getvalue(Key, PID).

Supprimer un message : ring:erase(Key, PID).

Envoyer un message : ring:send(Message, UUID, PID).