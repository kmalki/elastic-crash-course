# Beginner's Crash Course to Elastic Stack

Repo faisant lien aux workshops nommés Beginner's Crash Course to Elastic Stack mis en place par Elastic Community : https://www.youtube.com/watch?v=gS_nHTWZEJ8&list=PL_mJOmq4zsHZYAyK606y7wjQtC0aoE6Es&index=5


## Part 1: Intro to Elasticsearch and Kibana

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

Script d'insertion des documents du dataset des news categories du kaggle : https://www.kaggle.com/datasets/rmisra/news-category-dataset

https://github.com/kmalki/elastic-crash-course/blob/1c77b40aee81b3b32fe70ea8aaa8fe2f1f82f07c/main.py#L1-L19

Requète de recherche :
```
GET news-headers/_search
```
Retourne un sample de documents présents dans l'index
```
{
  "took" : 121,
  "timed_out" : false,
  "_shards" : {
    "total" : 5,
    "successful" : 5,
    "skipped" : 0,
    "failed" : 0
  },
  "hits" : {
    "total" : {
      "value" : 10000, #nb de documents retourné, 10000 max par défaut
      "relation" : "gte" #relation: description du nombre total de documents qui vérifie la recherche par rapport à value : gte (greater) ou eq (equal)
    },
    "max_score" : 1.0,
    "hits" : [
      {
        "_index" : "news-headlines",
        "_type" : "_doc",
        "_id" : "NoT9WIwBFc6yYpJYHHpm",
        "_score" : 1.0,
        "_source" : {
          "category" : "THE WORLDPOST",
          "headline" : "Think that 2016 Was A Tough Year For Saudi Arabia? Wait Till You See 2017",
          "authors" : "James M. Dorsey, ContributorS. Rajaratnam School of International Studies, Senior fellow",
          "link" : "https://www.huffingtonpost.com/entry/think-that-2016-was-a-tough-year-for-saudi-arabia-wait_us_5869e60ee4b014e7c72ee2a4",
          "short_description" : "By James M. Dorsey 2016 was not a good year for Saudi Arabia. Sharply lower oil prices sparked a domestic financial crisis",
          "date" : "2017-01-02"
        }
      }
      ...
    ]
  }
}
```
Récupérer le total de documents
```
GET news-headlines/_search
{
  "track_total_hits": true
}


RES
{
    ...
    "total" : {
      "value" : 209527,
      "relation" : "eq"
    },
}
```
2 types de recherches :
- query : retrouver les documents qui match certains critères
- aggs : aggregation, analyse sur les documents
  
Requète pour une période de temps précise :
```
GET news-headlines/_search
{
  "query": { #type de recherche
    "range": { #recherche dans un interval
      "date": { #par la date
        "gte": "2015-06-20", #greater than or eq
        "lte": "2015-09-22" #lower than or eq
      }
    }
  }
}
```
Nombre de documents par catégorie :
```
GET news-headlines/_search
{
  "aggs": {
    "by_category": { #nom de l'aggrega dans le résultat
      "terms": { #type d'aggrega (terms : création d'un bucket par unique valeur)
        "field": "category.keyword", #champ sur lequel se fait l'aggrega
        "size": 100 #nom de bucket à retourner max
      }
    }
  }
}

RES
"aggregations" : {
    "by_category" : {
      "doc_count_error_upper_bound" : 0,
      "sum_other_doc_count" : 0,
      "buckets" : [
        {
          "key" : "POLITICS",
          "doc_count" : 35602
        },
        {
          "key" : "WELLNESS",
          "doc_count" : 17945
        },
        {
          "key" : "ENTERTAINMENT",
          "doc_count" : 17362
        },
        ...
      ]
    }
}
```
Combinaison query & aggs

```
GET news-headlines/_search
{
  "query": {
    "match": {
      "category": "ENTERTAINMENT"
    }
  },
  "aggs": {
    "popular_in_entertainmment": { #nom de l'aggréga
      "significant_text": { #type : agg qui retourne les termes ayant une haute fréquence ou inhabituelle
        "field": "headline" #champ de l'agg
      }
    }
  }
}

RES
"aggregations" : {
    "popular_in_entertainmment" : {
      "doc_count" : 17362,
      "bg_count" : 209527,
      "buckets" : [
        {
          "key" : "trailer", #terme
          "doc_count" : 410, #nb de doc qui ont le terme dans le set de résultat
          "score" : 0.20821949710931825,
          "bg_count" : 504 #nb de doc qui ont le terme dans l'index
        },
        {
          "key" : "movie",
          "doc_count" : 437,
          "score" : 0.1506452864034305,
          "bg_count" : 755
        }
        ...
      ]
    }
}
```
Precison & recall
```
GET news-headlines/_search
{
  "query": {
    "match": {
      "headline": "Khloe Kardashian Kendall Jenner"
    }
  }
}

RES:
955 docs
```
=> *match* utilise un OR pour chaque terme et récupère chaque document contenant au moins un des termes, augmentant le nombre de hits, ce qui augmente le recall.
On peut changer ce comportement en ajouter le champ *operator*, ce qui baissera le nombre de résultats, et augmentera la précision.
```
GET news-headlines/_search
{
  "query": {
    "match": {
      "headline": 
      {
        "query": "Khloe Kardashian Kendall Jenner",
        "operator": "and"
        }
  }
}
}

RES:
1 doc
```
Pour tuner la précision et le recall, on peut utiliser le champ *minimum_should_math* qui indique le nombre minimum de terme qui doivent matcher
```
GET news-headlines/_search
{
  "query": {
    "match": {
      "headline": 
      {
        "query": "Khloe Kardashian Kendall Jenner",
      "minimum_should_match": 3
    }
  }
}
}

RES:
6 docs
```

