---------------------------EM CONSTRUÇÃO---------------------------




/* ========================================================================== 
					VERIFICAÇÃO DA TABELA DE CLIENTES
============================================================================= */

-- Verificação de chaves únicas duplicadas. Retorno esperado: zero.
SELECT 
	COUNT(customer_unique_id) - COUNT(DISTINCT customer_unique_id) AS diferenca
FROM bronze.customers

-- Verificação alternativa de chaves únicas duplicadas. Retorno esperado: nenhuma linha.
SELECT 
	customer_unique_id,
	COUNT(customer_unique_id) AS contagem_linhas
FROM bronze.customers GROUP BY customer_unique_id HAVING COUNT(customer_unique_id) > 1

-- Verificação de ZIP Code. Retorno esperado: nenhuma linha.
SELECT * FROM bronze.customers WHERE LENGTH(TRIM(customer_zip_code_prefix)) <> 5

-- Verificação de nulos em customer_state. Retorno esperado: nenhuma linha.
SELECT * FROM bronze.customers WHERE customer_state IS NULL 

-- Verificação dos Estados em customer_state
SELECT DISTINCT customer_state FROM bronze.customers

-------------------------------------
--Tratamento da tabela de clientes--
-------------------------------------
SELECT 
		TRIM(customer_id) AS id_cliente,
		TRIM(customer_unique_id) AS id_unico_cliente,
		CASE 
			WHEN LENGTH(TRIM(customer_zip_code_prefix)) <> 5 THEN NULL
			ELSE customer_zip_code_prefix
			END AS prefixo_cep_cliente,
		TRIM(UPPER(customer_city)) AS cidade_cliente,
		TRIM(UPPER(customer_state)) AS estado_cliente
FROM (SELECT 
		*,
		ROW_NUMBER() OVER(PARTITION BY customer_unique_id ORDER BY customer_id) AS flag -- Desempate técnico, sem regra de negócio aplicada
		FROM bronze.customers)
WHERE flag = 1

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

--- Verificação do percentual de datas inconsistentes
SELECT 
	COUNT(*) AS total,
    SUM(flag_inconsistencia_tempo) AS inconsistentes,
    ROUND(SUM(flag_inconsistencia_tempo)::numeric / COUNT(*) * 100, 2) AS percentual
FROM 
	(SELECT 
		CASE
		WHEN 
	        (order_purchase_timestamp IS NOT NULL AND order_approved_at IS NOT NULL
	         AND order_purchase_timestamp > order_approved_at)
	     OR (order_approved_at IS NOT NULL AND order_delivered_carrier_date IS NOT NULL
	         AND order_approved_at > order_delivered_carrier_date)
	     OR (order_delivered_carrier_date IS NOT NULL AND order_delivered_customer_date IS NOT NULL
	         AND order_delivered_carrier_date > order_delivered_customer_date)
	    THEN 1
	    ELSE 0
		END AS flag_inconsistencia_tempo
		FROM bronze.orders)

-------------------------------------
--Tratamento da tabela de pedidos--
-------------------------------------
SELECT 
	TRIM(order_id) AS id_pedido,
	TRIM(customer_id) AS id_cliente,
	CASE UPPER(TRIM(order_status))
		WHEN 'UNAVAILABLE' 				THEN 'INDISPONÍVEL'
		WHEN 'SHIPPED' 					THEN 'DESPACHADO'
		WHEN 'INVOICED' 				THEN 'PROCESSADO'
		WHEN 'CREATED' 					THEN 'CRIADO'
		WHEN 'APPROVED' 				THEN 'APROVADO'
		WHEN 'PROCESSING' 				THEN 'EM PROCESSAMENTO'
		WHEN 'DELIVERED' 				THEN 'ENTREGUE'
		WHEN 'CANCELED' 				THEN 'CANCELADO'
		ELSE 'INVÁLIDO'
	END AS status_pedido,
	order_purchase_timestamp 			AS data_compra,
	order_approved_at 					AS data_aprovacao,
	order_delivered_carrier_date 		AS data_envio,
	order_delivered_customer_date 		AS data_entrega,
	order_estimated_delivery_date 		AS previsao_entrega
