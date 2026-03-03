/*
===============================================================================
Script DDL: Criando as Views da camada ouro
===============================================================================

Objetivo do script: 
  Criar as views na camada ouro no esquema de estrela. 

===============================================================================
*/

CREATE SCHEMA IF NOT EXISTS ouro;

-- Fato vendas
CREATE OR REPLACE VIEW ouro.fato_vendas AS
WITH pagamentos_agr AS (
    SELECT
        id_pedido,
        SUM(valor_pagamento) AS total_pago,
        COUNT(DISTINCT n_pagamento_sequencial) AS n_pagamentos
    FROM prata.pedidos_pagamentos
    GROUP BY id_pedido
)
SELECT
    pi.id_pedido,
    pi.id_item_pedido,
    pi.id_produto,
    p.id_cliente,
    pi.id_vendedor,
    p.status_pedido,
    p.data_hora_compra,
    p.data_hora_envio,
    p.data_hora_entrega,
    p.previsao_entrega,
    pi.preco AS valor_item,
    pi.valor_frete,
    (pi.preco + pi.valor_frete) AS valor_total_item,
    (p.data_hora_entrega::date - p.data_hora_envio::date) AS tempo_entrega_dias,
    CASE WHEN p.data_hora_entrega > p.previsao_entrega THEN 1 ELSE 0 END AS flag_atraso,
    pa.nota,
    pg.total_pago,
    pg.n_pagamentos
FROM prata.pedidos_itens pi
JOIN prata.pedidos p ON pi.id_pedido = p.id_pedido
LEFT JOIN prata.pedidos_avaliacoes pa ON pi.id_pedido = pa.id_pedido
LEFT JOIN pagamentos_agr pg ON pi.id_pedido = pg.id_pedido;

-- Fato pagamentos
CREATE OR REPLACE VIEW ouro.fato_pagamentos AS
SELECT
    id_pedido,
    n_pagamento_sequencial,
    forma_pagamento,
    parcelas,
    valor_pagamento
FROM prata.pedidos_pagamentos;

-- Dimensão clientes
CREATE OR REPLACE VIEW ouro.dim_clientes AS
SELECT
    id_unico_cliente,
    id_cliente,
    prefixo_cep_cliente,
    cidade_cliente,
    estado_cliente,
    CASE
        WHEN estado_cliente IN ('RS','SC','PR') THEN 'Sul'
        WHEN estado_cliente IN ('SP','RJ','MG','ES') THEN 'Sudeste'
        WHEN estado_cliente IN ('BA','PE','CE','RN','PB','AL','SE','PI','MA') THEN 'Nordeste'
        WHEN estado_cliente IN ('DF','GO','MT','MS') THEN 'Centro-Oeste'
        WHEN estado_cliente IN ('AM','PA','AC','RO','RR','AP','TO') THEN 'Norte'
    END AS regiao_cliente
FROM prata.clientes;

-- Dimensão vendedores
CREATE OR REPLACE VIEW ouro.dim_vendedores AS
SELECT
    id_vendedor,
    prefixo_cep_vendedor,
    cidade_vendedor,
    estado_vendedor,
    CASE
        WHEN estado_vendedor IN ('RS','SC','PR') THEN 'Sul'
        WHEN estado_vendedor IN ('SP','RJ','MG','ES') THEN 'Sudeste'
        WHEN estado_vendedor IN ('BA','PE','CE','RN','PB','AL','SE','PI','MA') THEN 'Nordeste'
        WHEN estado_vendedor IN ('DF','GO','MT','MS') THEN 'Centro-Oeste'
        WHEN estado_vendedor IN ('AM','PA','AC','RO','RR','AP','TO') THEN 'Norte'
    END AS regiao_vendedor
FROM prata.vendedores;

-- Dimensão produtos
CREATE OR REPLACE VIEW ouro.dim_produtos AS
SELECT
    id_produto,
    categoria,
    qtde_caracteres_nome,
    qtde_caracteres_descricao,
    qtde_fotos,
    peso_g,
    comprimento_cm,
    altura_cm,
    largura_cm,
    CASE 
        WHEN qtde_caracteres_nome IS NULL
          OR qtde_caracteres_descricao IS NULL
          OR qtde_fotos IS NULL
          OR peso_g IS NULL
          OR comprimento_cm IS NULL
          OR altura_cm IS NULL
          OR largura_cm IS NULL
        THEN 1
        ELSE 0
    END AS metadados_faltando
FROM prata.produtos;

-- Dimensão geolocalização
CREATE OR REPLACE VIEW ouro.dim_geolocalizacao AS
SELECT
    prefixo_cep,
    latitude,
    longitude,
    cidade,
    estado
FROM prata.geolocalizacao;
