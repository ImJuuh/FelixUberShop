<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ include file="../basedados/basedados.h" %>

<%
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

    String acao = request.getParameter("acao");

    String editId = "";
    String editUsername = "";
    String editNome = "";
    String editEmail = "";
    String editTelefone = "";
    String editMorada = "";
    String editPerfil = "";

    try {
        conn = ligarBD();

        /*
         * Inativar utilizador.
         */
        if ("inativar".equals(acao)) {
            String id = request.getParameter("id");

            String sql = "UPDATE utilizadores SET ativo = FALSE WHERE id = ?";
            ps = conn.prepareStatement(sql);
            ps.setInt(1, Integer.parseInt(id));
            ps.executeUpdate();
            ps.close();

            sucesso = "Utilizador inativado com sucesso.";
        }

        /*
         * Reativar utilizador.
         */
        if ("reativar".equals(acao)) {
            String id = request.getParameter("id");

            String sql = "UPDATE utilizadores SET ativo = TRUE WHERE id = ?";
            ps = conn.prepareStatement(sql);
            ps.setInt(1, Integer.parseInt(id));
            ps.executeUpdate();
            ps.close();

            sucesso = "Utilizador reativado com sucesso.";
        }

        /*
         * Carregar dados do utilizador para edição.
         */
        if ("editar".equals(acao)) {
            String id = request.getParameter("id");

            String sql = "SELECT * FROM utilizadores WHERE id = ?";
            ps = conn.prepareStatement(sql);
            ps.setInt(1, Integer.parseInt(id));
            rs = ps.executeQuery();

            if (rs.next()) {
                editId = rs.getString("id");
                editUsername = rs.getString("username");
                editNome = rs.getString("nome");
                editEmail = rs.getString("email");
                editTelefone = rs.getString("telefone");
                editMorada = rs.getString("morada");
                editPerfil = rs.getString("perfil");
            }

            rs.close();
            ps.close();
        }

        /*
         * Atualizar dados do utilizador.
         */
        if (request.getMethod().equalsIgnoreCase("POST")) {

            String idUtilizador = request.getParameter("id_utilizador");
            String nome = request.getParameter("nome");
            String email = request.getParameter("email");
            String telefone = request.getParameter("telefone");
            String morada = request.getParameter("morada");
            String novoPerfil = request.getParameter("perfil");

            if (idUtilizador == null || idUtilizador.trim().isEmpty() ||
                nome == null || nome.trim().isEmpty() ||
                novoPerfil == null || novoPerfil.trim().isEmpty()) {

                erro = "Preencha os campos obrigatórios.";

            } else {

                String sql =
                    "UPDATE utilizadores SET nome = ?, email = ?, telefone = ?, morada = ?, perfil = ? " +
                    "WHERE id = ?";

                ps = conn.prepareStatement(sql);
                ps.setString(1, nome);
                ps.setString(2, email);
                ps.setString(3, telefone);
                ps.setString(4, morada);
                ps.setString(5, novoPerfil);
                ps.setInt(6, Integer.parseInt(idUtilizador));

                ps.executeUpdate();
                ps.close();

                sucesso = "Utilizador atualizado com sucesso.";

                editId = "";
                editUsername = "";
                editNome = "";
                editEmail = "";
                editTelefone = "";
                editMorada = "";
                editPerfil = "";
            }
        }

    } catch (Exception e) {
        erro = "Erro ao gerir utilizadores.";
        e.printStackTrace();
    }
%>

<!DOCTYPE html>
<html lang="pt">
<head>
    <meta charset="UTF-8">
    <title>Gestão de Utilizadores - FelixUberShop</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <link rel="stylesheet" href="style.css">
</head>
<body>

