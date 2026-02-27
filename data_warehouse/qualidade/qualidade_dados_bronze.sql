/*
===============================================================================
Testes de qualidade - Camada Bronze
===============================================================================
Objetivo: Este script verifica a qualidade dos dados na camada Bronze para orientar transformações na camada Prata. 

Notas: Utiize após carregar os dados na camada Bronze.
===============================================================================
*/

/* ========================================================================== 
					VERIFICAÇÃO DA TABELA DE CLIENTES
============================================================================= */

-- Verificação de chaves únicas (geradas a cada pedido) duplicadas. Retorno esperado: zero
SELECT 
	COUNT(customer_id) - COUNT(DISTINCT customer_id) AS diferenca
FROM bronze.customers

-- Verificação de tamanho inadequado de prefixo de CEP. Retorno esperado: nenhuma linha
SELECT * FROM bronze.customers WHERE LENGTH(TRIM(customer_zip_code_prefix)) <> 5

-- Verificação de nulos em customer_state. Retorno esperado: nenhuma linha.
SELECT * FROM bronze.customers WHERE customer_state IS NULL 

-- Verificação de nulos em customer_state. Retorno esperado: nenhuma linha
SELECT * FROM bronze.customers WHERE customer_city IS NULL 

-- Verificação de Estados inválidos ou fora do padrão
SELECT DISTINCT customer_state 
FROM bronze.customers
WHERE customer_state NOT IN ('AC','AL','AP','AM','BA','CE','DF','ES','GO','MA','MT','MS','MG','PA','PB','PR','PE','PI','RJ','RN','RS','RO','RR','SC','SP','SE','TO');


/* ========================================================================== 
					VERIFICAÇÃO DA TABELA DE PEDIDOS
============================================================================= */

--- Verificação de tipos de status de pedidos e quantidade. 
SELECT
    order_status,
    COUNT(*) AS contagem,
    ROUND(COUNT(*) / SUM(COUNT(*)) OVER () * 100, 2) AS percentual
FROM bronze.orders
GROUP BY order_status
ORDER BY contagem DESC;

--- Verificação de pedidos com datas inconsistentes

SELECT *
FROM bronze.orders
WHERE 
	  (order_purchase_timestamp IS NOT NULL AND order_approved_at IS NOT NULL
	   AND order_purchase_timestamp > order_approved_at)
	   OR (order_approved_at IS NOT NULL AND order_delivered_carrier_date IS NOT NULL
	   AND order_approved_at > order_delivered_carrier_date)
	   OR (order_delivered_carrier_date IS NOT NULL AND order_delivered_customer_date IS NOT NULL
	   AND order_delivered_carrier_date > order_delivered_customer_date)


--- Percentual de datas inconsistentes
SELECT 
	COUNT(*) AS total,
    SUM(flag_inconsistencia_tempo) AS inconsistentes,
    ROUND(SUM(flag_inconsistencia_tempo)::numeric / COUNT(*) * 100, 2) AS percentual
FROM 
	(SELECT 
		CASE WHEN 
	      	(order_purchase_timestamp IS NOT NULL AND order_approved_at IS NOT NULL AND order_purchase_timestamp > order_approved_at)
	     	OR (order_approved_at IS NOT NULL AND order_delivered_carrier_date IS NOT NULL AND order_approved_at > order_delivered_carrier_date)
	     	OR (order_delivered_carrier_date IS NOT NULL AND order_delivered_customer_date IS NOT NULL AND order_delivered_carrier_date > order_delivered_customer_date)
	    THEN 1
	    ELSE 0
		END AS flag_inconsistencia_tempo
		FROM bronze.orders);
		
--- Verificação de datas futuras
SELECT * FROM bronze.orders WHERE order_purchase_timestamp > NOW();


/* ========================================================================== 
					VERIFICAÇÃO DA TABELA DE PEDIDOS
============================================================================= */

-- Verificação de chaves únicas duplicadas. Retorno esperado: zero
SELECT 
	COUNT(product_id) - COUNT(DISTINCT product_id) AS diferenca
FROM bronze.products

-- Verificação de categorias existentes e quantidade
SELECT
    product_category_name,
    COUNT(*) AS contagem,
    ROUND(COUNT(*) / SUM(COUNT(*)) OVER () * 100, 2) AS percentual
FROM bronze.products
GROUP BY product_category_name
ORDER BY contagem DESC;

-- Verificação de nulos (ocorrem sempre juntos)
SELECT COUNT(*)
FROM bronze.products
WHERE product_name_lenght IS NULL AND product_description_lenght IS NULL AND product_photos_qty IS NULL

-- Verificação de nulos em outras colunas de metadados
SELECT COUNT(*)
FROM bronze.products
WHERE product_weight_g IS NULL OR product_length_cm IS NULL OR product_height_cm IS NULL OR product_width_cm IS NULL

-- Verificação de quais produtos não tem metadados completos
SELECT * FROM bronze.products 
WHERE	
	(product_weight_g IS NULL 
	OR product_length_cm IS NULL 
	OR product_height_cm IS NULL 
	OR product_width_cm IS NULL)

-- Verificação de vendas de produtos sem nenhum metadado
-- Como há 17 vendas, mantido.
SELECT COUNT(*) AS total_vendas
FROM bronze.order_items oi
JOIN bronze.products p ON oi.product_id = p.product_id
	WHERE p.product_category_name IS NULL
	  AND p.product_name_lenght IS NULL
	  AND p.product_description_lenght IS NULL
	  AND p.product_weight_g IS NULL
	  AND p.product_length_cm IS NULL
	  AND p.product_height_cm IS NULL
	  AND p.product_width_cm IS NULL;
	  
