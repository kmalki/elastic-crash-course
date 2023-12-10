# Beginner's Crash Course to Elastic Stack

Repo faisant lien aux workshops nommés Beginner's Crash Course to Elastic Stack mis en place par Elastic Community : https://www.youtube.com/watch?v=gS_nHTWZEJ8&list=PL_mJOmq4zsHZYAyK606y7wjQtC0aoE6Es&index=5


## Course 1 : Intro to Elasticsearch and Kibana

J'ai préféré déployer un cluster Elasticsearch sur AWS grâce au free tier. Le déploiement est fait avec Terraform.

Cluster de 2 nodes, 10GB de stockage par node.

Définitions techniques :
- index : groupement logique de shard, semblable à une collection et distribué sur tous les nodes
- shard : unité de distribution des données sur les noeuds. 

Un index distribue des documents dans des shards, qui contiennent ces documents, et les shards sont distribués sur les noeuds du cluster.

Cela permet à Elasticsearch d'assurer la redondance des données, ce qui protège de la panne matériel et augmente la performance de requêtage plus on ajoute de noeuds au cluster, grâce au calcul et requêtage distribués. Et plus le cluster s'agrandit, Elasticsearch va automatiquement migrer des shards vers les nouveaux noeuds et équilibrer le cluster.

Format de requètes via Kibana :
- générique : *METHODE* *API*/*parameter*
- GET _cluster/health : informations du cluster
- GET _nodes/stats : informations sur les noeuds du cluster
- GET *index*/_doc/*id*
- PUT *index* : création d'un index
- POST *index*/_doc *{document}* : création d'un document avec un id généré automatiquement
- PUT *index*/_doc/*id* *{document}* : création d'un document en spécifiant un id, modifie le document si déjà existant et incrémente sa version
- PUT *index*/_create/*id* *{document}* : création d'un document en spécifiant un id, mais crée uniquement si id n'existe pas, sinon il ne modifie pas le document
- POST *index*/_update/*id* *{champs_à_modifier}* : modifie le document *id* en donnant comme paramètre uniquement les champs à modifier
- DELETE *index*/_doc/*id* : supprimer le document *id*

Résultat d'une requète :
```{
  "_index" : "favorite_movie", #nom de l'index
  "_type" : "_doc",
  "_id" : "SYOAVYwBFc6yYpJYTfzo", #id du document
  "_version" : 2, #version du document
  "result" : "updated", #resultat de la requète, peut aussi être deleted ou created
  "_shards" : { #infos sur la replication de la requète
    "total" : 2, #nb total de shards sur lesquels l'opération est effectuée
    "successful" : 2, #nb de shards sur lesquels ont réussi l'opération
    "failed" : 0 #nb de shards sur lesquels n'ont pas réussi l'opération
  },
  "_seq_no" : 2,
  "_primary_term" : 1
}
```