package Wahlinfo

import java.sql.ResultSet
import Generator._
import Helpers._

/** General configuration of the generator */
object GeneratorConfig {
    implicit val connInfo:(String, Int, String, String, String) = ("localhost", 5432, "wisdb", "postgres", "abc123")

    /**
     *  generates configs for every Wahlkreis of the given year
     *  @returns Map of WKID -> Config
     */
    def allWKConfigs(year:Int):Map[Int, GeneratorConfig] = {
        val wkids:List[Int] = withDatabase(conn => {
                val statement = conn.createStatement()
                val resultset:ResultSet = statement.executeQuery(
                    f"SELECT wkid FROM Wahlkreis WHERE year = ${year}")
                var result = List[Int]()

                while (resultset.next()) {
                    result ::= resultset.getInt("wkid")
                }
                resultset.close()
                statement.close()
                Some(result)
            }).getOrElse(Nil)
        wkids.map((wkid:Int) => (wkid, new GeneratorConfig(year, wkid))).toMap
    }

    /**
     *  Creates a single config for given Wahlkreis and year
     *  @returns Config Class instance
     */
    def singleWKConfig(year:Int, wkid:Int):GeneratorConfig = new GeneratorConfig(year, wkid)


    var _existingCitizens:List[String] = null
    /**
     *  Queries the database for Citizens that have not voted yet
     *  @returns List of IDNos
     */
    def existingCitizens:List[String] = {
        if (_existingCitizens == null) {
            _existingCitizens = withDatabase(conn => {
                val statement = conn.createStatement()
                val resultset:ResultSet = statement.executeQuery(
                    f"SELECT idno FROM hasVoted WHERE NOT hasVoted;")
                var result = List[String]()

                while (resultset.next()) {
                    result ::= resultset.getString("idno")
                }
                resultset.close()
                statement.close()
                Some(result)
            }).getOrElse(Nil)
        }
        _existingCitizens
    }
}

class GeneratorConfig(val year:Int, val wkid:Int) {
    import GeneratorConfig.connInfo

    /**
     *  Queries the database for the Erststimmen-Distribution
     *  @returns Map of Direktkandidat -> number of votes it got
     */
    def erststimmenDist:Map[Erststimme, Int] = {
        withDatabase(conn => {
            val statement = conn.createStatement()
            val resultset:ResultSet = statement.executeQuery(
                f"SELECT cid, votes FROM Candidacy NATURAL JOIN Wahlkreis WHERE year = ${year} AND wkid = ${wkid}")
            var result = Map[Erststimme, Int]()

            while (resultset.next()) {
                val cid:Int = resultset.getInt("cid")
                val votes:Int = resultset.getInt("votes")
                result += (new Candidacy(cid) -> votes)
            }
            resultset.close()
            statement.close()
            Some(result)
        }).getOrElse(Map())
    }

    /**
     *  Queries the database for the Zweitstimmen-Distribution
     *  @returns Map of Landesliste -> number of votes it got
     */
    def zweitstimmenDist:Map[Zweitstimme, Int] = {
        withDatabase(conn => {
            val statement = conn.createStatement()
            val resultset:ResultSet = statement.executeQuery(
                f"SELECT llid, votes FROM AccumulatedZweitstimmenWK NATURAL JOIN Wahlkreis WHERE year = ${year} AND wkid = ${wkid};")
            var result = Map[Zweitstimme, Int]()

            while (resultset.next()) {
                val llid:Int = resultset.getInt("llid")
                val votes:Int = resultset.getInt("votes")
                result += (new Landesliste(llid) -> votes)
            }
            resultset.close()
            statement.close()
            Some(result)
        }).getOrElse(Map())
    }

    /**
     * @returns Lower bound for the number of citizens that voted
     */
    def sampleSize:Int = {
        val sizeInDB:Int = withDatabase(conn => {
            val statement = conn.createStatement()
            val resultset:ResultSet = statement.executeQuery(
                f"SELECT GREATEST(e.es, z.zs) AS total FROM (SELECT SUM(votes) AS es FROM Candidacy NATURAL JOIN Wahlkreis WHERE wkid = ${wkid} AND year = ${year}) e, (SELECT SUM(votes) AS zs FROM AccumulatedZweitstimmenWK NATURAL JOIN Landesliste WHERE wkid = ${wkid} AND year = ${year}) z")
            if (resultset.next())
                Some(resultset.getInt("total"))
            else
                None
        }).getOrElse(0)
        scala.math.max(sizeInDB, scala.math.max(erststimmenDist.size, zweitstimmenDist.size))
    }

    /**
     *  Accessor for erststimmenDist without having to query the DB each time
     */
    var _erststimmen:Map[Erststimme, Int] = null
    def erststimmen:Map[Erststimme, Int] = {
        if (_erststimmen == null) {
            _erststimmen = erststimmenDist
        }
        _erststimmen
    }

    /**
     *  Accessor for zweitstimmenDist without having to query the DB each time
     */
    var _zweitstimmen:Map[Zweitstimme, Int] = null
    def zweitstimmen:Map[Zweitstimme, Int] = {
        if (_zweitstimmen == null) {
            _zweitstimmen = zweitstimmenDist
        }
        _zweitstimmen
    }

    def possibleErststimmen:List[Erststimme] = erststimmen.keys.toList
    def possibleZweitstimmen:List[Zweitstimme] = zweitstimmen.keys.toList

    /**
     *  @returns Instance of Distribution with Erst- and Zweitstimmen
     */
    def distribution:Distribution = {
        val size:Int = sampleSize
        if (erststimmen.values.sum < size) {
            val diff:Int = size - erststimmen.values.sum
            val invalids:Int = erststimmen.getOrElse(InvalidErststimme, 0)
            _erststimmen += (InvalidErststimme -> (invalids + diff))
        } else if (zweitstimmen.values.sum < size) {
            val diff:Int = size - zweitstimmen.values.sum
            val invalids:Int = zweitstimmen.getOrElse(InvalidZweitstimme, 0)
            _zweitstimmen += (InvalidZweitstimme -> (invalids + diff))
        }
        val dist = new Distribution(erststimmen, zweitstimmen)
        assert(dist.erststimmen.values.sum == dist.zweitstimmen.values.sum, f"Same amount of ES (${erststimmen.size}) & ZS (${zweitstimmen.size}) required.")
        dist
    }

    override def toString():String = f"\nWahlkreis ${wkid}:\n----------------\n${distribution}\n\n"

}