-------------------------------------
--Tratamento da tabela de produtos--
-------------------------------------
SELECT 
    TRIM(product_id) AS id_produto,
    CASE 
        WHEN UPPER(TRIM(product_category_name)) = 'LA CUISINE' THEN 'COZINHA'
        WHEN UPPER(TRIM(product_category_name)) = 'COOL_STUFF' THEN 'MISCELÂNEA'
        WHEN product_category_name IS NULL THEN 'NÃO INFORMADO'
        ELSE UPPER(TRIM(product_category_name))
    END AS categoria,
    product_name_lenght AS qtde_caracteres_nome,
    product_description_lenght AS qtde_caracteres_descricao,
    product_photos_qty AS qtde_fotos,
    product_weight_g AS peso_g,
    product_length_cm AS comprimento_cm,
    product_height_cm AS altura_cm,
    product_width_cm AS largura_cm
FROM bronze.products;

/* ========================================================================== 
					VERIFICAÇÃO DA TABELA DE PAGAMENTOS
============================================================================= */

-- Verificação de nulos
SELECT COUNT(*) FROM bronze.order_payments WHERE order_id IS NULL;

SELECT COUNT(*) FROM bronze.order_payments WHERE payment_sequential IS NULL;

SELECT COUNT(*) FROM bronze.order_payments WHERE payment_installment IS NULL;

SELECT COUNT(*) FROM bronze.order_payments WHERE payment_value IS NULL OR payment_value < 0;

-- Verificação dos tipos de pagamento
SELECT DISTINCT payment_type FROM bronze.order_payments

-- Pedidos entregues com total de pagamento <= 0
SELECT op.order_id
FROM bronze.order_payments op
JOIN bronze.orders o 
    ON op.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY op.order_id
HAVING SUM(op.payment_value) <= 0;

-- Verificação se total pago é equivalente a preço + frete.
-- Variações podem ocorrer devido a descontos, juros, entre outros

WITH itens AS (
    SELECT 
        order_id,
        SUM(price + freight_value) AS total_itens
    FROM bronze.order_items
    GROUP BY order_id
),
pagamentos AS (
    SELECT 
        order_id,
        SUM(payment_value) AS total_pago
    FROM bronze.order_payments
    GROUP BY order_id
)

SELECT 
    i.order_id,
    i.total_itens,
    p.total_pago,
    (p.total_pago - i.total_itens) AS diferenca
FROM itens i
JOIN pagamentos p ON i.order_id = p.order_id
WHERE ABS(p.total_pago - i.total_itens) > 0.01;

--Verificação do percentual de valores inconsistentes

WITH itens AS (
    SELECT 
        order_id,
        SUM(price + freight_value) AS total_itens
    FROM bronze.order_items
    GROUP BY order_id
),
pagamentos AS (
    SELECT 
        order_id,
        SUM(payment_value) AS total_pago
    FROM bronze.order_payments
    GROUP BY order_id
)

SELECT 
    COUNT(*) AS total_pedidos,
    COUNT(*) FILTER (
        WHERE ABS(p.total_pago - i.total_itens) > 0.01
    ) AS total_pedidos_valor_inconsistente,
    ROUND(
        COUNT(*) FILTER (
            WHERE ABS(p.total_pago - i.total_itens) > 0.01
        ) * 100.0 / COUNT(*),
        2
    ) AS percentual_inconsistente
FROM itens i
JOIN pagamentos p 
    ON i.order_id = p.order_id;

/* ========================================================================== 
					VERIFICAÇÃO DA TABELA DE ITENS DE PEDIDOS
============================================================================= */

-- Verificação de nulos
SELECT COUNT(*) FROM bronze.order_items WHERE order_item_id < 1 OR order_item_id IS NULL 
SELECT * FROM bronze.order_items WHERE product_id IS NULL OR seller_id IS NULL OR price IS NULL OR freight_value IS NULL


/* ========================================================================== 
					VERIFICAÇÃO DA TABELA DE VENDEDORES
============================================================================= */

-- Verificação de nulos em chave primária. Retorno esperado: zero
SELECT COUNT(*) 
FROM bronze.sellers
WHERE seller_id IS NULL;

-- Verificação de nulos gerais. Retorno esperado: nenhuma linha
SELECT * FROM bronze.sellers WHERE seller_city IS NULL OR seller_state IS NULL

-- Verificação do prefixo do CEP. Retorno esperado: nenhuma linha
SELECT * FROM bronze.sellers WHERE LENGTH(seller_zip_code_prefix::text) <> 5


/* ========================================================================== 
					VERIFICAÇÃO DA TABELA DE AVALIAÇÕES
============================================================================= */

-- Verificação de duplicatas na chave primária
SELECT *
FROM bronze.order_reviews
WHERE review_id IN (
    SELECT review_id
    FROM bronze.order_reviews
    GROUP BY review_id
    HAVING COUNT(*) > 1
)
ORDER BY review_id;
	
/* ========================================================================== 
					    VERIFICAÇÕES CRUZADAS
============================================================================= */

-- Verificação de validade de clientes em orders. Retorno esperado: nenhuma linha
SELECT COUNT(*) 
FROM bronze.orders o
LEFT JOIN bronze.customers c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- Verificação de item de pedido apontando para número de pedido não existente. Retorno esperado: nenhuma linha
SELECT COUNT(*)
FROM bronze.order_items oi
LEFT JOIN bronze.orders o ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

-- Verificação de venda de produto não cadastrado. Retorno esperado: nenhuma linha
SELECT COUNT(*)
FROM bronze.order_items oi
LEFT JOIN bronze.products p ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;
