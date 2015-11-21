package Wahlinfo

import scala.util.Random
import scala.annotation.tailrec
import java.io.File

import Helpers._
import GeneratorConfig._

object Generator {

    trait Gender {}
    object Male extends Gender {
        override def toString(): String = "m"
    }
    object Female extends Gender {
        override def toString(): String = "f"
    }

    object Names {
        val firstnamesM:List[String] = List("Ben","Luis","Louis","Paul","Lukas","Lucas","Jonas","Leon","Finn","Fynn","Noah","Elias","Luca","Luka","Maximilian","Felix","Max","Henry","Henri","Moritz","Julian","Tim","Jakob","Jacob","Emil","Philipp","Niklas","Niclas","Alexander","David","Oskar","Oscar","Mats","Mads","Jan","Tom","Anton","Liam","Erik","Eric","Fabian","Matteo","Leo","Rafael","Raphael","Samuel","Mika","Theo","Jonathan","Lennard","Lennart","Simon","Hannes","Linus","Jannik","Yannik","Yannick","Yannic","Nico","Niko","Carl","Karl","Till","Vincent","Jona","Jonah","Benjamin","Nick","Leonard","Milan","Julius","Marlon","Florian","Johannes","Nils","Niels","Adrian","Mattis","Mathis","Matthis","Constantin","Konstantin","Levi","Aaron","Ole","Maxim","Maksim","Daniel","Sebastian","Mohammed","Muhammad","Jannis","Janis","Yannis","Johann","Lennox","Phil","Joshua","Damian","Timo","Tobias","Robin","Joel","Lasse","Levin","Lenny","Lenni","Jayden","Jaden","John","Dominic","Dominik","Colin","Collin","Valentin","Gabriel","Artur","Arthur","Bruno","Bastian","Benedikt","Malte","Kilian","Marvin","Marwin","Noel","Toni","Tony","Bennet","Pepe","Luke","Luc","Justus","Tyler","Tayler","Jason","Theodor","Christian","Jamie","Michael","Sam","Lars","Marc","Mark","Lian","Emilio","Oliver","Frederik","Frederic","Leopold","Manuel","Richard","Matti","Lias","Elia","Eliah","Nicolas","Nikolas","Fritz","Tristan","Jannes","Ali","Len","Lenn","Dean","Marco","Marko","Emir","Franz","Henrik","Silas","Marcel","Marius","Andreas","Adam","Fabio","Matthias","Malik","Piet","Finnley","Finley","Finlay","Leandro","Clemens","Klemens","Lionel","Hugo","Ludwig","Diego","Julien","Carlo","Karlo","Jasper","Martin","Thore","Tore","Eddie","Eddy","Emilian","Ilias","Ilyas","Neo","Ian","Dennis","Milo","Lio","Ferdinand","Lorenz","Nikita","Georg","Arne","Michel","Alessio","Connor","Conner","Friedrich","Leonhard","Willi","Willy","Maik","Meik","Mike","Mailo","Jeremy","Roman","Fiete","Yusuf","Alessandro","Kevin","Leonardo","Lion","Bela","Konrad","Thomas","Nino","Josef","Joseph","Luan","Ahmet","Jonte","Tiago","Thiago","Pascal","Aiden","Ayden","Magnus","Enes","Laurens","Laurenz","Curt","Kurt","Can","Mehmet","Mert","Yasin","Enno","Henning","Charlie","Charly","Leander","Jack","Maurice","Robert","Benno","Brian","Bryan","Ryan","Hendrik","Mick","Thilo","Tilo","Nevio","Oemer","Alex","Carlos","Gustav","Hamza","Taylor","Arian","Dario","Christoph","Deniz","Chris","Markus","Marcus","Laurin","Nathan","Kian","Kaan","Patrick","Claas","Klaas","Lean","Lino","Titus","Devin","Justin","Kai","Kay","Kerem","Mustafa","Sami","Bjarne","Darian","Mirac","Amir","Janne","Victor","Viktor","Christopher","Darius","Elian","Korbinian","Marten","Samu","William","Xaver","Antonio","Joris","Edgar","Ensar","Janosch","Torben","Thorben","Leonas","Bilal","Elija","Elijah","Jerome","Ricardo","Riccardo","Stefan","Stephan","Tammo","Berat","Leif","Domenic","Domenik","Hans","Semih","Tamme","Wilhelm","Cedric","Cedrik","Gregor","Kalle","Kerim","Ruben","Andre","Eymen","Jaron","Mikail","Miran","Cem","Giuliano","Ibrahim","Kjell","Mio","Peter","Lutz","Mario","Danny","Romeo","Tino","Valentino","Arda","Damien","James","Erwin","Tjark","Marian","Timon","Timur","Umut","Hanno","Aras","Efe","Joscha","Leonidas","Anthony","Damon","Jano","Marek","Pius","Quentin","Alan","Alwin","Danilo","Emin","Otto","Armin","Hassan","Hasan","Jakub","Milian","Sascha","Sidney","Sydney","Taylan","Adem","Emanuel","Eren","Joost","Jost","Rocco","Sandro","Etienne","Jean","Karim","Tamino","Yunus","Albert","Angelo","Jamal","Kenan","Kuzey","Logan","Pierre","Rayan","Sven","Bosse","Enrico","Jarne","Nicolai","Nikolai","Thies","Berkay","Caspar","Dustin","Flynn","Ismail","Jesse","Johnny","Jordan","Juri","Mattes","Arno","Cornelius","Emre","Francesco","Artjom","Baran","Eray","Hauke","Ilja","Jannek","Janek","Miro","Nathanael","Neven","Omar","Amin","Dante","Ivan","Lorik","Miguel","Rene","Tommi","Yigit","Azad","Lewis","Mattia","Peer","Quirin","Rudi","Samir","Selim","Vinzenz","Yassin","Arik","Ayaz","Edwin","Ilay","Jake","Jenke","Jonne","Keno","Luiz","Marlo","Mete","Younes","Alfred","Amar","Arvid","Davin","Dylan","Eduard","Jesper","Koray","Tyron","Vitus","Ansgar","Aurel","Christiano","Cristiano","Jim","Joey","Luuk","Maddox","Mason","Miko","Nelio","Rico","Said","Taha","Tillman","Tilman","Veit","Anas","Bjoern","Davide","Dorian","Jaro","Jon","Kimi","Leano","Lennert","Marley","Raik","Ron","Severin","Cinar","Dion","Eliano","Emirhan","Hagen","Iven","Yven","Jay","Keanu","Lucien","Steven","Talha","Thorin","Vince","Vito","Aidan","Alexandros","Burak","Ege","Ethan","Jarno","Joe","Kirill","Mahir","Merlin","Micha","Mirco","Mirko","Simeon","Amon","Arjen","August","Bent","Falk","Gianluca","Hussein","Levian","Lorenzo","Noyan","Pablo","Ramon","Rasmus","Raul","Salvatore","Sean","Sinan","Aurelius","Batu","Benny","Demian","Devran","Furkan","Hennes","Hermann","Ilian","Josua","Junis","Milow")
        val firstnamesF:List[String] = List("Emma","Mia","Hannah","Hanna","Sofia","Sophia","Emilia","Anna","Lena","Lea","Leah","Emily","Emilie","Marie","Lina","Leonie","Amelie","Sophie","Sofie","Luisa","Louisa","Johanna","Nele","Neele","Laura","Lilly","Lilli","Lara","Clara","Klara","Mila","Leni","Maja","Maya","Charlotte","Sarah","Sara","Frieda","Frida","Ida","Greta","Pia","Lotta","Lia","Liah","Lya","Mathilda","Matilda","Ella","Melina","Lisa","Julia","Paula","Alina","Mira","Zoe","Helena","Marlene","Emely","Emelie","Elisa","Victoria","Viktoria","Isabell","Isabel","Isabelle","Isabella","Jana","Amy","Mara","Marah","Finja","Finnja","Josephine/ Josefine","Katharina","Nora","Theresa","Teresa","Maria","Antonia","Jasmin","Yasmin","Stella","Pauline","Luise","Louise","Annika","Anni","Annie","Anny","Lucy","Lucie","Jule","Merle","Carla","Karla","Eva","Milena","Martha","Marta","Elena","Fiona","Melissa","Franziska","Luna","Magdalena","Nina","Annabell","Annabelle","Romy","Carlotta","Karlotta","Mina","Paulina","Ronja","Zoey","Chiara","Helene","Selina","Maila","Mayla","Fabienne","Elina","Jette","Sina","Sinah","Jolina","Joelina","Elif","Elisabeth","Linda","Miriam","Valentina","Lotte","Vanessa","Aylin","Eileen","Aileen","Ayleen","Rosalie","Celina","Olivia","Kira","Kyra","Carolin","Caroline","Karoline","Juna","Yuna","Samira","Joleen","Lenja","Lenya","Marla","Angelina","Hailey","Haylie","Thea","Anastasia","Leila","Leyla","Luana","Alexandra","Amelia","Ela","Lana","Marleen","Marlen","Amalia","Leticia","Letizia","Lene","Julie","Tessa","Lucia","Aaliyah","Aliya","Aurelia","Kim","Alissa","Alyssa","Elli","Elly","Mona","Diana","Vivien","Vivienne","Tabea","Amira","Mariella","Michelle","Alessia","Lynn","Linn","Carolina","Karolina","Liana","Laila","Layla","Larissa","Rebekka","Alisa","Elsa","Milla","Nala","Nahla","Malia","Svea","Nelly","Nelli","Alicia","Evelyn","Evelin","Eveline","Annalena","Giulia","Emmi","Emmy","Leana","Nisa","Amina","Lorena","Anne","Alexa","Kate","Tilda","Celine","Liv","Veronika","Zeynep","Dana","Hira","Linea","Linnea","Rieke","Rosa","Carina","Karina","Henriette","Alma","Christina","Felicitas","Ina","Melia","Elise","Kimberly","Kimberley","Azra","Daria","Helen","Nela","Noemi","Fenja","Miray","Jara","Yara","Maike","Meike","Natalie","Nathalie","Samantha","Tamara","Xenia","Liya","Josie","Josy","Medina","Ava","Cataleya","Jessika","Jessica","Liliana","Madita","Valerie","Enie","Jonna","Marlena","Janne","Livia","Aurora","Dilara","Malina","Edda","Marina","Selma","Tamina","Milana","Talia","Thalia","Alena","Leona","Enna","Florentine","Bella","Mailin","Maylin","Melinda","Alea","Amilia","Freya","Heidi","Leandra","Levke","Lilian","Lillian","Naila","Nayla","Alice","Elin","Enya","Joline","Joeline","Madlen","Madleen","Valeria","Annelie","Holly","Lilith","Malin","Meryem","Tuana","Estelle","Smilla","Aleyna","Ayla","Cheyenne","Chayenne","Melanie","Naomi","Jill","Jil","Lieselotte","Maira","Mayra","Mariam","Maryam","Melody","Selin","Ylvi","Ylvie","Cara","Felia","Felina","Mathea","Mattea","Matea","Abby","Jolien","Juliana","Marit","Nika","Viola","Alisha","Madeleine","Esila","Esma","Malea","Mary","Nike","Svenja","Hedi","Hedy","Adelina","Ariana","Adriana","Asya","Hermine","Josefin","Josephin","Lola","Ruby","Cassandra","Kassandra","Cecilia","Ellen","Esther","Lenia","Melek","Nicole","Elaine","Elea","Ilayda","Kaja","Kaya","Caja","Lilia","Ashley","Flora","Friederike","Judith","Malou","Mathilde","Nila","Patricia","Sonja","Tara","Alexia","Dalia","Fatima","Jamie","Lisann","Lysann","Anouk","Felicia","Melisa","Jasmina","Leia","Leya","Tiana","Aimee","Arina","Josephina","Josefina","Lydia","Alia","Alva","Eliana","Henrieke","Henrike","Jenna","Jolie","Juliane","Leonora","Fee","Maxi","Mirja","Philippa","Sarina","Zehra","Alica","Anja","Eleni","Janina","Saphira","Amanda","Melis","Nia","Romina","Shania","Soraya","Adele","Anisa","Joy","Miley","Wilma","Annemarie","Charlotta","Claire","Fritzi","Jennifer","Liara","Luca","Luka","Marieke","Marike","Marisa","Meyra","Mieke","Verena","Ceyda","Ceylin","Cora","Eda","Eliza","Feline","Gloria","Inga","Joyce","Katja","Lejla","Lou","Malena","Maren","Nea","Sila","Eslem","Janna","Sena","Summer","Ziva","Ann","Davina","Defne","Ecrin","Enni","Femke","Joana","Lavinia","Maxima","Rahel","Saskia","Toni","Tony","Zara","Ada","Bianca","Bianka","Clarissa","Fina","Gina","Megan","Naemi","Natalia","Ria","Tia","Tina","Yaren","Alara","Annabella","Betty","Beyza","Christin","Kristin","Cleo","Dilay","Eleanor","Elenor","Eleonora","Ellie","Eyluel","Franka","Giuliana","Hanne","Hedda","Jamila","Jenny","Jona","Jonah","Julina","Liyana","Loreen","Stefanie","Stephanie","Stina","Tamia","Zuemra","Erva","Ewa","Iva","Katrin","Catrin","Kathrin","Malak","Penelope","Rabia","Salome","Sandra","Sienna","Yagmur","Abigail","Ariane","Delia","Dila","Dina","Fine","Havin","Isa","Kaethe","Lisbeth","Liz","Maileen","Mayleen","Neyla","Palina","Samia","Shirin","Talea","Thalea","Vera","Vivian","Aria","Erna","Helin","Hilda","Kiana","Luzi","Luzie","Melike","Mika","Scarlett","Stine","Alana","Alba","Asmin","Celia","Damla","Elissa","Eve","Evelina","Grace","Kathleen","Lale","Laureen","Line","Milina","Minna","Neela","Rita","Sidney","Sydney","Sura")
        val   lastnames:List[String] = List("Mueller","Schmidt","Schneider","Fischer","Weber","Meyer","Wagner","Becker","Schulz","Hoffmann","Schaefer","Koch","Bauer","Richter","Klein","Wolf","Schroeder","Schneider","Neumann","Schwarz","Zimmermann","Braun","Krueger","Hofmann","Hartmann","Lange","Schmitt","Werner","Schmitz","Krause","Meier","Lehmann","Schmid","Schulze","Maier","Koehler","Herrmann","Koenig","Walter","Mayer","Huber","Kaiser","Fuchs","Peters","Lang","Scholz","Moeller","Weiss","Jung","Hahn","Schubert","Vogel","Friedrich","Keller","Guenther","Frank","Berger","Winkler","Roth","Beck","Lorenz","Baumann","Franke","Albrecht","Schuster","Simon","Ludwig","Boehm","Winter","Kraus","Martin","Schumacher","Kraemer","Vogt","Stein","Jaeger","Otto","Sommer","Gross","Seidel","Heinrich","Brandt","Haas","Schreiber","Graf","Schulte","Dietrich","Ziegler","Kuhn","Kuehn","Pohl","Engel","Horn","Busch","Bergmann","Thomas","Voigt","Sauer","Arnold","Wolff","Pfeiffer")

