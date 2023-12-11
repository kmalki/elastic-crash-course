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

## Part 2: Relevance of a search

Etat d'un document dans une recherche :
- Vrai positif : document **pertinent retourné** par la recherche, qu'on **attendait** dans le résultat
- Faux positif : document **non pertinent retourné** par la recherche, qu'on **n'attendait pas** dans le résultat
- Vrai négatif : document **non pertinent non retourné** par la recherche, qu'on **n'attendait pas** dans le résultat
- Faux négatif : document **pertinent non retourné** par la recherche, qu'on **attendait** dans le résultat

Comment mesurer la pertinence d'une recherche :
- precision : **Vrais positifs / (Vrais positifs + Faux positifs)** : ratio des **résultats réellement pertinents retournés** par **l'ensemble des résultats retournés**
- recall : Vrais positifs / (Vrais positifs + Faux négatifs) : ratio des **résultats retournés** par **l'ensemble des documents (totaux) pertinents**

Deux mesures inversément liées : augmenter la precision fera baisser le recall, et inversement

Score : valeur qui représente la pertinence d'un document retourné par une recherche
Manières de calculer le score :
- Term Frequency : détermine combien de fois chaque terme de la recherche est présent dans le document
- Inverse Document Frequency : diminue le poids des termes à haute fréquence et augmente le poids des termes à basse fréquence

Ranking : classement des documents retournés par une recherche par leurs score

Script d'insertion des documents du dataset des news headlines du kaggle : https://www.kaggle.com/datasets/rmisra/news-category-dataset

https://github.com/kmalki/elastic-crash-course/blob/1c77b40aee81b3b32fe70ea8aaa8fe2f1f82f07c/main.py#L1-L19