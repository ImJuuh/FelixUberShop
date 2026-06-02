<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.UUID" %>
<%@ include file="../basedados/basedados.h" %>

<%
    String perfil = (String) session.getAttribute("perfil");
    String nomeSessao = (String) session.getAttribute("nome");
    Integer userId = (Integer) session.getAttribute("user_id");

    if (perfil == null || !perfil.equals("cliente") || userId == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String erro = "";
    String sucesso = "";

    if (request.getMethod().equalsIgnoreCase("POST")) {

        String produtoIdTexto = request.getParameter("produto_id");
        String quantidadeTexto = request.getParameter("quantidade");

        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            int produtoId = Integer.parseInt(produtoIdTexto);
            int quantidade = Integer.parseInt(quantidadeTexto);

            if (quantidade <= 0) {
                erro = "A quantidade tem de ser superior a zero.";
            } else {

                conn = ligarBD();
                conn.setAutoCommit(false);

                int carteiraClienteId = 0;
                int carteiraLojaId = 0;
                double saldoCliente = 0.0;

                String nomeProduto = "";
                double precoProduto = 0.0;
                int stockProduto = 0;

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
                 * Buscar carteira da loja FelixUberShop.
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
                 * Buscar dados do produto escolhido.
                 */
                if (erro.equals("")) {
                    String sqlProduto =
                        "SELECT nome, preco, stock FROM produtos WHERE id = ? AND ativo = TRUE";

                    ps = conn.prepareStatement(sqlProduto);
                    ps.setInt(1, produtoId);
                    rs = ps.executeQuery();

                    if (rs.next()) {
                        nomeProduto = rs.getString("nome");
                        precoProduto = rs.getDouble("preco");
                        stockProduto = rs.getInt("stock");
                    } else {
                        erro = "Produto não encontrado.";
                    }

                    rs.close();
                    ps.close();
                }

                /*
                 * Verificar stock e saldo.
                 */
                if (erro.equals("")) {

                    double total = precoProduto * quantidade;

                    if (quantidade > stockProduto) {
                        erro = "Stock insuficiente. Stock disponível: " + stockProduto;

                    } else if (total > saldoCliente) {
                        erro = "Saldo insuficiente. Total da encomenda: " + String.format("%.2f", total) + " €";

                    } else {

                        /*
                         * Código único para validação da encomenda pelo funcionário.
                         */
                        String codigoValidacao = "ENC-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();

                        /*
                         * Criar encomenda.
                         */
                        String sqlEncomenda =
                            "INSERT INTO encomendas (codigo_validacao, cliente_id, estado, total) " +
                            "VALUES (?, ?, 'pendente', ?)";

                        ps = conn.prepareStatement(sqlEncomenda, Statement.RETURN_GENERATED_KEYS);
                        ps.setString(1, codigoValidacao);
                        ps.setInt(2, userId);
                        ps.setDouble(3, total);
                        ps.executeUpdate();

                        rs = ps.getGeneratedKeys();

                        int encomendaId = 0;

                        if (rs.next()) {
                            encomendaId = rs.getInt(1);
                        }

                        rs.close();
                        ps.close();

                        /*
                         * Inserir produto associado à encomenda.
                         */
                        String sqlEncomendaProduto =
                            "INSERT INTO encomenda_produtos " +
                            "(encomenda_id, produto_id, quantidade, preco_unitario) " +
                            "VALUES (?, ?, ?, ?)";

                        ps = conn.prepareStatement(sqlEncomendaProduto);
                        ps.setInt(1, encomendaId);
                        ps.setInt(2, produtoId);
                        ps.setInt(3, quantidade);
                        ps.setDouble(4, precoProduto);
                        ps.executeUpdate();
                        ps.close();

                        /*
                         * Atualizar stock do produto.
                         */
                        String sqlStock =
                            "UPDATE produtos SET stock = stock - ? WHERE id = ?";

                        ps = conn.prepareStatement(sqlStock);
                        ps.setInt(1, quantidade);
                        ps.setInt(2, produtoId);
                        ps.executeUpdate();
                        ps.close();

                        /*
                         * Retirar saldo do cliente.
                         */
                        String sqlRetirarSaldo =
                            "UPDATE carteiras SET saldo = saldo - ? WHERE id = ?";

                        ps = conn.prepareStatement(sqlRetirarSaldo);
                        ps.setDouble(1, total);
                        ps.setInt(2, carteiraClienteId);
                        ps.executeUpdate();
                        ps.close();

                        /*
                         * Adicionar saldo à carteira da loja.
                         */
                        String sqlAdicionarSaldoLoja =
                            "UPDATE carteiras SET saldo = saldo + ? WHERE id = ?";

                        ps = conn.prepareStatement(sqlAdicionarSaldoLoja);
                        ps.setDouble(1, total);
                        ps.setInt(2, carteiraLojaId);
                        ps.executeUpdate();
                        ps.close();

                        /*
                         * Registar movimento de auditoria.
                         */
                        String sqlMovimento =
                            "INSERT INTO movimentos_carteira " +
                            "(carteira_origem_id, carteira_destino_id, tipo_operacao, valor, descricao) " +
                            "VALUES (?, ?, 'pagamento', ?, ?)";

                        ps = conn.prepareStatement(sqlMovimento);
                        ps.setInt(1, carteiraClienteId);
                        ps.setInt(2, carteiraLojaId);
                        ps.setDouble(3, total);
                        ps.setString(4, "Pagamento da encomenda " + codigoValidacao + " - " + nomeProduto);
                        ps.executeUpdate();
                        ps.close();

                        conn.commit();

                        sucesso = "Encomenda criada com sucesso. Código de validação: " + codigoValidacao;
                    }
                }

                if (!erro.equals("")) {
                    conn.rollback();
                }
            }

        } catch (NumberFormatException e) {
            erro = "Dados inválidos. Escolha um produto e indique uma quantidade válida.";
            e.printStackTrace();

        } catch (Exception e) {
            erro = "Erro ao criar encomenda.";
            e.printStackTrace();

            try {
                if (conn != null) {
                    conn.rollback();
                }
            } catch (Exception ex) {
                ex.printStackTrace();
            }

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
    }
%>

<!DOCTYPE html>
<html lang="pt">
<head>
    <meta charset="UTF-8">
    <title>Nova Encomenda - FelixUberShop</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <link rel="stylesheet" href="style.css">
</head>
<body>

<div class="container">

    <div class="header">
        <h1>Nova Encomenda</h1>
        <p>Olá, <%= nomeSessao %>. Escolha o produto que pretende encomendar.</p>
    </div>

    <% if (!erro.equals("")) { %>
        <div class="erro"><%= erro %></div>
    <% } %>

    <% if (!sucesso.equals("")) { %>
        <div class="sucesso"><%= sucesso %></div>
    <% } %>

    <form method="post" action="nova_encomenda.jsp">

        <div class="form-group">
            <label for="produto_id">Produto</label>

            <select id="produto_id" name="produto_id" required>
                <option value="">-- Escolha um produto --</option>

                <%
                    Connection connLista = null;
                    PreparedStatement psLista = null;
                    ResultSet rsLista = null;

                    try {
                        connLista = ligarBD();

                        String sqlLista =
                            "SELECT id, nome, preco, stock FROM produtos " +
                            "WHERE ativo = TRUE AND stock > 0 " +
                            "ORDER BY nome";

                        psLista = connLista.prepareStatement(sqlLista);
                        rsLista = psLista.executeQuery();

                        while (rsLista.next()) {
                            int idProduto = rsLista.getInt("id");
                            String nomeProduto = rsLista.getString("nome");
                            double preco = rsLista.getDouble("preco");
                            int stock = rsLista.getInt("stock");
                %>

                    <option value="<%= idProduto %>">
                        <%= nomeProduto %> - <%= String.format("%.2f", preco) %> € - Stock: <%= stock %>
                    </option>

                <%
                        }

                    } catch (Exception e) {
                        e.printStackTrace();

                    } finally {
                        try {
                            if (rsLista != null) rsLista.close();
                            if (psLista != null) psLista.close();
                            if (connLista != null) connLista.close();
                        } catch (Exception e) {
                            e.printStackTrace();
                        }
                    }
                %>
            </select>
        </div>

        <div class="form-group">
            <label for="quantidade">Quantidade</label>
            <input type="number" id="quantidade" name="quantidade" min="1" value="1" required>
        </div>

        <input type="submit" value="Confirmar Encomenda">

    </form>

    <div class="links">
        <p><a href="produtos.jsp">Ver produtos</a></p>
        <p><a href="carteira.jsp">Consultar carteira</a></p>
        <p><a href="dashboard_cliente.jsp">Voltar à área do cliente</a></p>
    </div>

</div>

</body>
</html>