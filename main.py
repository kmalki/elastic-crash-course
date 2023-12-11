from elasticsearch import Elasticsearch, helpers
from elasticsearch.exceptions import RequestError
import json

client = Elasticsearch(HOST)

index_name = "news-headlines"

try:
    client.indices.create(index_name)
except RequestError as ex:
   pass

l = []

with open("News_Category_Dataset_v3.json") as file:
  l = list(file)

helpers.bulk(client, [client.index(index=index_name, body=json.loads(doc)) for doc in l], chunk_size=10000, ignore_status=400, request_timeout=60*3)