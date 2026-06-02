<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ include file="../basedados/basedados.h" %>

<%
    /*
     * Página de administração de produtos.
     * Permite ao administrador inserir, editar, visualizar, inativar e reativar produtos.
     */

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
    String editNome = "";
    String editDescricao = "";
    String editPreco = "";
    String editStock = "";
    String editCategoria = "";

    try {
        conn = ligarBD();

        /*
         * Inativar produto.
         */
        if ("inativar".equals(acao)) {
            String id = request.getParameter("id");

            String sql = "UPDATE produtos SET ativo = FALSE WHERE id = ?";
            ps = conn.prepareStatement(sql);
            ps.setInt(1, Integer.parseInt(id));
            ps.executeUpdate();
            ps.close();

            sucesso = "Produto inativado com sucesso.";
        }

        /*
         * Reativar produto.
         */
        if ("reativar".equals(acao)) {
            String id = request.getParameter("id");

            String sql = "UPDATE produtos SET ativo = TRUE WHERE id = ?";
            ps = conn.prepareStatement(sql);
            ps.setInt(1, Integer.parseInt(id));
            ps.executeUpdate();
            ps.close();

            sucesso = "Produto reativado com sucesso.";
        }

        /*
         * Carregar produto para edição.
         */
        if ("editar".equals(acao)) {
            String id = request.getParameter("id");

            String sql = "SELECT * FROM produtos WHERE id = ?";
            ps = conn.prepareStatement(sql);
            ps.setInt(1, Integer.parseInt(id));
            rs = ps.executeQuery();

            if (rs.next()) {
                editId = rs.getString("id");
                editNome = rs.getString("nome");
                editDescricao = rs.getString("descricao");
                editPreco = rs.getString("preco");
                editStock = rs.getString("stock");
                editCategoria = rs.getString("categoria");
            }

            rs.close();
            ps.close();
        }

        /*
         * Inserir ou atualizar produto.
         */
        if (request.getMethod().equalsIgnoreCase("POST")) {

            String idProduto = request.getParameter("id_produto");
            String nome = request.getParameter("nome");
            String descricao = request.getParameter("descricao");
            String precoTexto = request.getParameter("preco");
            String stockTexto = request.getParameter("stock");
            String categoria = request.getParameter("categoria");

            if (nome == null || nome.trim().isEmpty() ||
                precoTexto == null || precoTexto.trim().isEmpty() ||
                stockTexto == null || stockTexto.trim().isEmpty()) {

                erro = "Preencha os campos obrigatórios.";

            } else {

                double preco = Double.parseDouble(precoTexto);
                int stock = Integer.parseInt(stockTexto);

                if (preco < 0 || stock < 0) {
                    erro = "O preço e o stock não podem ser negativos.";

                } else {

                    /*
                     * Atualizar produto existente.
                     */
                    if (idProduto != null && !idProduto.trim().isEmpty()) {

                        String sql =
                            "UPDATE produtos SET nome = ?, descricao = ?, preco = ?, stock = ?, categoria = ? " +
                            "WHERE id = ?";

                        ps = conn.prepareStatement(sql);
                        ps.setString(1, nome);
                        ps.setString(2, descricao);
                        ps.setDouble(3, preco);
                        ps.setInt(4, stock);
                        ps.setString(5, categoria);
                        ps.setInt(6, Integer.parseInt(idProduto));

                        ps.executeUpdate();
                        ps.close();

                        sucesso = "Produto atualizado com sucesso.";

                        editId = "";
                        editNome = "";
                        editDescricao = "";
                        editPreco = "";
                        editStock = "";
                        editCategoria = "";

                    } else {

                        /*
                         * Inserir novo produto.
                         */
                        String sql =
                            "INSERT INTO produtos (nome, descricao, preco, stock, categoria, ativo) " +
                            "VALUES (?, ?, ?, ?, ?, TRUE)";

                        ps = conn.prepareStatement(sql);
                        ps.setString(1, nome);
                        ps.setString(2, descricao);
                        ps.setDouble(3, preco);
                        ps.setInt(4, stock);
                        ps.setString(5, categoria);

                        ps.executeUpdate();
                        ps.close();

                        sucesso = "Produto inserido com sucesso.";
                    }
                }
            }
        }

    } catch (NumberFormatException e) {
        erro = "Preço ou stock inválido.";
        e.printStackTrace();

    } catch (Exception e) {
        erro = "Erro ao gerir produtos.";
        e.printStackTrace();
    }
%>

<!DOCTYPE html>
<html lang="pt">
<head>
    <meta charset="UTF-8">
    <title>Gestão de Produtos - FelixUberShop</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <link rel="stylesheet" href="style.css">
</head>
<body>

