import scala.util.Random

object Generator {
    trait Gender {}
    object Male extends Gender {
        override def toString(): String = "m"
    }
    object Female extends Gender {
        override def toString(): String = "f"
    }

    case class Landesliste(val llid:Int, val year:Int, val pid:Int, val fsid:Int, val votes:Int) {
        def this(llid:Int, year:Int, pid:Int, fsid:Int) = this(llid, year, pid, fsid, 0)
        override def toString(): String = llid.toString
    }

    val cdu = new Landesliste(1, 2013, 1, 1)
    val spd = new Landesliste(2, 2013, 2, 1)


    case class Candidacy(val cid:Int, val idno:String, val wkid:Int, val year:Int, val supporter:Option[Landesliste]) {
        override def toString(): String = cid.toString
    }

    val c1 = new Candidacy(1, "abc123", 0, 2013, None)
    val c2 = new Candidacy(2, "defghi", 0, 2013, None)


    val possibleParties = List[Landesliste](
            cdu, spd
        )
    val possibleCandidates = List[Candidacy](
            c1, c2
        )

    case class Stimmzettel(gender:Gender, age:Int, erststimme:Candidacy, zweitstimme:Landesliste) {
        def this(erststimme:Candidacy, zweitstimme:Landesliste) =
            this(if (Random.nextInt(2) == 1) Male else Female, Random.nextInt(80) + 18, erststimme, zweitstimme)

        override def toString(): String = f"(${erststimme}, ${zweitstimme})"
    }

    object Stimmzettel {
        def random():Stimmzettel = {
            val gender = if (Random.nextInt(2) == 1) Male else Female
            val age = Random.nextInt(80) + 18
            val erststimme = Generator.possibleCandidates.apply(Random.nextInt(Generator.possibleCandidates.length))
            val zweitstimme = Generator.possibleParties.apply(Random.nextInt(Generator.possibleParties.length))
            new Stimmzettel(gender, age, erststimme, zweitstimme)
        }
    }

    class Ergebnis(val votes:Set[Stimmzettel]) {
        def insert(vote:Stimmzettel):Ergebnis = new Ergebnis(votes + vote)

        def distribution():Distribution = {
            def cummulate(maps:(Map[Candidacy, Int], Map[Landesliste, Int]),
                 sz:Stimmzettel):(Map[Candidacy, Int], Map[Landesliste, Int]) = {

                val (erststimmen, zweitstimmen) = maps
                val Stimmzettel(g, a, e, z) = sz

                val esc = erststimmen.getOrElse(e, 0) + 1
                val zsc = zweitstimmen.getOrElse(z, 0) + 1

                (erststimmen + (e -> esc), zweitstimmen + (z -> zsc))
            }

            val (erststimmenCount, zweitstimmenCount) = votes.foldLeft(Map[Candidacy, Int](), Map[Landesliste, Int]())(cummulate)
            val totalErststimme:Double = erststimmenCount.values.sum
            val totalZweistimme:Double = zweitstimmenCount.values.sum

            new Distribution(erststimmenCount.mapValues(_ / totalErststimme:Double), zweitstimmenCount.mapValues(_ / totalZweistimme:Double))
        }

        override def toString(): String = votes.toString()
    }

    class Distribution(val erststimmen:Map[Candidacy, Double], val zweitstimmen:Map[Landesliste, Double]) {
        /** Mean deviation from percentages of all values */
        def distance(other:Distribution):Double = {
            val (erststimmenDiffs, zweitstimmenDiffs) = deviation(other)
            (erststimmenDiffs.values.map(scala.math.abs(_)).sum /
                    (erststimmenDiffs.values.toList.length:Double) +
            zweitstimmenDiffs.values.map(scala.math.abs(_)).sum /
                (zweitstimmenDiffs.values.toList.length:Double)
            ) / (2:Double)
        }

        /** Relative differences between this and others percentages per entry */
        def deviation(other:Distribution):(Map[Candidacy, Double], Map[Landesliste, Double]) = {
            val allCandidacies:List[Candidacy] = (erststimmen.keys ++ other.erststimmen.keys).toList
            val allParties:List[Landesliste] = (zweitstimmen.keys ++ other.zweitstimmen.keys).toList

            val erststimmenDiffs:Map[Candidacy, Double] = allCandidacies.map((c:Candidacy) => {
                (c -> (erststimmen.getOrElse(c, 0:Double) - other.erststimmen.getOrElse(c, 0:Double)))
            }).toMap

            val zweitstimmenDiffs:Map[Landesliste, Double] = allParties.map((p:Landesliste) => {
                (p -> (zweitstimmen.getOrElse(p, 0:Double) - other.zweitstimmen.getOrElse(p, 0:Double)))
            }).toMap

            (erststimmenDiffs, zweitstimmenDiffs)

            // (Map((c1 -> 0.5), (c2 -> -0.5)), Map((cdu -> -0.5), (spd -> 0.5)))
        }

        def inNeedOfErststimme(other:Distribution):Candidacy = {
            val dev = deviation(other)._1
            val folksWithVotesMissing:List[Candidacy] = deviation(other)._1.filter(_._2 < 0).map(_._1).toList
            if (folksWithVotesMissing.length < 1)
                Generator.possibleCandidates.apply(Random.nextInt(Generator.possibleCandidates.length))
            else
                folksWithVotesMissing.apply(Random.nextInt(folksWithVotesMissing.length))
        }

        def inNeedOfZweitstimme(other:Distribution):Landesliste = {
            val dev = deviation(other)._2
            val folksWithVotesMissing:List[Landesliste] = deviation(other)._2.filter(_._2 < 0).map(_._1).toList
            if (folksWithVotesMissing.length < 1)
                Generator.possibleParties.apply(Random.nextInt(Generator.possibleParties.length))
            else
                folksWithVotesMissing.apply(Random.nextInt(folksWithVotesMissing.length))
        }

        override def toString(): String = f"${erststimmen}\n${zweitstimmen}"
    }


    def generate(targetDist:Distribution, size:Int):Ergebnis = {
        var result:Ergebnis = new Ergebnis(Set[Stimmzettel]())
        for (i <- 1 to size) {
            var newvote:Stimmzettel = new Stimmzettel(
                result.distribution.inNeedOfErststimme(targetDist),
                result.distribution.inNeedOfZweitstimme(targetDist))
            result = result.insert(newvote)
        }

        result
    }

    def main(args: Array[String]):Unit = {
        val dist = new Distribution(Map[Candidacy, Double](
                (c1 -> 0.5), (c2 -> 0.5)
            ), Map[Landesliste, Double](
                (cdu -> 0.5), (spd -> 0.5)
            ))
        val result = Generator.generate(dist, 100000);

        result.votes.map((sz:Stimmzettel) => {
            println(f"INSERT INTO Vote (gender, age, erststimme, zweitstimme) VALUES (${sz.gender}, ${sz.age}, ${sz.erststimme.cid}, ${sz.zweitstimme.llid});")
            })
        println(f"Deviation: ${100 * result.distribution.distance(dist)} percent")
    }

}