Part 3: Full text queries

Requète pour chercher une phrase complète :
```
GET news-headlines/_search
{
  "query": { #query
    "match_phrase": { #type de la query : recherche de phrase
      "Specify the field you want to search": { #champ sur lequel on recherche
        "query": "Enter search terms" #phrase à rechercher
      }
    }
  }
}
```
Comparaison *match* & *match_phrase* : "New York Knicks"
```
GET news-headlines/_search
{
  "query": {
    "match": {
      "headline": "New York Knicks"
    }
  }
}

RES : 8881 docs


GET news-headlines/_search
{
  "query": {
    "match_phrase": {
      "headline": "New York Knicks"
    }
  }
}

RES : 3 docs
```
Requète sur de multiples champs :
```
GET news-headlines/_search
{
  "query": {
    "multi_match": { #match sur de multiples champs
      "query": "", #recherche
      "fields": [] #champs dans lesquels rechercher
    }
  }
}
```
Multi-match équivaut à un match sur différents champs.
```
GET news-headlines/_search
{
  "query": {
    "multi_match": {
      "query": "NBA",
      "fields": ["headline", "short_description"]
    }
  }
}
```
Per-field boosting : permet de donner **plus de poids à certains champs** : exemple ici, un article qui aura la recherche dans l'en-tête plutot que dans la description, l'article devrait être plus intéressant dans notre recherche que l'inverse. On ajoute le poids après le champ suivi d'un ^ : **"headline^2"**
```
GET news-headlines/_search
{
  "query": {
    "multi_match": {
      "query": "NBA",
      "fields": ["headline^2", "short_description"]
    }
  }
}
```
Cela nous donne le même nombre de résultat mais le *ranking* sera différent en fonction des *boostings*.

Il existe différents type de multi-match.
Search phrase & multi-match :
```
GET news-headlines/_search
{
  "query": {
    "multi_match": {
      "query": "New York Knicks",
      "fields": ["headline^2", "short_description"]
    }
  }
}

RES : + 10000 docs


GET news-headlines/_search
{
  "query": {
    "multi_match": {
      "query": "New York Knicks",
      "fields": ["headline^2", "short_description"],
      "type": "phrase"
    }
  }
}

RES : 9 docs
```

Requète combinée :
On peut utiliser une *bool query*, qui permet de combiner des requètes et d'ajouter des conditions entre elles.
Il y a 4 clauses possibles :
- must :
- must_not :
- should :
- filter :
```
GET news-headlines/_search
{
  "query": {
    "bool": {
      "must": [
        {One or more queries can be specified here. A document MUST match all of these queries to be considered as a hit.}
      ],
      "must_not": [
        {A document must NOT match any of the queries specified here. If it does, it is excluded from the search results.}
      ],
      "should": [
        {A document does not have to match any queries specified here. However, it if it does match, this document is given a higher score.}
      ],
      "filter": [
        {These filters(queries) place documents in either yes or no category. Ones that fall into the yes category are included in the hits. }
      ]
    }
  }
}
```
Combinaison *query* & *aggs* :
Catégories d'article mentionnant Michelle Obama :
```
GET news-headlines/_search
{
  "query": {
    "match_phrase": {
      "headline": "Michelle Obama"
    }
  },
  "aggs": {
    "category_mentions": {
      "terms": {
        "field": "category.keyword",
        "size": 100
      }
    }
  }
}
```
Articles politiques mentionnant Michelle Obama dans le titre avec la clause *must* :
```
GET news-headlines/_search
{
  "query": {
    "bool": {
      "must": [
         {"match_phrase": {
            "headline": "Michelle Obama"
            }
         },
         {"match": {
            "category": "POLITICS"
            }
         }
      ]
    }
  }
}

RES : 53 docs
```
Articles mentionnant Michelle Obama dans le titre en excluant la catégorie WEDDING avec la clause *must_not* :
```
GET news-headlines/_search
{
  "query": {
    "bool": {
      "must": [
         {"match_phrase": {
            "headline": "Michelle Obama"
            }
         }
      ],
      "must_not": [
        {
          "match": {
            "category": "WEDDINGS"
          }
        }
      ]
    }
  }
}

RES : 216 docs
```
Tous les articles mentionnant Michelle Obama dans le titre en favorisant le score de ceux de la catégorie *BLACK VOICES* avec la clause *should* :
```
GET news-headlines/_search
{
  "query": {
    "bool": {
      "must": [
         {"match_phrase": {
            "headline": "Michelle Obama"
            }
         }
      ],
      "should": [
        {
          "match_phrase": {
            "category.keyword": "BLACK VOICES"
          }
        }
      ]
    }
  }
}

RES : 220 docs
```
Articles mentionnant Michelle Obama dans le titre entre 25/03/2014 et 25/03/2016 avec la clause *filter*:
```
GET news-headlines/_search
{
  "query": {
    "bool": {
      "must": [
         {"match_phrase": {
            "headline": "Michelle Obama"
            }
         }
      ],
      "filter": [
        {
          
           "range": {
             "date": {
               "gte" : "2014-03-25",
               "lte": "2016-03-25"
             }
           }
         
        }
      ]
    }
  }
}

RES : 33 docs
```