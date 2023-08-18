import os
import json
import orjson
import re
import zlib
import isbnlib
import httpx
import functools
import collections
import barcode
import io
import langcodes
import tqdm
import concurrent
import threading
import yappi
import multiprocessing
import langdetect
import gc
import random
import slugify
import elasticsearch.helpers
import time
import pathlib
import ftlangdetect
import traceback
import flask_mail
import click
import pymysql.cursors

from config import settings
from flask import Blueprint, __version__, render_template, make_response, redirect, request
from allthethings.extensions import engine, mariadb_url, mariadb_url_no_timeout, es, Reflected, mail, mariapersist_url
from sqlalchemy import select, func, text, create_engine
from sqlalchemy.dialects.mysql import match
from sqlalchemy.orm import Session
from pymysql.constants import CLIENT
from allthethings.extensions import ComputedAllMd5s

from allthethings.page.views import get_aarecords_mysql

cli = Blueprint("cli", __name__, template_folder="templates")


#################################################################################################
# ./run flask cli dbreset
@cli.cli.command('dbreset')
def dbreset():
    print("Erasing entire database (2 MariaDB databases servers + 1 ElasticSearch)! Did you double-check that any production/large databases are offline/inaccessible from here?")
    time.sleep(2)
    print("Giving you 5 seconds to abort..")
    time.sleep(5)

    mariapersist_reset_internal()
    nonpersistent_dbreset_internal()
    print("Done! Search for example for 'Rhythms of the brain': http://localhost:8000/search?q=Rhythms+of+the+brain")

#################################################################################################
# ./run flask cli nonpersistent_dbreset
@cli.cli.command('nonpersistent_dbreset')
def nonpersistent_dbreset():
    print("Erasing nonpersist databases (1 MariaDB databases servers + 1 ElasticSearch)! Did you double-check that any production/large databases are offline/inaccessible from here?")
    time.sleep(2)
    print("Giving you 5 seconds to abort..")
    time.sleep(5)

    nonpersistent_dbreset_internal()
    print("Done! Search for example for 'Rhythms of the brain': http://localhost:8000/search?q=Rhythms+of+the+brain")


def nonpersistent_dbreset_internal():
    # Per https://stackoverflow.com/a/4060259
    __location__ = os.path.realpath(os.path.join(os.getcwd(), os.path.dirname(__file__)))

    engine_multi = create_engine(mariadb_url_no_timeout, connect_args={"client_flag": CLIENT.MULTI_STATEMENTS})
    cursor = engine_multi.raw_connection().cursor()

    # Generated with `docker compose exec mariadb mysqldump -u allthethings -ppassword --opt --where="1 limit 100" --skip-comments --ignore-table=computed_all_md5s allthethings > mariadb_dump.sql`
    cursor.execute(pathlib.Path(os.path.join(__location__, 'mariadb_dump.sql')).read_text())
    cursor.close()

    mysql_build_computed_all_md5s_internal()

    time.sleep(1)
    Reflected.prepare(engine_multi)
    elastic_reset_aarecords_internal()
    elastic_build_aarecords_internal()


def chunks(l, n):
    for i in range(0, len(l), n):
        yield l[i:i + n]

def query_yield_batches(conn, qry, pk_attr, maxrq):
    """specialized windowed query generator (using LIMIT/OFFSET)

    This recipe is to select through a large number of rows thats too
    large to fetch at once. The technique depends on the primary key
    of the FROM clause being an integer value, and selects items
    using LIMIT."""

    firstid = None
    while True:
        q = qry
        if firstid is not None:
            q = qry.where(pk_attr > firstid)
        batch = conn.execute(q.order_by(pk_attr).limit(maxrq)).all()
        if len(batch) == 0:
            break
        yield batch
        firstid = batch[-1][0]


