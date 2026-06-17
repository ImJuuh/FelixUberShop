<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ include file="../basedados/basedados.h" %>

<%
    String perfil = (String) session.getAttribute("perfil");
    Integer userId = (Integer) session.getAttribute("user_id");

    if (perfil == null || !perfil.equals("cliente") || userId == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String erro = "";
    String sucesso = "";

    String username = "";
    String nome = "";
    String email = "";
    String telefone = "";
    String morada = "";
    String password = "";

    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    try {
        conn = ligarBD();

        /*
         * Atualizar dados do cliente.
         */
        if (request.getMethod().equalsIgnoreCase("POST")) {

            String novoNome = request.getParameter("nome");
            String novoEmail = request.getParameter("email");
            String novoTelefone = request.getParameter("telefone");
            String novaMorada = request.getParameter("morada");
            String novaPassword = request.getParameter("password");

            if (novoNome == null || novoNome.trim().isEmpty()) {
                erro = "O nome é obrigatório.";

            } else {

                String sql =
                    "UPDATE utilizadores SET nome = ?, email = ?, telefone = ?, morada = ?, password = ? " +
                    "WHERE id = ? AND perfil = 'cliente'";

                ps = conn.prepareStatement(sql);
                ps.setString(1, novoNome);
                ps.setString(2, novoEmail);
                ps.setString(3, novoTelefone);
                ps.setString(4, novaMorada);
                ps.setString(5, novaPassword);
                ps.setInt(6, userId);

                ps.executeUpdate();
                ps.close();

                session.setAttribute("nome", novoNome);

                sucesso = "Dados atualizados com sucesso.";
            }
        }

        /*
         * Buscar dados atuais do cliente.
         */
        String sqlDados = "SELECT * FROM utilizadores WHERE id = ? AND perfil = 'cliente'";
        ps = conn.prepareStatement(sqlDados);
        ps.setInt(1, userId);
        rs = ps.executeQuery();

        if (rs.next()) {
            username = rs.getString("username");
            nome = rs.getString("nome");
            email = rs.getString("email");
            telefone = rs.getString("telefone");
            morada = rs.getString("morada");
            password = rs.getString("password");
        }

    } catch (Exception e) {
        erro = "Erro ao carregar ou atualizar os dados.";
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

    if (email == null) email = "";
    if (telefone == null) telefone = "";
    if (morada == null) morada = "";
    if (password == null) password = "";
%>

<!DOCTYPE html>
<html lang="pt">
<head>
    <meta charset="UTF-8">
    <title>Perfil do Cliente - FelixUberShop</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <link rel="stylesheet" href="style.css">
</head>
<body>

<div class="container">

    <div class="header">
        <h1>O Meu Perfil</h1>
        <p>Consulte e edite os seus dados pessoais.</p>
    </div>

    <% if (!erro.equals("")) { %>
        <div class="erro"><%= erro %></div>
    <% } %>

    <% if (!sucesso.equals("")) { %>
        <div class="sucesso"><%= sucesso %></div>
    <% } %>

    <form method="post" action="perfil_cliente.jsp">

        <div class="form-group">
            <label>Username</label>
            <input type="text" value="<%= username %>" disabled>
        </div>

        <div class="form-group">
            <label for="nome">Nome *</label>
            <input type="text" id="nome" name="nome" value="<%= nome %>" required>
        </div>

        <div class="form-group">
            <label for="email">Email</label>
            <input type="email" id="email" name="email" value="<%= email %>">
        </div>

        <div class="form-group">
            <label for="telefone">Telefone</label>
            <input type="text" id="telefone" name="telefone" value="<%= telefone %>">
        </div>

        <div class="form-group">
            <label for="morada">Morada</label>
            <textarea id="morada" name="morada" rows="3"><%= morada %></textarea>
        </div>

        <div class="form-group">
            <label for="password">Password</label>
            <input type="text" id="password" name="password" value="<%= password %>">
        </div>

        <input type="submit" value="Guardar Alterações">

    </form>

    <div class="links">
        <p><a href="dashboard_cliente.jsp">Voltar à área do cliente</a></p>
        <p><a href="logout.jsp">Terminar sessão</a></p>
    </div>

</div>

</body>
</html>