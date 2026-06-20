<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ page import="java.util.*" %>
<%@ include file="../basedados/basedados.h" %>

<%
    request.setCharacterEncoding("UTF-8");

    /*
     * Página para editar uma encomenda pendente.
     * Agora suporta encomendas com vários produtos.
     */

    String perfil = (String) session.getAttribute("perfil");
    Integer userId = (Integer) session.getAttribute("user_id");

    if (perfil == null || !perfil.equals("cliente") || userId == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String erro = "";
    String sucesso = "";

    String idTexto = request.getParameter("id");

    if (idTexto == null || idTexto.trim().isEmpty()) {
        response.sendRedirect("minhas_encomendas.jsp");
        return;
    }

    int encomendaId = 0;

    try {
        encomendaId = Integer.parseInt(idTexto);
    } catch (Exception e) {
        response.sendRedirect("minhas_encomendas.jsp");
        return;
    }

    String codigoValidacao = "";
    String estado = "";
    double totalAtual = 0.0;

    ArrayList<Integer> itemIds = new ArrayList<Integer>();
    ArrayList<Integer> produtoIds = new ArrayList<Integer>();
    ArrayList<String> nomes = new ArrayList<String>();
    ArrayList<Integer> quantidadesAtuais = new ArrayList<Integer>();
    ArrayList<Double> precosUnitarios = new ArrayList<Double>();
    ArrayList<Integer> stocksAtuais = new ArrayList<Integer>();

    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    try {
        conn = ligarBD();

        /*
         * Buscar dados principais da encomenda.
         */
        String sqlEncomenda =
            "SELECT id, codigo_validacao, estado, total " +
            "FROM encomendas " +
            "WHERE id = ? AND cliente_id = ?";

        ps = conn.prepareStatement(sqlEncomenda);
        ps.setInt(1, encomendaId);
        ps.setInt(2, userId);
        rs = ps.executeQuery();

        if (rs.next()) {
            codigoValidacao = rs.getString("codigo_validacao");
            estado = rs.getString("estado");
            totalAtual = rs.getDouble("total");
        } else {
            response.sendRedirect("minhas_encomendas.jsp");
            return;
        }

        rs.close();
        ps.close();

        if (!estado.equals("pendente")) {
            erro = "Só é possível editar encomendas pendentes.";
        }

        /*
         * Buscar todos os produtos da encomenda.
         */
        String sqlItens =
            "SELECT ep.id AS item_id, ep.produto_id, ep.quantidade, ep.preco_unitario, " +
            "p.nome, p.stock " +
            "FROM encomenda_produtos ep " +
            "INNER JOIN produtos p ON ep.produto_id = p.id " +
            "WHERE ep.encomenda_id = ? " +
            "ORDER BY p.nome";

        ps = conn.prepareStatement(sqlItens);
        ps.setInt(1, encomendaId);
        rs = ps.executeQuery();

        while (rs.next()) {
            itemIds.add(rs.getInt("item_id"));
            produtoIds.add(rs.getInt("produto_id"));
            nomes.add(rs.getString("nome"));
            quantidadesAtuais.add(rs.getInt("quantidade"));
            precosUnitarios.add(rs.getDouble("preco_unitario"));
            stocksAtuais.add(rs.getInt("stock"));
        }

        rs.close();
        ps.close();

        /*
         * Processar edição.
         */
        if (request.getMethod().equalsIgnoreCase("POST") && erro.equals("")) {

            ArrayList<Integer> novasQuantidades = new ArrayList<Integer>();
            double novoTotal = 0.0;
            int totalProdutosEscolhidos = 0;

            /*
             * Validar todas as quantidades.
             */
            for (int i = 0; i < itemIds.size(); i++) {

                int itemId = itemIds.get(i);
                int quantidadeAtual = quantidadesAtuais.get(i);
                int stockAtual = stocksAtuais.get(i);
                double precoUnitario = precosUnitarios.get(i);

                String qtdTexto = request.getParameter("qtd_" + itemId);

                int novaQuantidade = 0;

                try {
                    if (qtdTexto != null && !qtdTexto.trim().isEmpty()) {
                        novaQuantidade = Integer.parseInt(qtdTexto);
                    }
                } catch (Exception e) {
                    novaQuantidade = -1;
                }

                if (novaQuantidade < 0) {
                    erro = "Quantidade inválida no produto: " + nomes.get(i);
                    break;
                }

                /*
                 * Stock disponível real = stock atual + quantidade que já estava reservada nesta encomenda.
                 */
                int stockDisponivelReal = stockAtual + quantidadeAtual;

                if (novaQuantidade > stockDisponivelReal) {
                    erro = "Stock insuficiente para o produto: " + nomes.get(i) +
                           ". Stock disponível: " + stockDisponivelReal;
                    break;
                }

                novasQuantidades.add(novaQuantidade);

                if (novaQuantidade > 0) {
                    totalProdutosEscolhidos++;
                    novoTotal = novoTotal + (novaQuantidade * precoUnitario);
                }
            }

            if (erro.equals("") && totalProdutosEscolhidos == 0) {
                erro = "A encomenda tem de ficar com pelo menos um produto.";
            }

            if (erro.equals("")) {

                conn.setAutoCommit(false);

                int carteiraClienteId = 0;
                int carteiraLojaId = 0;
                double saldoCliente = 0.0;

                /*
                 * Buscar carteira do cliente.
                 */
                String sqlCarteiraCliente =
                    "SELECT id, saldo " +
                    "FROM carteiras " +
                    "WHERE utilizador_id = ? AND tipo = 'cliente'";

                ps = conn.prepareStatement(sqlCarteiraCliente);
                ps.setInt(1, userId);
                rs = ps.executeQuery();

                if (rs.next()) {
                    carteiraClienteId = rs.getInt("id");
                    saldoCliente = rs.getDouble("saldo");
                } else {
                    erro = "Carteira do cliente não encontrada.";
                }

                rs.close();
                ps.close();

                /*
                 * Buscar carteira da loja.
                 */
                if (erro.equals("")) {
                    String sqlCarteiraLoja =
                        "SELECT id FROM carteiras WHERE tipo = 'loja' LIMIT 1";

                    ps = conn.prepareStatement(sqlCarteiraLoja);
                    rs = ps.executeQuery();

                    if (rs.next()) {
                        carteiraLojaId = rs.getInt("id");
                    } else {
                        erro = "Carteira da loja não encontrada.";
                    }

                    rs.close();
                    ps.close();
                }

                double diferenca = novoTotal - totalAtual;

                /*
                 * Se a encomenda ficou mais cara, verificar saldo.
                 */
                if (erro.equals("") && diferenca > saldoCliente) {
                    erro = "Saldo insuficiente para aumentar a encomenda. Diferença: " +
                           String.format("%.2f", diferenca) + " €";
                }

                if (erro.equals("")) {

                    /*
                     * Atualizar cada produto da encomenda.
                     */
                    for (int i = 0; i < itemIds.size(); i++) {

                        int itemId = itemIds.get(i);
                        int produtoId = produtoIds.get(i);
                        int quantidadeAtual = quantidadesAtuais.get(i);
                        int stockAtual = stocksAtuais.get(i);
                        int novaQuantidade = novasQuantidades.get(i);

                        /*
                         * Novo stock = stock atual + quantidade antiga - nova quantidade.
                         */
                        int novoStock = stockAtual + quantidadeAtual - novaQuantidade;

                        /*
                         * Atualizar stock do produto.
                         */
                        String sqlStock =
                            "UPDATE produtos SET stock = ? WHERE id = ?";

                        ps = conn.prepareStatement(sqlStock);
                        ps.setInt(1, novoStock);
                        ps.setInt(2, produtoId);
                        ps.executeUpdate();
                        ps.close();

                        /*
                         * Se a nova quantidade for 0, remove o produto da encomenda.
                         * Caso contrário, atualiza a quantidade.
                         */
                        if (novaQuantidade == 0) {

                            String sqlDeleteItem =
                                "DELETE FROM encomenda_produtos WHERE id = ?";

                            ps = conn.prepareStatement(sqlDeleteItem);
                            ps.setInt(1, itemId);
                            ps.executeUpdate();
                            ps.close();

                        } else {

                            String sqlUpdateItem =
                                "UPDATE encomenda_produtos SET quantidade = ? WHERE id = ?";

                            ps = conn.prepareStatement(sqlUpdateItem);
                            ps.setInt(1, novaQuantidade);
                            ps.setInt(2, itemId);
                            ps.executeUpdate();
                            ps.close();
                        }
                    }

                    /*
                     * Atualizar total da encomenda.
                     */
                    String sqlUpdateEncomenda =
                        "UPDATE encomendas SET total = ? WHERE id = ?";

                    ps = conn.prepareStatement(sqlUpdateEncomenda);
                    ps.setDouble(1, novoTotal);
                    ps.setInt(2, encomendaId);
                    ps.executeUpdate();
                    ps.close();

                    /*
                     * Ajustar carteiras.
                     */
                    if (diferenca > 0) {

                        /*
                         * Cliente paga mais.
                         */
                        String sqlCliente =
                            "UPDATE carteiras SET saldo = saldo - ? WHERE id = ?";

                        ps = conn.prepareStatement(sqlCliente);
                        ps.setDouble(1, diferenca);
                        ps.setInt(2, carteiraClienteId);
                        ps.executeUpdate();
                        ps.close();

                        String sqlLoja =
                            "UPDATE carteiras SET saldo = saldo + ? WHERE id = ?";

                        ps = conn.prepareStatement(sqlLoja);
                        ps.setDouble(1, diferenca);
                        ps.setInt(2, carteiraLojaId);
                        ps.executeUpdate();
                        ps.close();

                        String sqlMovimento =
                            "INSERT INTO movimentos_carteira " +
                            "(carteira_origem_id, carteira_destino_id, tipo_operacao, valor, descricao) " +
                            "VALUES (?, ?, 'pagamento', ?, ?)";

                        ps = conn.prepareStatement(sqlMovimento);
                        ps.setInt(1, carteiraClienteId);
                        ps.setInt(2, carteiraLojaId);
                        ps.setDouble(3, diferenca);
                        ps.setString(4, "Ajuste por edição da encomenda " + codigoValidacao);
                        ps.executeUpdate();
                        ps.close();

                    } else if (diferenca < 0) {

                        /*
                         * Cliente recebe devolução parcial.
                         */
                        double valorDevolver = Math.abs(diferenca);

                        String sqlCliente =
                            "UPDATE carteiras SET saldo = saldo + ? WHERE id = ?";

                        ps = conn.prepareStatement(sqlCliente);
                        ps.setDouble(1, valorDevolver);
                        ps.setInt(2, carteiraClienteId);
                        ps.executeUpdate();
                        ps.close();

                        String sqlLoja =
                            "UPDATE carteiras SET saldo = saldo - ? WHERE id = ?";

                        ps = conn.prepareStatement(sqlLoja);
                        ps.setDouble(1, valorDevolver);
                        ps.setInt(2, carteiraLojaId);
                        ps.executeUpdate();
                        ps.close();

                        String sqlMovimento =
                            "INSERT INTO movimentos_carteira " +
                            "(carteira_origem_id, carteira_destino_id, tipo_operacao, valor, descricao) " +
                            "VALUES (?, ?, 'devolucao', ?, ?)";

                        ps = conn.prepareStatement(sqlMovimento);
                        ps.setInt(1, carteiraLojaId);
                        ps.setInt(2, carteiraClienteId);
                        ps.setDouble(3, valorDevolver);
                        ps.setString(4, "Devolução parcial por edição da encomenda " + codigoValidacao);
                        ps.executeUpdate();
                        ps.close();
                    }

                    conn.commit();

                    sucesso = "Encomenda atualizada com sucesso.";

                    /*
                     * Atualizar valores em memória para mostrar a página correta.
                     */
                    totalAtual = novoTotal;

                    quantidadesAtuais.clear();
                    stocksAtuais.clear();

                    /*
                     * Recarregar produtos da encomenda depois da edição.
                     */
                    String sqlReload =
                        "SELECT ep.id AS item_id, ep.produto_id, ep.quantidade, ep.preco_unitario, " +
                        "p.nome, p.stock " +
                        "FROM encomenda_produtos ep " +
                        "INNER JOIN produtos p ON ep.produto_id = p.id " +
                        "WHERE ep.encomenda_id = ? " +
                        "ORDER BY p.nome";

                    itemIds.clear();
                    produtoIds.clear();
                    nomes.clear();
                    precosUnitarios.clear();

                    ps = conn.prepareStatement(sqlReload);
                    ps.setInt(1, encomendaId);
                    rs = ps.executeQuery();

                    while (rs.next()) {
                        itemIds.add(rs.getInt("item_id"));
                        produtoIds.add(rs.getInt("produto_id"));
                        nomes.add(rs.getString("nome"));
                        quantidadesAtuais.add(rs.getInt("quantidade"));
                        precosUnitarios.add(rs.getDouble("preco_unitario"));
                        stocksAtuais.add(rs.getInt("stock"));
                    }

                    rs.close();
                    ps.close();
                }

                if (!erro.equals("")) {
                    conn.rollback();
                }

                conn.setAutoCommit(true);
            }
        }

    } catch (Exception e) {
        erro = "Erro ao carregar ou editar encomenda.";
        e.printStackTrace();

        try {
            if (conn != null) {
                conn.rollback();
                conn.setAutoCommit(true);
            }
        } catch (Exception ex) {
            ex.printStackTrace();
        }

    } finally {
        try {
            if (rs != null) rs.close();
            if (ps != null) ps.close();
            if (conn != null) conn.close();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
%>

<!DOCTYPE html>
<html lang="pt">
<head>
    <meta charset="UTF-8">
    <title>Editar Encomenda - FelixUberShop</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <link rel="stylesheet" href="style.css">

    <style>
        body {
            display: block !important;
            padding: 20px;
            background: #f8fafc;
        }

        .container-editar {
            width: 900px;
            max-width: 95%;
            margin: 30px auto;
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 8px 25px rgba(0,0,0,0.08);
        }

        .topo h1 {
            margin: 0;
            color: #10b981;
        }

        .topo p {
            color: #6b7280;
            margin-top: 8px;
        }

        .info-encomenda {
            background: #ecfdf5;
            border: 1px solid #a7f3d0;
            padding: 15px;
            border-radius: 8px;
            margin: 20px 0;
        }

        .info-encomenda p {
            margin: 5px 0;
        }

        .produto-edit {
            display: grid;
            grid-template-columns: 1fr 120px 120px 140px;
            gap: 12px;
            align-items: center;
            border-bottom: 1px solid #e5e7eb;
            padding: 14px 0;
        }

        .produto-edit:first-child {
            border-top: 1px solid #e5e7eb;
        }

        .produto-nome {
            font-weight: 700;
            color: #1f2937;
        }

        .produto-info {
            color: #6b7280;
            font-size: 13px;
        }

        .produto-edit input {
            width: 100%;
            padding: 9px;
            border: 1px solid #d1d5db;
            border-radius: 6px;
        }

        .btn-submit {
            width: 100%;
            margin-top: 25px;
            padding: 14px;
            background: #10b981;
            color: white;
            border: none;
            border-radius: 6px;
            font-weight: 800;
            cursor: pointer;
        }

        .btn-submit:hover {
            background: #059669;
        }

        .links {
            text-align: center;
            margin-top: 22px;
        }

        .links a {
            color: #10b981;
            text-decoration: none;
            font-weight: 700;
            margin: 0 8px;
        }

        @media (max-width: 750px) {
            .produto-edit {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>
<body>

<div class="container-editar">

    <div class="topo">
        <h1>Editar Encomenda</h1>
        <p>Altere as quantidades dos produtos desta encomenda.</p>
    </div>

    <% if (!erro.equals("")) { %>
        <div class="erro"><%= erro %></div>
    <% } %>

    <% if (!sucesso.equals("")) { %>
        <div class="sucesso"><%= sucesso %></div>
    <% } %>

    <div class="info-encomenda">
        <p><strong>Código:</strong> <%= codigoValidacao %></p>
        <p><strong>Estado:</strong> <%= estado %></p>
        <p><strong>Total atual:</strong> <%= String.format("%.2f", totalAtual) %> €</p>
    </div>

    <% if (estado.equals("pendente")) { %>

        <form method="post" action="editar_encomenda.jsp?id=<%= encomendaId %>" accept-charset="UTF-8">

            <div class="produto-edit" style="font-weight:bold; color:#065f46;">
                <div>Produto</div>
                <div>Preço</div>
                <div>Stock máx.</div>
                <div>Quantidade</div>
            </div>

            <%
                for (int i = 0; i < itemIds.size(); i++) {

                    int stockMaximo = stocksAtuais.get(i) + quantidadesAtuais.get(i);
            %>

                <div class="produto-edit">
                    <div>
                        <div class="produto-nome"><%= nomes.get(i) %></div>
                        <div class="produto-info">Quantidade atual: <%= quantidadesAtuais.get(i) %></div>
                    </div>

                    <div>
                        <%= String.format("%.2f", precosUnitarios.get(i)) %> €
                    </div>

                    <div>
                        <%= stockMaximo %>
                    </div>

                    <div>
                        <input type="number"
                               name="qtd_<%= itemIds.get(i) %>"
                               min="0"
                               max="<%= stockMaximo %>"
                               value="<%= quantidadesAtuais.get(i) %>">
                    </div>
                </div>

            <%
                }
            %>

            <button type="submit" class="btn-submit">Guardar Alterações</button>

        </form>

    <% } else { %>

        <div class="erro">
            Esta encomenda já não pode ser editada.
        </div>

    <% } %>

    <div class="links">
        <a href="minhas_encomendas.jsp">Voltar às minhas encomendas</a>
        |
        <a href="dashboard_cliente.jsp">Voltar à área do cliente</a>
    </div>

</div>

</body>
</html>