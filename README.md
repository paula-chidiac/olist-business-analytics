# olist-business-analytics

Em construção

---

# Passo a Passo da Execução

## 1. Criação do DW (se preferir partir direto para a análise, prossiga para o 2.)

Dentro da pasta data_warehouse, execute os scripts na seguinte sequência:

1. **`init_db`**  
   - Cria o banco de dados e os schemas (`bronze`, `prata`, `ouro`).  
   - Exemplo: drop do banco antigo, criação do banco novo e schemas vazios.

2. **`ddl_bronze`**  
   - Criação das tabelas da camada Bronze.  
   - Estrutura baseada nos arquivos CSV originais do Olist.  

3. **`init_load_bronze`**  
   - Carrega os arquivos CSV para as tabelas Bronze.  
   - Dados brutos, sem transformação.

4. **`qualidade_bronze`**  
   - Valida consistência dos dados brutos.  
   - Checa duplicidade, campos nulos, tipos inválidos.  
   - Serve de guia para definir transformações na camada Prata.

5. **`ddl_prata`**  
   - Criação das tabelas da camada Prata.  
   - Inclui estrutura finalizada com tipos corretos e chaves primárias/estrangeiras.

6. **`init_load_prata`**  
   - Procedure que transforma e carrega dados da Bronze → Prata.  
   - Limpeza, deduplicação, padronização de valores, normalização de campos.  

7. **`qualidade_prata`**  
   - Checa se a carga da Prata foi realizada corretamente.  
   - Confirma integridade de dados, consistência entre tabelas e contagem de registros.  

8. **`ddl_ouro`**  
   - Criação de views e fatos/dimensões da camada Ouro (star schema).  
   - Inclui fatos: `fato_vendas`, `fato_pagamentos`.  
   - Inclui dimensões: `dim_clientes`, `dim_vendedores`, `dim_produtos`, `dim_geolocalizacao`.  
   - Calcula métricas analíticas (por exemplo, `flag_atraso`, `total_pago`, `metadados_faltando`).  


### Observações

- **Camada Bronze:** sempre dados brutos; nenhuma transformação complexa.  
- **Camada Prata:** dados limpos e normalizados; usada como fonte para Ouro.  
- **Camada Ouro:** preparada para análise; view desnormalizada, star schema, com métricas e flags analíticas.  
- **Qualidade:** scripts `qualidade_bronze` e `qualidade_prata` devem ser executados sempre após cada carga para garantir integridade.  

## 2. Analytics
  1. Utilize os arquivos disponibilizados em `analytics/datasets` ou, caso esteja com o dw montado, exporte cada view com o comando `COPY TO`, como no exemplo:
  ```sql
-- Exportar fato_vendas
COPY ouro.fato_vendas TO '/caminho_do_arquivo/fato_vendas.csv' WITH CSV HEADER;
```