<div class="container-tabela">

    <div class="header">
        <h1>Gestão de Produtos</h1>
        <p>Olá, <%= nomeSessao %>. Aqui pode gerir os produtos da mercearia.</p>
    </div>

    <% if (!erro.equals("")) { %>
        <div class="erro"><%= erro %></div>
    <% } %>

    <% if (!sucesso.equals("")) { %>
        <div class="sucesso"><%= sucesso %></div>
    <% } %>

    <div class="form-admin-box">

        <% if (!editId.equals("")) { %>
            <h2>Editar Produto</h2>
        <% } else { %>
            <h2>Inserir Novo Produto</h2>
        <% } %>

        <form method="post" action="admin_produtos.jsp">

            <input type="hidden" name="id_produto" value="<%= editId %>">

            <div class="form-group">
                <label for="nome">Nome *</label>
                <input type="text" id="nome" name="nome" value="<%= editNome %>" placeholder="Nome do produto">
            </div>

            <div class="form-group">
                <label for="descricao">Descrição</label>
                <textarea id="descricao" name="descricao" rows="3" placeholder="Descrição do produto"><%= editDescricao %></textarea>
            </div>

            <div class="form-row">
                <div class="form-group">
                    <label for="preco">Preço *</label>
                    <input type="number" step="0.01" min="0" id="preco" name="preco" value="<%= editPreco %>" placeholder="0.00">
                </div>

                <div class="form-group">
                    <label for="stock">Stock *</label>
                    <input type="number" min="0" id="stock" name="stock" value="<%= editStock %>" placeholder="0">
                </div>
            </div>

            <div class="form-group">
                <label for="categoria">Categoria</label>
                <input type="text" id="categoria" name="categoria" value="<%= editCategoria %>" placeholder="Ex: Mercearia, Fruta, Laticínios">
            </div>

            <% if (!editId.equals("")) { %>
                <input type="submit" value="Guardar Alterações">

                <div class="links">
                    <p><a href="admin_produtos.jsp">Cancelar edição</a></p>
                </div>
            <% } else { %>
                <input type="submit" value="Inserir Produto">
            <% } %>

        </form>
    </div>

    <h2>Lista de Produtos</h2>

    <table class="tabela">
        <thead>
            <tr>
                <th>ID</th>
                <th>Produto</th>
                <th>Categoria</th>
                <th>Preço</th>
                <th>Stock</th>
                <th>Estado</th>
                <th>Ações</th>
            </tr>
        </thead>

        <tbody>

        <%
            try {
                String sqlLista = "SELECT * FROM produtos ORDER BY id DESC";
                ps = conn.prepareStatement(sqlLista);
                rs = ps.executeQuery();

                boolean temProdutos = false;

                while (rs.next()) {
                    temProdutos = true;

                    int id = rs.getInt("id");
                    String nome = rs.getString("nome");
                    String categoria = rs.getString("categoria");
                    double preco = rs.getDouble("preco");
                    int stock = rs.getInt("stock");
                    boolean ativo = rs.getBoolean("ativo");
        %>

            <tr>
                <td><%= id %></td>
                <td><%= nome %></td>
                <td><%= categoria %></td>
                <td><%= String.format("%.2f", preco) %> €</td>
                <td><%= stock %></td>
                <td>
                    <% if (ativo) { %>
                        <span class="badge">Ativo</span>
                    <% } else { %>
                        <span class="badge badge-inativo">Inativo</span>
                    <% } %>
                </td>
                <td>
                    <a class="btn-pequeno" href="admin_produtos.jsp?acao=editar&id=<%= id %>">Editar</a>

                    <% if (ativo) { %>
                        <a class="btn-pequeno danger"
                           href="admin_produtos.jsp?acao=inativar&id=<%= id %>"
                           onclick="return confirm('Tem a certeza que deseja inativar este produto?');">
                            Inativar
                        </a>
                    <% } else { %>
                        <a class="btn-pequeno"
                           href="admin_produtos.jsp?acao=reativar&id=<%= id %>"
                           onclick="return confirm('Tem a certeza que deseja reativar este produto?');">
                            Reativar
                        </a>
                    <% } %>
                </td>
            </tr>

        <%
                }

                if (!temProdutos) {
        %>

            <tr>
                <td colspan="7" class="sem-dados">Não existem produtos registados.</td>
            </tr>

        <%
                }

            } catch (Exception e) {
                e.printStackTrace();
        %>

            <tr>
                <td colspan="7" class="sem-dados">Erro ao carregar produtos.</td>
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
        <p><a href="produtos.jsp">Ver produtos no site</a></p>
        <p><a href="logout.jsp">Terminar sessão</a></p>
    </div>

</div>

</body>
</html>