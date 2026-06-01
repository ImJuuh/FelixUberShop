<%@ page import="java.sql.*" %>

<%!
    public Connection ligarBD() {
        Connection conn = null;

        try {
            Class.forName("com.mysql.cj.jdbc.Driver");

            conn = DriverManager.getConnection(
                "jdbc:mysql://localhost:3306/felixubershop?useUnicode=true&characterEncoding=UTF-8",
                "root",
                ""
            );

        } catch (Exception e) {
            e.printStackTrace();
        }

        return conn;
    }
%>