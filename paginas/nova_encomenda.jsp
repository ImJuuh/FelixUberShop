<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ page import="java.util.*" %>
<%@ include file="../basedados/basedados.h" %>

<%
    request.setCharacterEncoding("UTF-8");

    String perfil = (String) session.getAttribute("perfil");
    Integer userId = (Integer) session.getAttribute("user_id");

    if (perfil == null || !perfil.equals("cliente") || userId == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String erro = "";
    String sucesso = "";

    ArrayList<Integer> ids = new ArrayList<Integer>();
    ArrayList<String> nomes = new ArrayList<String>();
    ArrayList<String> descricoes = new ArrayList<String>();
    ArrayList<String> categorias = new ArrayList<String>();
    ArrayList<Double> precos = new ArrayList<Double>();
    ArrayList<Integer> stocks = new ArrayList<Integer>();

    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    try {
        conn = ligarBD();

        /*
         * Carregar produtos ativos.
         */
        String sqlProdutos =
            "SELECT id, nome, descricao, preco, stock, categoria " +
            "FROM produtos " +
            "WHERE ativo = TRUE " +
            "ORDER BY categoria, nome";

        ps = conn.prepareStatement(sqlProdutos);
        rs = ps.executeQuery();

        while (rs.next()) {
            ids.add(rs.getInt("id"));
            nomes.add(rs.getString("nome"));
            descricoes.add(rs.getString("descricao"));
            categorias.add(rs.getString("categoria"));
            precos.add(rs.getDouble("preco"));
            stocks.add(rs.getInt("stock"));
        }

        rs.close();
        ps.close();

        /*
         * Criar encomenda com vários produtos.
         */
        if (request.getMethod().equalsIgnoreCase("POST")) {

            ArrayList<Integer> produtosSelecionados = new ArrayList<Integer>();
            ArrayList<Integer> quantidadesSelecionadas = new ArrayList<Integer>();
            ArrayList<Double> precosSelecionados = new ArrayList<Double>();

            double total = 0.0;

            for (int i = 0; i < ids.size(); i++) {

                int produtoId = ids.get(i);
                int stockAtual = stocks.get(i);
                double preco = precos.get(i);

                String quantidadeTexto = request.getParameter("qtd_" + produtoId);
                int quantidade = 0;

                try {
                    if (quantidadeTexto != null && !quantidadeTexto.trim().isEmpty()) {
                        quantidade = Integer.parseInt(quantidadeTexto);
                    }
                } catch (Exception e) {
                    quantidade = 0;
                }

                if (quantidade > 0) {

                    if (quantidade > stockAtual) {
                        erro = "Stock insuficiente para o produto: " + nomes.get(i);
                        break;
                    }

                    produtosSelecionados.add(produtoId);
                    quantidadesSelecionadas.add(quantidade);
                    precosSelecionados.add(preco);

                    total = total + (preco * quantidade);
                }
            }

            if (erro.equals("") && produtosSelecionados.size() == 0) {
                erro = "Tem de escolher pelo menos um produto.";
            }

            if (erro.equals("")) {

                conn.setAutoCommit(false);

                int carteiraClienteId = 0;
                int carteiraLojaId = 0;
                double saldoCliente = 0.0;

                /*
                 * Buscar carteira do cliente.
                 */
                String sqlCarteiraCliente =
                    "SELECT id, saldo " +
                    "FROM carteiras " +
                    "WHERE utilizador_id = ? AND tipo = 'cliente'";

                ps = conn.prepareStatement(sqlCarteiraCliente);
                ps.setInt(1, userId);
                rs = ps.executeQuery();

                if (rs.next()) {
                    carteiraClienteId = rs.getInt("id");
                    saldoCliente = rs.getDouble("saldo");
                } else {
                    erro = "Carteira do cliente não encontrada.";
                }

                rs.close();
                ps.close();

                /*
                 * Buscar carteira da loja.
                 */
                if (erro.equals("")) {
                    String sqlCarteiraLoja =
                        "SELECT id " +
                        "FROM carteiras " +
                        "WHERE tipo = 'loja' " +
                        "LIMIT 1";

                    ps = conn.prepareStatement(sqlCarteiraLoja);
                    rs = ps.executeQuery();

                    if (rs.next()) {
                        carteiraLojaId = rs.getInt("id");
                    } else {
                        erro = "Carteira da loja não encontrada.";
                    }

                    rs.close();
                    ps.close();
                }

                /*
                 * Verificar saldo.
                 */
                if (erro.equals("") && saldoCliente < total) {
                    erro = "Saldo insuficiente. Total da encomenda: " +
                           String.format("%.2f", total) + " €";
                }

                if (erro.equals("")) {

                    /*
                     * Criar encomenda principal.
                     */
                    String codigoValidacao = "ENC-" + System.currentTimeMillis();

                    String sqlEncomenda =
                        "INSERT INTO encomendas " +
                        "(codigo_validacao, cliente_id, data_encomenda, estado, total) " +
                        "VALUES (?, ?, NOW(), 'pendente', ?)";

                    ps = conn.prepareStatement(sqlEncomenda, Statement.RETURN_GENERATED_KEYS);
                    ps.setString(1, codigoValidacao);
                    ps.setInt(2, userId);
                    ps.setDouble(3, total);
                    ps.executeUpdate();

                    rs = ps.getGeneratedKeys();

                    int encomendaId = 0;

                    if (rs.next()) {
                        encomendaId = rs.getInt(1);
                    }

                    rs.close();
                    ps.close();

                    /*
                     * Inserir os vários produtos da encomenda.
                     */
                    for (int i = 0; i < produtosSelecionados.size(); i++) {

                        int produtoId = produtosSelecionados.get(i);
                        int quantidade = quantidadesSelecionadas.get(i);
                        double precoUnitario = precosSelecionados.get(i);

                        String sqlItem =
                            "INSERT INTO encomenda_produtos " +
                            "(encomenda_id, produto_id, quantidade, preco_unitario) " +
                            "VALUES (?, ?, ?, ?)";

                        ps = conn.prepareStatement(sqlItem);
                        ps.setInt(1, encomendaId);
                        ps.setInt(2, produtoId);
                        ps.setInt(3, quantidade);
                        ps.setDouble(4, precoUnitario);
                        ps.executeUpdate();
                        ps.close();

                        /*
                         * Atualizar stock.
                         */
                        String sqlStock =
                            "UPDATE produtos " +
                            "SET stock = stock - ? " +
                            "WHERE id = ?";

                        ps = conn.prepareStatement(sqlStock);
                        ps.setInt(1, quantidade);
                        ps.setInt(2, produtoId);
                        ps.executeUpdate();
                        ps.close();
                    }

                    /*
                     * Retirar saldo ao cliente.
                     */
                    String sqlSaldoCliente =
                        "UPDATE carteiras " +
                        "SET saldo = saldo - ? " +
                        "WHERE id = ?";

                    ps = conn.prepareStatement(sqlSaldoCliente);
                    ps.setDouble(1, total);
                    ps.setInt(2, carteiraClienteId);
                    ps.executeUpdate();
                    ps.close();

                    /*
                     * Adicionar saldo à loja.
                     */
                    String sqlSaldoLoja =
                        "UPDATE carteiras " +
                        "SET saldo = saldo + ? " +
                        "WHERE id = ?";

                    ps = conn.prepareStatement(sqlSaldoLoja);
                    ps.setDouble(1, total);
                    ps.setInt(2, carteiraLojaId);
                    ps.executeUpdate();
                    ps.close();

                    /*
                     * Registar movimento.
                     */
                    String sqlMovimento =
                        "INSERT INTO movimentos_carteira " +
                        "(carteira_origem_id, carteira_destino_id, tipo_operacao, valor, descricao) " +
                        "VALUES (?, ?, 'pagamento', ?, ?)";

                    ps = conn.prepareStatement(sqlMovimento);
                    ps.setInt(1, carteiraClienteId);
                    ps.setInt(2, carteiraLojaId);
                    ps.setDouble(3, total);
                    ps.setString(4, "Pagamento da encomenda " + codigoValidacao);
                    ps.executeUpdate();
                    ps.close();

                    conn.commit();

                    sucesso = "Encomenda criada com sucesso. Código: " + codigoValidacao;
                }

                if (!erro.equals("")) {
                    conn.rollback();
                }

                conn.setAutoCommit(true);
            }
        }

    } catch (Exception e) {
        erro = "Erro ao criar encomenda.";
        e.printStackTrace();

        try {
            if (conn != null) {
                conn.rollback();
                conn.setAutoCommit(true);
            }
        } catch (Exception ex) {
            ex.printStackTrace();
        }

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
    <title>Nova Encomenda - FelixUberShop</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <style>
        * {
            box-sizing: border-box;
            font-family: 'Inter', Arial, sans-serif;
        }

        body {
            margin: 0;
            padding: 0;
            background: #f8fafc;
            color: #1f2937;
        }

        .topbar {
            background: white;
            border-bottom: 1px solid #e5e7eb;
            padding: 18px 35px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .topbar h2 {
            color: #10b981;
            margin: 0;
        }

        .topbar a {
            color: #10b981;
            text-decoration: none;
            font-weight: 700;
        }

        .page {
            width: 1200px;
            max-width: 95%;
            margin: 35px auto;
        }

        .hero {
            background: linear-gradient(135deg, #10b981, #059669);
            color: white;
            padding: 35px;
            border-radius: 8px;
            margin-bottom: 25px;
        }

        .hero h1 {
            margin: 0 0 8px 0;
            font-size: 32px;
        }

        .hero p {
            margin: 0;
            opacity: 0.95;
        }

        .mensagem {
            margin-bottom: 20px;
        }

        .erro {
            background: #fef2f2;
            color: #991b1b;
            border: 1px solid #fca5a5;
            padding: 14px;
            border-radius: 6px;
            font-weight: 600;
        }

        .sucesso {
            background: #ecfdf5;
            color: #047857;
            border: 1px solid #a7f3d0;
            padding: 14px;
            border-radius: 6px;
            font-weight: 600;
        }

        .categoria-bloco {
            margin-bottom: 35px;
        }

        .categoria-titulo {
            display: flex;
            align-items: center;
            gap: 12px;
            margin-bottom: 15px;
            border-bottom: 2px solid #d1fae5;
            padding-bottom: 8px;
        }

        .categoria-titulo h2 {
            color: #065f46;
            margin: 0;
            font-size: 24px;
        }

        .categoria-titulo span {
            background: #d1fae5;
            color: #065f46;
            padding: 5px 10px;
            border-radius: 5px;
            font-size: 13px;
            font-weight: 700;
        }

        .grid-produtos {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
            gap: 18px;
        }

        .produto-card {
            background: white;
            border: 1px solid #e5e7eb;
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 5px 16px rgba(0, 0, 0, 0.06);
            transition: 0.2s;
        }

        .produto-card:hover {
            transform: translateY(-4px);
            box-shadow: 0 10px 22px rgba(0, 0, 0, 0.10);
            border-color: #10b981;
        }

        .produto-img-fake {
            width: 100%;
            height: 155px;
            background: linear-gradient(135deg, #ecfdf5, #d1fae5);
            display: flex;
            align-items: center;
            justify-content: center;
            border-bottom: 1px solid #e5e7eb;
        }

        .produto-img-fake span {
            font-size: 58px;
        }

        .produto-info {
            padding: 16px;
        }

        .produto-info h3 {
            color: #065f46;
            margin: 0 0 8px 0;
            font-size: 18px;
        }

        .descricao {
            color: #6b7280;
            font-size: 13px;
            line-height: 1.4;
            min-height: 38px;
            margin-bottom: 12px;
        }

        .linha-dados {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 14px;
        }

        .preco {
            font-size: 20px;
            font-weight: 800;
            color: #047857;
        }

        .stock {
            font-size: 12px;
            color: #6b7280;
            background: #f3f4f6;
            padding: 5px 8px;
            border-radius: 5px;
        }

        .qtd-area label {
            display: block;
            font-size: 13px;
            font-weight: 700;
            margin-bottom: 6px;
            color: #374151;
        }

        .qtd-area input {
            width: 100%;
            padding: 10px;
            border: 1px solid #d1d5db;
            border-radius: 6px;
            font-size: 15px;
        }

        .barra-final {
            position: sticky;
            bottom: 0;
            background: white;
            border-top: 1px solid #e5e7eb;
            margin-top: 30px;
            padding: 18px 25px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            box-shadow: 0 -5px 18px rgba(0, 0, 0, 0.06);
            border-radius: 8px 8px 0 0;
        }

        .barra-final p {
            margin: 0;
            color: #6b7280;
            font-size: 14px;
        }

        .btn-submit {
            background: #10b981;
            color: white;
            padding: 14px 28px;
            border: none;
            border-radius: 6px;
            font-size: 15px;
            font-weight: 800;
            cursor: pointer;
        }

        .btn-submit:hover {
            background: #059669;
        }

        @media (max-width: 700px) {
            .topbar {
                flex-direction: column;
                gap: 10px;
                text-align: center;
            }

            .hero h1 {
                font-size: 25px;
            }

            .barra-final {
                flex-direction: column;
                gap: 12px;
            }

            .btn-submit {
                width: 100%;
            }
        }
    </style>
</head>
<body>

<div class="topbar">
    <h2>FelixUberShop</h2>
    <div>
        <a href="dashboard_cliente.jsp">Área do Cliente</a>
        |
        <a href="minhas_encomendas.jsp">Minhas Encomendas</a>
    </div>
</div>

<div class="page">

    <div class="hero">
        <h1>Nova Encomenda</h1>
        <p>Escolha os produtos por categoria e indique as quantidades pretendidas.</p>
    </div>

    <div class="mensagem">
        <% if (!erro.equals("")) { %>
            <div class="erro"><%= erro %></div>
        <% } %>

        <% if (!sucesso.equals("")) { %>
            <div class="sucesso"><%= sucesso %></div>
        <% } %>
    </div>

    <form method="post" action="nova_encomenda.jsp" accept-charset="UTF-8">

        <%
            String categoriaAtual = "";

            for (int i = 0; i < ids.size(); i++) {

                String cat = categorias.get(i);

                if (cat == null || cat.trim().isEmpty()) {
                    cat = "Outros";
                }

                if (!cat.equals(categoriaAtual)) {

                    if (!categoriaAtual.equals("")) {
        %>
                        </div>
                    </div>
        <%
                    }

                    categoriaAtual = cat;
        %>

                    <div class="categoria-bloco">
                        <div class="categoria-titulo">
                            <h2><%= categoriaAtual %></h2>
                            <span>Produtos disponíveis</span>
                        </div>

                        <div class="grid-produtos">

        <%
                }

                String emoji = "🛒";

                if (cat.equalsIgnoreCase("Fruta")) {
                    emoji = "🍎";
                } else if (cat.equalsIgnoreCase("Legumes")) {
                    emoji = "🥕";
                } else if (cat.equalsIgnoreCase("Laticínios")) {
                    emoji = "🥛";
                } else if (cat.equalsIgnoreCase("Mercearia")) {
                    emoji = "🛍️";
                } else if (cat.equalsIgnoreCase("Padaria")) {
                    emoji = "🥖";
                } else if (cat.equalsIgnoreCase("Bebidas")) {
                    emoji = "🥤";
                } else if (cat.equalsIgnoreCase("Limpeza")) {
                    emoji = "🧼";
                }
        %>

                            <div class="produto-card">

                                <div class="produto-img-fake">
                                    <span><%= emoji %></span>
                                </div>

                                <div class="produto-info">
                                    <h3><%= nomes.get(i) %></h3>

                                    <div class="descricao">
                                        <%= descricoes.get(i) %>
                                    </div>

                                    <div class="linha-dados">
                                        <span class="preco"><%= String.format("%.2f", precos.get(i)) %> €</span>
                                        <span class="stock">Stock: <%= stocks.get(i) %></span>
                                    </div>

                                    <div class="qtd-area">
                                        <label>Quantidade</label>
                                        <input type="number"
                                               name="qtd_<%= ids.get(i) %>"
                                               min="0"
                                               max="<%= stocks.get(i) %>"
                                               value="0">
                                    </div>
                                </div>
                            </div>

        <%
            }

            if (!categoriaAtual.equals("")) {
        %>
                        </div>
                    </div>
        <%
            }
        %>

        <div class="barra-final">
            <p>Coloque quantidade apenas nos produtos que quer encomendar.</p>
            <button type="submit" class="btn-submit">Criar Encomenda</button>
        </div>

    </form>

</div>

</body>
</html>