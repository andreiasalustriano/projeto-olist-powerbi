-- =============================================================
-- PROJETO OLIST - REGISTRO CONSOLIDADO DE ANALISES SQL
-- Stack: MySQL 8+ / DBeaver
-- Periodo padrao da apresentacao: 2018-01-01 a 2018-08-31
-- Observacao metodologica:
--   payment_value = valor pago (pedido/pagamento)
--   price         = valor do produto/item
--   freight_value = valor do frete por item
-- Evitar somar payment_value apos join direto com itens, pois pedidos
-- com multiplos itens/pagamentos podem gerar duplicacao.
-- =============================================================

-- -------------------------------------------------------------
-- 01. KPIs gerais de vendas
-- -------------------------------------------------------------
SELECT
    COUNT(DISTINCT o.order_id) AS total_pedidos,
    ROUND(SUM(p.payment_value), 2) AS valor_total_pago,
    ROUND(SUM(p.payment_value) / COUNT(DISTINCT o.order_id), 2) AS ticket_medio
FROM olist_orders_dataset o
JOIN olist_order_payments_dataset p
    ON p.order_id = o.order_id
WHERE o.order_purchase_timestamp >= '2018-01-01'
  AND o.order_purchase_timestamp <  '2018-09-01';

-- -------------------------------------------------------------
-- 02. Evolucao mensal: pedidos, valor pago e ticket medio
-- -------------------------------------------------------------
SELECT
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS mes,
    COUNT(DISTINCT o.order_id) AS total_pedidos,
    ROUND(SUM(p.payment_value), 2) AS valor_total_pago,
    ROUND(SUM(p.payment_value) / COUNT(DISTINCT o.order_id), 2) AS ticket_medio
FROM olist_orders_dataset o
JOIN olist_order_payments_dataset p
    ON p.order_id = o.order_id
WHERE o.order_purchase_timestamp >= '2018-01-01'
  AND o.order_purchase_timestamp <  '2018-09-01'
GROUP BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
ORDER BY mes;

-- -------------------------------------------------------------
-- 03. Variacao mensal do valor pago
-- -------------------------------------------------------------
WITH mensal AS (
    SELECT
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS mes,
        SUM(p.payment_value) AS valor_pago
    FROM olist_orders_dataset o
    JOIN olist_order_payments_dataset p
        ON p.order_id = o.order_id
    WHERE o.order_purchase_timestamp >= '2017-12-01'
      AND o.order_purchase_timestamp <  '2018-09-01'
    GROUP BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
),
comparacao AS (
    SELECT
        mes,
        valor_pago,
        LAG(valor_pago) OVER (ORDER BY mes) AS valor_mes_anterior
    FROM mensal
)
SELECT
    mes,
    ROUND(valor_pago, 2) AS valor_pago,
    ROUND(valor_mes_anterior, 2) AS valor_mes_anterior,
    ROUND(valor_pago - valor_mes_anterior, 2) AS variacao_valor,
    ROUND(100 * (valor_pago - valor_mes_anterior) / NULLIF(valor_mes_anterior, 0), 2)
        AS variacao_percentual
FROM comparacao
WHERE mes >= '2018-01'
ORDER BY mes;

-- -------------------------------------------------------------
-- 04. Decomposicao mensal: valor pago, pedidos e ticket
-- -------------------------------------------------------------
WITH mensal AS (
    SELECT
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS mes,
        COUNT(DISTINCT o.order_id) AS pedidos,
        SUM(p.payment_value) AS valor_pago,
        SUM(p.payment_value) / COUNT(DISTINCT o.order_id) AS ticket_medio
    FROM olist_orders_dataset o
    JOIN olist_order_payments_dataset p
        ON p.order_id = o.order_id
    WHERE o.order_purchase_timestamp >= '2017-12-01'
      AND o.order_purchase_timestamp <  '2018-09-01'
    GROUP BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
),
comp AS (
    SELECT
        *,
        LAG(valor_pago) OVER (ORDER BY mes) AS valor_ant,
        LAG(pedidos) OVER (ORDER BY mes) AS pedidos_ant,
        LAG(ticket_medio) OVER (ORDER BY mes) AS ticket_ant
    FROM mensal
)
SELECT
    mes,
    ROUND(valor_pago, 2) AS valor_pago,
    pedidos,
    ROUND(ticket_medio, 2) AS ticket_medio,
    ROUND(100 * (valor_pago - valor_ant) / NULLIF(valor_ant, 0), 2) AS var_valor_pct,
    ROUND(100 * (pedidos - pedidos_ant) / NULLIF(pedidos_ant, 0), 2) AS var_pedidos_pct,
    ROUND(100 * (ticket_medio - ticket_ant) / NULLIF(ticket_ant, 0), 2) AS var_ticket_pct
