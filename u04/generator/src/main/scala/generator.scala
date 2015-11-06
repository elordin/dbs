import scala.util.Random

object Generator {
    trait Gender {}
    object Male extends Gender {
        override def toString(): String = "m"
    }
    object Female extends Gender {
        override def toString(): String = "f"
    }

    def randomGender:Gender = if (Random.nextInt(2) == 1) Male else Female
    // Gauss Curve values are empirical estimates
    def randomAge:Int = scala.math.max(18:Int, scala.math.min(115:Int, (scala.math.round(Random.nextGaussian() * 10:Double):Long).toInt + 50))

    trait Erststimme {}
    object InvalidErststimme extends Erststimme
    case class Candidacy(val cid:Int, val idno:String, val wkid:Int, val year:Int, val supporter:Option[Int]) extends Erststimme {
        override def toString(): String = cid.toString
    }
    trait Zweitstimme {}
    object InvalidZweitstimme extends Zweitstimme
    case class Landesliste(val llid:Int, val year:Int, val pid:Int, val fsid:Int) extends Zweitstimme {
        override def toString(): String = llid.toString
    }

    case class Stimmzettel(gender:Gender, age:Int, erststimme:Erststimme, zweitstimme:Zweitstimme) {
        def this(erststimme:Erststimme, zweitstimme:Zweitstimme) =
            this(randomGender, randomAge, erststimme, zweitstimme)

        override def toString(): String = f"(${erststimme}, ${zweitstimme})"
    }

    object Stimmzettel {
        /** Generates a random Stimmzettel */
        def random():Stimmzettel = {
            val erststimme = GeneratorConfig.possibleCandidates.apply(Random.nextInt(GeneratorConfig.possibleCandidates.length))
            val zweitstimme = GeneratorConfig.possibleParties.apply(Random.nextInt(GeneratorConfig.possibleParties.length))
            new Stimmzettel(randomGender, randomAge, erststimme, zweitstimme)
        }
    }

    class Ergebnis(val votes:Set[Stimmzettel]) {
        /** Adds a Stimmzettel */
        def insert(vote:Stimmzettel):Ergebnis = new Ergebnis(votes + vote)

        /** Calculates current distribution */
        def distribution():Distribution = {
            def cummulate(maps:(Map[Erststimme, Int], Map[Zweitstimme, Int]),
                 sz:Stimmzettel):(Map[Erststimme, Int], Map[Zweitstimme, Int]) = {

                val (erststimmen, zweitstimmen) = maps
                val Stimmzettel(g, a, e, z) = sz

                val esc = erststimmen.getOrElse(e, 0) + 1
                val zsc = zweitstimmen.getOrElse(z, 0) + 1

                (erststimmen + (e -> esc), zweitstimmen + (z -> zsc))
            }

            val (erststimmenCount, zweitstimmenCount) = votes.foldLeft(Map[Erststimme, Int](), Map[Zweitstimme, Int]())(cummulate)
            val totalErststimme:Double = erststimmenCount.values.sum
            val totalZweistimme:Double = zweitstimmenCount.values.sum

            new Distribution(erststimmenCount.mapValues(_ / totalErststimme:Double), zweitstimmenCount.mapValues(_ / totalZweistimme:Double))
        }

        override def toString(): String = votes.toString()
    }

    class Distribution(val erststimmen:Map[Erststimme, Double], val zweitstimmen:Map[Zweitstimme, Double]) {
        /** Mean of deviations from desired value for all values */
        def distance(other:Distribution):Double = {
            val (erststimmenDiffs, zweitstimmenDiffs) = deviation(other)
            (erststimmenDiffs.values.map(scala.math.abs(_)).sum /
                    (erststimmenDiffs.values.toList.length:Double) +
            zweitstimmenDiffs.values.map(scala.math.abs(_)).sum /
                (zweitstimmenDiffs.values.toList.length:Double)
            ) / (2.0)
        }

        /** Relative differences between this and others entry count */
        def deviation(other:Distribution):(Map[Erststimme, Double], Map[Zweitstimme, Double]) = {
            val allCandidacies:List[Erststimme] = (erststimmen.keys ++ other.erststimmen.keys).toList
            val allParties:List[Zweitstimme] = (zweitstimmen.keys ++ other.zweitstimmen.keys).toList

            val erststimmenDiffs:Map[Erststimme, Double] = allCandidacies.map((c:Erststimme) => {
                (c -> (erststimmen.getOrElse(c, 0.0) - other.erststimmen.getOrElse(c, 0.0)))
            }).toMap

            val zweitstimmenDiffs:Map[Zweitstimme, Double] = allParties.map((p:Zweitstimme) => {
                (p -> (zweitstimmen.getOrElse(p, 0:Double) - other.zweitstimmen.getOrElse(p, 0:Double)))
            }).toMap

            (erststimmenDiffs, zweitstimmenDiffs)

            // (Map((c1 -> 0.5), (c2 -> -0.5)), Map((cdu -> -0.5), (spd -> 0.5)))
        }

        /** Returns a random Candidacy that needs more Erststimmen to reach desired distribution */
        def inNeedOfErststimme(other:Distribution):Erststimme = {
            val dev = deviation(other)._1
            val folksWithVotesMissing:List[Erststimme] = deviation(other)._1.filter(_._2 < 0).map(_._1).toList
            if (folksWithVotesMissing.length < 1)
                GeneratorConfig.possibleCandidates.apply(Random.nextInt(GeneratorConfig.possibleCandidates.length))
            else
                folksWithVotesMissing.apply(Random.nextInt(folksWithVotesMissing.length))
        }

