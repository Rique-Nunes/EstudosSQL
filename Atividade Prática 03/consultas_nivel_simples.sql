-- Nível Simples: Fundamentos (SELECT, WHERE, ORDER BY e JOIN Básico)

SELECT nome, email, telefone
FROM tb_cliente
WHERE ativo = 'S'
ORDER BY nome ASC;

SELECT id_venda, dt_venda, valor_liquido
FROM tb_venda
WHERE canal = 'APP' AND status = 'FECHADA';

SELECT p.nome AS nome_produto, p.sku, c.nome AS nome_categoria
FROM tb_produto p
JOIN tb_categoria c ON p.id_categoria = c.id_categoria;

SELECT COUNT(*) AS total_vendedores
FROM tb_vendedor;

SELECT nome, preco_unit
FROM tb_produto
WHERE ativo = 'S'
ORDER BY preco_unit DESC;