FROM comp
WHERE mes >= '2018-01'
ORDER BY mes;

-- -------------------------------------------------------------
-- 05. Valor pago por estado
-- -------------------------------------------------------------
SELECT
    c.customer_state AS estado,
    COUNT(DISTINCT o.order_id) AS pedidos,
    ROUND(SUM(p.payment_value), 2) AS valor_total_pago,
    ROUND(SUM(p.payment_value) / COUNT(DISTINCT o.order_id), 2) AS ticket_medio
FROM olist_orders_dataset o
JOIN olist_order_customer_dataset c
    ON c.customer_id = o.customer_id
JOIN olist_order_payments_dataset p
    ON p.order_id = o.order_id
WHERE o.order_purchase_timestamp >= '2018-01-01'
  AND o.order_purchase_timestamp <  '2018-09-01'
GROUP BY c.customer_state
ORDER BY valor_total_pago DESC;

-- -------------------------------------------------------------
-- 06. Valor pago por forma de pagamento
-- -------------------------------------------------------------
SELECT
    p.payment_type AS forma_pagamento,
    COUNT(DISTINCT p.order_id) AS pedidos,
    ROUND(SUM(p.payment_value), 2) AS valor_total_pago
FROM olist_order_payments_dataset p
JOIN olist_orders_dataset o
    ON o.order_id = p.order_id
WHERE o.order_purchase_timestamp >= '2018-01-01'
  AND o.order_purchase_timestamp <  '2018-09-01'
GROUP BY p.payment_type
ORDER BY valor_total_pago DESC;

-- -------------------------------------------------------------
-- 07. Top categorias por valor dos produtos
--     (usa price; nao payment_value)
-- -------------------------------------------------------------
SELECT
    pr.product_category_name AS categoria,
    COUNT(*) AS itens_vendidos,
    ROUND(SUM(i.price), 2) AS valor_produtos,
    ROUND(AVG(i.price), 2) AS preco_medio,
    ROUND(AVG(i.freight_value), 2) AS frete_medio
FROM olist_order_items_dataset i
JOIN olist_products_dataset pr
    ON pr.product_id = i.product_id
JOIN olist_orders_dataset o
    ON o.order_id = i.order_id
WHERE o.order_purchase_timestamp >= '2018-01-01'
  AND o.order_purchase_timestamp <  '2018-09-01'
  AND pr.product_category_name IS NOT NULL
GROUP BY pr.product_category_name
ORDER BY valor_produtos DESC
LIMIT 10;

