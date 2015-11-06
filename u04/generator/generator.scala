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

    case class Candidacy(val idno:String, val wkid:Int, val year:Int, val supporter:Option[Party]) {}

    val c1 = Candidacy("abc123", 0, 2013, None)
    val c2 = Candidacy("defghi", 0, 2013, None)

    case class Stimmzettel(gender:Gender, age:Int, erststimme:Candidacy, zweitstimme:Party) {
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
            val totalErststimme = erststimmenCount.values.sum
            val totalZweistimme = zweitstimmenCount.values.sum

            new Distribution(erststimmenCount.mapValues(_ / totalErststimme), zweitstimmenCount.mapValues(_ / totalZweistimme))
        }

        override def toString(): String = votes.toString()

    }

    class Distribution(val erststimmen:Map[Candidacy, Double], val zweitstimmen:Map[Party, Double]) {
        /** Mean deviation from percentages of all values */
        def distance(other:Distribution):Double = {
            var dist = 0

            val allCandidacies:List[Candidacy] = (erststimmen.keys ++ other.erststimmen.keys).toList
            val allParties:List[Party] = (zweitstimmen.keys ++ other.zweitstimmen.keys).toList

            val erststimmenDiffs:List[Double] = allCandidacies.map((c:Candidacy) => {
                scala.math.abs(erststimmen.getOrElse(c, 0:Double) - other.erststimmen.getOrElse(c, 0:Double))
            })

            val zweitstimmenDiffs:List[Double] = allParties.map((p:Party) => {
                scala.math.abs(zweitstimmen.getOrElse(p, 0:Double) - other.zweitstimmen.getOrElse(p, 0:Double))
            })

            (erststimmenDiffs.sum / erststimmenDiffs.length + zweitstimmenDiffs.sum / zweitstimmenDiffs.length) / 2
        }

        override def toString(): String = f"${erststimmen}\n${zweitstimmen}"

    }

    def generate(targetDist:Distribution, size:Int):Ergebnis = {
        var result:Ergebnis = new Ergebnis(Set[Stimmzettel]())
        for (i <- 1 to size) {
            var epsilon = (size - i + 0.1) * (size - i + 0.1)
            var newvote:Stimmzettel = Stimmzettel.random
            var potentialResult:Ergebnis = result.insert(newvote)
            var newDistributionDistance:Double = result.distribution.distance(targetDist)
            var c = 0

            while (newDistributionDistance > epsilon && c < 10000) {
                c += 1
                newvote = Stimmzettel.random
                potentialResult = result.insert(newvote)
                newDistributionDistance = result.distribution.distance(targetDist)
            }
            assert(c < 9999)

            result = potentialResult
        }

        result
    }

    def main(args: Array[String]):Unit = {
        val dist = new Distribution(Map[Candidacy, Double](
                (c1 -> 1), (c2 -> 0)
            ), Map[Party, Double](
                (cdu -> 1), (spd -> 0)
            ))
        val result = Generator.generate(dist, 2);

        println(result)
        println(result.distribution)
        println(result.distribution.distance(dist))
    }

}
