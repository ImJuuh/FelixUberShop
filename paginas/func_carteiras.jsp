<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ include file="../basedados/basedados.h" %>

<%
    /*
     * Página de gestão de carteiras para funcionários.
     * Permite consultar carteiras de clientes, adicionar saldo,
     * retirar saldo e registar os movimentos para auditoria.
     */

    String perfil = (String) session.getAttribute("perfil");
    String nomeSessao = (String) session.getAttribute("nome");

    if (perfil == null || !perfil.equals("funcionario")) {
        response.sendRedirect("login.jsp");
        return;
    }

    String erro = "";
    String sucesso = "";

    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

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

                    /*
                     * Buscar saldo atual da carteira selecionada.
                     */
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

                            /*
                             * Adiciona saldo à carteira do cliente.
                             */
                            String sqlAtualizar = "UPDATE carteiras SET saldo = saldo + ? WHERE id = ?";
                            ps = conn.prepareStatement(sqlAtualizar);
                            ps.setDouble(1, valor);
                            ps.setInt(2, carteiraId);
                            ps.executeUpdate();
                            ps.close();

                            /*
                             * Regista movimento de auditoria.
                             */
                            String sqlMovimento =
                                "INSERT INTO movimentos_carteira " +
                                "(carteira_origem_id, carteira_destino_id, tipo_operacao, valor, descricao) " +
                                "VALUES (NULL, ?, 'adicionar', ?, ?)";

                            ps = conn.prepareStatement(sqlMovimento);
                            ps.setInt(1, carteiraId);
                            ps.setDouble(2, valor);
                            ps.setString(3, "Funcionário adicionou saldo à " + nomeCarteira);
                            ps.executeUpdate();
                            ps.close();

                            sucesso = "Saldo adicionado com sucesso.";

                        } else if ("retirar".equals(operacao)) {

                            /*
                             * Só permite retirar saldo se existir saldo suficiente.
                             */
                            if (valor > saldoAtual) {
                                erro = "Saldo insuficiente para retirar esse valor.";

                            } else {

                                String sqlAtualizar = "UPDATE carteiras SET saldo = saldo - ? WHERE id = ?";
                                ps = conn.prepareStatement(sqlAtualizar);
                                ps.setDouble(1, valor);
                                ps.setInt(2, carteiraId);
                                ps.executeUpdate();
                                ps.close();

                                /*
                                 * Regista movimento de auditoria.
                                 */
                                String sqlMovimento =
                                    "INSERT INTO movimentos_carteira " +
                                    "(carteira_origem_id, carteira_destino_id, tipo_operacao, valor, descricao) " +
                                    "VALUES (?, NULL, 'levantar', ?, ?)";

                                ps = conn.prepareStatement(sqlMovimento);
                                ps.setInt(1, carteiraId);
                                ps.setDouble(2, valor);
                                ps.setString(3, "Funcionário retirou saldo da " + nomeCarteira);
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
            e.printStackTrace();

        } catch (Exception e) {
            erro = "Erro ao gerir carteira.";
            e.printStackTrace();

        } finally {
            try {
                if (rs != null) rs.close();
                if (ps != null) ps.close();
                if (conn != null) conn.close();
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
    <title>Gestão de Carteiras - Funcionário</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <link rel="stylesheet" href="style.css">
</head>
<body>

<div class="container-tabela">

    <div class="header">
        <h1>Gestão de Carteiras</h1>
        <p>Olá, <%= nomeSessao %>. Aqui pode gerir o saldo das carteiras dos clientes.</p>
    </div>

    <% if (!erro.equals("")) { %>
        <div class="erro"><%= erro %></div>
    <% } %>

    <% if (!sucesso.equals("")) { %>
        <div class="sucesso"><%= sucesso %></div>
    <% } %>

    <div class="form-admin-box">

        <h2>Alterar Saldo de Cliente</h2>

        <form method="post" action="func_carteiras.jsp">

            <div class="form-group">
                <label for="carteira_id">Carteira do Cliente *</label>

                <select id="carteira_id" name="carteira_id" required>
                    <option value="">-- Escolha uma carteira --</option>

                    <%
                        Connection connSelect = null;
                        PreparedStatement psSelect = null;
                        ResultSet rsSelect = null;

                        try {
                            connSelect = ligarBD();

                            String sqlSelect =
                                "SELECT c.id, c.nome AS nome_carteira, c.saldo, u.nome AS nome_utilizador, u.username " +
                                "FROM carteiras c " +
                                "INNER JOIN utilizadores u ON c.utilizador_id = u.id " +
                                "WHERE c.tipo = 'cliente' " +
                                "ORDER BY u.nome ASC";

                            psSelect = connSelect.prepareStatement(sqlSelect);
                            rsSelect = psSelect.executeQuery();

                            while (rsSelect.next()) {
                                int idCarteira = rsSelect.getInt("id");
                                String nomeUtilizador = rsSelect.getString("nome_utilizador");
                                String username = rsSelect.getString("username");
                                double saldo = rsSelect.getDouble("saldo");
                    %>

                        <option value="<%= idCarteira %>">
                            <%= nomeUtilizador %> (<%= username %>) - Saldo: <%= String.format("%.2f", saldo) %> €
                        </option>

                    <%
                            }

                        } catch (Exception e) {
                            e.printStackTrace();

                        } finally {
                            try {
                                if (rsSelect != null) rsSelect.close();
                                if (psSelect != null) psSelect.close();
                                if (connSelect != null) connSelect.close();
                            } catch (Exception e) {
                                e.printStackTrace();
                            }
                        }
                    %>
                </select>
            </div>

            <div class="form-row">

                <div class="form-group">
                    <label for="operacao">Operação *</label>
                    <select id="operacao" name="operacao" required>
                        <option value="adicionar">Adicionar saldo</option>
                        <option value="retirar">Retirar saldo</option>
                    </select>
                </div>

                <div class="form-group">
                    <label for="valor">Valor *</label>
                    <input type="number" step="0.01" min="0.01" id="valor" name="valor" placeholder="Ex: 10.00" required>
                </div>

            </div>

            <input type="submit" value="Confirmar Operação">

        </form>

    </div>

    <h2>Lista de Carteiras</h2>

    <table class="tabela">
        <thead>
            <tr>
                <th>ID Carteira</th>
                <th>Cliente</th>
                <th>Username</th>
                <th>Email</th>
                <th>Saldo Atual</th>
                <th>Estado Cliente</th>
            </tr>
        </thead>

        <tbody>

        <%
            try {
                conn = ligarBD();

                String sqlLista =
                    "SELECT c.id, c.saldo, u.nome, u.username, u.email, u.ativo " +
                    "FROM carteiras c " +
                    "INNER JOIN utilizadores u ON c.utilizador_id = u.id " +
                    "WHERE c.tipo = 'cliente' " +
                    "ORDER BY u.nome ASC";

                ps = conn.prepareStatement(sqlLista);
                rs = ps.executeQuery();

                boolean temCarteiras = false;

                while (rs.next()) {
                    temCarteiras = true;

                    int idCarteira = rs.getInt("id");
                    double saldo = rs.getDouble("saldo");
                    String nome = rs.getString("nome");
                    String username = rs.getString("username");
                    String email = rs.getString("email");
                    boolean ativo = rs.getBoolean("ativo");
        %>

            <tr>
                <td><%= idCarteira %></td>
                <td><%= nome %></td>
                <td><%= username %></td>
                <td><%= email != null ? email : "-" %></td>
                <td><strong><%= String.format("%.2f", saldo) %> €</strong></td>
                <td>
                    <% if (ativo) { %>
                        <span class="badge">Ativo</span>
                    <% } else { %>
                        <span class="badge badge-inativo">Inativo</span>
                    <% } %>
                </td>
            </tr>

        <%
                }

                if (!temCarteiras) {
        %>

            <tr>
                <td colspan="6" class="sem-dados">Não existem carteiras de clientes registadas.</td>
            </tr>

        <%
                }

            } catch (Exception e) {
                e.printStackTrace();
        %>

            <tr>
                <td colspan="6" class="sem-dados">Erro ao carregar carteiras.</td>
            </tr>

        <%
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

        </tbody>
    </table>

    <h2>Últimos Movimentos</h2>

    <table class="tabela">
        <thead>
            <tr>
                <th>ID</th>
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
            Connection connMov = null;
            PreparedStatement psMov = null;
            ResultSet rsMov = null;

            try {
                connMov = ligarBD();

                String sqlMov =
                    "SELECT m.id, m.tipo_operacao, m.valor, m.data_movimento, m.descricao, " +
                    "co.nome AS origem, cd.nome AS destino " +
                    "FROM movimentos_carteira m " +
                    "LEFT JOIN carteiras co ON m.carteira_origem_id = co.id " +
                    "LEFT JOIN carteiras cd ON m.carteira_destino_id = cd.id " +
                    "ORDER BY m.data_movimento DESC " +
                    "LIMIT 10";

                psMov = connMov.prepareStatement(sqlMov);
                rsMov = psMov.executeQuery();

                boolean temMovimentos = false;

                while (rsMov.next()) {
                    temMovimentos = true;
        %>

            <tr>
                <td><%= rsMov.getInt("id") %></td>
                <td><span class="badge"><%= rsMov.getString("tipo_operacao") %></span></td>
                <td><%= String.format("%.2f", rsMov.getDouble("valor")) %> €</td>
                <td><%= rsMov.getString("data_movimento") %></td>
                <td><%= rsMov.getString("origem") != null ? rsMov.getString("origem") : "-" %></td>
                <td><%= rsMov.getString("destino") != null ? rsMov.getString("destino") : "-" %></td>
                <td><%= rsMov.getString("descricao") %></td>
            </tr>

        <%
                }

                if (!temMovimentos) {
        %>

            <tr>
                <td colspan="7" class="sem-dados">Ainda não existem movimentos registados.</td>
            </tr>

        <%
                }

            } catch (Exception e) {
                e.printStackTrace();
        %>

            <tr>
                <td colspan="7" class="sem-dados">Erro ao carregar movimentos.</td>
            </tr>

        <%
            } finally {
                try {
                    if (rsMov != null) rsMov.close();
                    if (psMov != null) psMov.close();
                    if (connMov != null) connMov.close();
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        %>

        </tbody>
    </table>

    <div class="links">
        <p><a href="dashboard_funcionario.jsp">Voltar à área do funcionário</a></p>
        <p><a href="logout.jsp">Terminar sessão</a></p>
    </div>

</div>

</body>
</html>