# Beginner's Crash Course to Elastic Stack

Repo faisant lien aux workshops nommés Beginner's Crash Course to Elastic Stack mis en place par Elastic Community : https://www.youtube.com/watch?v=gS_nHTWZEJ8&list=PL_mJOmq4zsHZYAyK606y7wjQtC0aoE6Es&index=5



- [Beginner's Crash Course to Elastic Stack](#beginners-crash-course-to-elastic-stack)
  - [Part 1: Intro to Elasticsearch and Kibana](#part-1-intro-to-elasticsearch-and-kibana)
  - [Part 2: Relevance of a search](#part-2-relevance-of-a-search)
  - [Part 3: Full text queries](#part-3-full-text-queries)
  - [Part 4: Running Aggregations with Elasticsearch and Kibana](#part-4-running-aggregations-with-elasticsearch-and-kibana)
    - [Metric aggs](#metric-aggs)
    - [Bucket aggs](#bucket-aggs)
      - [Date histogram aggs](#date-histogram-aggs)
      - [Histogram aggs](#histogram-aggs)
      - [Range aggs](#range-aggs)
      - [Terms aggs](#terms-aggs)
      - [Aggs combinés](#aggs-combinés)


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

https://github.com/kmalki/elastic-crash-course/blob/f09a7f57dd53acb6cd9f61b5e0267936ff9385d1/main_news_category_json_upload.py#L1-L19

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

## Part 3: Full text queries

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

## Part 4: Running Aggregations with Elasticsearch and Kibana

Nouveau dataset de factures ecommerces : https://www.kaggle.com/datasets/carrie1/ecommerce-data/data

Script ingestion des données du nouveau dataset :
(A du être modifié plusieurs fois car lors de la lecture et l'envoi des données du csv il y a eu plusieurs erreurs : timeout, problème de vm et de process car j'avais essayé de le faire via une vm EC2, et finalement j'ai fini par terminé l'envoi des données depuis mon local, en changeant à chaque fois le début du tableau de données à récupérer du csv. J'ai également par la suite utilisé *parallel_bulk* pour paralleliser et augmenter la vitesse d'insertion. J'ai aussi modifié le chunk_size.)

https://github.com/kmalki/elastic-crash-course/blob/f09a7f57dd53acb6cd9f61b5e0267936ff9385d1/main_ecommerce_csv_upload.py#L1-L22

Sample d'informations sur l'index
```
GET ecommerce_data/_search


RES : 
"hits" : [
      {
        "_index" : "ecommerce_data",
        "_type" : "_doc",
        "_id" : "RIZVX4wBFc6yYpJYlI8_",
        "_score" : 1.0,
        "_source" : {
          "InvoiceNo" : "545690",
          "StockCode" : "85062",
          "Description" : "PEARL CRYSTAL PUMPKIN T-LIGHT HLDR",
          "Quantity" : "1",
          "InvoiceDate" : "3/6/2011 12:46",
          "UnitPrice" : "1.65",
          "CustomerID" : "13263",
          "Country" : "United Kingdom"
        }
      },
      {
        "_index" : "ecommerce_data",
        "_type" : "_doc",
        "_id" : "RYZVX4wBFc6yYpJYlI9U",
        "_score" : 1.0,
        "_source" : {
          "InvoiceNo" : "545690",
          "StockCode" : "22460",
          "Description" : "EMBOSSED GLASS TEALIGHT HOLDER",
          "Quantity" : "1",
          "InvoiceDate" : "3/6/2011 12:46",
          "UnitPrice" : "1.25",
          "CustomerID" : "13263",
          "Country" : "United Kingdom"
        }
      },
      ...
]
```
Aggs syntax :
```
GET ecommerce_data/_search
{
  "aggs": {
    "Name your aggregations here": {
      "Specify the aggregation type here": {
        "field": "Name the field you want to aggregate on here"
      }
    }
  }
}
```

### Metric aggs
Type d'aggs qui permet de calculer des métriques numériques sur les données. Exemple :
- sum
- min
- max
- avg
- cardinality : unique count

Somme sur UnitPrice avec *sum*
```
GET ecommerce_data/_search
{
  "aggs": {
    "sum_unit_price": {
      "sum": {
        "field": "UnitPrice"
      }
    }
  }
}

RES :
{
  ...
  "aggregations" : {
    "sum_unit_price" : {
      "value" : 1946449.894
    }
  }
}
```
Ajouter size à 0 dans la query permet de ne pas retourner les top hits et accelérer la query
```
GET ecommerce_data/_search
{
  "size": 0, 
  "aggs": {
    "sum_unit_price": {
      "sum": {
        "field": "UnitPrice"
      }
    }
  }
}

RES :
{
  "took" : 70,
  "timed_out" : false,
  "_shards" : {
    "total" : 5,
    "successful" : 5,
    "skipped" : 0,
    "failed" : 0
  },
  "hits" : {
    "total" : {
      "value" : 10000,
      "relation" : "gte"
    },
    "max_score" : null,
    "hits" : [ ]
  },
  "aggregations" : {
    "sum_unit_price" : {
      "value" : 1946449.894
    }
  }
}

```
Prix le plus bas sur UnitPrice avec *min*
```
GET ecommerce_data/_search
{
  "size": 0, 
  "aggs": {
    "lowest_unit_price": {
      "min": {
        "field": "UnitPrice"
      }
    }
  }
}

RES :

"aggregations" : {
    "lowest_unit_price" : {
      "value" : 0.001
    }
  }
```
Prix le plus haut sur UnitPrice avec *max*
```
GET ecommerce_data/_search
{
  "size": 0, 
  "aggs": {
    "highest_unit_price": {
      "max": {
        "field": "UnitPrice"
      }
    }
  }
}

RES : 
"aggregations" : {
    "highest_unit_price" : {
      "value" : 498.79
    }
  }
```
Prix moyen sur UnitPrice avec *avg*
```
GET ecommerce_data/_search
{
  "size": 0, 
  "aggs": {
    "average_unit_price": {
      "avg": {
        "field": "UnitPrice"
      }
    }
  }
}

RES :
"aggregations" : {
    "average_unit_price" : {
      "value" : 3.6103066456206867
    }
  }
```
Statistiques sur UnitPrice en une requète avec *stats*
```
GET ecommerce_data/_search
{
  "size": 0, 
  "aggs": {
    "stats_unit_price": {
      "stats": {
        "field": "UnitPrice"
      }
    }
  }
}

RES :
"aggregations" : {
    "stats_unit_price" : {
      "count" : 539137,
      "min" : 0.001,
      "max" : 498.79,
      "avg" : 3.6103066456206867,
      "sum" : 1946449.894
    }
  }
```
Nombre de clients uniques avec *cardinality* sur CustomerID
```
GET ecommerce_data/_search
{
  "size": 0, 
  "aggs": {
    "unique_clients": {
      "cardinality": {
        "field": "CustomerID"
      }
    }
  }
}

RES :
"aggregations" : {
    "unique_clients" : {
      "value" : 4359
    }
  }
```
Prix moyen des produits vendu en Allemagne
```
GET ecommerce_data/_search
{
  "size": 0, 
  "query": {
    "match": {
      "Country": "Germany"
    }
  }, 
  "aggs": {
    "avg_product_price": {
      "avg": {
        "field": "UnitPrice"
      }
    }
  }
}

RES :
"aggregations" : {
    "avg_product_price" : {
      "value" : 3.6725674536256325
    }
  }
```
### Bucket aggs
Aggrégation sur différents subset de données : ex : avg sur chaque mois
Les données d'un même bucket partagent un même critère
Différents types de bucket aggs:
- date histogram aggs
- histogram aggs
- range aggs
- terms aggs

#### Date histogram aggs
Utile pour grouper par interval de temps
2 manière de grouper :
- fixed_interval : interval toujours constant
- calendar_interval : interval peut varier, ex mois (nb de jours varie)

Date histogram aggs fixed interval syntax
```
GET ecommerce_data/_search
{
  "size": 0,
  "aggs": {
    "Name your aggregations here": {
      "date_histogram": {
        "field":"Name the field you want to aggregate on here",
        "fixed_interval": "Specify the interval here"
      }
    }
  }
}
```
Aggs des transactions par interval de 8h
```
GET ecommerce_data/_search
{
  "size": 0, 
  "aggs": {
    "transactions_by_8hrs": {
      "date_histogram": {
        "field": "InvoiceDate"
      ,
        "fixed_interval": "8h"
      }
    }
  }
}

RES :
"aggregations" : {
    "transactions_by_8hrs" : {
      "buckets" : [
        {
          "key_as_string" : "12/1/2010 8:0",
          "key" : 1291190400000,
          "doc_count" : 2291
        },
        {
          "key_as_string" : "12/1/2010 16:0",
          "key" : 1291219200000,
          "doc_count" : 805
        },
        ...
      ]
    }
}
```
Aggs des transactions par calendar interval 
Valeurs possibles :
- minute,1m
- hour,1h
- day,1d
- week,1w
- month,1M
- quarter,1q
- year,1y
```
GET ecommerce_data/_search
{
  "size": 0, 
  "aggs": {
    "transactions_by_months": {
      "date_histogram": {
        "field": "InvoiceDate"
      ,
        "calendar_interval": "month"
      }
    }
  }
}

RES :
"aggregations" : {
    "transactions_by_months" : {
      "buckets" : [
        {
          "key_as_string" : "12/1/2010 0:0",
          "key" : 1291161600000,
          "doc_count" : 42170
        },
        {
          "key_as_string" : "1/1/2011 0:0",
          "key" : 1293840000000,
          "doc_count" : 34999
        },
        {
          "key_as_string" : "2/1/2011 0:0",
          "key" : 1296518400000,
          "doc_count" : 27573
        },
        {
          "key_as_string" : "3/1/2011 0:0",
          "key" : 1298937600000,
          "doc_count" : 36491
        }
      ]
    }
}
```
Order inversé des dates
```
GET ecommerce_data/_search
{
  "size": 0, 
  "aggs": {
    "transactions_by_months": {
      "date_histogram": {
        "field": "InvoiceDate"
      ,
        "calendar_interval": "month",
        "order": {
          "_key": "desc"
        }
      }
    }
  }
}
```

#### Histogram aggs
Crée des buckets par n'importe quelle interval de valeur numérique
Syntax
```
GET ecommerce_data/_search
{
  "size": 0,
  "aggs": {
    "Name your aggregations here": {
      "histogram": {
        "field":"Name the field you want to aggregate on here",
        "interval": Specify the interval here
      }
    }
  }
}
```
Aggs par interval de prix base 10
```
GET ecommerce_data/_search
{
  "size": 0, 
  "aggs": {
    "transactions_per_price_interval": {
      "histogram": {
        "field": "UnitPrice",
        "interval": 10
      }
    }
  }
}

RES :
"aggregations" : {
    "transactions_per_price_interval" : {
      "buckets" : [
        {
          "key" : 0.0,
          "doc_count" : 514354
        },
        {
          "key" : 10.0,
          "doc_count" : 20863
        },
        {
          "key" : 20.0,
          "doc_count" : 2135
        }
        ...
      ]
    }
}
```
Order inversé
```
GET ecommerce_data/_search
{
  "size": 0, 
  "aggs": {
    "transactions_per_price_interval": {
      "histogram": {
        "field": "UnitPrice",
"interval": 10,
"order": {
  "_key": "desc"
}
      }
    }
  }
}

RES :
"aggregations" : {
    "transactions_per_price_interval" : {
      "buckets" : [
        {
          "key" : 490.0,
          "doc_count" : 7
        },
        {
          "key" : 480.0,
          "doc_count" : 2
        },
        {
          "key" : 470.0,
          "doc_count" : 4
        },
        ...
      ]
    }
}
```
#### Range aggs
Semblable à histogram aggs, mais on peut avoir différents intervals numériques dans la même requète
Syntax
```
GET Enter_name_of_the_index_here/_search
{
  "size": 0,
  "aggs": {
   "Name your aggregations here": {
      "range": {
        "field": "Name the field you want to aggregate on here",
        "ranges": [
          {
            "to": x
          },
          {
            "from": x,
            "to": y
          },
          {
            "from": z
          }
        ]
      }
    }
  }
}
```
Exemple: interval 0-50, 50-200, 200+
```
GET ecommerce_data/_search
{
  "size": 0,
  "aggs": {
   "transactions_per_custom_ranges": {
      "range": {
        "field": "UnitPrice",
        "ranges": [
          {
            "to": 50
          },
          {
            "from": 50,
            "to": 200
          },
          {
            "from": 200
          }
        ]
      }
    }
  }
}

RES :
"aggregations" : {
    "transactions_per_custom_ranges" : {
      "buckets" : [
        {
          "key" : "*-50.0",
          "to" : 50.0,
          "doc_count" : 537975
        },
        {
          "key" : "50.0-200.0",
          "from" : 50.0,
          "to" : 200.0,
          "doc_count" : 855
        },
        {
          "key" : "200.0-*",
          "from" : 200.0,
          "doc_count" : 307
        }
      ]
    }
}
```

#### Terms aggs
Crée un bucket pour chaque terme unique d'un champ adns tous les documents. Souvent utilisé pour récupéré les termes les plus fréquents.
Syntax
```
GET Enter_name_of_the_index_here/_search
{
  "aggs": {
    "Name your aggregations here": {
      "terms": {
        "field": "Name the field you want to aggregate on here",
        "size": State how many top results you want returned here
      }
    }
  }
}
```
Top 5 customers par nombre d'achats
```
GET ecommerce_data/_search
{
  "size": 0, 
  "aggs": {
    "5_top_customers": {
      "terms": {
        "field": "CustomerID",
        "size": 5
      }
    }
  }
}

RES :
"buckets" : [
        {
          "key" : 17841,
          "doc_count" : 7983
        },
        {
          "key" : 14911,
          "doc_count" : 5897
        },
        {
          "key" : 14096,
          "doc_count" : 5110
        },
        {
          "key" : 12748,
          "doc_count" : 4638
        },
        {
          "key" : 14606,
          "doc_count" : 2782
        }
      ]
```
5 moins gros acheteurs en inversant order
```
GET ecommerce_data/_search
{
  "size": 0, 
  "aggs": {
    "5_bottom_customers": {
      "terms": {
        "field": "CustomerID",
        "size": 5,
      "order":{
        "_count": "asc"
      }
      }
    }
  }
}

RES :
 "aggregations" : {
    "5_bottom_customers" : {
      "doc_count_error_upper_bound" : 0,
      "sum_other_doc_count" : 406398,
      "buckets" : [
        {
          "key" : 12346,
          "doc_count" : 2
        },
        {
          "key" : 12347,
          "doc_count" : 182
        },
        {
          "key" : 12348,
          "doc_count" : 31
        },
        {
          "key" : 12349,
          "doc_count" : 73
        },
        {
          "key" : 12350,
          "doc_count" : 17
        }
      ]
    }
  }
```

#### Aggs combinés
Revenu journalier 
On ajoute un sous aggrégat dans l'aggrégat daily_transactions.
1. groupement par jour des transactions
2. ajout aggs de sum, avec un *script* qui calcule le total par transaction
```
{
  "size": 0,
  "aggs": {
    "daily_transactions": {
      "date_histogram": {
        "field": "InvoiceDate",
        "interval": "day"
      },
      "aggs": {
        "daily_revenue": {
          "sum": {
            "script": {
              "source": "doc['UnitPrice'].value * doc['Quantity'].value"
            }
          }
        }
      }
    }
  }
}

RES :
"aggregations" : {
    "daily_transactions" : {
      "buckets" : [
        {
          "key_as_string" : "12/1/2010 0:0",
          "key" : 1291161600000,
          "doc_count" : 3096,
          "daily_revenue" : {
            "value" : 57458.3
          }
        },
        {
          "key_as_string" : "12/2/2010 0:0",
          "key" : 1291248000000,
          "doc_count" : 2107,
          "daily_revenue" : {
            "value" : 46207.28
          }
        },
        ...
      ]
    }
}
```
Calcul de plusieurs metrics par bucket : ex daily revenue & clients unique par jour
```
GET ecommerce_data/_search
{
  "size": 0,
  "aggs": {
    "daily_transactions": {
      "date_histogram": {
        "field": "InvoiceDate",
        "interval": "day"
      },
      "aggs": {
        "daily_revenue": {
          "sum": {
            "script": {
              "source": "doc['UnitPrice'].value * doc['Quantity'].value"
            }
          }
        },
        "unique_count":{
          "cardinality": {
            "field": "CustomerID"
          }
        }
      }
    }
  }
}


RES :
"aggregations" : {
    "daily_transactions" : {
      "buckets" : [
        {
          "key_as_string" : "12/1/2010 0:0",
          "key" : 1291161600000,
          "doc_count" : 3096,
          "daily_revenue" : {
            "value" : 57458.3
          },
          "unique_count" : {
            "value" : 98
          }
        },
        {
          "key_as_string" : "12/2/2010 0:0",
          "key" : 1291248000000,
          "doc_count" : 2107,
          "daily_revenue" : {
            "value" : 46207.28
          },
          "unique_count" : {
            "value" : 117
          }
        },
        ...
      ]
    }
}
```
Order par un sous aggrégat : max daily_revenu
Ajout de order dans le premier aggrégat (création bucket)
```
GET ecommerce_data/_search
{
  "size": 0,
  "aggs": {
    "daily_transactions": {
      "date_histogram": {
        "field": "InvoiceDate",
        "interval": "day",
        "order": {
          "daily_revenue": "desc"
        }
      },
      "aggs": {
        "daily_revenue": {
          "sum": {
            "script": {
              "source": "doc['UnitPrice'].value * doc['Quantity'].value"
            }
          }
        },
        "unique_count":{
          "cardinality": {
            "field": "CustomerID"
          }
        }
      }
    }
  }
}

RES :
"aggregations" : {
    "daily_transactions" : {
      "buckets" : [
        {
          "key_as_string" : "11/14/2011 0:0",
          "key" : 1321228800000,
          "doc_count" : 3580,
          "daily_revenue" : {
            "value" : 111160.52
          },
          "unique_count" : {
            "value" : 109
          }
        },
        {
          "key_as_string" : "9/20/2011 0:0",
          "key" : 1316476800000,
          "doc_count" : 1716,
          "daily_revenue" : {
            "value" : 108194.0
          },
          "unique_count" : {
            "value" : 56
          }
        },
        ...
      ]
    }
}
```