#################################################################################################
# Rebuild "computed_all_md5s" table in MySQL. At the time of writing, this isn't
# used in the app, but it is used for `./run flask cli elastic_build_aarecords`.
# ./run flask cli mysql_build_computed_all_md5s
@cli.cli.command('mysql_build_computed_all_md5s')
def mysql_build_computed_all_md5s():
    print("Erasing entire MySQL 'computed_all_md5s' table! Did you double-check that any production/large databases are offline/inaccessible from here?")
    time.sleep(2)
    print("Giving you 5 seconds to abort..")
    time.sleep(5)

    mysql_build_computed_all_md5s_internal()

def mysql_build_computed_all_md5s_internal():
    engine_multi = create_engine(mariadb_url_no_timeout, connect_args={"client_flag": CLIENT.MULTI_STATEMENTS})
    cursor = engine_multi.raw_connection().cursor()
    print("Removing table computed_all_md5s (if exists)")
    cursor.execute('DROP TABLE IF EXISTS computed_all_md5s')
    print("Load indexes of libgenli_files")
    cursor.execute('LOAD INDEX INTO CACHE libgenli_files')
    print("Creating table computed_all_md5s and load with libgenli_files")
    cursor.execute('CREATE TABLE computed_all_md5s (md5 BINARY(16) NOT NULL, PRIMARY KEY (md5)) ENGINE=MyISAM ROW_FORMAT=FIXED SELECT UNHEX(md5) AS md5 FROM libgenli_files WHERE md5 IS NOT NULL')
    print("Load indexes of computed_all_md5s")
    cursor.execute('LOAD INDEX INTO CACHE computed_all_md5s')
    print("Load indexes of zlib_book")
    cursor.execute('LOAD INDEX INTO CACHE zlib_book')
    print("Inserting from 'zlib_book' (md5_reported)")
    cursor.execute('INSERT IGNORE INTO computed_all_md5s (md5) SELECT UNHEX(md5_reported) FROM zlib_book WHERE md5_reported != "" AND md5_reported IS NOT NULL')
    print("Inserting from 'zlib_book' (md5)")
    cursor.execute('INSERT IGNORE INTO computed_all_md5s (md5) SELECT UNHEX(md5) FROM zlib_book WHERE zlib_book.md5 != "" AND md5 IS NOT NULL')
    print("Load indexes of libgenrs_fiction")
    cursor.execute('LOAD INDEX INTO CACHE libgenrs_fiction')
    print("Inserting from 'libgenrs_fiction'")
    cursor.execute('INSERT IGNORE INTO computed_all_md5s (md5) SELECT UNHEX(md5) FROM libgenrs_fiction WHERE md5 IS NOT NULL')
    print("Load indexes of libgenrs_updated")
    cursor.execute('LOAD INDEX INTO CACHE libgenrs_updated')
    print("Inserting from 'libgenrs_updated'")
    cursor.execute('INSERT IGNORE INTO computed_all_md5s (md5) SELECT UNHEX(md5) FROM libgenrs_updated WHERE md5 IS NOT NULL')
    print("Load indexes of aa_ia_2023_06_files and aa_ia_2023_06_metadata")
    cursor.execute('LOAD INDEX INTO CACHE aa_ia_2023_06_files, aa_ia_2023_06_metadata')
    print("Inserting from 'aa_ia_2023_06_files'")
    cursor.execute('INSERT IGNORE INTO computed_all_md5s (md5) SELECT UNHEX(md5) FROM aa_ia_2023_06_metadata USE INDEX (libgen_md5) JOIN aa_ia_2023_06_files USING (ia_id) WHERE aa_ia_2023_06_metadata.libgen_md5 IS NULL')
    print("Load indexes of annas_archive_meta__aacid__zlib3_records")
    cursor.execute('LOAD INDEX INTO CACHE annas_archive_meta__aacid__zlib3_records')
    print("Inserting from 'annas_archive_meta__aacid__zlib3_records'")
    cursor.execute('INSERT IGNORE INTO computed_all_md5s (md5) SELECT UNHEX(md5) FROM annas_archive_meta__aacid__zlib3_records WHERE md5 IS NOT NULL')
    print("Load indexes of annas_archive_meta__aacid__zlib3_files")
    cursor.execute('LOAD INDEX INTO CACHE annas_archive_meta__aacid__zlib3_files')
    print("Inserting from 'annas_archive_meta__aacid__zlib3_files'")
    cursor.execute('INSERT IGNORE INTO computed_all_md5s (md5) SELECT UNHEX(md5) FROM annas_archive_meta__aacid__zlib3_files WHERE md5 IS NOT NULL')
    cursor.close()
    # engine_multi = create_engine(mariadb_url_no_timeout, connect_args={"client_flag": CLIENT.MULTI_STATEMENTS})
    # cursor = engine_multi.raw_connection().cursor()
    # print("Removing table computed_all_md5s (if exists)")
    # cursor.execute('DROP TABLE IF EXISTS computed_all_md5s')
    # print("Load indexes of libgenli_files")
    # cursor.execute('LOAD INDEX INTO CACHE libgenli_files')
    # # print("Creating table computed_all_md5s and load with libgenli_files")
    # # cursor.execute('CREATE TABLE computed_all_md5s (md5 CHAR(32) NOT NULL, PRIMARY KEY (md5)) ENGINE=MyISAM DEFAULT CHARSET=ascii COLLATE ascii_bin ROW_FORMAT=FIXED SELECT md5 FROM libgenli_files')

    # # print("Load indexes of computed_all_md5s")
    # # cursor.execute('LOAD INDEX INTO CACHE computed_all_md5s')
    # print("Load indexes of zlib_book")
    # cursor.execute('LOAD INDEX INTO CACHE zlib_book')
    # # print("Inserting from 'zlib_book' (md5_reported)")
    # # cursor.execute('INSERT INTO computed_all_md5s SELECT md5_reported FROM zlib_book LEFT JOIN computed_all_md5s ON (computed_all_md5s.md5 = zlib_book.md5_reported) WHERE md5_reported != "" AND computed_all_md5s.md5 IS NULL')
    # # print("Inserting from 'zlib_book' (md5)")
    # # cursor.execute('INSERT INTO computed_all_md5s SELECT md5 FROM zlib_book LEFT JOIN computed_all_md5s USING (md5) WHERE zlib_book.md5 != "" AND computed_all_md5s.md5 IS NULL')
    # print("Load indexes of libgenrs_fiction")
    # cursor.execute('LOAD INDEX INTO CACHE libgenrs_fiction')
    # # print("Inserting from 'libgenrs_fiction'")
    # # cursor.execute('INSERT INTO computed_all_md5s SELECT LOWER(libgenrs_fiction.MD5) FROM libgenrs_fiction LEFT JOIN computed_all_md5s ON (computed_all_md5s.md5 = LOWER(libgenrs_fiction.MD5)) WHERE computed_all_md5s.md5 IS NULL')
    # print("Load indexes of libgenrs_updated")
    # cursor.execute('LOAD INDEX INTO CACHE libgenrs_updated')
    # # print("Inserting from 'libgenrs_updated'")
    # # cursor.execute('INSERT INTO computed_all_md5s SELECT MD5 FROM libgenrs_updated LEFT JOIN computed_all_md5s USING (md5) WHERE computed_all_md5s.md5 IS NULL')
    # print("Load indexes of aa_ia_2023_06_files")
    # cursor.execute('LOAD INDEX INTO CACHE aa_ia_2023_06_files')
    # # print("Inserting from 'aa_ia_2023_06_files'")
    # # cursor.execute('INSERT INTO computed_all_md5s SELECT MD5 FROM aa_ia_2023_06_files LEFT JOIN aa_ia_2023_06_metadata USING (ia_id) LEFT JOIN computed_all_md5s USING (md5) WHERE aa_ia_2023_06_metadata.libgen_md5 IS NULL AND computed_all_md5s.md5 IS NULL')
    # print("Load indexes of annas_archive_meta__aacid__zlib3_records")
    # cursor.execute('LOAD INDEX INTO CACHE annas_archive_meta__aacid__zlib3_records')
    # # print("Inserting from 'annas_archive_meta__aacid__zlib3_records'")
    # # cursor.execute('INSERT INTO computed_all_md5s SELECT md5 FROM annas_archive_meta__aacid__zlib3_records LEFT JOIN computed_all_md5s USING (md5) WHERE md5 IS NOT NULL AND computed_all_md5s.md5 IS NULL')
    # print("Load indexes of annas_archive_meta__aacid__zlib3_files")
    # cursor.execute('LOAD INDEX INTO CACHE annas_archive_meta__aacid__zlib3_files')
    # # print("Inserting from 'annas_archive_meta__aacid__zlib3_files'")
    # # cursor.execute('INSERT INTO computed_all_md5s SELECT md5 FROM annas_archive_meta__aacid__zlib3_files LEFT JOIN computed_all_md5s USING (md5) WHERE md5 IS NOT NULL AND computed_all_md5s.md5 IS NULL')
    # print("Creating table computed_all_md5s")
    # cursor.execute('CREATE TABLE computed_all_md5s (md5 CHAR(32) NOT NULL, PRIMARY KEY (md5)) ENGINE=MyISAM DEFAULT CHARSET=ascii COLLATE ascii_bin ROW_FORMAT=FIXED IGNORE SELECT DISTINCT md5 AS md5 FROM libgenli_files UNION DISTINCT (SELECT DISTINCT md5_reported AS md5 FROM zlib_book WHERE md5_reported != "") UNION DISTINCT (SELECT DISTINCT md5 AS md5 FROM zlib_book WHERE md5 != "") UNION DISTINCT (SELECT DISTINCT LOWER(libgenrs_fiction.MD5) AS md5 FROM libgenrs_fiction) UNION DISTINCT (SELECT DISTINCT MD5 AS md5 FROM libgenrs_updated) UNION DISTINCT (SELECT DISTINCT md5 AS md5 FROM aa_ia_2023_06_files LEFT JOIN aa_ia_2023_06_metadata USING (ia_id) WHERE aa_ia_2023_06_metadata.libgen_md5 IS NULL) UNION DISTINCT (SELECT DISTINCT md5 AS md5 FROM annas_archive_meta__aacid__zlib3_records WHERE md5 IS NOT NULL) UNION DISTINCT (SELECT DISTINCT md5 AS md5 FROM annas_archive_meta__aacid__zlib3_files WHERE md5 IS NOT NULL)')
    # cursor.close()


