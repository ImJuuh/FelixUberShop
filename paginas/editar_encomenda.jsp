<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ include file="../basedados/basedados.h" %>

<%
    /*
     * Página responsável por editar uma encomenda pendente.
     * O cliente só pode editar encomendas suas e apenas se estiverem pendentes.
     * Ao alterar a quantidade, o sistema recalcula o total, ajusta stock,
     * ajusta saldo do cliente/loja e regista auditoria.
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

    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    String codigoValidacao = "";
    String estado = "";
    String nomeProduto = "";
    int produtoId = 0;
    int quantidadeAtual = 0;
    int stockAtual = 0;
    double precoUnitario = 0.0;
    double totalAtual = 0.0;

    try {
        conn = ligarBD();

        /*
         * Buscar dados da encomenda.
         */
        String sqlDados =
            "SELECT e.codigo_validacao, e.estado, e.total, " +
            "ep.produto_id, ep.quantidade, ep.preco_unitario, " +
            "p.nome AS produto, p.stock " +
            "FROM encomendas e " +
            "INNER JOIN encomenda_produtos ep ON e.id = ep.encomenda_id " +
            "INNER JOIN produtos p ON ep.produto_id = p.id " +
            "WHERE e.id = ? AND e.cliente_id = ?";

        ps = conn.prepareStatement(sqlDados);
        ps.setInt(1, encomendaId);
        ps.setInt(2, userId);
        rs = ps.executeQuery();

        if (rs.next()) {
            codigoValidacao = rs.getString("codigo_validacao");
            estado = rs.getString("estado");
            totalAtual = rs.getDouble("total");
            produtoId = rs.getInt("produto_id");
            quantidadeAtual = rs.getInt("quantidade");
            precoUnitario = rs.getDouble("preco_unitario");
            nomeProduto = rs.getString("produto");
            stockAtual = rs.getInt("stock");
        } else {
            response.sendRedirect("minhas_encomendas.jsp");
            return;
        }

        rs.close();
        ps.close();

        /*
         * Só permite editar encomendas pendentes.
         */
        if (!estado.equals("pendente")) {
            erro = "Só é possível editar encomendas pendentes.";
        }

        /*
         * Processar alteração da quantidade.
         */
        if (request.getMethod().equalsIgnoreCase("POST") && erro.equals("")) {

            String novaQuantidadeTexto = request.getParameter("quantidade");

            try {
                int novaQuantidade = Integer.parseInt(novaQuantidadeTexto);

                if (novaQuantidade <= 0) {
                    erro = "A quantidade tem de ser superior a zero.";

                } else {

                    conn.setAutoCommit(false);

                    /*
                     * Stock disponível real = stock atual + quantidade que já estava reservada nesta encomenda.
                     */
                    int stockDisponivelReal = stockAtual + quantidadeAtual;

                    if (novaQuantidade > stockDisponivelReal) {
                        erro = "Stock insuficiente. Stock disponível: " + stockDisponivelReal;

                    } else {

                        double novoTotal = precoUnitario * novaQuantidade;
                        double diferenca = novoTotal - totalAtual;

                        int carteiraClienteId = 0;
                        int carteiraLojaId = 0;
                        double saldoCliente = 0.0;

                        /*
                         * Buscar carteira do cliente.
                         */
                        String sqlCarteiraCliente =
                            "SELECT id, saldo FROM carteiras WHERE utilizador_id = ? AND tipo = 'cliente'";

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
                                erro = "Carteira da FelixUberShop não encontrada.";
                            }

                            rs.close();
                            ps.close();
                        }

                        /*
                         * Se a nova encomenda for mais cara, verifica se o cliente tem saldo.
                         */
                        if (erro.equals("") && diferenca > saldoCliente) {
                            erro = "Saldo insuficiente para aumentar a encomenda. Diferença: " +
                                   String.format("%.2f", diferenca) + " €";
                        }

                        if (erro.equals("")) {

                            /*
                             * Atualizar quantidade na encomenda.
                             */
                            String sqlAtualizarProduto =
                                "UPDATE encomenda_produtos SET quantidade = ? WHERE encomenda_id = ?";

                            ps = conn.prepareStatement(sqlAtualizarProduto);
                            ps.setInt(1, novaQuantidade);
                            ps.setInt(2, encomendaId);
                            ps.executeUpdate();
                            ps.close();

                            /*
                             * Atualizar total da encomenda.
                             */
                            String sqlAtualizarEncomenda =
                                "UPDATE encomendas SET total = ? WHERE id = ?";

                            ps = conn.prepareStatement(sqlAtualizarEncomenda);
                            ps.setDouble(1, novoTotal);
                            ps.setInt(2, encomendaId);
                            ps.executeUpdate();
                            ps.close();

                            /*
                             * Atualizar stock.
                             * Novo stock = stock disponível real - nova quantidade.
                             */
                            int novoStock = stockDisponivelReal - novaQuantidade;

                            String sqlStock =
                                "UPDATE produtos SET stock = ? WHERE id = ?";

                            ps = conn.prepareStatement(sqlStock);
                            ps.setInt(1, novoStock);
                            ps.setInt(2, produtoId);
                            ps.executeUpdate();
                            ps.close();

                            /*
                             * Ajustar saldos apenas se existir diferença.
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

                            quantidadeAtual = novaQuantidade;
                            totalAtual = novoTotal;
                            stockAtual = novoStock;
                        }
                    }

                    if (!erro.equals("")) {
                        conn.rollback();
                    }
                }

            } catch (NumberFormatException e) {
                erro = "Quantidade inválida.";
                e.printStackTrace();

            } catch (Exception e) {
                erro = "Erro ao editar encomenda.";
                e.printStackTrace();

                try {
                    if (conn != null) conn.rollback();
                } catch (Exception ex) {
                    ex.printStackTrace();
                }
            }
        }

    } catch (Exception e) {
        erro = "Erro ao carregar encomenda.";
        e.printStackTrace();

    } finally {
        try {
            if (rs != null) rs.close();
            if (ps != null) ps.close();
            if (conn != null) {
                conn.setAutoCommit(true);
                conn.close();
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    int stockDisponivelParaEditar = stockAtual + quantidadeAtual;
%>

<!DOCTYPE html>
<html lang="pt">
<head>
    <meta charset="UTF-8">
    <title>Editar Encomenda - FelixUberShop</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <link rel="stylesheet" href="style.css">
</head>
<body>

<div class="container">

    <div class="header">
        <h1>Editar Encomenda</h1>
        <p>Altere a quantidade da sua encomenda pendente.</p>
    </div>

    <% if (!erro.equals("")) { %>
        <div class="erro"><%= erro %></div>
    <% } %>

    <% if (!sucesso.equals("")) { %>
        <div class="sucesso"><%= sucesso %></div>
    <% } %>

    <div class="form-group">
        <label>Código da Encomenda</label>
        <input type="text" value="<%= codigoValidacao %>" disabled>
    </div>

    <div class="form-group">
        <label>Produto</label>
        <input type="text" value="<%= nomeProduto %>" disabled>
    </div>

    <div class="form-group">
        <label>Preço Unitário</label>
        <input type="text" value="<%= String.format("%.2f", precoUnitario) %> €" disabled>
    </div>

    <div class="form-group">
        <label>Total Atual</label>
        <input type="text" value="<%= String.format("%.2f", totalAtual) %> €" disabled>
    </div>

    <form method="post" action="editar_encomenda.jsp?id=<%= encomendaId %>">

        <div class="form-group">
            <label for="quantidade">Nova Quantidade</label>
            <input type="number"
                   id="quantidade"
                   name="quantidade"
                   min="1"
                   max="<%= stockDisponivelParaEditar %>"
                   value="<%= quantidadeAtual %>"
                   required>
        </div>

        <p style="font-size:13px; color:#6b7280; margin-bottom:15px;">
            Stock máximo disponível para esta edição: <%= stockDisponivelParaEditar %> unidades.
        </p>

        <% if (estado.equals("pendente")) { %>
            <input type="submit" value="Guardar Alterações">
        <% } else { %>
            <div class="erro">Esta encomenda já não pode ser editada.</div>
        <% } %>

    </form>

    <div class="links">
        <p><a href="minhas_encomendas.jsp">Voltar às minhas encomendas</a></p>
        <p><a href="dashboard_cliente.jsp">Voltar à área do cliente</a></p>
    </div>

</div>

</body>
</html>