/*
===============================================================================
Testes de qualidade - Camada Prata
===============================================================================
Objetivo: Este script verifica a qualidade dos dados na camada Prata para verificar transformações realizadas.

Notas: Utiize após carregar os dados na camada Prata.
===============================================================================
*/



/* ========================================================================== 
                    Verificação da Tabela de Clientes
============================================================================= */

-- Verificação de IDs de clientes duplicados. Resultado esperado: nenhuma linha.
SELECT 
    COUNT(id_cliente) - COUNT(DISTINCT id_cliente) AS diferenca
FROM prata.clientes;

-- Verificação de CEPs fora do padrão. Resultado esperado: nenhuma linha.
SELECT *
FROM prata.clientes
WHERE LENGTH(TRIM(prefixo_cep_cliente)) <> 5;

-- Verificação de nulos em cidade ou estado
SELECT *
FROM prata.clientes
WHERE cidade_cliente IS NULL OR estado_cliente IS NULL;

/* ========================================================================== 
                    Verificação da Tabela de Pedidos
============================================================================= */

-- Verificação de datas inconsistentes
SELECT *
FROM prata.pedidos
WHERE
      (data_hora_compra IS NOT NULL AND data_hora_aprovacao IS NOT NULL AND data_hora_compra > data_hora_aprovacao)
   OR (data_hora_aprovacao IS NOT NULL AND data_hora_envio IS NOT NULL AND data_hora_aprovacao > data_hora_envio)
   OR (data_hora_envio IS NOT NULL AND data_hora_entrega IS NOT NULL AND data_hora_envio > data_hora_entrega);

-- Verificação de percentual de datas inconsistentes
SELECT 
    COUNT(*) AS total,
    SUM(
        CASE
            WHEN (data_hora_compra IS NOT NULL AND data_hora_aprovacao IS NOT NULL AND data_hora_compra > data_hora_aprovacao)
              OR (data_hora_aprovacao IS NOT NULL AND data_hora_envio IS NOT NULL AND data_hora_aprovacao > data_hora_envio)
              OR (data_hora_envio IS NOT NULL AND data_hora_entrega IS NOT NULL AND data_hora_envio > data_hora_entrega)
            THEN 1 ELSE 0
        END
    ) AS total_datas_inconsistentes,
    ROUND(
        SUM(
            CASE
                WHEN (data_hora_compra IS NOT NULL AND data_hora_aprovacao IS NOT NULL AND data_hora_compra > data_hora_aprovacao)
                  OR (data_hora_aprovacao IS NOT NULL AND data_hora_envio IS NOT NULL AND data_hora_aprovacao > data_hora_envio)
                  OR (data_hora_envio IS NOT NULL AND data_hora_entrega IS NOT NULL AND data_hora_envio > data_hora_entrega)
                THEN 1 ELSE 0
            END
        ) * 100.0 / COUNT(*), 2
    ) AS percentual
FROM prata.pedidos;

-- Verificação de datas futuras
SELECT *
FROM prata.pedidos
WHERE data_hora_compra > NOW();

/* ========================================================================== 
                    Verificação da Tabela de Produtos
============================================================================= */

-- Verificação de produtos com algum metadado faltando
SELECT *
FROM prata.produtos
WHERE 
    qtde_caracteres_nome IS NULL
    OR qtde_caracteres_descricao IS NULL
    OR qtde_fotos IS NULL
    OR peso_g IS NULL
    OR comprimento_cm IS NULL
    OR altura_cm IS NULL
    OR largura_cm IS NULL;
	
-- Contagem de produtos sem categoria
SELECT COUNT(*)
FROM prata.produtos
WHERE 
    categoria = 'NÃO INFORMADO'

/* ========================================================================== 
                    Verificação da Tabela de Pagamentos
============================================================================= */

-- Verificação de pagamentos negativos ou zero para pedidos entregues
SELECT pp.id_pedido
FROM prata.pedidos_pagamentos pp
JOIN prata.pedidos p ON pp.id_pedido = p.id_pedido
WHERE p.status_pedido = 'ENTREGUE'
GROUP BY pp.id_pedido
HAVING SUM(valor_pagamento) <= 0;


/* ========================================================================== 
                    Verificação da Tabela de Itens de Pedidos
============================================================================= */

-- Verificação de IDs nulos ou inválidos
SELECT *
FROM prata.pedidos_itens
WHERE id_item_pedido < 1 OR id_produto IS NULL OR id_vendedor IS NULL OR preco IS NULL OR valor_frete IS NULL;

/* ========================================================================== 
                    Verificação da Tabela de Avaliações
============================================================================= */

-- Verificação de IDs duplicados
SELECT *
FROM prata.pedidos_avaliacoes
WHERE id_avaliacao IN (
    SELECT id_avaliacao
    FROM prata.pedidos_avaliacoes
    GROUP BY id_avaliacao
    HAVING COUNT(*) > 1
);

/* ========================================================================== 
                    Verificações Cruzadas
============================================================================= */

-- Verificação de validade de clientes em orders. Retorno esperado: nenhuma linha
SELECT COUNT(*)
FROM prata.pedidos p
LEFT JOIN prata.clientes c ON p.id_cliente = c.id_cliente
WHERE c.id_cliente IS NULL;

-- Verificação de item de pedido apontando para número de pedido não existente. Retorno esperado: nenhuma linha
SELECT COUNT(*)
FROM prata.pedidos_itens pi
LEFT JOIN prata.pedidos p ON pi.id_pedido = p.id_pedido
WHERE p.id_pedido IS NULL;

-- Verificação de venda de produto não cadastrado. Retorno esperado: nenhuma linha
SELECT COUNT(*)
FROM prata.pedidos_itens pi
LEFT JOIN prata.produtos pr ON pi.id_produto = pr.id_produto
WHERE pr.id_produto IS NULL;