        def getName(g:Gender):(String, String) = (getFirstName(g), getLastName)
        def getFirstName(g:Gender):String =
            if (g == Male) firstnamesM.apply(Random.nextInt(firstnamesM.length))
            else firstnamesF.apply(Random.nextInt(firstnamesF.length))
        def getLastName:String =
                lastnames.apply(Random.nextInt(lastnames.length))
    }

    def randomDayOfBirth:(Int, Int) =
        (Random.nextInt(28) + 1, Random.nextInt(12) + 1)

    def randomGender:Gender = if (Random.nextInt(2) == 1) Male else Female
    // Gauss Curve parameters are empirical estimates
    def randomAge:Int = scala.math.max(18:Int, scala.math.min(115:Int, (scala.math.round(Random.nextGaussian() * 10:Double):Long).toInt + 50))

    trait Erststimme {}
    object InvalidErststimme extends Erststimme {
        override def toString(): String = "NULL"
    }
    case class Candidacy(val cid:Int) extends Erststimme {
        override def toString(): String = cid.toString
    }

    trait Zweitstimme {}
    object InvalidZweitstimme extends Zweitstimme {
        override def toString(): String = "NULL"
    }
    case class Landesliste(val llid:Int) extends Zweitstimme {
        override def toString(): String = llid.toString
    }