#################################################################################################
# Recreate "aarecords" index in ElasticSearch, without filling it with data yet.
# (That is done with `./run flask cli elastic_build_aarecords`)
# ./run flask cli elastic_reset_aarecords
@cli.cli.command('elastic_reset_aarecords')
def elastic_reset_aarecords():
    print("Erasing entire ElasticSearch 'aarecords' index! Did you double-check that any production/large databases are offline/inaccessible from here?")
    time.sleep(2)
    print("Giving you 5 seconds to abort..")
    time.sleep(5)

    elastic_reset_aarecords_internal()

def elastic_reset_aarecords_internal():
    es.options(ignore_status=[400,404]).indices.delete(index='aarecords')
    es.options(ignore_status=[400,404]).indices.delete(index='aarecords_online_borrow')
    body = {
        "mappings": {
            "dynamic": False,
            "properties": {
                "search_only_fields": {
                    "properties": {
                        "search_filesize": { "type": "long", "index": False, "doc_values": True },
                        "search_year": { "type": "keyword", "index": True, "doc_values": True },
                        "search_extension": { "type": "keyword", "index": True, "doc_values": True, "eager_global_ordinals": True },
                        "search_content_type": { "type": "keyword", "index": True, "doc_values": True, "eager_global_ordinals": True },
                        "search_most_likely_language_code": { "type": "keyword", "index": True, "doc_values": True, "eager_global_ordinals": True },
                        "search_isbn13": { "type": "keyword", "index": True, "doc_values": True },
                        "search_doi": { "type": "keyword", "index": True, "doc_values": True },
                        "search_text": { "type": "text", "index": True, "analyzer": "icu_analyzer" },
                        "search_score_base": { "type": "float", "index": False, "doc_values": True },
                        "search_score_base_rank": { "type": "rank_feature" },
                        "search_access_types": { "type": "keyword", "index": True, "doc_values": True, "eager_global_ordinals": True },
                        "search_record_sources": { "type": "keyword", "index": True, "doc_values": True, "eager_global_ordinals": True },
                    },
                },
            },
        },
        "settings": {
            "index.number_of_replicas": 0,
            "index.search.slowlog.threshold.query.warn": "2s",
            "index.store.preload": ["nvd", "dvd"],
            "index.sort.field": "search_only_fields.search_score_base",
            "index.sort.order": "desc",
        },
    }
    es.indices.create(index='aarecords', body=body)
    es.indices.create(index='aarecords_online_borrow', body=body)

