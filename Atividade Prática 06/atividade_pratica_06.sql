-- Questão 1

CREATE OR REPLACE VIEW V_VENDAS_RESUMO AS
SELECT v.id_venda, v.dt_venda, v.status, v.canal, c.nome AS nome_cliente, vnd.nome AS nome_vendedor, v.valor_liquido FROM tb_venda v JOIN tb_cliente c ON v.id_cliente = c.id_cliente JOIN tb_vendedor vnd ON v.id_vendedor = vnd.id_vendedor;

-- Questão 2

CREATE OR REPLACE VIEW V_CLIENTE_PUBLICO AS SELECT  id_cliente, nome, email, dt_cadastro FROM tb_cliente WHERE ativo = 'S';


-- Questão 3 

CREATE OR REPLACE VIEW V_VENDAS_POR_CATEGORIA AS
SELECT 
    TO_CHAR(v.dt_venda, 'YYYY-MM') AS ano_mes,
    c.nome AS nome_categoria,
    SUM(iv.valor_total) AS faturamento_total
FROM tb_venda v
JOIN tb_venda_item iv ON v.id_venda = iv.id_venda
JOIN tb_produto p ON iv.id_produto = p.id_produto
JOIN tb_categoria c ON p.id_categoria = c.id_categoria
WHERE v.status = 'FECHADA'
GROUP BY TO_CHAR(v.dt_venda, 'YYYY-MM'), c.nome;


-- Questão 4

SELECT ano_mes, nome_categoria, faturamento_total FROM V_VENDAS_POR_CATEGORIA WHERE ano_mes = TO_CHAR(SYSDATE, 'YYYY-MM') AND faturamento_total > 5000.00;


