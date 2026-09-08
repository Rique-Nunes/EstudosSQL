-- Nível Avançado: Organização e Análise de Dados (CTE - WITH e Funções Analíticas - OVER)
SELECT 
    c.nome AS nome_cliente,
    v.dt_venda,
    v.valor_liquido,
    ROW_NUMBER() OVER (PARTITION BY v.id_cliente ORDER BY v.dt_venda, v.id_venda) AS numero_compra
FROM tb_venda v
JOIN tb_cliente c ON v.id_cliente = c.id_cliente;

SELECT 
    v.nome AS nome_vendedor,
    SUM(ven.valor_liquido) AS faturamento_vendedor,
    ROUND((SUM(ven.valor_liquido) / SUM(SUM(ven.valor_liquido)) OVER()) * 100, 2) AS percentual_faturamento
FROM tb_vendedor v
JOIN tb_venda ven ON v.id_vendedor = ven.id_vendedor
WHERE ven.status = 'FECHADA'
GROUP BY v.id_vendedor, v.nome;

WITH faturamento_mensal_vendedor AS (
    SELECT 
        TRUNC(ven.dt_venda, 'MM') AS mes_referencia,
        v.nome AS nome_vendedor,
        SUM(ven.valor_liquido) AS receita_total
    FROM tb_venda ven
    JOIN tb_vendedor v ON ven.id_vendedor = v.id_vendedor
    WHERE ven.status = 'FECHADA'
    GROUP BY TRUNC(ven.dt_venda, 'MM'), v.id_vendedor, v.nome
)
SELECT 
    mes_referencia,
    nome_vendedor,
    receita_total,
    DENSE_RANK() OVER (PARTITION BY mes_referencia ORDER BY receita_total DESC) AS posicao_ranking
FROM faturamento_mensal_vendedor
ORDER BY mes_referencia, posicao_ranking;

SELECT 
    id_venda,
    valor_liquido,
    ROUND(valor_liquido - AVG(valor_liquido) OVER(), 2) AS diferenca_para_media
FROM tb_venda;

WITH ranking_produtos AS (
    SELECT 
        p.id_produto,
        p.nome AS nome_produto,
        SUM(i.quantidade) AS total_quantidade_vendida,
        DENSE_RANK() OVER (ORDER BY SUM(i.quantidade) DESC) AS ranking
    FROM tb_venda_item i
    JOIN tb_produto p ON i.id_produto = p.id_produto
    GROUP BY p.id_produto, p.nome
)
SELECT 
    id_produto,
    nome_produto,
    total_quantidade_vendida,
    ranking
FROM ranking_produtos
WHERE ranking <= 3
ORDER BY ranking;