#################################################################################################
# Regenerate "aarecords" index in ElasticSearch.
# ./run flask cli elastic_build_aarecords
@cli.cli.command('elastic_build_aarecords')
def elastic_build_aarecords():
    elastic_build_aarecords_internal()

def elastic_build_aarecords_job(canonical_md5s):
    try:
        with Session(engine) as session:
            operations = []
            aarecords = get_aarecords_mysql(session, [f"md5:{canonical_md5}" for canonical_md5 in canonical_md5s])
            for aarecord in aarecords:
                for index in aarecord['indexes']:
                    operations.append({ **aarecord, '_op_type': 'index', '_index': index, '_id': aarecord['id'] })
                
            try:
                elasticsearch.helpers.bulk(es, operations, request_timeout=30)
            except Exception as err:
                if hasattr(err, 'errors'):
                    print(err.errors)
                print(repr(err))
                print("Got the above error; retrying..")
                try:
                    elasticsearch.helpers.bulk(es, operations, request_timeout=30)
                except Exception as err:
                    if hasattr(err, 'errors'):
                        print(err.errors)
                    print(repr(err))
                    print("Got the above error; retrying one more time..")
                    elasticsearch.helpers.bulk(es, operations, request_timeout=30)
            # print(f"Processed {len(aarecords)} md5s")
    except Exception as err:
        print(repr(err))
        traceback.print_tb(err.__traceback__)
        raise err

