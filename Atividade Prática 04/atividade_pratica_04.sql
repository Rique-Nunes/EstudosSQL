--Jornada de Compras do Cliente
SELECT 
    cliente.nome AS nome_cliente,
    venda.dt_venda,
    venda.valor_liquido,
    ROW_NUMBER() OVER (
        PARTITION BY venda.id_cliente 
        ORDER BY venda.dt_venda ASC, venda.id_venda ASC
    ) AS numero_compra
FROM tb_venda venda
JOIN tb_cliente cliente 
    ON venda.id_cliente = cliente.id_cliente
WHERE venda.status = 'FECHADA'
ORDER BY cliente.nome, numero_compra;

--Ranking Mensal de Vendedores
WITH faturamento_mensal AS (
    SELECT 
        TRUNC(venda.dt_venda, 'MM') AS mes_referencia,
        vendedor.nome AS nome_vendedor,
        SUM(venda.valor_liquido) AS total_vendido
    FROM tb_venda venda
    JOIN tb_vendedor vendedor 
        ON venda.id_vendedor = vendedor.id_vendedor
    WHERE venda.status = 'FECHADA'
    GROUP BY TRUNC(venda.dt_venda, 'MM'), vendedor.nome
)
SELECT 
    mes_referencia,
    nome_vendedor,
    total_vendido,
    DENSE_RANK() OVER (
        PARTITION BY mes_referencia 
        ORDER BY total_vendido DESC
    ) AS posicao_ranking
FROM faturamento_mensal
ORDER BY mes_referencia ASC, posicao_ranking ASC;

--Os 2 Produtos Mais Vendidos por Categoria
WITH ranking_produtos_categoria AS (
    SELECT 
        categoria.nome AS nome_categoria,
        produto.nome AS nome_produto,
        SUM(item.quantidade) AS total_quantidade_vendida,
        DENSE_RANK() OVER (
            PARTITION BY categoria.nome 
            ORDER BY SUM(item.quantidade) DESC
        ) AS posicao_ranking
    FROM tb_venda_item item
    JOIN tb_produto produto 
        ON item.id_produto = produto.id_produto
    JOIN tb_categoria categoria 
        ON produto.id_categoria = categoria.id_categoria
    GROUP BY categoria.nome, produto.nome
)
SELECT 
    nome_categoria,
    nome_produto,
    total_quantidade_vendida,
    posicao_ranking
FROM ranking_produtos_categoria
WHERE posicao_ranking <= 2
ORDER BY nome_categoria ASC, posicao_ranking ASC;

-- Participação no Faturamento (Market Share Interno)
WITH faturamento_por_vendedor AS (
    SELECT 
        vendedor.nome AS nome_vendedor,
        SUM(venda.valor_liquido) AS faturamento_vendedor
    FROM tb_venda venda
    JOIN tb_vendedor vendedor 
        ON venda.id_vendedor = vendedor.id_vendedor
    WHERE venda.status = 'FECHADA'
    GROUP BY vendedor.nome
)
SELECT 
    nome_vendedor,
    faturamento_vendedor,
    ROUND(
        (faturamento_vendedor / SUM(faturamento_vendedor) OVER()) * 100, 
        2
    ) AS percentual_faturamento
FROM faturamento_por_vendedor
ORDER BY faturamento_vendedor DESC;

--Termômetro de Vendas (Acima ou Abaixo da Média?)
SELECT 
    id_venda,
    valor_liquido,
    ROUND(AVG(valor_liquido) OVER(), 2) AS media_geral,
    ROUND(valor_liquido - AVG(valor_liquido) OVER(), 2) AS diferenca_media
FROM tb_venda
ORDER BY id_venda ASC;