FROM bronze.orders


/* ========================================================================== 
					VERIFICAÇÃO DA TABELA DE PEDIDOS
============================================================================= */

-- Verificação de chaves únicas duplicadas. Retorno esperado: zero.
SELECT 
	COUNT(product_id) - COUNT(DISTINCT product_id) AS diferenca
FROM bronze.products

-- Verificação de categorias existentes e quantidade.
SELECT
    product_category_name,
    COUNT(*) AS contagem,
    ROUND(COUNT(*) / SUM(COUNT(*)) OVER () * 100, 2) AS percentual
FROM bronze.products
GROUP BY product_category_name
ORDER BY contagem DESC;

-- Verificação de nulos (ocorrem sempre juntos). 
SELECT COUNT(*)
FROM bronze.products
WHERE product_name_lenght IS NULL 

SELECT COUNT(*)
FROM bronze.products
WHERE product_description_lenght IS NULL 

SELECT COUNT(*)
FROM bronze.products
WHERE product_photos_qty IS NULL

SELECT COUNT(*)
FROM bronze.products
WHERE product_name_lenght IS NULL AND product_description_lenght IS NULL AND product_photos_qty IS NULL

-- Verificação de nulos em outras colunas de metadados
SELECT COUNT(*)
FROM bronze.products
WHERE product_weight_g IS NULL OR product_length_cm IS NULL OR  product_height_cm IS NULL OR product_width_cm IS NULL

-- Verificação de quais produtos não tem metadados completos
SELECT * FROM bronze.products WHERE product_weight_g IS NULL 

-- Verificação de vendas de produto sem nenhum metadado além de id
-- Como há 17 vendas, mantido.
SELECT COUNT(*)
FROM bronze.order_items
WHERE product_id = '5eb564652db742ff8f28759cd8d2652a';

-- Verificação de datas futuras
SELECT COUNT(*)
FROM bronze.orders
WHERE order_purchase_timestamp > CURRENT_DATE;


-------------------------------------
--Tratamento da tabela de produtos--
-------------------------------------
SELECT 
	TRIM(product_id) AS id_produto,	
	CASE 
		WHEN UPPER(product_category_name) = 'LA CUISINE' THEN 'COZINHA'
		WHEN UPPER(product_category_name) = 'COOL_STUFF' THEN 'MISCELÂNEA'
		WHEN product_category_name IS NULL THEN 'NÃO INFORMADO'
		ELSE UPPER(product_category_name)
	END AS categoria_produto,
	product_name_lenght AS tamanho_nome_produto,
	product_description_lenght AS tamanho_descricao_produto,
	product_photos_qty AS quantidade_fotos_produto,
	product_weight_g AS peso_produto_g,
	product_length_cm AS comprimento_produto_cm,
	product_height_cm AS altura_produto_cm,
	product_width_cm AS largura_produto_cm,
	CASE 
		WHEN product_name_lenght IS NULL
		OR product_description_lenght IS NULL 
		OR product_photos_qty IS NULL 
		OR product_category_name IS NULL
		OR product_weight_g IS NULL
		OR product_length_cm IS NULL
		OR product_height_cm IS NULL
		OR product_width_cm IS NULL
		THEN 1
		ELSE 0
	END AS flag_metadados_produto_incompletos
FROM bronze.products

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

-- Verificação de pedidos com total de pagamento não positivo
SELECT order_id
FROM bronze.order_payments
GROUP BY order_id
HAVING SUM(payment_value) <= 0;

/* EM CONSTRUÇÃO
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
WHERE ABS(p.total_pago - i.total_itens) > 0.01; */