-- -------------------------------------------------------------
-- 08. Contribuicao por estado: mes selecionado x mes anterior
--     Altere @mes_atual para analisar outro mes.
-- -------------------------------------------------------------
SET @mes_atual = '2018-06-01';
WITH base AS (
    SELECT
        c.customer_state AS estado,
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m-01') AS mes,
        SUM(p.payment_value) AS valor_pago
    FROM olist_orders_dataset o
    JOIN olist_order_customer_dataset c
        ON c.customer_id = o.customer_id
    JOIN olist_order_payments_dataset p
        ON p.order_id = o.order_id
    WHERE o.order_purchase_timestamp >= DATE_SUB(@mes_atual, INTERVAL 1 MONTH)
      AND o.order_purchase_timestamp <  DATE_ADD(@mes_atual, INTERVAL 1 MONTH)
    GROUP BY c.customer_state, DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m-01')
)
SELECT
    estado,
    ROUND(SUM(CASE WHEN mes = DATE_FORMAT(@mes_atual, '%Y-%m-01') THEN valor_pago ELSE 0 END), 2) AS valor_mes_atual,
    ROUND(SUM(CASE WHEN mes = DATE_FORMAT(DATE_SUB(@mes_atual, INTERVAL 1 MONTH), '%Y-%m-01') THEN valor_pago ELSE 0 END), 2) AS valor_mes_anterior,
    ROUND(
        SUM(CASE WHEN mes = DATE_FORMAT(@mes_atual, '%Y-%m-01') THEN valor_pago ELSE 0 END)
        - SUM(CASE WHEN mes = DATE_FORMAT(DATE_SUB(@mes_atual, INTERVAL 1 MONTH), '%Y-%m-01') THEN valor_pago ELSE 0 END),
        2
    ) AS variacao_valor,
    ROUND(
        100 * (
            SUM(CASE WHEN mes = DATE_FORMAT(@mes_atual, '%Y-%m-01') THEN valor_pago ELSE 0 END)
            - SUM(CASE WHEN mes = DATE_FORMAT(DATE_SUB(@mes_atual, INTERVAL 1 MONTH), '%Y-%m-01') THEN valor_pago ELSE 0 END)
        ) / NULLIF(
            SUM(CASE WHEN mes = DATE_FORMAT(DATE_SUB(@mes_atual, INTERVAL 1 MONTH), '%Y-%m-01') THEN valor_pago ELSE 0 END), 0
        ),
        2
    ) AS variacao_pct
FROM base
GROUP BY estado
ORDER BY variacao_valor ASC;

-- -------------------------------------------------------------
-- 09. Contribuicao por forma de pagamento: mes x mes anterior
-- -------------------------------------------------------------
SET @mes_atual = '2018-06-01';
WITH base AS (
    SELECT
        p.payment_type,
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m-01') AS mes,
        SUM(p.payment_value) AS valor_pago
    FROM olist_order_payments_dataset p
    JOIN olist_orders_dataset o
        ON o.order_id = p.order_id
    WHERE o.order_purchase_timestamp >= DATE_SUB(@mes_atual, INTERVAL 1 MONTH)
      AND o.order_purchase_timestamp <  DATE_ADD(@mes_atual, INTERVAL 1 MONTH)
    GROUP BY p.payment_type, DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m-01')
)
SELECT
    payment_type,
    ROUND(SUM(CASE WHEN mes = DATE_FORMAT(@mes_atual, '%Y-%m-01') THEN valor_pago ELSE 0 END), 2) AS valor_mes_atual,
    ROUND(SUM(CASE WHEN mes = DATE_FORMAT(DATE_SUB(@mes_atual, INTERVAL 1 MONTH), '%Y-%m-01') THEN valor_pago ELSE 0 END), 2) AS valor_mes_anterior,
    ROUND(
        SUM(CASE WHEN mes = DATE_FORMAT(@mes_atual, '%Y-%m-01') THEN valor_pago ELSE 0 END)
        - SUM(CASE WHEN mes = DATE_FORMAT(DATE_SUB(@mes_atual, INTERVAL 1 MONTH), '%Y-%m-01') THEN valor_pago ELSE 0 END), 2
    ) AS variacao_valor,
    ROUND(
        100 * (
            SUM(CASE WHEN mes = DATE_FORMAT(@mes_atual, '%Y-%m-01') THEN valor_pago ELSE 0 END)
            - SUM(CASE WHEN mes = DATE_FORMAT(DATE_SUB(@mes_atual, INTERVAL 1 MONTH), '%Y-%m-01') THEN valor_pago ELSE 0 END)
        ) / NULLIF(
            SUM(CASE WHEN mes = DATE_FORMAT(DATE_SUB(@mes_atual, INTERVAL 1 MONTH), '%Y-%m-01') THEN valor_pago ELSE 0 END), 0
        ), 2
    ) AS variacao_pct
FROM base
GROUP BY payment_type
ORDER BY variacao_valor ASC;