<div class="container-tabela">

    <div class="header">
        <h1>Gestão de Utilizadores</h1>
        <p>Olá, <%= nomeSessao %>. Aqui pode gerir os utilizadores da aplicação.</p>
    </div>

    <% if (!erro.equals("")) { %>
        <div class="erro"><%= erro %></div>
    <% } %>

    <% if (!sucesso.equals("")) { %>
        <div class="sucesso"><%= sucesso %></div>
    <% } %>

    <% if (!editId.equals("")) { %>

        <div class="form-admin-box">

            <h2>Editar Utilizador</h2>

            <form method="post" action="admin_utilizadores.jsp">

                <input type="hidden" name="id_utilizador" value="<%= editId %>">

                <div class="form-group">
                    <label>Username</label>
                    <input type="text" value="<%= editUsername %>" disabled>
                </div>

                <div class="form-group">
                    <label for="nome">Nome *</label>
                    <input type="text" id="nome" name="nome" value="<%= editNome %>">
                </div>

                <div class="form-row">
                    <div class="form-group">
                        <label for="email">Email</label>
                        <input type="email" id="email" name="email" value="<%= editEmail %>">
                    </div>

                    <div class="form-group">
                        <label for="telefone">Telefone</label>
                        <input type="text" id="telefone" name="telefone" value="<%= editTelefone %>">
                    </div>
                </div>

                <div class="form-group">
                    <label for="morada">Morada</label>
                    <textarea id="morada" name="morada" rows="3"><%= editMorada %></textarea>
                </div>

                <div class="form-group">
                    <label for="perfil">Perfil *</label>
                    <select id="perfil" name="perfil">
                        <option value="cliente" <%= editPerfil.equals("cliente") ? "selected" : "" %>>Cliente</option>
                        <option value="funcionario" <%= editPerfil.equals("funcionario") ? "selected" : "" %>>Funcionário</option>
                        <option value="admin" <%= editPerfil.equals("admin") ? "selected" : "" %>>Administrador</option>
                    </select>
                </div>

                <input type="submit" value="Guardar Alterações">

                <div class="links">
                    <p><a href="admin_utilizadores.jsp">Cancelar edição</a></p>
                </div>

            </form>

        </div>

    <% } %>

    <h2>Lista de Utilizadores</h2>

    <table class="tabela">
        <thead>
            <tr>
                <th>ID</th>
                <th>Username</th>
                <th>Nome</th>
                <th>Email</th>
                <th>Telefone</th>
                <th>Perfil</th>
                <th>Estado</th>
                <th>Ações</th>
            </tr>
        </thead>

        <tbody>

        <%
            try {
                String sqlLista = "SELECT * FROM utilizadores ORDER BY id ASC";
                ps = conn.prepareStatement(sqlLista);
                rs = ps.executeQuery();

                boolean temUtilizadores = false;

                while (rs.next()) {
                    temUtilizadores = true;

                    int id = rs.getInt("id");
                    String username = rs.getString("username");
                    String nome = rs.getString("nome");
                    String email = rs.getString("email");
                    String telefone = rs.getString("telefone");
                    String perfilUser = rs.getString("perfil");
                    boolean ativo = rs.getBoolean("ativo");
        %>

            <tr>
                <td><%= id %></td>
                <td><%= username %></td>
                <td><%= nome %></td>
                <td><%= email != null ? email : "-" %></td>
                <td><%= telefone != null ? telefone : "-" %></td>
                <td>
                    <% if (perfilUser.equals("admin")) { %>
                        <span class="badge badge-admin">Admin</span>
                    <% } else if (perfilUser.equals("funcionario")) { %>
                        <span class="badge badge-funcionario">Funcionário</span>
                    <% } else { %>
                        <span class="badge badge-cliente">Cliente</span>
                    <% } %>
                </td>
                <td>
                    <% if (ativo) { %>
                        <span class="badge">Ativo</span>
                    <% } else { %>
                        <span class="badge badge-inativo">Inativo</span>
                    <% } %>
                </td>
                <td>
                    <a class="btn-pequeno" href="admin_utilizadores.jsp?acao=editar&id=<%= id %>">Editar</a>

                    <% if (ativo) { %>
                        <a class="btn-pequeno danger"
                           href="admin_utilizadores.jsp?acao=inativar&id=<%= id %>"
                           onclick="return confirm('Tem a certeza que deseja inativar este utilizador?');">
                            Inativar
                        </a>
                    <% } else { %>
                        <a class="btn-pequeno"
                           href="admin_utilizadores.jsp?acao=reativar&id=<%= id %>"
                           onclick="return confirm('Tem a certeza que deseja reativar este utilizador?');">
                            Reativar
                        </a>
                    <% } %>
                </td>
            </tr>

        <%
                }

                if (!temUtilizadores) {
        %>

            <tr>
                <td colspan="8" class="sem-dados">Não existem utilizadores registados.</td>
            </tr>

        <%
                }

            } catch (Exception e) {
                e.printStackTrace();
        %>

            <tr>
                <td colspan="8" class="sem-dados">Erro ao carregar utilizadores.</td>
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

    <div class="links">
        <p><a href="dashboard_admin.jsp">Voltar à administração</a></p>
        <p><a href="logout.jsp">Terminar sessão</a></p>
    </div>

</div>

</body>
</html>