--------------------------------------
--Tratamento da tabela de pagamentos--
--------------------------------------
SELECT
	order_id AS id_pedido,
	payment_sequential AS numero_pagamento_sequencial,
	CASE TRIM(UPPER(payment_type))
			WHEN 'NOT_DEFINED' THEN 'INDEFINIDO'
			WHEN 'DEBIT_CARD' THEN 'DEBITO'
			WHEN 'CREDIT_CARD' THEN 'CREDITO'
			WHEN 'BOLETO' THEN UPPER(payment_type)
			WHEN 'VOUCHER' THEN UPPER(payment_type)
			ELSE 'INVÁLIDO'
	END AS forma_pagamento,
	payment_installment AS numero_parcelas,
	ROUND(payment_value, 2) AS valor_pagamento
FROM bronze.order_payments

/* ========================================================================== 
					VERIFICAÇÃO DA TABELA DE ITENS DE PEDIDOS
============================================================================= */

-- Verificação de nulos
SELECT COUNT(*) FROM bronze.order_items WHERE order_item_id < 1 OR order_item_id IS NULL 
SELECT * FROM bronze.order_items WHERE product_id IS NULL OR seller_id IS NULL OR price IS NULL OR freight_value IS NULL

--------------------------------------------
--Tratamento da tabela de itens de pedidos--
--------------------------------------------

SELECT
	TRIM(order_id) AS id_pedido,
	order_item_id AS id_item_pedido,
	TRIM(product_id) AS id_produto,
	TRIM(seller_id) AS id_vendedor,
	shipping_limit_date AS data_limite_entrega,
	ROUND(price, 2) AS preco,
	ROUND(freight_value, 2) AS valor_frete
FROM bronze.order_items

--------------------------------------------
--Tratamento da tabela de geolocalização--
--------------------------------------------

SELECT
	TRIM(geolocation_zip_code_prefix) AS prefixo_cep,
	geolocation_lat AS latitude,
	geolocation_lng AS longitude,
	UPPER(geolocation_city) AS cidade,
	UPPER(geolocation_state) AS estado
FROM bronze.geolocation


--------------------------------------------
--Tratamento da tabela de reviews--
--------------------------------------------

SELECT 
	TRIM(review_id) AS id_avaliacao,
	TRIM(order_id) AS id_pedido,
	review_score AS nota_avaliacao,
	review_comment_title AS titulo_avaliacao,
	review_comment_message AS texto_avaliacao
FROM bronze.order_reviews

/* ========================================================================== 
					VERIFICAÇÃO DA TABELA DE VENDEDORES
============================================================================= */
-- Verificação de nulos em chave primária. Retorno esperado: zero.
SELECT COUNT(*) 
FROM bronze.sellers
WHERE seller_id IS NULL;

-- Verificação de nulos gerais. Retorno esperado: nenhuma linha.
SELECT * FROM bronze.sellers WHERE seller_city IS NULL OR seller_state IS NULL

-- Verificação do prefixo do CEP. Retorno esperado: nenhuma linha.
SELECT * FROM bronze.sellers WHERE LENGTH(seller_zip_code_prefix::text) <> 5

--------------------------------------------
--Tratamento da tabela de sellers--
--------------------------------------------

SELECT 
	TRIM(seller_id) AS id_vendedor,
	seller_zip_code_prefix AS prefixo_cep_vendedor,
	UPPER(seller_city) AS cidade_vendedor,
	UPPER(seller_state) AS estado_vendedor
FROM bronze.sellers


/* ========================================================================== 
					VERIFICAÇÕES CRUZADAS
============================================================================= */

-- Verificação de validade de clientes em orders. Retorno esperado: nenhuma linha.
SELECT COUNT(*) 
FROM bronze.orders o
LEFT JOIN bronze.customers c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- Verificação de item de pedido apontando para pedido não existente. Retorno esperado: nenhuma linha.
SELECT COUNT(*)
FROM bronze.order_items oi
LEFT JOIN bronze.orders o ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

-- Verificação de venda de produto não cadastrado. Retorno esperado: nenhuma linha.
SELECT COUNT(*)
FROM bronze.order_items oi
LEFT JOIN bronze.products p ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;