-- -------------------------------------------------------------
-- 10. Contribuicao por categoria: mes x mes anterior
--     (usa price, ou seja, valor dos produtos)
-- -------------------------------------------------------------
SET @mes_atual = '2018-06-01';
WITH base AS (
    SELECT
        pr.product_category_name AS categoria,
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m-01') AS mes,
        SUM(i.price) AS valor_produtos
    FROM olist_order_items_dataset i
    JOIN olist_orders_dataset o
        ON o.order_id = i.order_id
    JOIN olist_products_dataset pr
        ON pr.product_id = i.product_id
    WHERE o.order_purchase_timestamp >= DATE_SUB(@mes_atual, INTERVAL 1 MONTH)
      AND o.order_purchase_timestamp <  DATE_ADD(@mes_atual, INTERVAL 1 MONTH)
      AND pr.product_category_name IS NOT NULL
    GROUP BY pr.product_category_name, DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m-01')
)
SELECT
    categoria,
    ROUND(SUM(CASE WHEN mes = DATE_FORMAT(@mes_atual, '%Y-%m-01') THEN valor_produtos ELSE 0 END), 2) AS valor_mes_atual,
    ROUND(SUM(CASE WHEN mes = DATE_FORMAT(DATE_SUB(@mes_atual, INTERVAL 1 MONTH), '%Y-%m-01') THEN valor_produtos ELSE 0 END), 2) AS valor_mes_anterior,
    ROUND(
        SUM(CASE WHEN mes = DATE_FORMAT(@mes_atual, '%Y-%m-01') THEN valor_produtos ELSE 0 END)
        - SUM(CASE WHEN mes = DATE_FORMAT(DATE_SUB(@mes_atual, INTERVAL 1 MONTH), '%Y-%m-01') THEN valor_produtos ELSE 0 END), 2
    ) AS variacao_valor,
    ROUND(
        100 * (
            SUM(CASE WHEN mes = DATE_FORMAT(@mes_atual, '%Y-%m-01') THEN valor_produtos ELSE 0 END)
            - SUM(CASE WHEN mes = DATE_FORMAT(DATE_SUB(@mes_atual, INTERVAL 1 MONTH), '%Y-%m-01') THEN valor_produtos ELSE 0 END)
        ) / NULLIF(
            SUM(CASE WHEN mes = DATE_FORMAT(DATE_SUB(@mes_atual, INTERVAL 1 MONTH), '%Y-%m-01') THEN valor_produtos ELSE 0 END), 0
        ), 2
    ) AS variacao_pct
FROM base
GROUP BY categoria
HAVING variacao_valor < 0
ORDER BY variacao_valor ASC
LIMIT 10;

-- -------------------------------------------------------------
-- 11. Base de clientes: pedidos e gasto por customer_unique_id
-- -------------------------------------------------------------
SELECT
    c.customer_unique_id,
    COUNT(DISTINCT o.order_id) AS qtd_pedidos,
    ROUND(SUM(p.payment_value), 2) AS valor_total_gasto
FROM olist_order_customer_dataset c
JOIN olist_orders_dataset o
    ON o.customer_id = c.customer_id
JOIN olist_order_payments_dataset p
    ON p.order_id = o.order_id
WHERE o.order_purchase_timestamp >= '2018-01-01'
  AND o.order_purchase_timestamp <  '2018-09-01'
GROUP BY c.customer_unique_id;

-- -------------------------------------------------------------
-- 12. Clientes analisados, recorrentes e taxa de recorrencia
-- -------------------------------------------------------------
WITH clientes AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS qtd_pedidos,
        SUM(p.payment_value) AS valor_total_gasto
    FROM olist_order_customer_dataset c
    JOIN olist_orders_dataset o
        ON o.customer_id = c.customer_id
    JOIN olist_order_payments_dataset p
        ON p.order_id = o.order_id
    WHERE o.order_purchase_timestamp >= '2018-01-01'
      AND o.order_purchase_timestamp <  '2018-09-01'
    GROUP BY c.customer_unique_id
)
SELECT
    COUNT(*) AS clientes_analisados,
    SUM(qtd_pedidos > 1) AS clientes_recorrentes,
    ROUND(100 * SUM(qtd_pedidos > 1) / COUNT(*), 2) AS taxa_recorrencia_pct
FROM clientes;

