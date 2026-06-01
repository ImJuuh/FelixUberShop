<%@ page contentType="text/html;charset=UTF-8" language="java" %>
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

    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    int carteiraId = 0;
    double saldo = 0.0;

    try {
        conn = ligarBD();

        /*
         * Buscar a carteira do cliente autenticado.
         */
        String sqlCarteira = "SELECT id, saldo FROM carteiras WHERE utilizador_id = ? AND tipo = 'cliente'";
        ps = conn.prepareStatement(sqlCarteira);
        ps.setInt(1, userId);
        rs = ps.executeQuery();

        if (rs.next()) {
            carteiraId = rs.getInt("id");
            saldo = rs.getDouble("saldo");
        } else {
            erro = "Carteira não encontrada.";
        }

        if (rs != null) rs.close();
        if (ps != null) ps.close();

        /*
         * Processar operações de adicionar ou levantar saldo.
         */
        if (request.getMethod().equalsIgnoreCase("POST") && carteiraId > 0) {

            String operacao = request.getParameter("operacao");
            String valorTexto = request.getParameter("valor");

            if (valorTexto == null || valorTexto.trim().isEmpty()) {
                erro = "Introduza um valor.";
            } else {

                double valor = Double.parseDouble(valorTexto);

                if (valor <= 0) {
                    erro = "O valor tem de ser superior a zero.";
                } else {

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
                        ps.setString(3, "Cliente adicionou saldo à carteira.");
                        ps.executeUpdate();
                        ps.close();

                        sucesso = "Saldo adicionado com sucesso.";

                    } else if ("levantar".equals(operacao)) {

                        /*
                         * Só permite levantar se houver saldo suficiente.
                         */
                        if (valor > saldo) {
                            erro = "Saldo insuficiente para levantar esse valor.";
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
                            ps.setString(3, "Cliente levantou saldo da carteira.");
                            ps.executeUpdate();
                            ps.close();

                            sucesso = "Saldo levantado com sucesso.";
                        }

                    } else {
                        erro = "Operação inválida.";
                    }

                    /*
                     * Atualiza o saldo apresentado após a operação.
                     */
                    String sqlNovoSaldo = "SELECT saldo FROM carteiras WHERE id = ?";
                    ps = conn.prepareStatement(sqlNovoSaldo);
                    ps.setInt(1, carteiraId);
                    rs = ps.executeQuery();

                    if (rs.next()) {
                        saldo = rs.getDouble("saldo");
                    }

                    rs.close();
                    ps.close();
                }
            }
        }

    } catch (NumberFormatException e) {
        erro = "Valor inválido. Use apenas números.";
        e.printStackTrace();

    } catch (Exception e) {
        erro = "Erro ao processar a carteira.";
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
%>

<!DOCTYPE html>
<html lang="pt">
<head>
    <meta charset="UTF-8">
    <title>Carteira - FelixUberShop</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <link rel="stylesheet" href="style.css">

    <style>
        .saldo-box {
            background: #e8f5e9;
            border: 1px solid #b7dfb9;
            padding: 25px;
            border-radius: 12px;
            text-align: center;
            margin-bottom: 25px;
        }

        .saldo-box h2 {
            margin: 0;
            color: #2e7d32;
            font-size: 32px;
        }

        .saldo-box p {
            margin-top: 8px;
            color: #555;
        }

        .botoes-operacao {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 12px;
            margin-top: 15px;
        }

        .btn-secundario {
            display: inline-block;
            text-align: center;
            padding: 12px;
            background: #eeeeee;
            color: #333;
            border-radius: 8px;
            text-decoration: none;
            font-weight: 600;
        }

        .btn-secundario:hover {
            background: #dddddd;
        }
    </style>
</head>
<body>

<div class="container">

    <div class="header">
        <h1>Carteira</h1>
        <p>Olá, <%= nomeSessao %>. Aqui pode gerir o seu saldo.</p>
    </div>

    <% if (!erro.equals("")) { %>
        <div class="erro"><%= erro %></div>
    <% } %>

    <% if (!sucesso.equals("")) { %>
        <div class="sucesso"><%= sucesso %></div>
    <% } %>

    <div class="saldo-box">
        <h2><%= String.format("%.2f", saldo) %> €</h2>
        <p>Saldo disponível</p>
    </div>

    <form method="post" action="carteira.jsp">

        <div class="form-group">
            <label for="valor">Valor</label>
            <input type="number" step="0.01" min="0.01" id="valor" name="valor" placeholder="Exemplo: 10.00">
        </div>

        <div class="form-group">
            <label for="operacao">Operação</label>
            <select id="operacao" name="operacao">
                <option value="adicionar">Adicionar saldo</option>
                <option value="levantar">Levantar saldo</option>
            </select>
        </div>

        <input type="submit" value="Confirmar Operação">

    </form>

    <div class="links">
        <p><a href="dashboard_cliente.jsp">Voltar à área do cliente</a></p>
        <p><a href="logout.jsp">Terminar sessão</a></p>
    </div>

</div>

</body>
</html>