<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ include file="../basedados/basedados.h" %>

<%
    /*
     * Página de perfil do cliente.
     * Permite consultar e editar os dados pessoais.
     * A password nunca é mostrada no formulário.
     * Só é alterada se o cliente escrever uma nova password.
     */

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

    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    try {
        conn = ligarBD();

        /*
         * Se o formulário foi submetido, atualiza os dados.
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

                /*
                 * Se a password estiver vazia, atualiza apenas os dados pessoais.
                 */
                if (novaPassword == null || novaPassword.trim().isEmpty()) {

                    String sqlUpdate =
                        "UPDATE utilizadores " +
                        "SET nome = ?, email = ?, telefone = ?, morada = ? " +
                        "WHERE id = ? AND perfil = 'cliente'";

                    ps = conn.prepareStatement(sqlUpdate);
                    ps.setString(1, novoNome);
                    ps.setString(2, novoEmail);
                    ps.setString(3, novoTelefone);
                    ps.setString(4, novaMorada);
                    ps.setInt(5, userId);

                    ps.executeUpdate();
                    ps.close();

                } else {

                    /*
                     * Se o cliente escreveu uma nova password,
                     * gera hash e atualiza também a password.
                     * A função gerarHash() deve estar no basedados.h.
                     */
                    String passwordEmHash = gerarHash(novaPassword);

                    String sqlUpdate =
                        "UPDATE utilizadores " +
                        "SET nome = ?, email = ?, telefone = ?, morada = ?, password = ? " +
                        "WHERE id = ? AND perfil = 'cliente'";

                    ps = conn.prepareStatement(sqlUpdate);
                    ps.setString(1, novoNome);
                    ps.setString(2, novoEmail);
                    ps.setString(3, novoTelefone);
                    ps.setString(4, novaMorada);
                    ps.setString(5, passwordEmHash);
                    ps.setInt(6, userId);

                    ps.executeUpdate();
                    ps.close();
                }

                session.setAttribute("nome", novoNome);
                sucesso = "Dados atualizados com sucesso.";
            }
        }

        /*
         * Vai buscar os dados atuais do cliente.
         * A password NÃO é selecionada, para nunca aparecer no formulário.
         */
        String sqlDados =
            "SELECT username, nome, email, telefone, morada " +
            "FROM utilizadores " +
            "WHERE id = ? AND perfil = 'cliente'";

        ps = conn.prepareStatement(sqlDados);
        ps.setInt(1, userId);
        rs = ps.executeQuery();

        if (rs.next()) {
            username = rs.getString("username");
            nome = rs.getString("nome");
            email = rs.getString("email");
            telefone = rs.getString("telefone");
            morada = rs.getString("morada");
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

    if (username == null) username = "";
    if (nome == null) nome = "";
    if (email == null) email = "";
    if (telefone == null) telefone = "";
    if (morada == null) morada = "";
%>

<!DOCTYPE html>
<html lang="pt">
<head>
    <meta charset="UTF-8">
    <title>Perfil do Cliente - FelixUberShop</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <link rel="stylesheet" href="style.css">

    <style>
        .container {
            max-width: 550px !important;
            width: 100% !important;
            margin: 40px auto;
            padding: 25px;
            box-sizing: border-box;
        }

        .form-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 15px;
        }

        .campo-total {
            grid-column: span 2;
        }

        .form-group input,
        .form-group textarea {
            width: 100%;
            box-sizing: border-box;
            padding: 8px;
        }

        .botao-container {
            grid-column: span 2;
            text-align: center;
            margin-top: 15px;
        }

        .botao-container input[type="submit"] {
            width: 100%;
            padding: 10px;
            cursor: pointer;
            font-weight: bold;
        }

        .info-password {
            font-size: 11px;
            color: #777;
            display: block;
            margin-top: 3px;
        }

        .links {
            text-align: center;
            margin-top: 20px;
        }

        @media (max-width: 600px) {
            .form-grid {
                grid-template-columns: 1fr;
            }

            .campo-total,
            .botao-container {
                grid-column: span 1;
            }
        }
    </style>
</head>
<body>

<div class="container">

    <div class="header" style="text-align: center; margin-bottom: 20px;">
        <h1 style="margin: 0 0 5px 0;">O Meu Perfil</h1>
        <p style="margin: 0; color: #666;">Consulte e edite os seus dados.</p>
    </div>

    <% if (!erro.equals("")) { %>
        <div class="erro"><%= erro %></div>
    <% } %>

    <% if (!sucesso.equals("")) { %>
        <div class="sucesso"><%= sucesso %></div>
    <% } %>

    <form method="post" action="perfil_cliente.jsp">

        <div class="form-grid">

            <div class="form-group campo-total">
                <label>Username</label>
                <input type="text" value="<%= username %>" disabled>
            </div>

            <div class="form-group campo-total">
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

            <div class="form-group campo-total">
                <label for="morada">Morada</label>
                <textarea id="morada" name="morada" rows="2"><%= morada %></textarea>
            </div>

            <div class="form-group campo-total">
                <label for="password">Nova Password</label>
                <input type="password"
                       id="password"
                       name="password"
                       value=""
                       autocomplete="new-password"
                       placeholder="Nova Password">
            </div>

            <div class="botao-container">
                <input type="submit" value="Guardar Alterações">
            </div>

        </div>

    </form>

    <div class="links">
        <hr style="border: 0; border-top: 1px solid #eee; margin-bottom: 15px;">
        <p>
            <a href="dashboard_cliente.jsp">Voltar à área do cliente</a>
            |
            <a href="logout.jsp">Terminar sessão</a>
        </p>
    </div>

</div>

</body>
</html>