import java.util.Date
import java.net.URL
import java.net.ConnectException

import akka.actor.{Actor, ActorRef, ActorSystem, Props, Terminated, PoisonPill}
import akka.event.Logging

import uk.co.bigbeeconsultants.http.HttpBrowser
import uk.co.bigbeeconsultants.http.response.Response

import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import scala.util.Random
import scala.Console


trait Query {
    def url:URL
    def prop:Int
}

case class GenericQuery(_url:String, _prop:Int) extends Query {
    def url = new URL(_url)
    def prop = _prop
}

object Q1 extends Query {
    def url = new URL("http://localhost:3000/seat-distribution/2013")
    def prop = 25
    override def toString(): String = "Q1"
}

object Q2 extends Query {
    def url = new URL("http://localhost:3000/delegates/2013")
    def prop = 10
    override def toString(): String = "Q2"
}

object Q3 extends Query {
    def url = new URL("http://localhost:3000/wahlkreise/2013/1")
    def prop = 25
    override def toString(): String = "Q3"
}

object Q4 extends Query {
    def url = new URL("http://localhost:3000/wahlkreise/2013/winners")
    def prop = 10
    override def toString(): String = "Q4"
}

object Q5 extends Query {
    def url = new URL("http://localhost:3000/ueberhangmandate/2013")
    def prop = 10
    override def toString(): String = "Q5"
}

object Q6 extends Query {
    def url = new URL("http://localhost:3000/closest-winners/2013")
    def prop = 20
    override def toString(): String = "Q6"
}



object MasterActor {
    case class Success(q:Query, t:Long)
    case class Failure(e:String)
    def props(n:Int, t:Int, queries:List[Query]) = Props(new MasterActor(n, t, queries))
}

class MasterActor(n:Int, t:Int, queries:List[Query]) extends Actor {
    import MasterActor._
    import HttpDispatcherActor._

    val logging = Logging(context.system, this)
    var responses:Map[Query, List[Long]] = Map[Query, List[Long]]()
    var fails:Int = 0

    def printAvgs:Unit = {
        val avgs = responses.mapValues( ds => ds.sum / ds.length )
        avgs.map( (kvp:(Query, Long)) => println ( kvp._1 + "\t| " + kvp._2 ) )
        println("")
    }

    var c = 0
    // println("Running: " + c)

    def receive = {
        case Success(query, responseTime) => {
            // c = c + 1
            // print("\rRunning: " + c)

            val curr:List[Long] = responses.getOrElse(query, Nil)
            responses += (query -> (responseTime :: curr))
        }
        case Failure(error) => {
            // c = c + 1
            // print("\rRunning: " + c)

            logging.error(error)
            fails = fails + 1
        }
        case m => logging.info("received unknown message: " + m.toString)
    }

    override def postStop {
        println("\n\nResults from " + responses.values.map(_.length).sum + " Requests\n")
        printAvgs
        println("Failures: " + fails + "\n")
    }

    for (i <- 1 to n) {
        context.actorOf(HttpDispatcherActor.props(t, queries), "Dispatcher" + i)
    }
}

object HttpDispatcherActor {
    case class Fire(query:Query)
    def props(t:Int, queries:List[Query]) = Props(new HttpDispatcherActor(t, queries))
}

class HttpDispatcherActor(t:Int, queries:List[Query]) extends Actor {
    import MasterActor._
    import HttpDispatcherActor._

    var requestsSent = 0

    if (queries.length < 1) {
        context.parent ! Failure("Empty Query List")
        context.self ! PoisonPill
    }

    val logging = Logging(context.system, this)

    def getQuery:Query = {
        val pool = queries.flatMap( (q) => for (i <- 1 to q.prop) yield q )
        pool.apply(Random.nextInt(pool.size))
    }

    val browser = new HttpBrowser

    def receive = {
        case Fire(query) => {
            val requestFuture:Future[(Query, Long, Response)] = Future {
                val startTime = System.currentTimeMillis()
                val query = getQuery
                val response:Response = (new HttpBrowser).get(query.url)
                val endTime = System.currentTimeMillis()
                val responseTime = endTime - startTime
                (query, responseTime, response)
            }

            requestFuture onSuccess {
                case (query, responseTime, response) => {
                    if (response.status.isSuccess)
                        if (context != null && context.parent != null)
                            context.parent ! Success(query, responseTime)
                    else
                        if (context != null && context.parent != null)
                            context.parent ! Failure(response.status.message)
                }
            }

            requestFuture onFailure {
                case error => {
                    if (context != null && context.parent != null)
                        context.parent ! Failure(error.getMessage)
                }
            }

            requestsSent = requestsSent + 1

            val nextRequest:Future[Unit] = Future {
                // val sleepTime = ((Random.nextFloat * 0.4f + 0.8f) * t).toLong
                // Thread.sleep(sleepTime)
                if (context != null && context.self != null)
                    context.self ! Fire(getQuery)
            }

            /* try {
                val startTime = System.currentTimeMillis()
                val query = getQuery
                val response:Response = browser.get(query.url)
                val endTime = System.currentTimeMillis()
                val responseTime = endTime - startTime
                if (response.status.isSuccess)
                    if (context != null && context.parent != null)
                        context.parent ! Success(query, responseTime)
                else
                    if (context != null && context.parent != null)
                        context.parent ! Failure(response.status.message)
            } catch {
                case e:Exception => context.parent ! Failure(e.toString)
            } finally {
                context.self ! Fire(getQuery)
            } */
        }
        case _ => logging.error("Received unknown message.")
    }

    override def postStop {
        println(requestsSent)
    }

    context.self ! Fire(getQuery)
}


object BenchmarkClient extends App {
    // args : Array[String]
    val startTime = System.currentTimeMillis()
    val system = ActorSystem("BenchmarkClient")
    val master = system.actorOf(MasterActor.props(4, 20, List(Q1, Q2, Q3, Q4, Q5, Q6)), "Master")

    Console.in.read()

    val endTime = System.currentTimeMillis()
    val responseTime = endTime - startTime

    println("After running for " + responseTime + "ms")

    master ! PoisonPill
}
