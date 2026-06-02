<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ include file="../basedados/basedados.h" %>

<%
    String perfil = (String) session.getAttribute("perfil");
    Integer userId = (Integer) session.getAttribute("user_id");

    if (perfil == null || !perfil.equals("cliente") || userId == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String idTexto = request.getParameter("id");

    if (idTexto == null || idTexto.trim().isEmpty()) {
        response.sendRedirect("minhas_encomendas.jsp");
        return;
    }

    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    try {
        int encomendaId = Integer.parseInt(idTexto);

        conn = ligarBD();
        conn.setAutoCommit(false);

        int carteiraClienteId = 0;
        int carteiraLojaId = 0;
        int produtoId = 0;
        int quantidade = 0;

        double total = 0.0;
        String estado = "";
        String codigoValidacao = "";

        /*
         * Buscar a encomenda e confirmar que pertence ao cliente autenticado.
         */
        String sqlEncomenda =
            "SELECT e.id, e.codigo_validacao, e.estado, e.total, ep.produto_id, ep.quantidade " +
            "FROM encomendas e " +
            "INNER JOIN encomenda_produtos ep ON e.id = ep.encomenda_id " +
            "WHERE e.id = ? AND e.cliente_id = ?";

        ps = conn.prepareStatement(sqlEncomenda);
        ps.setInt(1, encomendaId);
        ps.setInt(2, userId);
        rs = ps.executeQuery();

        if (rs.next()) {
            codigoValidacao = rs.getString("codigo_validacao");
            estado = rs.getString("estado");
            total = rs.getDouble("total");
            produtoId = rs.getInt("produto_id");
            quantidade = rs.getInt("quantidade");
        } else {
            conn.rollback();
            response.sendRedirect("minhas_encomendas.jsp");
            return;
        }

        rs.close();
        ps.close();

        /*
         * Apenas encomendas pendentes podem ser canceladas.
         */
        if (!estado.equals("pendente")) {
            conn.rollback();
            response.sendRedirect("minhas_encomendas.jsp");
            return;
        }

        /*
         * Buscar carteira do cliente.
         */
        String sqlCarteiraCliente =
            "SELECT id FROM carteiras WHERE utilizador_id = ? AND tipo = 'cliente'";

        ps = conn.prepareStatement(sqlCarteiraCliente);
        ps.setInt(1, userId);
        rs = ps.executeQuery();

        if (rs.next()) {
            carteiraClienteId = rs.getInt("id");
        } else {
            conn.rollback();
            response.sendRedirect("minhas_encomendas.jsp");
            return;
        }

        rs.close();
        ps.close();

        /*
         * Buscar carteira da loja.
         */
        String sqlCarteiraLoja =
            "SELECT id FROM carteiras WHERE tipo = 'loja' LIMIT 1";

        ps = conn.prepareStatement(sqlCarteiraLoja);
        rs = ps.executeQuery();

        if (rs.next()) {
            carteiraLojaId = rs.getInt("id");
        } else {
            conn.rollback();
            response.sendRedirect("minhas_encomendas.jsp");
            return;
        }

        rs.close();
        ps.close();

        /*
         * Atualizar estado da encomenda.
         */
        String sqlCancelar =
            "UPDATE encomendas SET estado = 'cancelada' WHERE id = ?";

        ps = conn.prepareStatement(sqlCancelar);
        ps.setInt(1, encomendaId);
        ps.executeUpdate();
        ps.close();

        /*
         * Repor stock do produto.
         */
        String sqlStock =
            "UPDATE produtos SET stock = stock + ? WHERE id = ?";

        ps = conn.prepareStatement(sqlStock);
        ps.setInt(1, quantidade);
        ps.setInt(2, produtoId);
        ps.executeUpdate();
        ps.close();

        /*
         * Devolver saldo ao cliente.
         */
        String sqlSaldoCliente =
            "UPDATE carteiras SET saldo = saldo + ? WHERE id = ?";

        ps = conn.prepareStatement(sqlSaldoCliente);
        ps.setDouble(1, total);
        ps.setInt(2, carteiraClienteId);
        ps.executeUpdate();
        ps.close();

        /*
         * Retirar saldo da carteira da loja.
         */
        String sqlSaldoLoja =
            "UPDATE carteiras SET saldo = saldo - ? WHERE id = ?";

        ps = conn.prepareStatement(sqlSaldoLoja);
        ps.setDouble(1, total);
        ps.setInt(2, carteiraLojaId);
        ps.executeUpdate();
        ps.close();

        /*
         * Registar movimento de devolução.
         */
        String sqlMovimento =
            "INSERT INTO movimentos_carteira " +
            "(carteira_origem_id, carteira_destino_id, tipo_operacao, valor, descricao) " +
            "VALUES (?, ?, 'devolucao', ?, ?)";

        ps = conn.prepareStatement(sqlMovimento);
        ps.setInt(1, carteiraLojaId);
        ps.setInt(2, carteiraClienteId);
        ps.setDouble(3, total);
        ps.setString(4, "Devolução por cancelamento da encomenda " + codigoValidacao);
        ps.executeUpdate();
        ps.close();

        conn.commit();

        response.sendRedirect("minhas_encomendas.jsp");

    } catch (Exception e) {
        e.printStackTrace();

        try {
            if (conn != null) {
                conn.rollback();
            }
        } catch (Exception ex) {
            ex.printStackTrace();
        }

        response.sendRedirect("minhas_encomendas.jsp");

    } finally {
        try {
            if (rs != null) rs.close();
            if (ps != null) ps.close();
            if (conn != null) {
                conn.setAutoCommit(true);
                conn.close();
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
%>