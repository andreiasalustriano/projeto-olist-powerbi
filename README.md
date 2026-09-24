# Projeto Olist — Análise de Dados com SQL + Power BI

## Resumo

Projeto de análise do e-commerce Olist com foco em quatro perguntas de negócio: evolução e quedas de vendas, perfil dos melhores clientes, impacto das entregas na experiência e desempenho das categorias. A exploração/validação foi realizada em SQL (DBeaver/MySQL) e o dashboard final foi construído em Power BI com medidas DAX dinâmicas.

**Período padrão da apresentação:** 01/01/2018 a 31/08/2018.  
**Páginas do dashboard:** Vendas, Análise das Quedas, Clientes, Entregas e Categorias.

## Perguntas de negócio

1. **Por que as vendas estão caindo?** O que mudou ao longo do tempo e quais categorias, regiões ou formas de pagamento mais impactam as quedas?
2. **Quem são os melhores clientes?** Quais perfis compram mais, retornam e geram mais valor?
3. **Problemas na entrega estão prejudicando satisfação e vendas?** Como atrasos e prazos se relacionam com nota e recompra?
4. **Quais categorias sustentam ou derrubam o valor dos produtos?** Quais se destacam por valor, volume, preço e frete?

## Metodologia financeira

- `payment_value` → **Valor Total Pago** (pedido/pagamento): vendas gerais, ticket, estados e formas de pagamento.
- `price` → **Valor dos Produtos** (item): categorias e produtos.
- `freight_value` → **Frete** (item): análise logística/categorias.

> `payment_value` não foi somado diretamente após junção com itens, evitando duplicação em pedidos com múltiplos itens e/ou pagamentos.

## Principais resultados

### Vendas

No período padrão foram registrados **53.991 pedidos**, **R$ 8.694.733,84 em valor pago** e **ticket médio de R$ 161,04**. As principais quedas mensais ocorreram em **fevereiro (-10,99%)**, **junho (-11,27%)** e **agosto (-4,14%)**.

A decomposição mostra padrões diferentes: fevereiro combinou redução de pedidos e ticket; junho foi principalmente uma queda de volume de pedidos; agosto teve aumento de pedidos, mas queda relevante de ticket médio.

A distribuição geográfica é concentrada: São Paulo responde por aproximadamente **39,3%** do valor pago; SP, RJ e MG juntos representam cerca de **63,3%**.

### Análise das Quedas

A página permite selecionar um mês e comparar o resultado com o mês anterior. Em **jun/2018**, a queda foi concentrada sobretudo em:

- **Estados:** SP (-R$ 96,4 mil), RJ (-R$ 24,9 mil) e GO (-R$ 10,6 mil) entre os principais impactos negativos.
- **Pagamento:** cartão de crédito (-R$ 116,0 mil) e boleto (-R$ 42,0 mil); débito e voucher compensaram parcialmente.
- **Categorias (valor dos produtos):** relógios/presentes (-R$ 37,0 mil), ferramentas/jardim (-R$ 19,8 mil) e esporte/lazer (-R$ 13,8 mil) lideraram as retrações.

Esses resultados mostram **onde a queda se concentrou**, mas não provam causalidade operacional ou comercial.

### Clientes

Foram analisados **52.743 clientes**, dos quais **1.157 são recorrentes**, resultando em **2,19% de recorrência**. Entre recorrentes, **87,21%** ficaram no grupo de alto valor. O gasto médio dos recorrentes de alto valor foi **R$ 356,71**, contra **R$ 262,52** nos clientes de compra única de alto valor.

Apesar do maior valor individual dos recorrentes, a baixa recorrência faz com que clientes de compra única representem a maior parcela do valor pago no período. O principal potencial comercial está em converter clientes de compra única com alto valor em recorrentes.

### Entregas

No período foram registrados **52.778 pedidos entregues**, **4.079 atrasados** e **taxa de atraso de 7,73%**. A mediana do tempo de entrega foi **9 dias**. Pedidos atrasados tiveram **nota média de 2,23**, indicando associação clara entre atraso e pior experiência.

A recorrência após a primeira entrega foi **2,08%** para clientes sem atraso e **2,37%** para clientes com atraso. A diferença é pequena e na direção oposta ao esperado; portanto, o recorte não sustenta a conclusão de que atraso na primeira entrega reduz recompra.

### Categorias

A análise usa `order_items.price`, permitindo atribuição correta do valor ao produto. Beleza/saúde e relógios/presentes aparecem entre as categorias de maior valor no período. O dashboard complementa valor com volume, preço médio e frete, além de um gráfico de dispersão para visualizar categorias de alto volume, alto preço ou alto valor.

## 5 insights principais

1. **As quedas mensais não têm uma única origem:** junho foi majoritariamente volume; agosto foi majoritariamente ticket; fevereiro combinou os dois fatores.
2. **Há forte concentração geográfica:** SP representa ~39,3% do valor pago e os três maiores estados ~63,3%, aumentando a exposição a retrações regionais.
3. **Recorrência é baixa (2,19%):** clientes recorrentes de alto valor gastam mais, mas são poucos — retenção é uma oportunidade relevante.
4. **Atraso está associado a pior satisfação:** a nota média de pedidos atrasados (2,23) é um sinal de risco de experiência, mesmo sem evidência de menor recompra no recorte.
5. **Categorias e meios de pagamento explicam onde uma queda se concentra:** em junho, relógios/presentes e ferramentas/jardim recuaram fortemente; cartão de crédito e boleto concentraram o impacto negativo.

## Recomendações

- Implantar um **painel de alerta mensal** que decomponha qualquer queda em valor pago, pedidos e ticket antes de acionar planos comerciais.
- Automatizar a análise de contribuição por **estado, categoria e forma de pagamento** para localizar rapidamente o foco da retração.
- Criar programa de **segunda compra** para clientes de compra única de alto valor, com comunicação pós-compra e ofertas por categoria de afinidade.
- Priorizar planos logísticos nos estados com maior atraso e usar recuperação de serviço após atrasos, dado o baixo score médio desses pedidos.
- Monitorar categorias líderes e categorias com queda relevante, investigando estoque, preço, promoções, mix de sellers e frete — variáveis que não estão totalmente disponíveis no dataset atual.
- Complementar o modelo com dados de tráfego, conversão, campanhas, estoque, preço histórico, aprovação de pagamento e cancelamentos para diferenciar queda de demanda de falhas operacionais.

## Limitações

O dashboard identifica **associações e contribuições**, não causalidade. O dataset não contém todo o contexto necessário para afirmar motivos finais de uma queda (ex.: tráfego, marketing, estoque, concorrência, aprovação de pagamento). A dimensão de avaliação por perfil de cliente, distância de entrega e características físicas/fotos dos produtos não foi incorporada ao dashboard final; scripts de apoio estão documentados quando aplicável.

## Estrutura dos arquivos

```text
olist_entrega_final/
├── README.md
├── Relatorio_Profissional_Olist.docx
├── Relatorio_Profissional_Olist.pdf
└── scripts/
    ├── olist_analises.sql
    └── olist_medidas.dax
```

## Documentação técnica

- [`scripts/olist_analises.sql`](scripts/olist_analises.sql): consultas de exploração e validação.
- [`scripts/olist_medidas.dax`](scripts/olist_medidas.dax): tabela calendário, colunas calculadas e medidas do Power BI.

## Stack

- SQL / MySQL / DBeaver
- Power BI
- DAX