-- -------------------------------------------------------------
-- 13. Mediana de gasto e perfis alto/baixo valor por recorrencia
-- -------------------------------------------------------------
WITH clientes AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS qtd_pedidos,
        SUM(p.payment_value) AS valor_total_gasto
    FROM olist_order_customer_dataset c
    JOIN olist_orders_dataset o ON o.customer_id = c.customer_id
    JOIN olist_order_payments_dataset p ON p.order_id = o.order_id
    WHERE o.order_purchase_timestamp >= '2018-01-01'
      AND o.order_purchase_timestamp <  '2018-09-01'
    GROUP BY c.customer_unique_id
),
ordenado AS (
    SELECT
        *,
        ROW_NUMBER() OVER (ORDER BY valor_total_gasto) AS rn,
        COUNT(*) OVER () AS n
    FROM clientes
),
mediana AS (
    SELECT AVG(valor_total_gasto) AS mediana_gasto
    FROM ordenado
    WHERE rn IN (FLOOR((n + 1) / 2), FLOOR((n + 2) / 2))
)
SELECT
    CASE WHEN c.qtd_pedidos > 1 THEN 'Recorrente' ELSE 'Compra unica' END AS tipo_cliente,
    CASE WHEN c.valor_total_gasto > m.mediana_gasto THEN 'Alto valor' ELSE 'Baixo valor' END AS faixa_valor,
    COUNT(*) AS clientes,
    ROUND(AVG(c.valor_total_gasto), 2) AS gasto_medio,
    ROUND(SUM(c.valor_total_gasto), 2) AS valor_pago
FROM clientes c
CROSS JOIN mediana m
GROUP BY tipo_cliente, faixa_valor
ORDER BY tipo_cliente, faixa_valor;

-- -------------------------------------------------------------
-- 14. Recorrentes por estado
-- -------------------------------------------------------------
WITH clientes AS (
    SELECT
        c.customer_unique_id,
        MAX(c.customer_state) AS estado,
        COUNT(DISTINCT o.order_id) AS qtd_pedidos
    FROM olist_order_customer_dataset c
    JOIN olist_orders_dataset o ON o.customer_id = c.customer_id
    WHERE o.order_purchase_timestamp >= '2018-01-01'
      AND o.order_purchase_timestamp <  '2018-09-01'
    GROUP BY c.customer_unique_id
)
SELECT
    estado,
    COUNT(*) AS clientes_recorrentes
FROM clientes
WHERE qtd_pedidos > 1
GROUP BY estado
ORDER BY clientes_recorrentes DESC
LIMIT 10;

-- -------------------------------------------------------------
-- 15. Forma de pagamento por tipo de cliente
-- -------------------------------------------------------------
WITH perfil AS (
    SELECT
        c.customer_unique_id,
        CASE WHEN COUNT(DISTINCT o.order_id) > 1 THEN 'Recorrente' ELSE 'Compra unica' END AS tipo_cliente
    FROM olist_order_customer_dataset c
    JOIN olist_orders_dataset o ON o.customer_id = c.customer_id
    WHERE o.order_purchase_timestamp >= '2018-01-01'
      AND o.order_purchase_timestamp <  '2018-09-01'
    GROUP BY c.customer_unique_id
)
SELECT
    pf.tipo_cliente,
    p.payment_type,
    COUNT(DISTINCT p.order_id) AS pedidos,
    ROUND(SUM(p.payment_value), 2) AS valor_pago
FROM perfil pf
JOIN olist_order_customer_dataset c
    ON c.customer_unique_id = pf.customer_unique_id
JOIN olist_orders_dataset o
    ON o.customer_id = c.customer_id
JOIN olist_order_payments_dataset p
    ON p.order_id = o.order_id
WHERE o.order_purchase_timestamp >= '2018-01-01'
  AND o.order_purchase_timestamp <  '2018-09-01'
GROUP BY pf.tipo_cliente, p.payment_type
ORDER BY pf.tipo_cliente, pedidos DESC;

-- -------------------------------------------------------------
-- 16. Status de entrega
-- -------------------------------------------------------------
SELECT
    CASE
        WHEN DATE(order_delivered_customer_date) > DATE(order_estimated_delivery_date) THEN 'Atrasado'
        WHEN DATE(order_delivered_customer_date) = DATE(order_estimated_delivery_date) THEN 'No prazo'
        WHEN DATE(order_delivered_customer_date) < DATE(order_estimated_delivery_date) THEN 'Adiantado'
    END AS status_entrega,
    COUNT(DISTINCT order_id) AS pedidos