        /** Returns a random Landesliste that needs more Zweitstimmen to reach desired distribution */
        def inNeedOfZweitstimme(other:Distribution):Zweitstimme = {
            val dev = deviation(other)._2
            val folksWithVotesMissing:List[Zweitstimme] = deviation(other)._2.filter(_._2 < 0).map(_._1).toList
            if (folksWithVotesMissing.length < 1)
                GeneratorConfig.possibleParties.apply(Random.nextInt(GeneratorConfig.possibleParties.length))
            else
                folksWithVotesMissing.apply(Random.nextInt(folksWithVotesMissing.length))
        }

        override def toString(): String = f"${erststimmen}\n${zweitstimmen}"
    }

    /** Generates list of Stimmzettel for given distribution etc. */
    def generate(targetDist:Distribution, size:Int, invalidsES:Int, invalidisZS:Int):Ergebnis = {
        var result:Ergebnis = new Ergebnis(Set[Stimmzettel]())
        for (i <- 1 to size) {
            val erststimme:Erststimme = if (i + invalidsES > size)
                                           InvalidErststimme
                                       else result.distribution.inNeedOfErststimme(targetDist)
            val zweitstimme:Zweitstimme = if (i + invalidisZS > size)
                                            InvalidZweitstimme
                                       else result.distribution.inNeedOfZweitstimme(targetDist)
            var newvote:Stimmzettel = new Stimmzettel(erststimme, zweitstimme)
            result = result.insert(newvote)
        }

        result
    }


    def main(args: Array[String]):Unit = {
        import GeneratorConfig._

        val result = generate(distribution, sampleSize, invalidES, invalidZS);

        result.votes.map((sz:Stimmzettel) => {
            println(f"INSERT INTO Vote (gender, age, erststimme, zweitstimme) VALUES (${sz.gender}, ${sz.age}, ${sz.erststimme}, ${sz.zweitstimme});")
            })
        println(f"Deviation from target distribution: ${result.distribution.distance(distribution)}")
    }
}

/** General configuration of the generator */
object GeneratorConfig {
    import Generator._

    def possibleCandidates = distribution.erststimmen.keys.toList
    def possibleParties = distribution.zweitstimmen.keys.toList
    def distribution:Distribution = GeneratorConfigHardcoded.distribution
    def sampleSize:Int = GeneratorConfigHardcoded.sampleSize
    def invalidES:Int = GeneratorConfigHardcoded.invalidES
    def invalidZS:Int = GeneratorConfigHardcoded.invalidZS


    /** Loads distribution from database */
    object GeneratorConfigFromDatabase {
        def distributionWahlbezirk(wbid:Int, year:Int):Distribution = throw new NotImplementedError
        def distributionWahlkreis(wkid:Int, year:Int):Distribution  = throw new NotImplementedError
        def distributionBundesland(fsid:Int, year:Int):Distribution = throw new NotImplementedError
        def distributionBundesweit(year:Int):Distribution           = throw new NotImplementedError

        def sampleSizeWahlbezirk(wbid:Int, year:Int):Int            = throw new NotImplementedError
        def sampleSizeWahlkreis(wkid:Int, year:Int):Int             = throw new NotImplementedError
        def sampleSizeBundesland(fsid:Int, year:Int):Int            = throw new NotImplementedError
        def sampleSizeBundesweit(year:Int):Int                      = throw new NotImplementedError

        def invalidESWahlbezirk(wbid:Int, year:Int):Int             = throw new NotImplementedError
        def invalidESWahlkreis(wkid:Int, year:Int):Int              = throw new NotImplementedError
        def invalidESBundesland(fsid:Int, year:Int):Int             = throw new NotImplementedError
        def invalidESBundesweit(year:Int):Int                       = throw new NotImplementedError

        def invalidZSWahlbezirk(wbid:Int, year:Int):Int             = throw new NotImplementedError
        def invalidZSWahlkreis(wkid:Int, year:Int):Int              = throw new NotImplementedError
        def invalidZSBundesland(fsid:Int, year:Int):Int             = throw new NotImplementedError
        def invalidZSBundesweit(year:Int):Int                       = throw new NotImplementedError
    }

    /** Loads hardcoded distribution */
    object GeneratorConfigHardcoded {
        /* DEFINE LANDESLISTEN HERE */
        val npd     = new Landesliste(1, 2013, 1, 1)
        val spd     = new Landesliste(2, 2013, 2, 1)
        val linke   = new Landesliste(3, 2013, 3, 1)
        val fdp     = new Landesliste(4, 2013, 4, 1)
        val gruene  = new Landesliste(5, 2013, 5, 1)
        val piraten = new Landesliste(7, 2013, 7, 1)
        val dvu     = new Landesliste(11, 2013, 11, 1)
        val cdu     = new Landesliste(12, 2013, 12, 1)
        val mlpd    = new Landesliste(13, 2013, 13, 1)
        val rentner = new Landesliste(18, 2013, 18, 1)
        /* DEFINE CANDIDACIES HERE */
        val c1 = new Candidacy(1, "abc123", 0, 2013, None)
        val c2 = new Candidacy(2, "defghi", 0, 2013, None)

        def distribution:Distribution = new Distribution(Map[Erststimme, Double](
            /* Erststimmen results */
            (c1 -> 0.5),
            (c2 -> 0.5)
        ), Map[Zweitstimme, Double](
            /* Zweitstimmen results */
            (npd -> 1240),
            (spd -> 41793),
            (linke -> 13481),
            (fdp -> 24187),
            (gruene -> 21967),
            (piraten -> 3385),
            (dvu -> 159),
            (cdu -> 51068),
            (mlpd -> 47),
            (rentner -> 1821)
        ))

        def sampleSize:Int = 163329
        def invalidZS:Int = 4181
        def invalidES:Int = 4117
    }
}
