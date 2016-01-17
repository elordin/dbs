package benchmark

import spray.http.Uri

trait Query {
    def uri:Uri
    def prop:Int
}

case class GenericQuery(name:String, _uri:String, _prop:Int) extends Query {
    def uri = Uri(_uri)
    def prop = _prop
    override def toString:String = name
}

object Q1 extends Query {
    def uri = Uri("http://localhost:3000/seat-distribution/2013")
    def prop = 25
    override def toString(): String = "Q1"
}

object Q2 extends Query {
    def uri = Uri("http://localhost:3000/delegates/2013")
    def prop = 10
    override def toString(): String = "Q2"
}

object Q3 extends Query {
    def uri = Uri("http://localhost:3000/wahlkreise/2013/1")
    def prop = 25
    override def toString(): String = "Q3"
}

object Q4 extends Query {
    def uri = Uri("http://localhost:3000/wahlkreise/2013/winners")
    def prop = 10
    override def toString(): String = "Q4"
}

object Q5 extends Query {
    def uri = Uri("http://localhost:3000/ueberhangmandate/2013")
    def prop = 10
    override def toString(): String = "Q5"
}

object Q6 extends Query {
    def uri = Uri("http://localhost:3000/closest-winners/2013")
    def prop = 20
    override def toString(): String = "Q6"
}