    class Distribution(val erststimmen:Map[Erststimme, Int], val zweitstimmen:Map[Zweitstimme, Int]) {
        // TODO: Maybe don't use head but random index instead
        def inNeedOfErststimme:Erststimme = erststimmen.filter(_._2 > 0).head._1
        def inNeedOfZweitstimme:Zweitstimme = zweitstimmen.filter(_._2 > 0).head._1

        def next(es:Erststimme, zs:Zweitstimme):Distribution = {

            new Distribution(
                erststimmen.toList.map((kv:(Erststimme, Int)) => {
                    val (k,v) = kv
                    (k, if (k == es)
                            if (v < 1) throw new IllegalStateException
                            else v - 1
                        else v)
                }).toMap,
                zweitstimmen.toList.map((kv:(Zweitstimme, Int)) => {
                    val (k,v) = kv
                    (k, if (k == zs)
                            if (v < 1) throw new IllegalStateException(f"Generated for ${k}, ")
                            else v - 1
                        else v)
                }).toMap)
        }

        override def toString(): String = f"Erststimmen:\n----------------\n${erststimmen}\nZweitstimmen:\n----------------\n${zweitstimmen}"
    }

    case class Stimmzettel(gender:Gender, age:Int, erststimme:Erststimme, zweitstimme:Zweitstimme) {
        val id = Stimmzettel.c
        Stimmzettel.c += 1

        def this(erststimme:Erststimme, zweitstimme:Zweitstimme) =
            this(randomGender, randomAge, erststimme, zweitstimme)

        override def toString:String = f"${gender}${age}${erststimme}${zweitstimme}${id}"
    }

