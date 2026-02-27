/*
===============================================================================
Criação de Procedure: Carregamento da Camada Prata
-===============================================================================

Objetivo: Essa procedure é destinada à Camada Prata. Ela trunca as tabelas, insere e trata dados vindos da camada bronze.

Parâmetros: Nenhum.

Exemplo de uso:
    CALL prata.load_prata();

ATENÇÃO: lembre-se de atualizar os destinos dos arquivos antes de rodar o script.
===============================================================================
*/

CREATE OR REPLACE PROCEDURE prata.load_prata()
LANGUAGE plpgsql
AS $$
BEGIN -- Início da procedure
  
  DECLARE
      tempo_inicio_batch TIMESTAMP;
      tempo_inicio_tarefa TIMESTAMP;
      tempo_final_tarefa TIMESTAMP;
      tempo_final_batch TIMESTAMP;
      duracao INT;
  
  BEGIN -- Início do try
      tempo_inicio_batch := CLOCK_TIMESTAMP();

      RAISE NOTICE '================================================';
      RAISE NOTICE 'Truncando toda a Camada Prata';
      RAISE NOTICE '================================================';
  
      tempo_inicio_tarefa := CLOCK_TIMESTAMP();
      TRUNCATE 
          prata.clientes,
          prata.vendedores,
          prata.produtos,
          prata.pedidos,
          prata.pedidos_pagamentos,
          prata.pedidos_itens,
          prata.pedidos_avaliacoes,
          prata.geolocalizacao
      CASCADE;
      tempo_final_tarefa := CLOCK_TIMESTAMP();
      duracao := EXTRACT(EPOCH FROM (tempo_final_tarefa - tempo_inicio_tarefa));
      RAISE NOTICE '>> Duração do truncamento das tabelas: % segundos', duracao;
      RAISE NOTICE '>> -------------';
  
      RAISE NOTICE '================================================';
      RAISE NOTICE 'Inserindo dados na Camada Prata';
      RAISE NOTICE '================================================';
  
      -- Clientes
      tempo_inicio_tarefa := CLOCK_TIMESTAMP();
      RAISE NOTICE '>> Inserindo dados na tabela prata.clientes';
      INSERT INTO prata.clientes (
          id_cliente,
          id_unico_cliente,
          prefixo_cep_cliente,
          cidade_cliente,
          estado_cliente
      )
      SELECT 
          TRIM(customer_id),
          TRIM(customer_unique_id),
          CASE 
              WHEN LENGTH(TRIM(customer_zip_code_prefix)) <> 5 OR customer_zip_code_prefix IS NULL THEN NULL
              ELSE TRIM(customer_zip_code_prefix)
          END AS prefixo_cep_cliente,
          UPPER(TRIM(customer_city)) AS cidade_cliente,
          UPPER(TRIM(customer_state)) AS estado_cliente
      FROM bronze.customers;
      tempo_final_tarefa := CLOCK_TIMESTAMP();
      duracao := EXTRACT(EPOCH FROM (tempo_final_tarefa - tempo_inicio_tarefa));
      RAISE NOTICE '>> Duração do carregamento da tabela: % segundos', duracao;
      RAISE NOTICE '>> -------------';
  
      -- Vendedores
      tempo_inicio_tarefa := CLOCK_TIMESTAMP();
      RAISE NOTICE '>> Inserindo dados na tabela prata.vendedores';
      INSERT INTO prata.vendedores (
          id_vendedor,
          prefixo_cep_vendedor,
          cidade_vendedor,
          estado_vendedor
      )
      SELECT 
          TRIM(seller_id),
          TRIM(seller_zip_code_prefix),
          TRIM(UPPER(seller_city)),
          TRIM(UPPER(seller_state))
      FROM bronze.sellers;
      tempo_final_tarefa := CLOCK_TIMESTAMP();
      duracao := EXTRACT(EPOCH FROM (tempo_final_tarefa - tempo_inicio_tarefa));
      RAISE NOTICE '>> Duração do carregamento da tabela: % segundos', duracao;
      RAISE NOTICE '>> -------------';
  
      -- Produtos
      tempo_inicio_tarefa := CLOCK_TIMESTAMP();
      RAISE NOTICE '>> Inserindo dados na tabela prata.produtos';
      INSERT INTO prata.produtos (
          id_produto,
          categoria,
          qtde_caracteres_nome,
          qtde_caracteres_descricao,
          qtde_fotos,
          peso_g,
          comprimento_cm,
          altura_cm,
          largura_cm
      )
      SELECT 
          TRIM(product_id),
          CASE 
              WHEN UPPER(TRIM(product_category_name)) = 'LA CUISINE' THEN 'COZINHA'
              WHEN UPPER(TRIM(product_category_name)) = 'COOL_STUFF' THEN 'MISCELÂNEA'
              WHEN product_category_name IS NULL THEN 'NÃO INFORMADO'
              ELSE UPPER(TRIM(product_category_name))
          END AS categoria,
          product_name_lenght,
          product_description_lenght,
          product_photos_qty,
          product_weight_g,
          product_length_cm,
          product_height_cm,
          product_width_cm
      FROM bronze.products;
      tempo_final_tarefa := CLOCK_TIMESTAMP();
      duracao := EXTRACT(EPOCH FROM (tempo_final_tarefa - tempo_inicio_tarefa));
      RAISE NOTICE '>> Duração do carregamento da tabela: % segundos', duracao;
      RAISE NOTICE '>> -------------';
  
      -- Pedidos
      tempo_inicio_tarefa := CLOCK_TIMESTAMP();
      RAISE NOTICE '>> Inserindo dados na tabela prata.pedidos';
      INSERT INTO prata.pedidos (
          id_pedido,
          id_cliente,
          status_pedido,
          data_hora_compra,
          data_hora_aprovacao,
          data_hora_envio,
          data_hora_entrega,
          previsao_entrega
      )
      SELECT 
          TRIM(order_id),
          TRIM(customer_id),
          CASE UPPER(TRIM(order_status))
              WHEN 'UNAVAILABLE' THEN 'INDISPONÍVEL'
              WHEN 'SHIPPED' THEN 'DESPACHADO'
              WHEN 'INVOICED' THEN 'PROCESSADO'
              WHEN 'CREATED' THEN 'CRIADO'
              WHEN 'APPROVED' THEN 'APROVADO'
              WHEN 'PROCESSING' THEN 'EM PROCESSAMENTO'
              WHEN 'DELIVERED' THEN 'ENTREGUE'
              WHEN 'CANCELED' THEN 'CANCELADO'
              ELSE 'INVÁLIDO'
          END AS status_pedido,
          order_purchase_timestamp,
          order_approved_at,
          order_delivered_carrier_date,
          order_delivered_customer_date,
          order_estimated_delivery_date
      FROM bronze.orders;
      tempo_final_tarefa := CLOCK_TIMESTAMP();
      duracao := EXTRACT(EPOCH FROM (tempo_final_tarefa - tempo_inicio_tarefa));
      RAISE NOTICE '>> Duração do carregamento da tabela: % segundos', duracao;
      RAISE NOTICE '>> -------------';
  
      -- Pagamentos
      tempo_inicio_tarefa := CLOCK_TIMESTAMP();
      RAISE NOTICE '>> Inserindo dados na tabela prata.pedidos_pagamentos';
      INSERT INTO prata.pedidos_pagamentos (
          id_pedido,
          n_pagamento_sequencial,
          forma_pagamento,
          parcelas,
          valor_pagamento
      )
      SELECT
          order_id,
          payment_sequential,
          CASE TRIM(UPPER(payment_type))
              WHEN 'NOT_DEFINED' THEN 'INDEFINIDO'
              WHEN 'DEBIT_CARD' THEN 'DEBITO'
              WHEN 'CREDIT_CARD' THEN 'CREDITO'
              WHEN 'BOLETO' THEN UPPER(payment_type)
              WHEN 'VOUCHER' THEN UPPER(payment_type)
              ELSE 'INVÁLIDO'
          END,
          payment_installment,
          payment_value
      FROM bronze.order_payments;
      tempo_final_tarefa := CLOCK_TIMESTAMP();
      duracao := EXTRACT(EPOCH FROM (tempo_final_tarefa - tempo_inicio_tarefa));
      RAISE NOTICE '>> Duração do carregamento da tabela: % segundos', duracao;
      RAISE NOTICE '>> -------------';
  
      -- Itens de pedidos
      tempo_inicio_tarefa := CLOCK_TIMESTAMP();
      RAISE NOTICE '>> Inserindo dados na tabela prata.pedidos_itens';
      INSERT INTO prata.pedidos_itens (
          id_pedido,
          id_item_pedido,
          id_produto,
          id_vendedor,
          data_hora_limite_envio,
          preco,
          valor_frete
      )
      SELECT
          TRIM(order_id),
          order_item_id,
          TRIM(product_id),
          TRIM(seller_id),
          shipping_limit_date,
          price,
          freight_value
      FROM bronze.order_items;
      tempo_final_tarefa := CLOCK_TIMESTAMP();
      duracao := EXTRACT(EPOCH FROM (tempo_final_tarefa - tempo_inicio_tarefa));
      RAISE NOTICE '>> Duração do carregamento da tabela: % segundos', duracao;
      RAISE NOTICE '>> -------------';
  
      -- Geolocalização
      tempo_inicio_tarefa := CLOCK_TIMESTAMP();
      RAISE NOTICE '>> Inserindo dados na tabela prata.geolocalizacao';
      INSERT INTO prata.geolocalizacao (
          prefixo_cep,
          latitude,
          longitude,
          cidade,
          estado
      )
      SELECT
          TRIM(geolocation_zip_code_prefix),
          geolocation_lat,
          geolocation_lng,
          UPPER(geolocation_city),
          UPPER(geolocation_state)
      FROM bronze.geolocation;
      tempo_final_tarefa := CLOCK_TIMESTAMP();
      duracao := EXTRACT(EPOCH FROM (tempo_final_tarefa - tempo_inicio_tarefa));
      RAISE NOTICE '>> Duração do carregamento da tabela: % segundos', duracao;
      RAISE NOTICE '>> -------------';
  
      -- Reviews
      tempo_inicio_tarefa := CLOCK_TIMESTAMP();
      RAISE NOTICE '>> Inserindo dados na tabela prata.pedidos_avaliacoes';
  	INSERT INTO prata.pedidos_avaliacoes (
  	    id_avaliacao,
  	    id_pedido,
  	    nota,
  	    titulo,
  	    comentario,
  	    data_envio_formulario,
  	    data_hora_resposta_formulario
  	)
  	SELECT
  	    review_id,
  	    order_id,
  	    review_score,
  	    COALESCE(review_comment_title, 'N/SA'),
  	    COALESCE(review_comment_message, 'N/SA'),
  	    review_creation_date,
  	    review_answer_timestamp
  	FROM (
  	    SELECT *,
  	           ROW_NUMBER() OVER (PARTITION BY review_id ORDER BY review_creation_date) AS rn -- Condição da deduplicação
  	    FROM bronze.order_reviews
  	)
  	WHERE rn = 1;
      duracao := EXTRACT(EPOCH FROM (tempo_final_tarefa - tempo_inicio_tarefa));
      RAISE NOTICE '>> Duração do carregamento da tabela: % segundos', duracao;
      RAISE NOTICE '>> -------------';
  
      tempo_final_batch := CLOCK_TIMESTAMP();
      duracao := EXTRACT(EPOCH FROM (tempo_final_batch - tempo_inicio_batch));
      RAISE NOTICE '>> Duração total do carregamento da Camada Prata: % segundos', duracao;
      RAISE NOTICE '>> -------------';
  
  EXCEPTION
      WHEN OTHERS THEN
          RAISE NOTICE 'Mensagem de erro: %', SQLERRM;
	END;
END;
$$;
