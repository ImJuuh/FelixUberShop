<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ include file="../basedados/basedados.h" %>

<%
    /*
     * Página de administração de carteiras com Paginação Independente (Sem IDs Visíveis).
     */

    String perfil = (String) session.getAttribute("perfil");
    String nomeSessao = (String) session.getAttribute("nome");

    if (perfil == null || !perfil.equals("admin")) {
        response.sendRedirect("login.jsp");
        return;
    }

    String erro = "";
    String sucesso = "";

    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    // --- CONFIGURAÇÃO DA PAGINAÇÃO ---
    int itensPorPagina = 5; 

    int pagCarteiras = 1;
    String paramPagCart = request.getParameter("pag_cart");
    if (paramPagCart != null && !paramPagCart.isEmpty()) {
        pagCarteiras = Integer.parseInt(paramPagCart);
    }
    int offsetCart = (pagCarteiras - 1) * itensPorPagina;

    int pagMovimentos = 1;
    String paramPagMov = request.getParameter("pag_mov");
    if (paramPagMov != null && !paramPagMov.isEmpty()) {
        pagMovimentos = Integer.parseInt(paramPagMov);
    }
    int offsetMov = (pagMovimentos - 1) * itensPorPagina;

    int totalCart = 0, totalPagCart = 1;
    int totalMov = 0, totalPagMov = 1;


    // --- PROCESSAMENTO DO FORMULÁRIO (POST) ---
    if (request.getMethod().equalsIgnoreCase("POST")) {

        String carteiraIdTexto = request.getParameter("carteira_id");
        String operacao = request.getParameter("operacao");
        String valorTexto = request.getParameter("valor");

        try {
            if (carteiraIdTexto == null || carteiraIdTexto.trim().isEmpty() ||
                valorTexto == null || valorTexto.trim().isEmpty() ||
                operacao == null || operacao.trim().isEmpty()) {

                erro = "Preencha todos os campos.";

            } else {

                int carteiraId = Integer.parseInt(carteiraIdTexto);
                double valor = Double.parseDouble(valorTexto);

                if (valor <= 0) {
                    erro = "O valor tem de ser superior a zero.";
                } else {

                    conn = ligarBD();

                    double saldoAtual = 0.0;
                    String nomeCarteira = "";

                    String sqlSaldo = "SELECT nome, saldo FROM carteiras WHERE id = ? AND tipo = 'cliente'";
                    ps = conn.prepareStatement(sqlSaldo);
                    ps.setInt(1, carteiraId);
                    rs = ps.executeQuery();

                    if (rs.next()) {
                        nomeCarteira = rs.getString("nome");
                        saldoAtual = rs.getDouble("saldo");
                    } else {
                        erro = "Carteira não encontrada.";
                    }

                    rs.close();
                    ps.close();

                    if (erro.equals("")) {

                        if ("adicionar".equals(operacao)) {

                            String sqlAtualizar = "UPDATE carteiras SET saldo = saldo + ? WHERE id = ?";
                            ps = conn.prepareStatement(sqlAtualizar);
                            ps.setDouble(1, valor);
                            ps.setInt(2, carteiraId);
                            ps.executeUpdate();
                            ps.close();

                            String sqlMovimento =
                                "INSERT INTO movimentos_carteira (carteira_origem_id, carteira_destino_id, tipo_operacao, valor, descricao) " +
                                "VALUES (NULL, ?, 'adicionar', ?, ?)";

                            ps = conn.prepareStatement(sqlMovimento);
                            ps.setInt(1, carteiraId);
                            ps.setDouble(2, valor);
                            ps.setString(3, "Administrador adicionou saldo à " + nomeCarteira);
                            ps.executeUpdate();
                            ps.close();

                            sucesso = "Saldo adicionado com sucesso.";

                        } else if ("retirar".equals(operacao)) {

                            if (valor > saldoAtual) {
                                erro = "Saldo insuficiente para retirar esse valor.";
                            } else {

                                String sqlAtualizar = "UPDATE carteiras SET saldo = saldo - ? WHERE id = ?";
                                ps = conn.prepareStatement(sqlAtualizar);
                                ps.setDouble(1, valor);
                                ps.setInt(2, carteiraId);
                                ps.executeUpdate();
                                ps.close();

                                String sqlMovimento =
                                    "INSERT INTO movimentos_carteira (carteira_origem_id, carteira_destino_id, tipo_operacao, valor, descricao) " +
                                    "VALUES (?, NULL, 'levantar', ?, ?)";

                                ps = conn.prepareStatement(sqlMovimento);
                                ps.setInt(1, carteiraId);
                                ps.setDouble(2, valor);
                                ps.setString(3, "Administrador retirou saldo da " + nomeCarteira);
                                ps.executeUpdate();
                                ps.close();

                                sucesso = "Saldo retirado com sucesso.";
                            }

                        } else {
                            erro = "Operação inválida.";
                        }
                    }
                }
            }

        } catch (NumberFormatException e) {
            erro = "Valor inválido.";
        } catch (Exception e) {
            erro = "Erro ao gerir carteira.";
        } finally {
            try {
                if (rs != null) rs.close();
                if (ps != null) ps.close();
                if (conn != null) conn.close();
            } catch (Exception e) {}
        }
    }