def elastic_build_aarecords_internal():
    THREADS = 50
    CHUNK_SIZE = 50
    BATCH_SIZE = 100000

    # Locally
    # THREADS = 1
    # CHUNK_SIZE = 10
    # BATCH_SIZE = 1000

    # Uncomment to do them one by one
    # THREADS = 1
    # CHUNK_SIZE = 1
    # BATCH_SIZE = 1

    first_md5 = ''
    # Uncomment to resume from a given md5, e.g. after a crash
    # first_md5 = '0337ca7b631f796fa2f465ef42cb815c'

    print("Do a dummy detect of language so that we're sure the model is downloaded")
    ftlangdetect.detect('dummy')

    with engine.connect() as conn:
        total = conn.execute(select([func.count(ComputedAllMd5s.md5)])).scalar()
        with tqdm.tqdm(total=total, bar_format='{l_bar}{bar}{r_bar} {eta}') as pbar:
            for batch in query_yield_batches(conn, select(ComputedAllMd5s.md5).where(ComputedAllMd5s.md5 >= bytes.fromhex(first_md5)), ComputedAllMd5s.md5, BATCH_SIZE):
                with multiprocessing.Pool(THREADS) as executor:
                    print(f"Processing {len(batch)} md5s from computed_all_md5s ( starting md5: {batch[0][0].hex()} )...")
                    executor.map(elastic_build_aarecords_job, chunks([item[0].hex() for item in batch], CHUNK_SIZE))
                    pbar.update(len(batch))

            print(f"Done!")


# Kept for future reference, for future migrations
# #################################################################################################
# # ./run flask cli elastic_migrate_from_aarecords_to_aarecords2
# @cli.cli.command('elastic_migrate_from_aarecords_to_aarecords2')
# def elastic_migrate_from_aarecords_to_aarecords2():
#     print("Erasing entire ElasticSearch 'aarecords2' index! Did you double-check that any production/large databases are offline/inaccessible from here?")
#     time.sleep(2)
#     print("Giving you 5 seconds to abort..")
#     time.sleep(5)

