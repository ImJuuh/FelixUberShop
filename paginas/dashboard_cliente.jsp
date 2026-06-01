<%@ page contentType="text/html;charset=UTF-8" language="java" %>

<%
    String perfil = (String) session.getAttribute("perfil");
    String nome = (String) session.getAttribute("nome");

    if (perfil == null || !perfil.equals("cliente")) {
        response.sendRedirect("login.jsp");
        return;
    }
%>

<!DOCTYPE html>
<html lang="pt">
<head>
    <meta charset="UTF-8">
    <title>Área Cliente</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>

<div class="container">
    <div class="header">
        <h1>Área do Cliente</h1>
        <p>Bem-vindo, <%= nome %></p>
    </div>

    <p>Login de cliente feito com sucesso.</p>

    <div class="links">
        <p><a href="logout.jsp">Terminar sessão</a></p>
    </div>
</div>

</body>
</html>