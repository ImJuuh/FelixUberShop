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

    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;
    String erro = "";
%>

<!DOCTYPE html>
<html lang="pt">
<head>
    <meta charset="UTF-8">
    <title>Minhas Encomendas - FelixUberShop</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <link rel="stylesheet" href="style.css">
</head>
<body>

<div class="container-tabela">

    <div class="header">
        <h1>Minhas Encomendas</h1>
        <p>Olá, <%= nomeSessao %>. Consulte aqui as suas encomendas.</p>
    </div>

    <%
        try {
            conn = ligarBD();

            String sql =
                "SELECT e.id, e.codigo_validacao, e.data_encomenda, e.estado, e.total, " +
                "p.nome AS produto, ep.quantidade, ep.preco_unitario " +
                "FROM encomendas e " +
                "INNER JOIN encomenda_produtos ep ON e.id = ep.encomenda_id " +
                "INNER JOIN produtos p ON ep.produto_id = p.id " +
                "WHERE e.cliente_id = ? " +
                "ORDER BY e.data_encomenda DESC";

            ps = conn.prepareStatement(sql);
            ps.setInt(1, userId);
            rs = ps.executeQuery();

            boolean temEncomendas = false;
    %>

    <table class="tabela">
        <thead>
            <tr>
                <th>Código</th>
                <th>Data</th>
                <th>Produto</th>
                <th>Qtd.</th>
                <th>Preço</th>
                <th>Total</th>
                <th>Estado</th>
                <th>Ação</th>
            </tr>
        </thead>

        <tbody>

        <%
            while (rs.next()) {
                temEncomendas = true;

                int encomendaId = rs.getInt("id");
                String codigo = rs.getString("codigo_validacao");
                String data = rs.getString("data_encomenda");
                String produto = rs.getString("produto");
                int quantidade = rs.getInt("quantidade");
                double preco = rs.getDouble("preco_unitario");
                double total = rs.getDouble("total");
                String estado = rs.getString("estado");
        %>

            <tr>
                <td><%= codigo %></td>
                <td><%= data %></td>
                <td><%= produto %></td>
                <td><%= quantidade %></td>
                <td><%= String.format("%.2f", preco) %> €</td>
                <td><%= String.format("%.2f", total) %> €</td>
                <td><span class="badge"><%= estado %></span></td>
                <td>
                    <% if (estado.equals("pendente")) { %>
                        <a class="btn-pequeno danger" href="cancelar_encomenda.jsp?id=<%= encomendaId %>">
                            Cancelar
                        </a>
                    <% } else { %>
                        -
                    <% } %>
                </td>
            </tr>

        <%
            }

            if (!temEncomendas) {
        %>

            <tr>
                <td colspan="8" class="sem-dados">Ainda não tem encomendas.</td>
            </tr>

        <%
            }
        %>

        </tbody>
    </table>

    <%
        } catch (Exception e) {
            erro = "Erro ao carregar encomendas.";
            e.printStackTrace();
    %>

        <div class="erro"><%= erro %></div>

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

    <div class="links">
        <p><a href="nova_encomenda.jsp">Fazer nova encomenda</a></p>
        <p><a href="dashboard_cliente.jsp">Voltar à área do cliente</a></p>
    </div>

</div>

</body>
</html>