    object Stimmzettel {
        var c:Int = 0
        /** Generates a random Stimmzettel */
        def random(config:GeneratorConfigFromDatabase):Stimmzettel = {
            val erststimme = config.possibleErststimmen.apply(Random.nextInt(config.possibleErststimmen.length))
            val zweitstimme = config.possibleZweitstimmen.apply(Random.nextInt(config.possibleZweitstimmen.length))
            new Stimmzettel(randomGender, randomAge, erststimme, zweitstimme)
        }
    }

    @tailrec
    def generate(distribution: Distribution, result:List[Stimmzettel]):List[Stimmzettel] = {
        val totalES:Int = distribution.erststimmen.values.sum
        val totalZS:Int = distribution.zweitstimmen.values.sum
        assert(totalES == totalZS)
        if (totalES > 1 && totalZS > 1) {
            val sz = new Stimmzettel(distribution.inNeedOfErststimme, distribution.inNeedOfZweitstimme)
            val newDistribution:Distribution = distribution.next(sz.erststimme, sz.zweitstimme)
            generate(newDistribution, sz :: result)
        } else {
            result
        }
    }

    def main(args: Array[String]):Unit = {

        println(allWKConfigs(2013))
        /*
        val szs = generate(allWKConfigs(year).head.distribution, List())
        var availableCitizens = allWKConfigs(year).existingCitizens

        withPrintWriter(new File(filename)) { p =>
            szs.map((sz:Stimmzettel) => {
                val idno:String = if (availableCitizens.length < 1) {
                        val (firstname, lastname) = Names.getName(sz.gender)
                        val (dobDay, dobMonth) = randomDayOfBirth
                        p.println(f"INSERT INTO Citizen (idno, firstname, lastname, dateofbirth, gender, authtoken) VALUES ('${sz.toString}', '${firstname}', '${lastname}', '${dobDay}.${dobMonth}.${2009 - sz.age}.', '${sz.gender}', '');")
                        sz.toString
                    } else {
                        val ret = availableCitizens.head
                        availableCitizens = availableCitizens.tail
                        ret
                    }
                p.println(f"INSERT INTO CitizenRegistration (idno, dwbid) VALUES ('${idno}', ${dwbid});")
                p.println(f"INSERT INTO hasVoted (idno, year, hasvoted) VALUES('${idno}', ${year}, true);")
                p.println(f"INSERT INTO Stimmzettel (dwbid, gender, age, erststimme, zweitstimme) VALUES (${dwbid}, '${sz.gender}', ${sz.age}, ${sz.erststimme}, ${sz.zweitstimme});")
            })
        } */
    }
}
