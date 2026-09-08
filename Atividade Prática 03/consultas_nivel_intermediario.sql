-- Nível Intermediário: Agrupamentos e Lógica de Negócio (GROUP BY, Subqueries, EXISTS e CASE WHEN)

SELECT canal, SUM(valor_liquido) AS faturamento_total
FROM tb_venda
WHERE status = 'FECHADA'
GROUP BY canal
ORDER BY faturamento_total DESC;

SELECT v.nome AS nome_vendedor, ROUND(AVG(ven.valor_liquido), 2) AS ticket_medio
FROM tb_vendedor v
JOIN tb_venda ven ON v.id_vendedor = ven.id_vendedor
WHERE ven.status = 'FECHADA'
GROUP BY v.id_vendedor, v.nome;

SELECT c.nome, c.email
FROM tb_cliente c
WHERE NOT EXISTS (
    SELECT 1
    FROM tb_venda v
    WHERE v.id_cliente = c.id_cliente
);

SELECT v.id_venda, c.nome AS nome_cliente, v.valor_liquido
FROM tb_venda v
JOIN tb_cliente c ON v.id_cliente = c.id_cliente
WHERE v.status = 'FECHADA'
  AND v.valor_liquido > (
      SELECT AVG(valor_liquido)
      FROM tb_venda
      WHERE status = 'FECHADA'
  );

SELECT nome, preco_unit,
    CASE 
        WHEN preco_unit < 50 THEN 'BARATO'
        WHEN preco_unit <= 200 THEN 'MÉDIO'
        ELSE 'CARO'
    END AS faixa_preco
FROM tb_produto;
