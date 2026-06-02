<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ include file="../basedados/basedados.h" %>

<%
    String perfil = (String) session.getAttribute("perfil");
    String nomeSessao = (String) session.getAttribute("nome");

    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    String erro = "";
%>

<!DOCTYPE html>
<html lang="pt">
<head>
    <meta charset="UTF-8">
    <title>Produtos - FelixUberShop</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <link rel="stylesheet" href="style.css">
</head>
<body>

<div class="container-produtos">

    <div class="topo-produtos">
        <h1>Produtos da FelixUberShop</h1>

        <% if (perfil != null) { %>
            <p>Olá, <%= nomeSessao %>. Consulte os nossos produtos disponíveis.</p>
        <% } else { %>
            <p>Consulte os produtos disponíveis na nossa mercearia.</p>
        <% } %>
    </div>

    <%
        try {
            conn = ligarBD();

            String sql = "SELECT * FROM produtos WHERE ativo = TRUE ORDER BY categoria, nome";
            ps = conn.prepareStatement(sql);
            rs = ps.executeQuery();
    %>

    <div class="grelha-produtos">

        <%
            boolean temProdutos = false;

            while (rs.next()) {
                temProdutos = true;

                String nome = rs.getString("nome");
                String descricao = rs.getString("descricao");
                String categoria = rs.getString("categoria");
                double preco = rs.getDouble("preco");
                int stock = rs.getInt("stock");
        %>

            <div class="produto-card">
                <span class="categoria"><%= categoria %></span>
                <h3><%= nome %></h3>
                <p class="descricao"><%= descricao %></p>
                <p class="preco"><%= String.format("%.2f", preco) %> €</p>
                <p class="stock">Stock disponível: <%= stock %> unidades</p>
            </div>

        <%
            }

            if (!temProdutos) {
        %>

            <div class="sem-produtos">
                <p>De momento não existem produtos disponíveis.</p>
            </div>

        <%
            }
        %>

    </div>

    <%
        } catch (Exception e) {
            erro = "Erro ao carregar os produtos.";
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

    <div class="nav-links">

        <% if (perfil == null) { %>
            <a href="index.jsp">Voltar ao início</a>
            <a href="login.jsp">Login</a>
        <% } else if (perfil.equals("cliente")) { %>
            <a href="dashboard_cliente.jsp">Voltar à área do cliente</a>
            <a href="nova_encomenda.jsp">Fazer encomenda</a>
        <% } else if (perfil.equals("funcionario")) { %>
            <a href="dashboard_funcionario.jsp">Voltar à área do funcionário</a>
        <% } else if (perfil.equals("admin")) { %>
            <a href="dashboard_admin.jsp">Voltar à administração</a>
            <a href="admin_produtos.jsp">Gerir produtos</a>
        <% } %>

    </div>

</div>

</body>
</html>