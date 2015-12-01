import java.net.URL
import java.net.ConnectException

import akka.actor.{Actor, ActorRef, ActorSystem, Props, Terminated}
import akka.event.Logging

import uk.co.bigbeeconsultants.http.HttpBrowser
import uk.co.bigbeeconsultants.http.response.Response

import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import scala.util.Random


trait Query {
    def url:URL
    def prop:Float
}

case class GenericQuery(_url:String, _prop:Float) extends Query {
    def url = new URL(_url)
    def prop = _prop
}

object Q1 extends Query {
    def url = new URL("http://localhost:3000/seat-distribution/2013")
    def prop = 0.25f
}

object Q2 extends Query {
    def url = new URL("http://localhost:3000/delegates/2013")
    def prop = 0.25f
}

object MasterActor {
    case class Success(q:Query, t:Int)
    case class Failure(e:String)
    def props(n:Int, t:Int, queries:List[Query]) = Props(new MasterActor(n, t, queries))
}

class MasterActor(n:Int, t:Int, queries:List[Query]) extends Actor {
    import MasterActor._

    val logging = Logging(context.system, this)
    var responses:Map[Query, List[Int]] = Map[Query, List[Int]]()
    var fails:Int = 0

    var children = for (i <- 1 to n) yield context.actorOf(HttpDispatcherActor.props(t, queries), "Dispatcher" + i)

    def receive = {
        case Success(query, responseTime) => {
            val curr:List[Int] = responses.getOrElse(query, Nil)
            responses += (query -> (responseTime :: curr))
        }
        case Failure(error) => {
            logging.error(error)
            fails = fails + 1
        }
        case m => logging.info("received unknown message: " + m.toString)
    }
}

object HttpDispatcherActor {
    def props(t:Int, queries:List[Query]) = Props(new HttpDispatcherActor(t, queries))
}

class HttpDispatcherActor(t:Int, queries:List[Query]) extends Actor {
    import MasterActor._

    if (queries.length < 1) {
        context.parent ! Failure("Empty Query List")
        context stop self
    }

    val logging = Logging(context.system, this)

    def getQuery:Query = queries.head

    while (true) {
        val requestFuture:Future[(Query, Int)] = Future {
            val query = getQuery
            val response:Response = (new HttpBrowser).get(query.url)
            (query, response.status.code)
        }

        requestFuture onSuccess {
            case (query, responseTime) => {
                context.parent ! Success(query, responseTime)
                context stop self
            }
        }

        requestFuture onFailure {
            case error => {
                context.parent ! Failure(error.getMessage)
                context stop self
            }
        }
        val sleepTime = ((Random.nextFloat * 0.4f + 0.8f) * t).toLong
        Thread.sleep(sleepTime)
    }

    def receive = {
        case _ => logging.error("Received unknown message.")
    }
}


object BenchmarkClient extends App {
    // args : Array[String]
    val system = ActorSystem("BenchmarkClient")
    val myActor = system.actorOf(MasterActor.props(2, 10, List(Q2)), "Master")
    Thread.sleep(2000)
    system.terminate
}
