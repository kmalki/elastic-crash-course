from elasticsearch import Elasticsearch, helpers
from elasticsearch.exceptions import RequestError
import json, csv

client = Elasticsearch(HOST)

index_name_2 = "ecommerce"
data_file_2 = "data.csv"

try:
    client.indices.create(index_name_2)
except RequestError as ex:
   pass

l = []

with open(data_file_2, 'r', encoding='windows-1252') as file:
    csvReader = csv.DictReader(file)
    l = list(csvReader)


helpers.parallel_bulk(client, [client.index(index=index_name_2, body=json.dumps(doc)) for doc in l], chunk_size=500, ignore_status=400, request_timeout=60*3, thread_count=3)