FROM olist_orders_dataset
WHERE order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL
  AND order_purchase_timestamp >= '2018-01-01'
  AND order_purchase_timestamp <  '2018-09-01'
GROUP BY status_entrega;

-- -------------------------------------------------------------
-- 17. KPIs de entrega: entregues, atrasados e taxa de atraso
-- -------------------------------------------------------------
SELECT
    COUNT(DISTINCT CASE WHEN order_delivered_customer_date IS NOT NULL THEN order_id END) AS pedidos_entregues,
    COUNT(DISTINCT CASE
        WHEN DATE(order_delivered_customer_date) > DATE(order_estimated_delivery_date) THEN order_id
    END) AS pedidos_atrasados,
    ROUND(
        100 * COUNT(DISTINCT CASE
            WHEN DATE(order_delivered_customer_date) > DATE(order_estimated_delivery_date) THEN order_id
        END)
        / NULLIF(COUNT(DISTINCT CASE WHEN order_delivered_customer_date IS NOT NULL THEN order_id END), 0),
        2
    ) AS taxa_atraso_pct
FROM olist_orders_dataset
WHERE order_purchase_timestamp >= '2018-01-01'
  AND order_purchase_timestamp <  '2018-09-01';

-- -------------------------------------------------------------
-- 18. Tempo real x prazo prometido por estado
-- -------------------------------------------------------------
SELECT
    c.customer_state AS estado,
    ROUND(AVG(TIMESTAMPDIFF(DAY, o.order_approved_at, o.order_delivered_customer_date)), 2)
        AS tempo_medio_real_dias,
    ROUND(AVG(TIMESTAMPDIFF(DAY, o.order_approved_at, o.order_estimated_delivery_date)), 2)
        AS prazo_medio_prometido_dias
FROM olist_orders_dataset o
JOIN olist_order_customer_dataset c
    ON c.customer_id = o.customer_id
WHERE o.order_purchase_timestamp >= '2018-01-01'
  AND o.order_purchase_timestamp <  '2018-09-01'
  AND o.order_approved_at IS NOT NULL
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY tempo_medio_real_dias DESC
LIMIT 10;

-- -------------------------------------------------------------
-- 19. Taxa de atraso por estado
-- -------------------------------------------------------------
SELECT
    c.customer_state AS estado,
    COUNT(DISTINCT o.order_id) AS pedidos_entregues,
    COUNT(DISTINCT CASE
        WHEN DATE(o.order_delivered_customer_date) > DATE(o.order_estimated_delivery_date) THEN o.order_id
    END) AS pedidos_atrasados,
    ROUND(
        100 * COUNT(DISTINCT CASE
            WHEN DATE(o.order_delivered_customer_date) > DATE(o.order_estimated_delivery_date) THEN o.order_id
        END) / NULLIF(COUNT(DISTINCT o.order_id), 0),
        2
    ) AS taxa_atraso_pct
FROM olist_orders_dataset o
JOIN olist_order_customer_dataset c
    ON c.customer_id = o.customer_id
WHERE o.order_purchase_timestamp >= '2018-01-01'
  AND o.order_purchase_timestamp <  '2018-09-01'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY taxa_atraso_pct DESC;

-- -------------------------------------------------------------
-- 20. Nota media por status de entrega
-- -------------------------------------------------------------
WITH review_por_pedido AS (
    SELECT order_id, AVG(review_score) AS review_score
    FROM olist_order_reviews_dataset
    GROUP BY order_id
)
SELECT
    CASE
        WHEN DATE(o.order_delivered_customer_date) > DATE(o.order_estimated_delivery_date) THEN 'Atrasado'
        WHEN DATE(o.order_delivered_customer_date) = DATE(o.order_estimated_delivery_date) THEN 'No prazo'
        WHEN DATE(o.order_delivered_customer_date) < DATE(o.order_estimated_delivery_date) THEN 'Adiantado'
    END AS status_entrega,
    COUNT(DISTINCT o.order_id) AS pedidos,
    ROUND(AVG(r.review_score), 2) AS nota_media