#     elastic_migrate_from_aarecords_to_aarecords2_internal()

# def elastic_migrate_from_aarecords_to_aarecords2_job(canonical_md5s):
#     try:
#         search_results_raw = es.mget(index="aarecords", ids=canonical_md5s)
#         # print(f"{search_results_raw}"[0:10000])
#         new_aarecords = []
#         for item in search_results_raw['docs']:
#             new_aarecords.append({
#                 **item['_source'],
#                 '_op_type': 'index',
#                 '_index': 'aarecords2',
#                 '_id': item['_id'],
#             })
                
#         elasticsearch.helpers.bulk(es, new_aarecords, request_timeout=30)
#         # print(f"Processed {len(new_aarecords)} md5s")
#     except Exception as err:
#         print(repr(err))
#         raise err

# def elastic_migrate_from_aarecords_to_aarecords2_internal():
#     elastic_reset_aarecords_internal()

#     THREADS = 60
#     CHUNK_SIZE = 70
#     BATCH_SIZE = 100000

#     first_md5 = ''
#     # Uncomment to resume from a given md5, e.g. after a crash (be sure to also comment out the index deletion above)
#     # first_md5 = '0337ca7b631f796fa2f465ef42cb815c'

#     with engine.connect() as conn:
#         total = conn.execute(select([func.count(ComputedAllMd5s.md5)])).scalar()
#         with tqdm.tqdm(total=total, bar_format='{l_bar}{bar}{r_bar} {eta}') as pbar:
#             for batch in query_yield_batches(conn, select(ComputedAllMd5s.md5).where(ComputedAllMd5s.md5 >= first_md5), ComputedAllMd5s.md5, BATCH_SIZE):
#                 with multiprocessing.Pool(THREADS) as executor:
#                     print(f"Processing {len(batch)} md5s from computed_all_md5s (starting md5: {batch[0][0]})...")
#                     executor.map(elastic_migrate_from_aarecords_to_aarecords2_job, chunks([item[0] for item in batch], CHUNK_SIZE))
#                     pbar.update(len(batch))

#             print(f"Done!")



#################################################################################################
# ./run flask cli mariapersist_reset
@cli.cli.command('mariapersist_reset')
def mariapersist_reset():
    print("Erasing entire persistent database ('mariapersist')! Did you double-check that any production databases are offline/inaccessible from here?")
    time.sleep(2)
    print("Giving you 5 seconds to abort..")
    time.sleep(5)
    mariapersist_reset_internal()

def mariapersist_reset_internal():
    # Per https://stackoverflow.com/a/4060259
    __location__ = os.path.realpath(os.path.join(os.getcwd(), os.path.dirname(__file__)))

    mariapersist_engine_multi = create_engine(mariapersist_url, connect_args={"client_flag": CLIENT.MULTI_STATEMENTS})
    cursor = mariapersist_engine_multi.raw_connection().cursor()

    # From https://stackoverflow.com/a/8248281
    cursor.execute("SELECT concat('DROP TABLE IF EXISTS `', table_name, '`;') FROM information_schema.tables WHERE table_schema = 'mariapersist' AND table_name LIKE 'mariapersist_%';")
    delete_all_query = "\n".join([item[0] for item in cursor.fetchall()])
    if len(delete_all_query) > 0:
        cursor.execute("SET FOREIGN_KEY_CHECKS = 0;")
        cursor.execute(delete_all_query)
        cursor.execute("SET FOREIGN_KEY_CHECKS = 1; COMMIT;")

    cursor.execute(pathlib.Path(os.path.join(__location__, 'mariapersist_migration.sql')).read_text())
    cursor.close()

#################################################################################################
# Send test email
# ./run flask cli send_test_email <email_addr>
@cli.cli.command('send_test_email')
@click.argument("email_addr")
def send_test_email(email_addr):
    email_msg = flask_mail.Message(subject="Hello", body="Hi there, this is a test!", recipients=[email_addr])
    mail.send(email_msg)
