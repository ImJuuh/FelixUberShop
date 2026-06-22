<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ include file="../basedados/basedados.h" %>

<%
    String erro = "";
    String sucesso = "";

    if (request.getMethod().equalsIgnoreCase("POST")) {

        String username = request.getParameter("username");
        String password = request.getParameter("password");
        String nome = request.getParameter("nome");
        String email = request.getParameter("email");
        String telefone = request.getParameter("telefone");
        String morada = request.getParameter("morada");

        if (username == null || username.trim().isEmpty() ||
            password == null || password.trim().isEmpty() ||
            nome == null || nome.trim().isEmpty()) {

            erro = "Preencha todos os campos obrigatórios.";

        } else {

            Connection conn = null;
            PreparedStatement psVerificar = null;
            PreparedStatement psInserirUser = null;
            PreparedStatement psInserirCarteira = null;
            ResultSet rs = null;

            try {
                conn = ligarBD();

                /*
                 * Verifica se já existe um utilizador com o mesmo username.
                 */
                String sqlVerificar = "SELECT id FROM utilizadores WHERE username = ?";
                psVerificar = conn.prepareStatement(sqlVerificar);
                psVerificar.setString(1, username);

                rs = psVerificar.executeQuery();

                if (rs.next()) {
                    erro = "Esse username já está a ser utilizado.";

                } else {

                    /*
                     * Insere o novo utilizador com perfil de cliente.
                     */
                    String sqlInserirUser =
                        "INSERT INTO utilizadores (username, password, nome, email, telefone, morada, perfil, ativo) " +
                        "VALUES (?, ?, ?, ?, ?, ?, 'cliente', TRUE)";

                    psInserirUser = conn.prepareStatement(sqlInserirUser, Statement.RETURN_GENERATED_KEYS);
                    psInserirUser.setString(1, username);
                    psInserirUser.setString(2, gerarHash(password));
                    psInserirUser.setString(3, nome);
                    psInserirUser.setString(4, email);
                    psInserirUser.setString(5, telefone);
                    psInserirUser.setString(6, morada);

                    int linhas = psInserirUser.executeUpdate();

                    if (linhas > 0) {

                        ResultSet chaves = psInserirUser.getGeneratedKeys();

                        if (chaves.next()) {
                            int novoUserId = chaves.getInt(1);

                            /*
                             * Cria a carteira do novo cliente com saldo inicial 0.
                             */
                            String sqlCarteira =
                                "INSERT INTO carteiras (utilizador_id, nome, saldo, tipo) " +
                                "VALUES (?, ?, 0.00, 'cliente')";

                            psInserirCarteira = conn.prepareStatement(sqlCarteira);
                            psInserirCarteira.setInt(1, novoUserId);
                            psInserirCarteira.setString(2, "Carteira de " + nome);

                            psInserirCarteira.executeUpdate();

                            sucesso = "Registo efetuado com sucesso. Já pode iniciar sessão.";
                        }

                        if (chaves != null) {
                            chaves.close();
                        }

                    } else {
                        erro = "Não foi possível criar o utilizador.";
                    }
                }

            } catch (Exception e) {
                erro = "Erro ao efetuar o registo.";
                e.printStackTrace();

            } finally {
                try {
                    if (rs != null) rs.close();
                    if (psVerificar != null) psVerificar.close();
                    if (psInserirUser != null) psInserirUser.close();
                    if (psInserirCarteira != null) psInserirCarteira.close();
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
    <title>Registo - FelixUberShop</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <link rel="stylesheet" href="style.css">
</head>
<body>

<div class="container">

    <div class="header">
        <h1>FelixUberShop</h1>
        <p>Crie a sua conta de cliente</p>
    </div>

    <% if (!erro.equals("")) { %>
        <div class="erro"><%= erro %></div>
    <% } %>

    <% if (!sucesso.equals("")) { %>
        <div class="sucesso"><%= sucesso %></div>
    <% } %>

    <form method="post" action="registo.jsp">

        <div class="form-group">
            <label for="nome">Nome completo *</label>
            <input type="text" id="nome" name="nome" placeholder="Introduza o seu nome">
        </div>

        <div class="form-group">
            <label for="username">Username *</label>
            <input type="text" id="username" name="username" placeholder="Escolha um username">
        </div>

        <div class="form-group">
            <label for="password">Password *</label>
            <input type="password" id="password" name="password" placeholder="Escolha uma password">
        </div>

        <div class="form-group">
            <label for="email">Email</label>
            <input type="email" id="email" name="email" placeholder="exemplo@email.com">
        </div>

        <div class="form-group">
            <label for="telefone">Telefone</label>
            <input type="text" id="telefone" name="telefone" placeholder="910000000">
        </div>

        <div class="form-group">
            <label for="morada">Morada</label>
            <textarea id="morada" name="morada" rows="3" placeholder="Introduza a sua morada"></textarea>
        </div>

        <input type="submit" value="Criar Conta">

    </form>

    <div class="links">
        <p>Já tem conta? <a href="login.jsp">Iniciar sessão</a></p>
        <p><a href="index.jsp">Voltar ao início</a></p>
    </div>

</div>

</body>
</html>