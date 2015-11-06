import scala.util.Random

object Generator {
    trait Gender {}
    object Male extends Gender {
        override def toString(): String = "m"
    }
    object Female extends Gender {
        override def toString(): String = "f"
    }

    case class Party(val name:String, val shorthand:String, val website:String, val color:String, val isMinority:Boolean) {
        override def toString(): String = shorthand
    }

    val cdu = Party("CDU", "CDU", "", "black", false)
    val spd = Party("SPD", "SPD", "", "red", false)



    case class Candidacy(val idno:String, val wkid:Int, val year:Int, val supporter:Option[Party]) {
        override def toString(): String = idno
    }

    val c1 = Candidacy("abc123", 0, 2013, None)
    val c2 = Candidacy("defghi", 0, 2013, None)



    case class Stimmzettel(gender:Gender, age:Int, erststimme:Candidacy, zweitstimme:Party) {
        def this(erststimme:Candidacy, zweitstimme:Party) =
            this(if (Random.nextInt(2) == 1) Male else Female, Random.nextInt(80) + 18, erststimme, zweitstimme)

        override def toString(): String =
            f"((${erststimme.idno}, ${erststimme.wkid}, ${erststimme.year}), ${zweitstimme.name}, ${gender}, ${age})"
    }

    object Stimmzettel {
        val possibleParties = List[Party](
                cdu, spd
            )
        val possibleCandidates = List[Candidacy](
                c1, c2
            )

        def random():Stimmzettel = {
            val gender = if (Random.nextInt(2) == 1) Male else Female
            val age = Random.nextInt(80) + 18
            val erststimme = possibleCandidates.apply(Random.nextInt(possibleCandidates.length))
            val zweitstimme = possibleParties.apply(Random.nextInt(possibleParties.length))
            new Stimmzettel(gender, age, erststimme, zweitstimme)
        }
    }

    class Ergebnis(val votes:Set[Stimmzettel]) {
        def insert(vote:Stimmzettel):Ergebnis = new Ergebnis(votes + vote)

        def distribution():Distribution = {
            def cummulate(maps:(Map[Candidacy, Int], Map[Party, Int]),
                 sz:Stimmzettel):(Map[Candidacy, Int], Map[Party, Int]) = {

                val (erststimmen, zweitstimmen) = maps
                val Stimmzettel(g, a, e, z) = sz

                val esc = erststimmen.getOrElse(e, 0) + 1
                val zsc = zweitstimmen.getOrElse(z, 0) + 1

                (erststimmen + (e -> esc), zweitstimmen + (z -> zsc))
            }

            val (erststimmenCount, zweitstimmenCount) = votes.foldLeft(Map[Candidacy, Int](), Map[Party, Int]())(cummulate)
            val totalErststimme:Double = erststimmenCount.values.sum
            val totalZweistimme:Double = zweitstimmenCount.values.sum

            new Distribution(erststimmenCount.mapValues(_ / totalErststimme:Double), zweitstimmenCount.mapValues(_ / totalZweistimme:Double))
        }

        override def toString(): String = votes.toString()
    }

    class Distribution(val erststimmen:Map[Candidacy, Double], val zweitstimmen:Map[Party, Double]) {
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
        def deviation(other:Distribution):(Map[Candidacy, Double], Map[Party, Double]) = {
            val allCandidacies:List[Candidacy] = (erststimmen.keys ++ other.erststimmen.keys).toList
            val allParties:List[Party] = (zweitstimmen.keys ++ other.zweitstimmen.keys).toList

            val erststimmenDiffs:Map[Candidacy, Double] = allCandidacies.map((c:Candidacy) => {
                (c -> (other.erststimmen.getOrElse(c, 0:Double) - erststimmen.getOrElse(c, 0:Double)))
            }).toMap

            val zweitstimmenDiffs:Map[Party, Double] = allParties.map((p:Party) => {
                (p -> (other.zweitstimmen.getOrElse(p, 0:Double) - zweitstimmen.getOrElse(p, 0:Double)))
            }).toMap


            println("> " + erststimmenDiffs)

            // (erststimmenDiffs, zweitstimmenDiffs)

            (Map((c1 -> 0.5), (c2 -> -0.5)), Map((cdu -> -0.5), (spd -> 0.5)))
        }

        def inNeedOfErststimme(other:Distribution):Candidacy = {
            val folksWithVotesMissing:List[Candidacy] = deviation(other)._1.filter(_._2 < 0).map(_._1).toList
            if (folksWithVotesMissing.length < 1)
                Stimmzettel.possibleCandidates.apply(Random.nextInt(Stimmzettel.possibleCandidates.length))
            else
                folksWithVotesMissing.apply(Random.nextInt(folksWithVotesMissing.length))
        }

        def inNeedOfZweitstimme(other:Distribution):Party = {
            val folksWithVotesMissing:List[Party] = deviation(other)._2.filter(_._2 < 0).map(_._1).toList
            if (folksWithVotesMissing.length < 1)
                Stimmzettel.possibleParties.apply(Random.nextInt(Stimmzettel.possibleParties.length))
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
            ), Map[Party, Double](
                (cdu -> 0.5), (spd -> 0.5)
            ))
        val result = Generator.generate(dist, 100);

        println(result)
        println(result.distribution)
        println(result.distribution.distance(dist))
    }

}
