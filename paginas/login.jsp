<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ include file="../basedados/basedados.h" %>

<%
    String erro = "";

    if (request.getMethod().equalsIgnoreCase("POST")) {

        String username = request.getParameter("username");
        String password = request.getParameter("password");

        if (username == null || username.trim().isEmpty() ||
            password == null || password.trim().isEmpty()) {

            erro = "Preencha todos os campos.";

        } else {

            Connection conn = null;
            PreparedStatement ps = null;
            ResultSet rs = null;

            try {
                conn = ligarBD();

                String sql = "SELECT * FROM utilizadores WHERE username = ? AND password = ? AND ativo = TRUE";
                ps = conn.prepareStatement(sql);
                ps.setString(1, username);
                ps.setString(2, password);

                rs = ps.executeQuery();

                if (rs.next()) {

                    int id = rs.getInt("id");
                    String nome = rs.getString("nome");
                    String perfil = rs.getString("perfil");

                    session.setAttribute("user_id", id);
                    session.setAttribute("username", username);
                    session.setAttribute("nome", nome);
                    session.setAttribute("perfil", perfil);

                    if (perfil.equals("cliente")) {
                        response.sendRedirect("dashboard_cliente.jsp");
                    } else if (perfil.equals("funcionario")) {
                        response.sendRedirect("dashboard_funcionario.jsp");
                    } else if (perfil.equals("admin")) {
                        response.sendRedirect("dashboard_admin.jsp");
                    }

                } else {
                    erro = "Username ou password incorretos.";
                }

            } catch (Exception e) {
                erro = "Erro ao tentar iniciar sessão.";
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
    }
%>

<!DOCTYPE html>
<html lang="pt">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login - FelixUberShop</title>

    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">

    <link rel="stylesheet" href="css/style.css">
</head>
<body>

<div class="container">

    <div class="header">
        <h1>FelixUberShop</h1>
        <p>Inicie sessão na sua conta para continuar</p>
    </div>

    <% if (!erro.equals("")) { %>
        <div class="erro"><%= erro %></div>
    <% } %>

    <form method="post" action="login.jsp">

        <div class="form-group">
            <label for="username">Username</label>
            <input type="text" id="username" name="username" placeholder="Introduza o username">
        </div>

        <div class="form-group">
            <label for="password">Password</label>
            <input type="password" id="password" name="password" placeholder="Introduza a password">
        </div>

        <input type="submit" value="Entrar na Conta">

    </form>

    <div class="links">
        <p>Ainda não tem conta? <a href="registo.jsp">Registar cliente</a></p>
        <p><a href="index.jsp">Voltar ao início</a></p>
    </div>

</div>

</body>
</html>