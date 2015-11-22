package Wahlinfo

import java.sql.DriverManager;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.ResultSet;
import java.io.PrintWriter
import java.io.File

object Helpers {
    /**
     *  Database-Connection loaner
     */
    def withDatabase[R](action:(Connection => Option[R]))(
            implicit connInfo:(String, Int, String, String, String)):Option[R] = {
        val (host, port, dbname, username, password) = connInfo

        var connection:Connection = null;
        var result:Option[R] = None

        try {
            Class.forName("org.postgresql.Driver");
            connection = DriverManager.getConnection(
               f"jdbc:postgresql://${host}:${port}/${dbname}",username, password);

            result = action(connection)
        } catch {
            case e:ClassNotFoundException => println("Driver not found.")
            case e:SQLException => println("SQL Exception:" + e)
            result = None
        } finally {
            if (connection != null) connection.close();
        }
        result
    }

    /**
     *  PrintWriter loaner
     */
    def withPrintWriter(f: File)(op: PrintWriter => Unit):Unit = {
        val p = new PrintWriter(f)
        try { op(p) } finally { p.close() }
    }
}
