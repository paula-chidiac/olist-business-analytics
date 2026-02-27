/*
===============================================================================
Script DDL: Criando as tabelas da camada prata
===============================================================================

Objetivo do script: 
  Criar as tabelas na camada prata com relação de PK e FK, apagando tabelas já existentes. 
  Adicionalmente, o script cria uma coluna dwh para controle de data e hora de criação da tabela.

===============================================================================
*/

CREATE SCHEMA IF NOT EXISTS prata;

DROP TABLE IF EXISTS
	prata.pedidos_itens,
	prata.pedidos_avaliacoes,
	prata.pedidos_pagamentos,
	prata.pedidos,
	prata.produtos,
	prata.vendedores,
	prata.clientes,
	prata.geolocalizacao
CASCADE;

CREATE TABLE prata.geolocalizacao (
	prefixo_cep 			TEXT PRIMARY KEY,
	latitude 				NUMERIC(9,6),
	longitude 				NUMERIC(9,6),
	cidade 					TEXT,
	estado 					TEXT,
	dwh_data_hora_criacao 	TIMESTAMP DEFAULT NOW()
);

CREATE TABLE prata.clientes (
	id_cliente 				TEXT PRIMARY KEY,
	id_unico_cliente 		TEXT,
	prefixo_cep_cliente 	TEXT,
	cidade_cliente 			TEXT,
	estado_cliente 			TEXT,
	dwh_data_hora_criacao 	TIMESTAMP DEFAULT NOW()
);


CREATE TABLE prata.vendedores (
	id_vendedor 			TEXT PRIMARY KEY,
	prefixo_cep_vendedor 	TEXT,
	cidade_vendedor 		TEXT,
	estado_vendedor 		TEXT,
	dwh_data_hora_criacao 	TIMESTAMP DEFAULT NOW()
);


CREATE TABLE prata.produtos (
	id_produto 					TEXT PRIMARY KEY,
	categoria 					TEXT,
	qtde_caracteres_nome 		INT,
	qtde_caracteres_descricao 	INT,
	quantidade_fotos 			INT,
	peso_g 						INT,
	comprimento_cm 				INT,
	altura_cm 					INT,
	largura_cm 					INT,
	dwh_data_hora_criacao 		TIMESTAMP DEFAULT NOW()
);

CREATE TABLE prata.pedidos(
	id_pedido	 					TEXT PRIMARY KEY,
	id_cliente	 					TEXT,
	status_pedido 					TEXT,
	data_hora_compra				TIMESTAMP,
	data_hora_aprovacao	 			TIMESTAMP,
	data_hora_envio					TIMESTAMP,
	data_hora_entrega				TIMESTAMP,
	previsao_entrega			 	DATE,
	dwh_data_hora_criacao 			TIMESTAMP DEFAULT NOW(),

	CONSTRAINT fk_pedidos_cliente
        FOREIGN KEY (id_cliente)
        REFERENCES prata.clientes (id_cliente)
);


CREATE TABLE prata.pedidos_pagamentos (
	id_pedido		 		TEXT,
	n_pagamento_sequencial 	INT,
	tipo_pagamento			TEXT,
	parcelas				INT,
	valor_pagamento			NUMERIC(10,2),
	dwh_data_hora_criacao 	TIMESTAMP DEFAULT NOW(),

	CONSTRAINT fk_pgtos_pedido
        FOREIGN KEY (id_pedido)
        REFERENCES prata.pedidos (id_pedido)
);


CREATE TABLE prata.pedidos_avaliacoes (
	id_avaliacao					TEXT PRIMARY KEY,
	id_pedido						TEXT,
	nota							INT,
	titulo							TEXT,
	comentario						TEXT,
	data_envio_formulario			DATE,
	data_hora_resposta_formulario	TIMESTAMP,
	dwh_data_hora_criacao 			TIMESTAMP DEFAULT NOW(),

	CONSTRAINT fk_avaliacoes_pedidos
        FOREIGN KEY (id_pedido)
        REFERENCES prata.pedidos (id_pedido),

	CONSTRAINT verificacao_review
		CHECK (nota BETWEEN 1 AND 5)
);


CREATE TABLE prata.pedidos_itens (
	id_pedido				TEXT,
	id_item_pedido 			INT,
	id_produto 				TEXT,
	id_vendedor 			TEXT,
	data_hora_limite_envio 	TIMESTAMP,
	preco 					NUMERIC(10,2),
	valor_frete 			NUMERIC(10,2),
	dwh_data_hora_criacao 	TIMESTAMP DEFAULT NOW(),

	PRIMARY KEY (id_pedido, id_item_pedido),
	
	CONSTRAINT fk_itens_pedidos
		FOREIGN KEY (id_pedido)
		REFERENCES prata.pedidos (id_pedido),

	CONSTRAINT fk_itens_vendedores
		FOREIGN KEY (id_vendedor)
		REFERENCES prata.vendedores (id_vendedor),

	CONSTRAINT fk_itens_produtos
		FOREIGN KEY (id_produto)
		REFERENCES prata.produtos (id_produto)
);