%>

<!DOCTYPE html>
<html lang="pt">
<head>
    <meta charset="UTF-8">
    <title>Gestão de Carteiras - FelixUberShop</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="stylesheet" href="style.css">

    <style>
        .container-tabela {
            max-width: 1000px !important;
            width: 95% !important;
            margin: 30px auto;
            padding: 25px;
            font-family: sans-serif;
        }

        .header { text-align: center; margin-bottom: 30px; }
        .header h1 { margin: 0 0 5px 0; }
        .header p { margin: 0; color: #666; }

        h2 { margin: 35px 0 15px 0; padding-bottom: 8px; border-bottom: 2px solid #eee; color: #333; }

        .form-admin-box {
            background: #f9f9f9; padding: 20px; border-radius: 8px; border: 1px solid #e3e3e3; margin-bottom: 20px;
        }
        .form-admin-box h2 { margin-top: 0; border: none; padding: 0; }

        .form-row { display: grid; grid-template-columns: 1fr 1fr; gap: 15px; margin-top: 15px; }
        .form-group select, .form-group input {
            width: 100%; padding: 10px; box-sizing: border-box; border: 1px solid #ccc; border-radius: 4px; margin-top: 5px;
        }
        input[type="submit"] {
            width: 100%; padding: 12px; background: #0288d1; color: white; border: none; border-radius: 4px; font-weight: bold; cursor: pointer; margin-top: 15px;
        }
        input[type="submit"]:hover { background: #01579b; }

        .tabela { width: 100%; border-collapse: collapse; margin-bottom: 15px; background: #fff; }
        .tabela th, .tabela td { padding: 12px; text-align: left; border-bottom: 1px solid #eee; }
        .tabela th { background: #f4f4f4; color: #333; font-weight: bold; }
        .tabela tr:hover { background: #fdfdfd; }

        .badge {
            background: #e3f2fd; color: #0d47a1; padding: 3px 8px; border-radius: 12px; font-size: 12px; font-weight: bold;
        }
        .badge-inativo { background: #ffebee; color: #c62828; }

        .paginacao { display: flex; justify-content: center; gap: 5px; margin: 15px 0 30px 0; }
        .paginacao a { padding: 6px 12px; border: 1px solid #ddd; text-decoration: none; color: #333; border-radius: 4px; font-size: 13px; }
        .paginacao a.ativa { background: #0288d1; color: white; border-color: #0288d1; }
        .paginacao a:hover:not(.ativa) { background: #eee; }

        .links { text-align: center; margin-top: 30px; }
        .links a { margin: 0 10px; color: #0288d1; text-decoration: none; font-weight: bold; }
        .sem-dados { text-align: center; color: #888; font-style: italic; }
    </style>
</head>
<body>

<div class="container-tabela">

    <div class="header">
        <h1>Gestão de Carteiras</h1>
        <p>Olá, <strong><%= nomeSessao %></strong>. Painel administrativo de saldos e auditoria.</p>
    </div>

    <% if (!erro.equals("")) { %> <div class="erro"><%= erro %></div> <% } %>
    <% if (!sucesso.equals("")) { %> <div class="sucesso"><%= sucesso %></div> <% } %>

    <div class="form-admin-box">
        <h2>Alterar Saldo de Cliente</h2>
        <form method="post" action="admin_carteiras.jsp?pag_cart=<%= pagCarteiras %>&pag_mov=<%= pagMovimentos %>">
            
            <div class="form-group">
                <label for="carteira_id">Carteira do Cliente *</label>
                <select id="carteira_id" name="carteira_id" required>
                    <option value="">-- Escolha uma carteira --</option>
                    <%
                        Connection connSelect = null; PreparedStatement psSelect = null; ResultSet rsSelect = null;
                        try {
                            connSelect = ligarBD();
                            String sqlSelect = "SELECT c.id, u.nome, u.username, c.saldo FROM carteiras c INNER JOIN utilizadores u ON c.utilizador_id = u.id WHERE c.tipo = 'cliente' ORDER BY u.nome ASC";
                            psSelect = connSelect.prepareStatement(sqlSelect); rsSelect = psSelect.executeQuery();
                            while (rsSelect.next()) {
                    %>
                        <%-- IDs ocultados no texto visível ao administrador --%>
                        <option value="<%= rsSelect.getInt("id") %>">
                            <%= rsSelect.getString("nome") %> (<%= rsSelect.getString("username") %>) - Saldo: <%= String.format("%.2f", rsSelect.getDouble("saldo")) %> €
                        </option>
                    <%     }
                        } catch (Exception e) {} finally {
                            if (rsSelect != null) rsSelect.close(); if (psSelect != null) psSelect.close(); if (connSelect != null) connSelect.close();
                        }
                    %>
                </select>
            </div>

            <div class="form-row">
                <div class="form-group">
                    <label for="operacao">Operação *</label>
                    <select id="operacao" name="operacao" required>
                        <option value="adicionar">➕ Adicionar saldo</option>
                        <option value="retirar">➖ Retirar saldo</option>
                    </select>
                </div>
                <div class="form-group">
                    <label for="valor">Valor (€) *</label>
                    <input type="number" step="0.01" min="0.01" id="valor" name="valor" placeholder="0.00" required>
                </div>
            </div>
            <input type="submit" value="Confirmar Operação">
        </form>
    </div>

    <h2>Lista de Carteiras</h2>
    <%
        try {
            conn = ligarBD();

            String sqlCountCart = "SELECT COUNT(*) FROM carteiras WHERE tipo = 'cliente'";
            ps = conn.prepareStatement(sqlCountCart); rs = ps.executeQuery();
            if (rs.next()) totalCart = rs.getInt(1);
            rs.close(); ps.close();
            totalPagCart = (int) Math.ceil((double) totalCart / itensPorPagina);

            String sqlLista = "SELECT c.saldo, u.nome, u.username, u.email, u.ativo FROM carteiras c " +
                               "INNER JOIN utilizadores u ON c.utilizador_id = u.id WHERE c.tipo = 'cliente' " +
                               "ORDER BY u.nome ASC LIMIT ? OFFSET ?";
            ps = conn.prepareStatement(sqlLista);
            ps.setInt(1, itensPorPagina);
            ps.setInt(2, offsetCart);
            rs = ps.executeQuery();
    %>
    <table class="tabela">
        <thead>
            <tr>
                <th>Cliente</th>
                <th>Username</th>
                <th>Email</th>
                <th>Saldo Atual</th>
                <th>Estado</th>
            </tr>
        </thead>
        <tbody>
        <%
            boolean temCarteiras = false;
            while (rs.next()) {
                temCarteiras = true;
        %>
            <tr>
                <td><strong><%= rs.getString("nome") %></strong></td>
                <td><%= rs.getString("username") %></td>
                <td><%= rs.getString("email") != null ? rs.getString("email") : "-" %></td>
                <td style="color: #2e7d32;"><strong><%= String.format("%.2f", rs.getDouble("saldo")) %> €</strong></td>
                <td>
                    <span class="badge <%= !rs.getBoolean("ativo") ? "badge-inativo" : "" %>">
                        <%= rs.getBoolean("ativo") ? "Ativo" : "Inativo" %>
                    </span>
                </td>
            </tr>
        <% } if (!temCarteiras) { %>
            <tr><td colspan="5" class="sem-dados">Não existem carteiras registadas.</td></tr>
        <% } %>
        </tbody>
    </table>

    <% if (totalPagCart > 1) { %>
        <div class="paginacao">
            <% for (int i = 1; i <= totalPagCart; i++) { %>
                <a href="admin_carteiras.jsp?pag_cart=<%= i %>&pag_mov=<%= pagMovimentos %>" class="<%= (i == pagCarteiras) ? "ativa" : "" %>"><%= i %></a>
            <% } %>
        </div>
    <% } %>

    <% 
        } catch (Exception e) { e.printStackTrace(); } finally { if (rs != null) rs.close(); if (ps != null) ps.close(); if (conn != null) conn.close(); }
    %>


    <h2>Últimos Movimentos (Auditoria)</h2>
    <%
        try {
            conn = ligarBD();

            String sqlCountMov = "SELECT COUNT(*) FROM movimentos_carteira";
            ps = conn.prepareStatement(sqlCountMov); rs = ps.executeQuery();
            if (rs.next()) totalMov = rs.getInt(1);
            rs.close(); ps.close();
            totalPagMov = (int) Math.ceil((double) totalMov / itensPorPagina);

            String sqlMov = "SELECT m.tipo_operacao, m.valor, m.data_movimento, m.descricao, co.nome AS origem, cd.nome AS destino " +
                             "FROM movimentos_carteira m LEFT JOIN carteiras co ON m.carteira_origem_id = co.id " +
                             "LEFT JOIN carteiras cd ON m.carteira_destino_id = cd.id ORDER BY m.data_movimento DESC LIMIT ? OFFSET ?";
            ps = conn.prepareStatement(sqlMov);
            ps.setInt(1, itensPorPagina);
            ps.setInt(2, offsetMov);
            rs = ps.executeQuery();
    %>
    <table class="tabela">
        <thead>
            <tr>
                <th>Tipo</th>
                <th>Valor</th>
                <th>Data</th>
                <th>Origem</th>
                <th>Destino</th>
                <th>Descrição</th>
            </tr>
        </thead>
        <tbody>
        <%
            boolean temMovimentos = false;
            while (rs.next()) {
                temMovimentos = true;
        %>
            <tr>
                <td><span class="badge"><%= rs.getString("tipo_operacao") %></span></td>
                <td><strong><%= String.format("%.2f", rs.getDouble("valor")) %> €</strong></td>
                <td style="font-size: 13px; color: #555;"><%= rs.getString("data_movimento") %></td>
                <td><%= rs.getString("origem") != null ? rs.getString("origem") : "-" %></td>
                <td><%= rs.getString("destino") != null ? rs.getString("destino") : "-" %></td>
                <td style="font-size: 13px; color: #666;"><%= rs.getString("descricao") %></td>
            </tr>
        <% } if (!temMovimentos) { %>
            <tr><td colspan="6" class="sem-dados">Ainda não existem movimentos efetuados.</td></tr>
        <% } %>
        </tbody>
    </table>

    <% if (totalPagMov > 1) { %>
        <div class="paginacao">
            <% for (int i = 1; i <= totalPagMov; i++) { %>
                <a href="admin_carteiras.jsp?pag_cart=<%= pagCarteiras %>&pag_mov=<%= i %>" class="<%= (i == pagMovimentos) ? "ativa" : "" %>"><%= i %></a>
            <% } %>
        </div>
    <% } %>

    <% 
        } catch (Exception e) { e.printStackTrace(); } finally { if (rs != null) rs.close(); if (ps != null) ps.close(); if (conn != null) conn.close(); }
    %>

    <div class="links">
        <hr style="border: 0; border-top: 1px solid #eee; margin-bottom: 20px;">
        <a href="dashboard_admin.jsp">← Painel de Administração</a> | 
        <a href="logout.jsp" style="color: #d32f2f;">Terminar Sessão</a>
    </div>

</div>

</body>
</html>