FROM olist_orders_dataset o
JOIN review_por_pedido r
    ON r.order_id = o.order_id
WHERE o.order_purchase_timestamp >= '2018-01-01'
  AND o.order_purchase_timestamp <  '2018-09-01'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY status_entrega;

-- -------------------------------------------------------------
-- 21. Recorrencia conforme o status da primeira entrega
-- -------------------------------------------------------------
WITH base AS (
    SELECT
        c.customer_unique_id,
        o.order_id,
        o.order_purchase_timestamp,
        CASE
            WHEN DATE(o.order_delivered_customer_date) > DATE(o.order_estimated_delivery_date) THEN 'Com atraso'
            ELSE 'Sem atraso'
        END AS status_primeira_candidato,
        ROW_NUMBER() OVER (
            PARTITION BY c.customer_unique_id
            ORDER BY o.order_purchase_timestamp, o.order_id
        ) AS rn,
        COUNT(*) OVER (PARTITION BY c.customer_unique_id) AS qtd_pedidos
    FROM olist_order_customer_dataset c
    JOIN olist_orders_dataset o
        ON o.customer_id = c.customer_id
    WHERE o.order_purchase_timestamp >= '2018-01-01'
      AND o.order_purchase_timestamp <  '2018-09-01'
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_estimated_delivery_date IS NOT NULL
),
clientes AS (
    SELECT
        customer_unique_id,
        MAX(CASE WHEN rn = 1 THEN status_primeira_candidato END) AS status_primeira_entrega,
        MAX(qtd_pedidos) AS qtd_pedidos
    FROM base
    GROUP BY customer_unique_id
)
SELECT
    status_primeira_entrega,
    COUNT(*) AS clientes,
    SUM(qtd_pedidos > 1) AS clientes_recorrentes,
    ROUND(100 * SUM(qtd_pedidos > 1) / COUNT(*), 2) AS taxa_recorrencia_pct
FROM clientes
GROUP BY status_primeira_entrega;

-- -------------------------------------------------------------
-- 22. Categorias: valor, volume, preco e frete
-- -------------------------------------------------------------
SELECT
    p.product_category_name AS categoria,
    COUNT(*) AS itens_vendidos,
    ROUND(SUM(i.price), 2) AS valor_produtos,
    ROUND(AVG(i.price), 2) AS preco_medio,
    ROUND(AVG(i.freight_value), 2) AS frete_medio
FROM olist_order_items_dataset i
JOIN olist_products_dataset p
    ON p.product_id = i.product_id
JOIN olist_orders_dataset o
    ON o.order_id = i.order_id
WHERE o.order_purchase_timestamp >= '2018-01-01'
  AND o.order_purchase_timestamp <  '2018-09-01'
  AND p.product_category_name IS NOT NULL
GROUP BY p.product_category_name
ORDER BY valor_produtos DESC;

-- -------------------------------------------------------------
-- 23. Analise complementar de fotos, peso e volume fisico
--     (disponivel nos dados; nao entrou como visual final)
-- -------------------------------------------------------------
SELECT
    p.product_category_name AS categoria,
    COUNT(*) AS itens_vendidos,
    ROUND(SUM(i.price), 2) AS valor_produtos,
    ROUND(AVG(i.price), 2) AS preco_medio,
    ROUND(AVG(i.freight_value), 2) AS frete_medio,
    ROUND(AVG(p.product_photos_qty), 2) AS media_fotos,
    ROUND(AVG(p.product_weight_g), 2) AS peso_medio_g,
    ROUND(AVG(p.product_length_cm * p.product_height_cm * p.product_width_cm), 2)
        AS volume_medio_cm3
FROM olist_order_items_dataset i
JOIN olist_products_dataset p
    ON p.product_id = i.product_id
JOIN olist_orders_dataset o
    ON o.order_id = i.order_id
WHERE o.order_purchase_timestamp >= '2018-01-01'
  AND o.order_purchase_timestamp <  '2018-09-01'
  AND p.product_category_name IS NOT NULL
GROUP BY p.product_category_name
ORDER BY valor_produtos DESC;
