-- Questão 1
INSERT INTO tb_venda (id_venda, id_cliente, id_vendedor, dt_venda, status, canal, valor_bruto, desconto_total, valor_liquido
) VALUES (999, 9999, 1, SYSDATE, 'ABERTA', 'SITE', 100.00, 0.00, 100.00 );

-- Questão 2
UPDATE tb_venda SET status = 'PENDENTE' WHERE id_venda = 1;

-- Questão 3
INSERT INTO tb_produto ( id_produto, id_categoria, sku, nome, preco_unit, ativo, dt_cadastro
) VALUES ( 99, 1, 'PROD-TESTE-NEGATIVO', 'Produto Teste Valor Invalido', -15.00, 'S',SYSDATE );

-- Questão 4
ALTER TABLE TB_VENDA_ITEM  ADD CONSTRAINT chk_max_desconto_valor CHECK (desconto_item <= (preco_unit * 0.50)) ENABLE NOVALIDATE; (somente para novos inserts)

-- Questão 5
ALTER TABLE tb_cliente
ADD CONSTRAINT uk_cliente_telefone UNIQUE (telefone);

-- Questão 6
DELETE FROM tb_venda WHERE id_venda = 1;

-- Questão 7
UPDATE tb_vendedor SET ativo = 'N' WHERE id_vendedor = 1;