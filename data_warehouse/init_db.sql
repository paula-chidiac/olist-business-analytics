/*
=============================================================
Criação da base de dados e schemas
=============================================================

Objetivo do script: 
  Garantir que a database "olist" seja (re)criada do zero. Adicionalmente, cria os três esquemas para arquitetura medallion.

AVISO:
  Este script apaga todo o database "olist", junto com dados armazenados. 

=============================================================
*/


--- AVISO: Relizar operação fora da database;
--- Termina a conexão de todos os usuários do db; 

SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'datawarehouse';

--- AVISO: Relizar operação fora da database;
--- Apaga o datawarehouse;

DROP DATABASE IF EXISTS olist CASCADE;

--- Cria a database 'datawarehouse'

CREATE DATABASE olist;

--- AVISO: Realizar operação DENTRO de 'datawarehouse'
--- Cria os schemas

CREATE SCHEMA bronze;
CREATE SCHEMA prata;
CREATE SCHEMA ouro;
