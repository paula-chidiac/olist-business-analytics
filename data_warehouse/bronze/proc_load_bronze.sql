/*
===============================================================================
Criação de Procedure: Carregamento da Camada Bronze
===============================================================================

Objetivo: Essa procedure é destinada à camada Bronze. Ela trunca as tabelas e copia dados de arquivos CSV armazenados localmente para elas. 

Exemplo de uso:
    CALL bronze.load_bronze();

ATENÇÃO: lembre-se de atualizar os destinos dos arquivos antes de rodar o script.
===============================================================================
*/

CREATE OR REPLACE PROCEDURE bronze.load_bronze()
LANGUAGE plpgsql
AS $$
BEGIN -- Início da procedure

	DECLARE
	    tempo_inicio_tarefa TIMESTAMP;
	    tempo_final_tarefa TIMESTAMP;
	    duracao INT;
		tempo_inicio_batch TIMESTAMP;
		tempo_final_batch TIMESTAMP;

	BEGIN -- Início do "Try"

	tempo_inicio_batch := CLOCK_TIMESTAMP();

		RAISE NOTICE '================================================';
		RAISE NOTICE 'Copiando dados para a Camada Bronze';
		RAISE NOTICE '================================================';

		tempo_inicio_tarefa := CLOCK_TIMESTAMP();
		RAISE NOTICE '>> Truncando bronze.customers';
		TRUNCATE TABLE bronze.customers;
		RAISE NOTICE '>> Copiando dados para bronze.customers';
		COPY bronze.customers
		FROM 'D:\Projetos\Olist\olist_customers_dataset.csv'
		DELIMITER ','
		CSV HEADER;
		tempo_final_tarefa := CLOCK_TIMESTAMP();
		duracao := EXTRACT(EPOCH FROM (tempo_final_tarefa - tempo_inicio_tarefa));
		RAISE NOTICE '>> Duração do carregamento da tabela: % segundos', duracao;
    	RAISE NOTICE '>> -------------';
		
		tempo_inicio_tarefa := CLOCK_TIMESTAMP();
		RAISE NOTICE '>> Truncando bronze.sellers';
		TRUNCATE TABLE bronze.sellers;
		RAISE NOTICE '>> Copiando dados para bronze.sellers';
		COPY bronze.sellers
		FROM 'D:\Projetos\Olist\olist_sellers_dataset.csv'
		DELIMITER ','
		CSV HEADER;
		tempo_final_tarefa := CLOCK_TIMESTAMP();
		duracao := EXTRACT(EPOCH FROM (tempo_final_tarefa - tempo_inicio_tarefa));
		RAISE NOTICE '>> Duração do carregamento da tabela: % segundos', duracao;
		RAISE NOTICE '>> -------------';

		RAISE NOTICE '>> Truncando bronze.products';
		TRUNCATE TABLE bronze.products;
		tempo_inicio_tarefa := CLOCK_TIMESTAMP();
		RAISE NOTICE '>> Copiando dados para bronze.products';
		COPY bronze.products
		FROM 'D:\Projetos\Olist\olist_products_dataset.csv'
		DELIMITER ','
		CSV HEADER;
		tempo_final_tarefa := CLOCK_TIMESTAMP();
		duracao := EXTRACT(EPOCH FROM (tempo_final_tarefa - tempo_inicio_tarefa));
		RAISE NOTICE '>> Duração do carregamento da tabela: % segundos', duracao;
		RAISE NOTICE '>> -------------';

		tempo_inicio_tarefa := CLOCK_TIMESTAMP();
		RAISE NOTICE '>> Truncando bronze.orders';
		TRUNCATE TABLE bronze.orders;
		RAISE NOTICE '>> Copiando dados para bronze.orders';
		COPY bronze.orders
		FROM 'D:\Projetos\Olist\olist_orders_dataset.csv'
		DELIMITER ','
		CSV HEADER;
		tempo_final_tarefa := CLOCK_TIMESTAMP();
		duracao := EXTRACT(EPOCH FROM (tempo_final_tarefa - tempo_inicio_tarefa));
		RAISE NOTICE '>> Duração do carregamento da tabela: % segundos', duracao;
		RAISE NOTICE '>> -------------';

		RAISE NOTICE '>> Truncando bronze.order_items';
		TRUNCATE TABLE bronze.order_items;
		tempo_inicio_tarefa := CLOCK_TIMESTAMP();
		RAISE NOTICE '>> Copiando dados para bronze.order_items';
		COPY bronze.order_items
		FROM 'D:\Projetos\Olist\olist_order_items_dataset.csv'
		DELIMITER ','
		CSV HEADER;
		tempo_final_tarefa := CLOCK_TIMESTAMP();
		duracao := EXTRACT(EPOCH FROM (tempo_final_tarefa - tempo_inicio_tarefa));
		RAISE NOTICE '>> Duração do carregamento da tabela: % segundos', duracao;
		RAISE NOTICE '>> -------------';

		tempo_inicio_tarefa := CLOCK_TIMESTAMP();
		RAISE NOTICE '>> Truncando bronze.order_payments';
		TRUNCATE TABLE bronze.order_payments;
		RAISE NOTICE '>> Copiando dados para bronze.order_payments';
		COPY bronze.order_payments
		FROM 'D:\Projetos\Olist\olist_order_payments_dataset.csv'
		DELIMITER ','
		CSV HEADER;
		tempo_final_tarefa := CLOCK_TIMESTAMP();
		duracao := EXTRACT(EPOCH FROM (tempo_final_tarefa - tempo_inicio_tarefa));
		RAISE NOTICE '>> Duração do carregamento da tabela: % segundos', duracao;
		RAISE NOTICE '>> -------------';

		tempo_inicio_tarefa := CLOCK_TIMESTAMP();
		RAISE NOTICE '>> Truncando bronze.order_reviews';
		TRUNCATE TABLE bronze.order_reviews;
		RAISE NOTICE '>> Copiando dados para bronze.order_reviews';
		COPY bronze.order_reviews
		FROM 'D:\Projetos\Olist\olist_order_reviews_dataset.csv'
		DELIMITER ','
		CSV HEADER;
		tempo_final_tarefa := CLOCK_TIMESTAMP();
		duracao := EXTRACT(EPOCH FROM (tempo_final_tarefa - tempo_inicio_tarefa));
		RAISE NOTICE '>> Duração do carregamento da tabela: % segundos', duracao;
		RAISE NOTICE '>> -------------';

		tempo_inicio_tarefa := CLOCK_TIMESTAMP();
		RAISE NOTICE '>> Truncando bronze.geolocation';
		TRUNCATE TABLE bronze.geolocation;
		RAISE NOTICE '>> Copiando dados para bronze.geolocation';
		COPY bronze.geolocation
		FROM 'D:\Projetos\Olist\olist_geolocation_dataset.csv'
		DELIMITER ','
		CSV HEADER;
		tempo_final_tarefa := CLOCK_TIMESTAMP();
		duracao := EXTRACT(EPOCH FROM (tempo_final_tarefa - tempo_inicio_tarefa));
		RAISE NOTICE '>> Duração do carregamento da tabela: % segundos', duracao;
		RAISE NOTICE '>> -------------';
		tempo_final_batch := CLOCK_TIMESTAMP();
		duracao := EXTRACT(EPOCH FROM (tempo_final_batch - tempo_inicio_batch));
		RAISE NOTICE '>> Duração total do carregamento da camada Bronze: % seconds', duracao;
    RAISE NOTICE '>> -------------';
		
	EXCEPTION
		WHEN OTHERS THEN
			RAISE NOTICE 'Mensagem de erro: %', SQLERRM;
	END;
END;
$$;
